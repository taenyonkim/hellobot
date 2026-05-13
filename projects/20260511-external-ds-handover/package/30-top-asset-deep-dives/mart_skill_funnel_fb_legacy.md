# F-103 — `hlb_mart.mart_skill_funnel_fb` 시맨틱 baseline (★ 레거시)

> **외부 전달용 안내** — 본 문서는 내부 dbt 마이그 분석 과정에서 작성된 자산 baseline 카드입니다. 본문 중 "Tier 1~4", "dbt 마이그 가이드", "F-NNN" 등 내부 의사결정 마커는 무시하셔도 됩니다. 자산의 **그레인 · 컬럼 · 비즈 룰 · 외부 의존** 정보만 분석 참고용으로 활용하세요.

| 항목 | 값 |
|---|---|
| Phase | P2 |
| 중요도 | ★★★ (다운스트림 23, F-001 3위) — 그러나 **레거시** 명시 자산 |
| 상태 | 확정 (★ 레거시 vs v2 결정 필요) |
| 작성일 | 2026-05-01 |
| 출처 | SQL 본문 (line 3 "레거시 테이블" 코멘트) + queries.py + `bq show` 실측 + F-001 raw |

## 0. ★ 레거시 명시 자산

본 마트의 SQL 본문 [`mart_skill_funnel_fb.sql:3`](../../../../../common-data-airflow/dags/scripts/hellobot/mart/mart_skill_funnel_fb.sql) 코멘트에 **"레거시 테이블"** 명시:

```sql
-- 데이터 소스 : firebase
-- 데이터 필터링 조건 : 헬로우봇 스킬퍼널 관련 이벤트 마트 테이블 (레거시 테이블)
```

**그러나**:
- 다운스트림 23 SQL = report 22 + queries.py 1 — **report 영역 활성 사용 중**
- 후속 v2 마트 `mart_v2_skill_funnel_fb` 존재 (다운스트림 4 — F-001 27위)
- 카탈로그에는 `mart_v2_skill_funnel_fb.md` 카드만 있고 **본 v1 카드 없음**

→ dbt 마이그 시 **결정 필요**: (A) 레거시 폐기 + report 22 SQL 을 v2 로 마이그 / (B) 보존 / (C) 양쪽 유지. **Tier 3 (재정의 + 합의)** 에 해당.

## 1. 자산 메타 (실측)

| 항목 | 값 |
|---|---|
| Full name | `hellobot-f445c.hlb_mart.mart_skill_funnel_fb` |
| 행 수 | 124,633,580 (1.25억) |
| 크기 | 35.38 GB |
| 파티션 | `DAY (event_date)` |
| 클러스터링 | 없음 |
| 컬럼 수 | 47 |
| Materialization | `DELETE + INSERT` (멱등) |
| 마지막 갱신 | 2026-05-01 (활성) — 레거시지만 매일 빌드 중 |

## 2. 그레인

```
1 row = (event_date × event_timestamp × user_id_processed × event_name)
```

- 4종 이벤트: `view_enter_name`, `click_start_button`, `open_skill_description`, `open_coaching_program_description`
- 동일 사용자가 같은 시점에 다른 이벤트 발화하면 다중 행

## 3. 핵심 컬럼 시맨틱 (47개)

### 시간 (6) + 사용자 ID (1)
- `event_date` (파티션) / `event_timestamp` / `event_month` / `event_week` / `start_of_week` / `end_of_week`
- `user_id_processed` (표준 ID)

### 이벤트
- `event_name` ∈ {`view_enter_name`, `click_start_button`, `open_skill_description`, `open_coaching_program_description`}

### 챗봇·메뉴·블록 (event_params 추출 + 조인)
| 컬럼 | 출처 | 비고 |
|---|---|---|
| `chatbot_seq` | event_params.chatbot_seq | INT/STRING COALESCE |
| `chatbot_name` `chatbot_category` `chatbot_created_at_date` | `staging_chatbot_server` 조인 (`scs.id = chatbot_seq`) | |
| `menu_seq` | event_params.menu_seq → block.menu_seq 폴백 | |
| `menu_name` | `staging_fixed_menu_copy` 조인 | |
| `block_seq` `block_name` | event_params.block_seq + `staging_block_copy_server` 조인 | |

### 가격 (4)
| 컬럼 | event_params 키 | 타입 | NULL |
|---|---|---|---|
| `price` | `price` | INTEGER | event_params 에 키 부재 시 NULL |
| `current_price` | `currentPrice` 우선, `current_price` 폴백 (camelCase ↔ snake_case 혼재) | INTEGER | NULL |
| `current_unlock_price` `unlock_price` | 동명 키 | INTEGER | NULL |

### 마케팅 추적 (5)
- `source` `medium` `term` `campaign` `referral` `event_category` `is_in_package` `is_free_today` (event_params 추출)

### 사용자 디멘전 (16)
`country` `platform` `language` `operating_system` `version` 등 + user_* (디멘전 보강)

## 4. 비즈 룰 (보존 필수)

### 4-1. event_params 추출 패턴 (Firebase 표준)
```sql
(SELECT COALESCE(CAST(value.int_value AS STRING), value.string_value)
 FROM UNNEST(event_params)
 WHERE key="chatbot_seq") AS chatbot_seq
```
- `chatbot_seq`, `menu_seq` 는 **INT 또는 STRING 둘 중 하나** 로 발화 → COALESCE 로 STRING 통일
- → 이벤트 발송 시 타입 일관성 부재 (클라이언트별 차이 추정) — Firebase 이벤트 일반 패턴

### 4-2. `chatbot_seq != "0"` 필터 (line 73)
```sql
WHERE (... chatbot_seq) != "0"
```
- chatbot_seq 가 `"0"` 인 이벤트는 제외 — **운영 룰 (테스트 봇 또는 invalid 데이터)**
- → 이 룰의 historical 출처 미명문화 (P6 수집 후보)

### 4-3. `current_price` 다중 키 폴백
- camelCase (`currentPrice`) 우선, snake_case (`current_price`) 폴백
- → 클라이언트 마이그 흔적 (네이밍 컨벤션 변경 historical)

### 4-4. event_params NULL 동작
- event_params 에 해당 키 부재 시 NULL — **데이터 누락이 아니라 정상**
- → 다운스트림에서 NULL 처리 가정 필요

## 5. ★ 알려진 결함 (보존 필수 X — 마이그 시 정리)

### 5-1. **Alias 오타** — `pricegit`
SQL line 36:
```sql
(SELECT value.int_value FROM UNNEST(event_params) WHERE key="price") AS pricegit,
```

- alias 가 `pricegit` (오타 — `price` 의도?)
- 그러나 BQ 실제 스키마는 `price` (정상) — **`INSERT INTO` 가 컬럼 명시 없이 SELECT 결과를 destination 컬럼 순서대로 매핑하기 때문**
- → SQL alias 무시되고 destination 의 `price` 위치에 들어감 (정상 동작)
- → **dbt 마이그 시 alias 정정** (코드 가독성)

→ MP-2 개선 후보 1.

### 5-2. SQL 코멘트와 alias 의 일관성 부족
- 일부 컬럼 alias 가 SQL 본문 코멘트와 다름 (예: `pricegit` 외 line 38 `event_category` 코멘트 "click_start_button")
- → dbt 마이그 시 자가 문서화 일관성 강화

## 6. 외부·내부 의존

### 업스트림
- `hlb_intermediate.intermediate_ir_dashboard_metrics_fb` (직접 base — F-004 검증 활성 자산)
- `hlb_staging.staging_block_copy_server` (블록 메타)
- `hlb_staging.staging_fixed_menu_copy` (메뉴 메타)
- `hlb_staging.staging_chatbot_server` (챗봇 메타)

### 다운스트림 (23 SQL — F-001 raw 정확한 list)

| 카테고리 | 파일 |
|---|---|
| **mart** | `queries.py` (자체) |
| **report (22)** | `report_activation_monthly{,_app,_web}` (3) / `report_chatbot_info_daily` / `report_key_metrics_by_{daily,monthly,weekly,platform_daily}` / `report_key_metrics_kr_by_daily` / `report_key_metrics_new_user_by_platform_daily` / `report_kpi_total_skill_{monthly,weekly}{,_platform_app,_platform_web}` (6) / `report_skill_info_{daily,mybot,origin}` (3) / `report_skill_referral_mkt_daily` / `report_total_metrics_ip_{monthly,weekly}` (2) |

→ **report 22 SQL** = 본 레거시 마트 의존. v2 로 마이그하려면 22개 SQL 재작성 필요.

### KPI 알림 직접 의존
없음 (본 마트는 report 만 → kpi_noti 는 report 결과 사용). 단 report 가 KPI 알림 source 라 간접 영향.

