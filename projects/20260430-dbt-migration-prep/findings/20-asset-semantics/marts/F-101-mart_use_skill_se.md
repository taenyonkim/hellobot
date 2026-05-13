# F-101 — `hlb_mart.mart_use_skill_se` 시맨틱 baseline

| 항목 | 값 |
|---|---|
| Phase | P2 |
| 중요도 | ★★★ (다운스트림 47, F-001 1위, KPI 알림 직접 의존) |
| 상태 | 확정 |
| 작성일 | 2026-05-01 |
| 출처 | 카탈로그 [tables/mart/mart_use_skill_se.md](../../../../../common-data-airflow/docs/hellobot-data/catalog/tables/mart/mart_use_skill_se.md) + SQL 본문 + queries.py destination DDL + `bq show` 실측 + F-001/F-003 cross-link |
| affects-ssot | yes — 1건 stale (파티션) v2 인계 |
| affects-tier | **Tier 1·2 후보** — 보존 권장 강도 ★★★ |

## 1. 자산 메타 (실측)

| 항목 | 값 |
|---|---|
| Full name | `hellobot-f445c.hlb_mart.mart_use_skill_se` |
| 행 수 | 201,435,590 (2.01억) |
| 크기 | 57.19 GB |
| **파티션** | **DAY (`event_date`)** ★ ([카탈로그 stale](../../../../../common-data-airflow/docs/hellobot-data/catalog/tables/mart/mart_use_skill_se.md): "*미지정*" 으로 표기 — v2 인계) |
| 클러스터링 | 없음 |
| 컬럼 수 | 51 |
| Materialization | `DELETE + INSERT` (멱등 재실행 가능, queries.py 안에서 정의) |
| 스케줄 | 매일 KST 11시경 (mart pipeline 체인) |
| 마지막 갱신 | 2026-05-01 (활성) |
| 생성일 | 2025-06-24 |

## 2. 그레인 (1 row 의 의미)

```
1 row = (user × event_timestamp × event_name)
```

- 같은 사용자가 같은 시점에 다른 이벤트(`enter_skill` + `consume_skill`) 발화하면 **2 rows**
- `menu_seq` 는 NULL 가능 (`collection_seq` 만 있는 케이스) — 그레인 키에서 제외
- 카탈로그 표현 "user × event_timestamp × menu_seq" 는 부분적으로 부정확 — **menu_seq 는 dimension** (NULL 허용)

## 3. 핵심 컬럼 시맨틱 (51개 중 마이그·KPI 영향 큰 항목)

### 시간 (6개 — 전부 정규화 디멘전)
| 컬럼 | 의미 | NULL | 가정 |
|---|---|---|---|
| `event_date` | KST 일자 (파티션 키) | NOT NULL | UTC→KST 변환됨 |
| `event_timestamp` | 발화 시점 (UTC TIMESTAMP) | NOT NULL | |
| `event_month` `event_week` `start_of_week` `end_of_week` | 사전 계산 시간 디멘전 | - | dbt date_dim 으로 추출 가능 (개선 후보) |

### 이벤트 / 사용자
| 컬럼 | 의미 | NULL | 가정 |
|---|---|---|---|
| `event_name` | 8종: `enter_skill`/`consume_skill`/`pay_for_contents`/`pay_for_package`/`pay_for_coaching_program`/`pay_for_collection`/`pay_for_chatbot_subscription`/**`pay_under_750`** | NOT NULL | `pay_under_750` 는 파생 — `pay_for_contents` 중 총 매출 < 750 KRW 케이스 |
| `user_id` | 사용자 ID (`user_id_processed` 와 다름 주의) | NOT NULL | 서버 발송 이벤트라 `user_id` 자체가 표준 — `user_pseudo_id` 폴백 X |

### 챗봇·메뉴·블록 (다단 COALESCE 의 결과)
| 컬럼 | 우선순위 |
|---|---|
| `chatbot_seq` `chatbot_name` `chatbot_category` `chatbot_original_type` | 서버 chatbot (`scs1`) → 이벤트 파라미터 → 블록 chatbot (`scs2`) → collection chatbot (`scs3`) |
| `menu_seq` `menu_name` | 서버 메뉴 (`sfmc`) → 이벤트 파라미터 → 블록 폴백 (`"[스킬 정보 없음] 블록: ..."`) |
| `menu_is_open` | 서버 노출 여부 (`sfmc.is_open`) |
| `block_seq` `block_name` | 블록 메타 (`sbcs`) 또는 이벤트 파라미터 폴백 |

### 결제·매출 (★ KPI 직접 의존)
| 컬럼 | 의미 | NULL | 비고 |
|---|---|---|---|
| `spent_heart_coin` | 유료 구매 하트 사용량 (개) | 0 = 비사용 | |
| `spent_bonus_heart_coin` | 보너스 하트 (프로모션) | 0 | **revenue_krw 계산에서 제외** |
| `spent_cash_amount` | 현금 결제액 (FLOAT, 통화 단위는 `spent_cash_currency`) | 0 / NULL | |
| `spent_cash_currency` | KRW / JPY / USD 등 | NULL = 무료/하트 결제 | |
| `spent_cash_amount_krw` | `spent_cash_amount × cr.rate` (KRW 환산) | NULL | GSheet 환율 의존 |
| `spent_total_amount_krw` | **유료 + 보너스 하트 + 현금** (할인가 / 표시 가격) | NULL | 보너스 포함 |
| **`revenue_krw`** | **유료 하트 + 현금** = 실제 매출 (보너스 제외) | NULL | **★ HelloBot 의 매출 표준 — 모든 KPI 의 1차 정의** |

### 채널·플랫폼·사용자 속성 (16개)
사용자 디멘전 (channel/platform/locale/country/language/gender/birth/age/created_at/is_new_*/in_app_language/product_category) — 분석 슬라이스용. KPI 알림은 일부만 사용 (platform 등).

### 패키지·콜렉션 (7개)
`package_*`, `unlock_*`, `current_*`, `collection_*` — 결제 카테고리별 메타. 빈도 낮음.

## 4. 비즈 룰 (보존 필수)

### 4-1. `revenue_krw` 매출 표준
```sql
revenue_krw = IFNULL(spent_heart_coin, 0) * KRW_PER_HEART
            + IFNULL(spent_cash_amount * cr.rate, 0)
```
- **`KRW_PER_HEART = 150`** (queries.py 안 DDL 에서 DECLARE)
- 보너스 하트 (`spent_bonus_heart_coin`) **제외**
- 외화 결제는 GSheet `google_sheet_sync.currency_rate` 의 `cr.rate` 로 환산
- → **dbt 마이그 시 `KRW_PER_HEART` 를 dbt var 로 통합 권장 (개선 후보 §6-2)**

### 4-2. `pay_under_750` 파생 룰
```sql
event_name = CASE
  WHEN event_name = "pay_for_contents"
   AND (heart_value + bonus_heart_value + cash_value_krw) < 750
  THEN "pay_under_750"
  ELSE event_name
END
```
- 750 KRW 미만 결제 = 별도 분류 (저가 상품 분석 분리 의도)
- 원본 `pay_for_contents` 건수만 세려면 **`pay_under_750` 포함 필수**
- → dbt 마이그 시 임계값 (750) 을 dbt var 권장

### 4-3. chatbot/menu 다단 COALESCE (역사 보존)
- 서버 메뉴 삭제·변경 시에도 과거 이벤트의 chatbot·menu 문맥이 보존됨
- 단점: "동일 menu_seq 인데 menu_name 이 다른 행" 가능 (시점별 메타 다름)
- → dbt 마이그 시 CTE 분리 또는 dbt macro 로 추상화 권장 (개선 후보)

### 4-4. 외화 환율 의존
- `google_sheet_sync.currency_rate` (운영자 수동 갱신 GSheet)
- 환율 미갱신 시 외화 결제 KRW 환산 부정확
- → dbt source + freshness test 권장

## 5. 외부·내부 의존

### 업스트림
- `hlb_intermediate.intermediate_use_skill_se` (직접 base)
  - ← `hlb_intermediate.intermediate_key_metrics_se` (사용자 조인)
  - ← `hlb_staging.staging_key_events_se` (서버 이벤트 정제)
- `hlb_staging.staging_fixed_menu_copy` (메뉴 메타, RDS 스냅샷)
- `hlb_staging.staging_block_copy_server` (블록 메타)
- `hlb_staging.staging_chatbot_server` (챗봇 메타) — 3번 다른 키로 조인 (`scs1/scs2/scs3`)
- `google_sheet_sync.currency_rate` (환율, GSheet)

### 다운스트림 (47 SQL files — F-001 1위)
| 카테고리 | 다운스트림 | 비고 |
|---|---|---|
| **mart 자체** | `mart_skill_open_date_se` | mart→mart 참조 ([ISS-003](../../../../../common-data-airflow/docs/hellobot-data/catalog/issues.md) 레이어 위반) |
| **mart_integrated** | `union_mart_user_key_actions` (본진) + 4 union 마트 | 매출 정합 기준 |
| **mart_adhoc** | `adhoc_mart_user_rfm_info_daily` 외 | RFM 계산 기준 이벤트 |
| **pre_report** | 4 SQL | 매출 코호트 |
| **report** | **31 SQL** | 매출·KPI 보고 본진 |
| **tf_report** | 2 SQL | 회사 KPI |
| **kpi_noti** | `queries.py` | ★★★ Slack KPI 알림 직접 |

### KPI 알림 직접 의존 (★★★ 보존 강도 최상)

[F-003 §2 / kpi_noti/queries.py](../../../../../common-data-airflow/dags/scripts/hellobot/kpi_noti/queries.py) 분석 결과 다음 알림이 본 마트를 직접 사용:

| 함수 / 알림 | 컬럼 의존 | 채널 |
|---|---|---|
| `hlb_fs_new_skill_pay_amounts` (FS 챗봇팀) | `menu_seq`, `menu_name`, `spent_cash_amount`, `spent_heart_coin`, `event_name = "pay_for_contents"` | `C06QV5555A7` (#div_chatbot_biz) |
| `hlb_fs_new_skill_total_pay_amounts` | 동일 | 동일 |
| `hlb_marketing_contribution_margins` | `revenue_krw`, channel·platform | 동일 |
| `hlb_monthly_pay_amounts` | `revenue_krw`, `event_date` | 동일 |

→ **변경 영향**: 컬럼명·계산식 변경 시 위 4개 알림 SQL 동시 수정 필요. KRW_PER_HEART 변경은 더 광범위 (KPI noti 안에서도 `* 150` 직접 곱셈 사용 — 변수 미통합).

## 6. dbt 마이그 가이드

### 6-1. Tier 분류 권장: **Tier 1 (그대로 이식) 또는 Tier 2 (보존하며 재구현)**

| 평가 축 | 결과 |
|---|---|
| 시맨틱 명확도 | **명확** (카탈로그 + 본 카드로 충분히 정의됨) |
| 의존 단순도 | 복잡 (47 다운스트림 + KPI 알림 4) |
| 외부 인터페이스 | **있음** (KPI 알림 직접) — MP-1 trade-off 권장 보존 |
| 시맨틱 변경 가치 (MP-2) | 중간 — naming 개선 가치는 있으나 보존 부담이 큼 |

→ **추천**: Tier 2 (보존하며 재구현, dbt 표준 패턴 적용 + 시맨틱 동일)

### 6-2. dbt 모델 설정 권장

```yaml
# models/marts/hellobot/skill/mart_use_skill_se.sql
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={'field': 'event_date', 'data_type': 'date'},
    unique_key=['event_timestamp', 'user_id', 'event_name'],
) }}
```

### 6-3. 보존 필수 항목 (변경 X)

- 51개 컬럼 이름 (특히 `revenue_krw`, `spent_*`, `menu_*`, `chatbot_*`)
- `event_name` 8종 enum (특히 파생 `pay_under_750`)
- `revenue_krw` 산식 (유료 하트 × 150 + 현금 KRW)
- 다단 COALESCE 의 우선순위 룰 (4-3)
- KRW_PER_HEART = 150
- `pay_under_750` 임계값 = 750

### 6-4. 개선 후보 (MP-2 — 사용자 합의 후)

| # | 개선안 | 영향 | 가치 vs 부담 |
|---|---|---|---|
| 1 | `KRW_PER_HEART` 를 **dbt var 로 통합** | 본 SQL + mart_integrated 7곳 + kpi_noti 직접 곱셈 | 가치 高 (단일 진실원천) / 부담 中 (KPI 알림 SQL 도 동시 수정) |
| 2 | `pay_under_750` 임계값을 dbt var | 본 SQL + 분석 쿼리 다수 | 가치 中 / 부담 低 |
| 3 | chatbot/menu 다단 COALESCE 를 **dbt macro** 로 추상화 | 본 SQL 가독성 +50줄 → +5줄 | 가치 中 / 부담 低 |
| 4 | `currency_rate` GSheet 를 **dbt source + freshness test** | 환율 미갱신 시 데이터 품질 알림 | 가치 高 / 부담 低 |
| 5 | `spent_cash_amount` 의 FLOAT → NUMERIC 변경 | 통화 정확도 | 가치 中 / 부담 低 (단 다운스트림 47 영향 검토) |
| 6 | 컬럼 naming 개선 (`spent_cash_amount_krw` → `cash_spent_krw`) | 가독성 | 가치 低 / 부담 高 (다운스트림 47 + KPI 알림 동시 수정) — **권장 X** |

→ **권장 MP-2 적용 1·2·3·4** (5·6 은 보존 우선)

### 6-5. 위험 요소

- **mart→mart 참조**: `mart_skill_open_date_se` 가 본 마트를 source 로 사용 (ISS-003 레이어 위반). dbt 마이그 시 dependency graph 에 영향
- **KRW_PER_HEART 7곳 중복**: 본 SQL 의 DDL + mart_integrated 7 SQL + kpi_noti 직접 곱셈 → 변경 시 모두 수정 필요
- **외화 결제 환율 stale**: GSheet 미갱신 시 KRW 환산 오류 (자동 알림 부재)
- **51 컬럼**: dbt 모델로 옮길 때 컬럼 누락 검증 필요 (dbt schema test)

## 7. 답할 수 있는·없는 질문

### 답할 수 있는
- 일별 유료 결제 건수·금액 (`pay_for_*` 합)
- 스킬별 진입→결제 전환율 (`enter_skill` → `pay_for_contents`)
- 저가 결제 비중 (`pay_under_750` 비율)
- 특정 스킬·챗봇의 총 매출·구매자 수
- 결제 통화별 비중

### 답할 수 없는 (다른 마트 필요)
| 필요 | 가야 할 곳 |
|---|---|
| Firebase 인앱 결제 (스토어) | `mart_purchase_fb` |
| 이벤트 파라미터 원본 | `intermediate_use_skill_se` |
| 비결제 이벤트 (`view_*`/`click_*`) | `mart_v2_skill_funnel_fb` / `mart_home_action_fb` |
| 누적·코호트·LTV | `union_mart_user_key_actions` (본 마트 기반) |

## 8. 후속 액션

- [x] 본 카드 작성 (2026-05-01)
- [ ] **stale 발견 v2 인계 (★ 추가 1건)** — 카탈로그 카드의 "파티션: *미지정*" 표현 → 실제 `DAY (event_date)` 로 정정
- [ ] (P7) Tier 결정 — Tier 2 (보존하며 재구현) 권장
- [ ] (후속 dbt 프로젝트) 6-4 개선안 1·2·3·4 적용 검토

## 참조

- 카탈로그: [tables/mart/mart_use_skill_se.md](../../../../../common-data-airflow/docs/hellobot-data/catalog/tables/mart/mart_use_skill_se.md)
- SQL: [scripts/hellobot/mart/mart_use_skill_se.sql](../../../../../common-data-airflow/dags/scripts/hellobot/mart/mart_use_skill_se.sql)
- 다운스트림 47 list: [F-001-data-mart-downstream.tsv](../../10-usage-frequency/F-001-data-mart-downstream.tsv)
- KPI 알림 매핑: [F-003 §2](../../10-usage-frequency/F-003-external-interfaces.md#2-slack-kpi-알림--채널소스-마트-매핑-보존-필수)
