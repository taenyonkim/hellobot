# F-102 — `hlb_intermediate.intermediate_user_daily_info` 시맨틱 baseline

> **외부 전달용 안내** — 본 문서는 내부 dbt 마이그 분석 과정에서 작성된 자산 baseline 카드입니다. 본문 중 "Tier 1~4", "dbt 마이그 가이드", "F-NNN" 등 내부 의사결정 마커는 무시하셔도 됩니다. 자산의 **그레인 · 컬럼 · 비즈 룰 · 외부 의존** 정보만 분석 참고용으로 활용하세요.

| 항목 | 값 |
|---|---|
| Phase | P2 |
| 중요도 | ★★★ (다운스트림 26, F-001 2위, KPI 알림 + 18 report SQL 의존) |
| 상태 | 확정 |
| 작성일 | 2026-05-01 |
| 출처 | SQL 본문 + queries.py + `bq show` 실측 |

> ℹ️ 카탈로그(`tables/intermediate/`)에 본 마트의 정식 카드는 아직 없는 상태입니다 (intermediate 레이어 전체 미작성). 본 baseline 카드를 참고 자료로 사용하세요.

## 1. 자산 메타 (실측)

| 항목 | 값 |
|---|---|
| Full name | `hellobot-f445c.hlb_intermediate.intermediate_user_daily_info` |
| 행 수 | 61,696,447 (6,170만) |
| 크기 | 11.02 GB |
| 파티션 | `DAY (event_date)` |
| 클러스터링 | 없음 |
| 컬럼 수 | 26 |
| Materialization | `DELETE + INSERT` (멱등 재실행) |
| 스케줄 | 매일 KST 11시경 (intermediate pipeline 체인) |
| 마지막 갱신 | 2026-05-01 (활성) |
| 생성일 | 2023-11-29 |

## 2. 그레인 (1 row 의 의미)

```
1 row = (event_date × user_id_processed)
```

- **DISTINCT 명확**: SQL 의 `ROW_NUMBER() OVER(PARTITION BY event_date, user_id_processed ORDER BY fb_order ASC)` + `WHERE rn = 1` 로 보장
- 사용자가 같은 날 Firebase + Server 양쪽에 발화해도 **Firebase 데이터 1행만 유지** (Server 폴백)
- → **DAU 계산의 진실 원천** (`COUNT(DISTINCT user_id_processed)` 가 자연스러움)

## 3. 핵심 컬럼 시맨틱 (26개)

### 시간 (5)
| 컬럼 | 의미 |
|---|---|
| `event_date` | KST 일자 (파티션 키, NOT NULL) |
| `event_month` `event_week` `start_of_week` `end_of_week` | 사전 계산 시간 디멘전 |

### 사용자 ID (3)
| 컬럼 | 의미 | NULL |
|---|---|---|
| `user_id` | 로그인 사용자 ID | NULL 가능 (비로그인) |
| `user_pseudo_id` | Firebase 자동 생성 anonymous ID | Firebase 이벤트만 |
| `user_id_processed` | **표준 ID** (APP 19/4+ user_id, 그 전 user_pseudo_id) | NOT NULL |

→ **`user_id_processed` 가 그레인 키 + 모든 분석의 기준**. 카탈로그 §결정적 컨벤션과 일치.

### 사용자 디멘전 (12)
`language` `country` `platform` `operating_system` `operating_system_version` `version` `gender` `birth_year` `birth_month` `birth_day` `age` `user_type` `in_app_language`

→ 분석 슬라이스용 (KPI 알림은 `platform` 위주 사용).

### 데이터 소스 추적 (2)
| 컬럼 | 의미 |
|---|---|
| `event_source` | `"fb_events"` 또는 `"server_events"` — 어느 쪽이 살아남았는지 |
| `rn` | ROW_NUMBER 결과 (필터 후 항상 1 — **불필요 컬럼**, MP-2 제거 후보) |

### 신규 사용자 플래그 (3)
| 컬럼 | 의미 |
|---|---|
| `user_created_at` | 사용자 최초 가입일 (`intermediate_user_first_info` 조인) |
| `is_new_month` | 이벤트 월 == 가입 월 |
| `is_new_week` | 이벤트 주 == 가입 주 (월요일 기준) |

→ DAU/WAU/MAU 안에서 신규 vs 기존 분기의 1차 신호.

## 4. 비즈 룰 (보존 필수)

### 4-1. UNION + ROW_NUMBER 우선순위 (가장 중요)
```sql
UNION ALL (
  Firebase events with fb_order=1
  Server events  with fb_order=2
)
→ ROW_NUMBER() OVER(PARTITION BY event_date, user_id_processed ORDER BY fb_order ASC)
→ WHERE rn = 1
```

- **Firebase 우선**, Server 폴백
- 의도: Firebase 가 더 풍부한 사용자 디멘전 (gender·age·birth_*) 을 가짐 → Firebase 가 있으면 그것을 사용
- 결과: 한 사용자가 한 날에 양쪽에 발화해도 행 1개만 유지

### 4-2. `user_id_processed` 표준 (보존 필수)
- APP 2019-04-01+ / WEB 2022-12-01+ 이후 → `user_id`
- 그 전 → `user_pseudo_id`
- → 카탈로그 §결정적 컨벤션 + `intermediate_user_daily_info_temp_*` 에서 결정됨 (본 마트는 그 결과를 받기만 함)

### 4-3. `is_new_*` 산식
```sql
is_new_month = FORMAT_DATE("%Y-%m", event_date) = FORMAT_DATE("%Y-%m", user_created_at)
is_new_week  = FORMAT_DATE("%Y-%Ww", DATE_TRUNC(event_date, WEEK(MONDAY)))
             = FORMAT_DATE("%Y-%Ww", DATE_TRUNC(user_created_at, WEEK(MONDAY)))
```
- 주차 기준 = **MONDAY** (보존 필수)
- → 다운스트림 활성·코호트 분석의 정의 기반

### 4-4. `intermediate_user_first_info` LEFT JOIN
- `user_created_at` 가 없으면 (= 가입 정보 부재) `is_new_*` 가 NULL
- LEFT JOIN 이라 raw 사용자 행은 보존 (가입 정보 없어도 표시)

## 5. 외부·내부 의존

### 업스트림 (3)
- `hlb_intermediate.intermediate_user_daily_info_temp_fb` (Firebase staging 결과)
- `hlb_intermediate.intermediate_user_daily_info_temp_se` (Server staging 결과)
- `hlb_intermediate.intermediate_user_first_info` (가입일 lookup)

→ `_temp_fb` 와 `_temp_se` 가 실제 staging 변환 (테스터 제외, env 필터, KST 변환 등) 을 수행. 본 마트는 그 결과를 UNION + dedup 만.

### 다운스트림 (26 SQL files — F-001 2위, 정확한 list)

| 카테고리 | 파일 수 | 상세 |
|---|---|---|
| **intermediate (4)** | 자체 + 3 | `intermediate_key_metrics_fb`, `intermediate_key_metrics_se`, `intermediate_marketing_utm_first_fb`, `queries.py` |
| **mart (1)** | | `mart_user_daily_info` (mart 레이어로 승격) |
| **mart_adhoc (1)** | | `adhoc_mart_user_rfm_info_daily` (RFM 계산 기준) |
| **pre_report (1)** | | `pre_report_cohort_retention_visit` |
| **report (18)** | DAU/리텐션 본진 | `report_activation_monthly{,_app,_web}`, `report_key_metrics_by_{daily,monthly,weekly,platform_daily}`, `report_key_metrics_kr_by_daily`, `report_key_metrics_new_user_by_platform_daily`, `report_kpi_total_skill_{monthly,weekly}{,_platform_app,_platform_web}`, `report_revenue_monthly{,_app,_web}` |
| **kpi_noti (1)** | KPI 알림 직접 | `queries.py` |

→ **report 18 SQL 의존 = 활성·매출·KPI 보고의 사용자 1차 진실 원천**. 변경 영향 매우 큼.

### KPI 알림 직접 의존

[kpi_noti/queries.py](../../../../../common-data-airflow/dags/scripts/hellobot/kpi_noti/queries.py) 에서 본 마트 직접 사용:
- `get_user_data` 함수 → DAU/WAU/MAU 계산 → 챗봇 프로덕트팀 Slack 채널
- 변경 시 KPI 알림 SQL 수정 필요

