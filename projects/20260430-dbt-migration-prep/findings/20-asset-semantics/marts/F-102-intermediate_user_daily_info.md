# F-102 — `hlb_intermediate.intermediate_user_daily_info` 시맨틱 baseline

| 항목 | 값 |
|---|---|
| Phase | P2 |
| 중요도 | ★★★ (다운스트림 26, F-001 2위, KPI 알림 + 18 report SQL 의존) |
| 상태 | 확정 |
| 작성일 | 2026-05-01 |
| 출처 | SQL 본문 + queries.py + `bq show` 실측 + F-001 raw 데이터 |
| affects-ssot | **yes (★ 큰 갭)** — 카탈로그 `tables/intermediate/` 디렉토리 자체 미작성. 본 카드가 1차 카탈로그 보강 가치 |
| affects-tier | **Tier 1 후보** — 그레인 명확, 의존 단순 (UNION + ROW_NUMBER), KPI 알림 직접 |

## 0. 카탈로그 갭 발견 (★ v2 인계 추가)

**`common-data-airflow/docs/hellobot-data/catalog/tables/`** 에 `intermediate/` 디렉토리가 **존재하지 않음**. `mart/`, `mart_adhoc/`, `mart_integrated/` 만 존재. 즉 **`hlb_intermediate.*` 25개 테이블 전체의 카탈로그 카드가 미작성** 상태. 본 마트는 다운스트림 2위인데도 카탈로그 카드 부재.

→ 본 baseline 카드가 1차 카탈로그 보강 후보. v2 §신규 과업 14번째로 인계.

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
- `get_user_data` 함수 → DAU/WAU/MAU 계산 → 챗봇 프로덕트팀 채널 (`C06QV5555A7` #div_chatbot_biz)
- 변경 시 KPI 알림 SQL 수정 필요

## 6. dbt 마이그 가이드

### 6-1. Tier 분류 권장: **Tier 1 (그대로 이식)** 후보

| 평가 축 | 결과 |
|---|---|
| 시맨틱 명확도 | **매우 명확** (그레인 명확, UNION + ROW_NUMBER 패턴 표준) |
| 의존 단순도 | 단순 (업스트림 3개) |
| 외부 인터페이스 | 있음 (KPI 알림 + 18 report SQL) — 보존 권장 |
| 시맨틱 변경 가치 (MP-2) | 낮음 — 기존 구조가 dbt 패턴과 잘 align |

→ **추천**: Tier 1 (그대로 이식, dbt 표준 패턴 적용)

### 6-2. dbt 모델 설정 권장

```yaml
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={'field': 'event_date', 'data_type': 'date'},
    unique_key=['event_date', 'user_id_processed'],
) }}

WITH unioned AS (
    SELECT *, 1 AS source_priority FROM {{ ref('intermediate_user_daily_info_temp_fb') }}
    UNION ALL
    SELECT *, 2 AS source_priority FROM {{ ref('intermediate_user_daily_info_temp_se') }}
),
deduped AS (
    SELECT * EXCEPT(source_priority),
           ROW_NUMBER() OVER(PARTITION BY event_date, user_id_processed ORDER BY source_priority) AS rn
    FROM unioned
)
SELECT d.* EXCEPT(rn),
       ufi.event_date AS user_created_at,
       ...
FROM deduped d
LEFT JOIN {{ ref('intermediate_user_first_info') }} ufi USING (user_id_processed)
WHERE rn = 1
```

### 6-3. 보존 필수 항목 (변경 X)

- 26 컬럼 이름 (특히 `user_id_processed`, `event_source`, `is_new_*`)
- `user_id_processed` 정의 (APP 19/4+ + WEB 22/12+ 분기)
- UNION + ROW_NUMBER 우선순위 (Firebase fb_order=1, Server fb_order=2)
- 주차 기준 = MONDAY
- LEFT JOIN with `intermediate_user_first_info` (가입일 lookup)

### 6-4. 개선 후보 (MP-2 — 사용자 합의 후)

| # | 개선안 | 영향 | 가치 vs 부담 |
|---|---|---|---|
| 1 | **`rn` 컬럼 제거** | rn=1 로 필터된 후 결과라 항상 1 — 불필요 | 가치 中 (스토리지 ↓) / 부담 低 (다운스트림 26 grep 후 영향 없음 확인) |
| 2 | `event_source` enum 강화 — `fb_events`/`server_events` 외 분류 추가 | 데이터 quality test | 가치 低 / 부담 低 |
| 3 | UNION + ROW_NUMBER 패턴을 dbt macro 로 추상화 | 다른 user_daily_info 마트와 패턴 공유 | 가치 中 / 부담 低 |
| 4 | `is_new_month`/`is_new_week` 를 dbt macro `{{ is_new_period('month') }}` 로 | 가독성 + 다른 마트 재사용 | 가치 中 / 부담 低 |
| 5 | 컬럼 naming 변경 (`is_new_month` → `is_new_user_in_month`) | 의미 명확 | 가치 低 / 부담 高 — **권장 X** (다운스트림 26 동시 수정) |

→ **권장 MP-2 적용 1·3·4** (5 는 보존 우선)

### 6-5. 위험 요소

- **Firebase 우선 의존**: Firebase BQ export 가 늦어지면 Server 폴백으로 디멘전 (gender/age 등) 일부 NULL 발생
- **`user_first_info` 의존**: 가입일이 부재면 `is_new_*` NULL — 다운스트림에서 NULL 처리 가정 필요
- **report 18 SQL 동시 영향**: 컬럼 변경 시 모두 동시 수정. 특히 `user_id_processed`, `is_new_*` 변경은 활성/리텐션 모든 보고 영향

## 7. 답할 수 있는·없는 질문

### 답할 수 있는
- 일별 DAU (`COUNT(DISTINCT user_id_processed)`)
- 일별 신규 vs 기존 사용자 (`is_new_month` / `is_new_week`)
- 플랫폼별·국가별·언어별 DAU 분포
- 사용자 디멘전 (성별·연령·OS) 별 활성도

### 답할 수 없는 (다른 마트 필요)
| 필요 | 가야 할 곳 |
|---|---|
| 사용자 행위 (스킬 사용·결제) | `mart_use_skill_se`, `mart_purchase_fb` |
| 코호트 리텐션 | `pre_report_cohort_retention_*` (본 마트 기반) |
| 누적 LTV | `union_mart_user_key_actions` |
| Firebase vs Server 양쪽 raw | `_temp_fb` / `_temp_se` 직접 |

## 8. 후속 액션

- [x] 본 카드 작성 (2026-05-01)
- [ ] **(★ v2 인계 추가)** 카탈로그 `tables/intermediate/` 디렉토리 신설 + 본 마트 카드 작성 (1차 보강 후보)
- [ ] (P7) Tier 결정 — Tier 1 권장
- [ ] (후속 dbt 프로젝트) 6-4 개선안 1·3·4 적용 검토

## 참조

- SQL: [scripts/hellobot/intermediate/intermediate_user_daily_info.sql](../../../../../common-data-airflow/dags/scripts/hellobot/intermediate/intermediate_user_daily_info.sql)
- 다운스트림 26 list: [F-001-data-mart-downstream.tsv](../../10-usage-frequency/F-001-data-mart-downstream.tsv)
- KPI 알림 매핑: [F-003 §2](../../10-usage-frequency/F-003-external-interfaces.md#2-slack-kpi-알림--채널소스-마트-매핑-보존-필수)
- (카탈로그 카드 미작성 — 본 카드가 1차 보강 후보)
