# adhoc_mart_user_rfm_info_daily

> **사용자 RFM 스코어** (결제 R/F/M + 참여 R/F + 세그먼트 분류). `union_mart_user_key_actions`가 어제자 스냅샷을 join하여 모든 이벤트 행에 RFM 꼬리표를 붙임.

## 개요

- **Full name**: `hellobot-f445c.hlb_mart_adhoc.adhoc_mart_user_rfm_info_daily`
- **그레인**: 사용자 단위 — `(event_date = TARGET_DATE, user_id)`
- **파티션**: *미지정* (event_date 파티션 필요, 일별 스냅샷 성격)
- **머티리얼라이제이션**: `CREATE OR REPLACE TABLE` (일별 추가/업데이트 설명이지만 실제로는 전체 치환 추정 — 검증 필요)
- **스케줄**: 매일 1회 (`TARGET_DATE` = 어제)
- **기반 문서**: `common-data-airflow/docs/hellobot-data/RFME.md`

## 설명

`mart_use_skill_se` 전체 이력을 대상으로 **Payment RFM** + **Engagement RF** 점수를 계산하고, 12개의 비즈니스 세그먼트 (Champions, Loyal Customers, At Risk 등)로 분류.

### RFME 모델 (헬로우봇 고유)

두 가지 행동 축을 분리:
1. **결제 RFM** — R_pay, F_pay, F_pay_freq, M
2. **참여 RF** — R_engage, F_engage, F_engage_freq (M은 결제 전용)

### 스코어링 기준 (5점 척도)

| 지표 | 조건 (RFME.md 기준) |
|---|---|
| **R_pay_score** (마지막 구매 경과일) | 5:≤7일, 4:≤28일, 3:≤84일, 2:≤420일, 1:≥420일, 0:미구매 |
| **R_engage_score** (마지막 활성 경과일) | 동일 기준, 참여 이벤트 기반 |
| **F_pay_score** (구매 일수) | 5:≥19일, 4:8~18, 3:4~7, 2:2~3, 1:1일, 0:미구매 |
| **F_engage_score** (활성 방문 일수) | 5:≥91일(VIP), 4:31~90, 3:7~30, 2:2~6, 1:1일, 0:비활성 |
| **M_score** (총 구매금액) | 5:≥136,000원(8회), 4:≥68,000(4회), 3:≥34,000(2회), 2:≥17,000(1회), 1:<17,000, 0:미구매 |

### `payment_segment` 분류 (12종)

CASE WHEN 체인 순서대로 평가 (먼저 일치한 세그먼트가 최종):
- **Champions** — R≥4, F≥4, M≥4
- **Loyal Customers** — R≥4, F≥2, M≥3
- **Potential Loyalists** — R≥3, F≥1, M≥3
- **New Customers** — R≥4, F≥1
- **Promising** — R≥2, F≥3, M≥3
- **Need Attention** — R≥2, F≥2
- **About to Sleep** — R≥2, F≥2, M≥2 (Need Attention 먼저 매칭되면 도달 불가 — dead branch 가능성)
- **At Risk** — F≥4, M≥4 (R 조건 없음, 위 R 조건 분기에서 다 걸러진 후)
- **Cannot Lose Them** — F≥1, M≥3
- **Hibernating** — R≤2
- **Lost** — M=0
- **Others** — 나머지

## 업스트림

- `hlb_mart.mart_use_skill_se` — 결제·참여 이벤트의 원천 (혼재: skill enter/consume + pay_for)
- `hlb_intermediate.intermediate_user_daily_info` — 사용자 속성 (user_type, country, platform 조인)

## 다운스트림

- `hlb_mart_integrated.union_mart_user_key_actions` — 어제 기준 스냅샷을 **모든 이벤트 행에 조인**하여 `rfm_*` 컬럼 생성

## 컬럼

### 키 · 기준일
- `event_date` (**not_null**) — TARGET_DATE (파이프라인 실행 시 어제로 주입)
- `user_id` (**not_null**)

### Raw RFM 지표
- `last_pay_date` / `last_engage_date`
- `R_pay` / `R_engage` — 날짜 차이 (일)
- `F_pay` / `F_pay_freq` — 구매 일수 / 구매 횟수
- `F_engage` / `F_engage_freq` — 방문 일수 / 이벤트 횟수
- `M` — 총 매출 (KRW, revenue_krw 합)

### 스코어 (0~5)
- `R_pay_score` / `F_pay_score` / `M_score`
- `R_engage_score` / `F_engage_score`

### 조합 스코어 / 세그먼트
- `payment_rfm_score` — `CONCAT(R_pay_score, F_pay_score, M_score)` 문자열 (예: "543")
- `engagement_rf_score` — `CONCAT(R_engage_score, F_engage_score)` 문자열
- `payment_segment` — 12종 분류 (위 참조)

### 사용자 속성
- `user_created_at` / `user_type` / `user_country` / `platform`

### 코호트
- `cohort_week` (`YYYY-Ww`) / `cohort_start_of_week` / `cohort_end_of_week` / `cohort_month`

## 답할 수 있는 질문

- 현재(어제 기준) 세그먼트별 사용자 수 분포
- 코호트별 세그먼트 이동 추이 (시계열로 쌓여야 가능 — 현재는 스냅샷)
- VIP (F_engage ≥ 5) 리스트 및 매출 기여도
- At Risk / Cannot Lose Them 대상 마케팅 타겟 추출
- 구매 깊이(M_score) × 참여 빈도(F_engage_score) 매트릭스

## 답할 수 없는 질문

| 필요 분석 | 대안 |
|---|---|
| 역사적 RFM 추이 (매일의 RFM 변화) | 본 테이블이 **스냅샷 덮어쓰기** 방식이라면 불가. 별도 이력 테이블 필요 (확인 필요 — ISS 후보) |
| 결제·참여 이외 축 (예: 공유, 추천) | 본 테이블 범위 밖 |
| 실시간 RFM | 매일 1회 배치라 전일 최신 |

## 주의사항

### 스냅샷 성격 확인 필요
- SQL 주석은 "일별 추가/업데이트"라 언급하나, 쿼리는 `CREATE OR REPLACE TABLE` 수준으로 보임
- **매일 실행 시 역사 데이터가 덮어써지는지 / 누적되는지** 확인 필요 → 외부 확인 과업 추가
- 현 상태로는 `union_mart_user_key_actions`가 "어제 기준 RFM"만 모든 행에 조인하므로, **과거 이벤트 행의 RFM은 당시 RFM이 아님** (당일 기준값)

### dead branch 추정
- `About to Sleep` 조건 (`R≥2 AND F≥2 AND M≥2`)은 `Need Attention` (`R≥2 AND F≥2`) 이후에 평가되므로, `Need Attention` 에서 이미 매칭됨 → `About to Sleep` 세그먼트가 선택되지 않는 **dead branch** 가능성
- 검증 필요 (세그먼트 분포 실측 시 About to Sleep 이 0이면 확정)

### 세그먼트 정의 단일 소스
- RFME.md 와 SQL 두 군데에 정의가 적혀있음 → 변경 시 둘 다 업데이트 필요
- dbt 이식 시 **seed 테이블** 또는 **macro**로 세그먼트 로직 추출 권장

### 결제 이벤트 정의
- `event_name LIKE 'pay_for_%'` 로 필터링 → `pay_under_750` 은 `pay_for_contents` 의 하위 파생이지만 LIKE 패턴에 매칭됨 (정상 동작)
- Firebase 인앱 결제 (`mart_purchase_fb` 의 `in_app_purchase`, `purchase`)는 **포함되지 않음** — 결제 RFM은 서버 이벤트(`mart_use_skill_se`) 기반만

## dbt 이식 매핑

```
현재 경로        scripts/hellobot/mart_adhoc/adhoc_mart_user_rfm_info_daily.sql
dbt 경로        models/marts/hellobot/rfm/user_rfm_daily.sql
materialized    incremental (partition_by=event_date, unique_key=['event_date','user_id'])
  → 이력 보존 시 incremental이 적합. 현재 스냅샷 방식은 dbt 이식 시 방침 결정 필요.
seeds           세그먼트 규칙을 seed 또는 macro로 분리
```
