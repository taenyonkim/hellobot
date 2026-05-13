# 성과 분석 리포트 — 데이터 엔지니어링 설계

> ⚠️ **DEPRECATED (2026-04-28)** — 본 문서는 초안. 결정·정책은 다음으로 분할 흡수:
> - **무엇을 측정할지** → [`../data-measurement-plan.md`](../data-measurement-plan.md) (KPI·정의·Q1/Q2/Q4 결정·갭)
> - **어떻게 발화할지** → [`../event-spec.md`](../event-spec.md) (이벤트 3종·파라미터·검증)
> - **누가 보고 의사결정할지** → [`./launch-performance-report-plan.md`](./launch-performance-report-plan.md) (R1~R5)
>
> 본 문서는 작업 히스토리 보존용으로만 유지하며, 신규 결정·갱신은 위 3개 문서에 기록합니다.

---

> 작성일: 2026-04-22 (초안), 2026-04-27 (Q1 거래액 인식 결정 반영)
> 작성자: /dev-data
> 상태: deprecated (2026-04-28) — 위 3개 문서로 흡수
> 선행 문서: [1pager.md](../1pager.md), [planning/success-metrics-kpi.md](./success-metrics-kpi.md), [architecture.md](../architecture.md)

> **2026-04-27 갱신 (히스토리)**: 거래액(GMV) 인식 방식이 신규 이벤트/마트 도입 → `spent_cash_amount` 인젝션으로 변경되었습니다.

---

## 0. 목적과 범위

1pager Success Metric 측정을 위한 **데이터 엔지니어링 설계**. PM의 KPI 정의서(`planning/success-metrics-kpi.md`)를 구체적 이벤트·마트·DAG·SQL 레벨로 연결한다.

**다루는 것**
- 재사용 가능한 기존 이벤트/마트 매핑
- 신규 이벤트·마트 스펙(이름·파라미터·컬럼·그레인)
- DAG 체인·화이트리스트 등록·union 태깅 변경
- 분석 쿼리 템플릿·대시보드 구성
- 외부 확인 필요 항목(TBD)

**다루지 않는 것**
- 지표 정의 철학("신규 구매자" 옵션 A/B/C 선택) — `planning/success-metrics-kpi.md §2` 확정 후 본 문서가 수용
- Amplitude/Braze 의사결정 — 본 설계는 Firebase + 서버 이벤트 체계만 다룸

**데이터 카탈로그 레시피 참조**: Template A-4 "외부 결제 채널"([recipes/feature-performance-measurement.md §템플릿 A](../../../common-data-airflow/docs/hellobot-data/catalog/recipes/feature-performance-measurement.md#템플릿-a--purchase--conversion)). HelloBot 기존 4가지 결제 경로 중 **미지원 신규 도메인** — 이벤트·마트·매출 환산 규칙 모두 신규 필요.

---

## 1. 성과 측정 체계 요약

```
[상품권 발급 (쿠프마케팅)]  ──┐
                              │ 분모 (Input)
                              ▼
[상품권 등록 시도 (서버 이벤트)] ──▶ [등록 성공 = 전환]
                                           │
                                           ├─ heart: 하트 충전 (즉시)
                                           ├─ skill: 100% 쿠폰 발급 + 이용권 카드
                                           └─ coupon: 일반 쿠폰(프리픽스 미매칭)
                                           │
                                           ▼
                          [신규 구매자 태깅] ──▶ Output: 앱/웹 신규 구매자 수
                          (union_mart_user_key_actions.funnel_from_coop_coupon)
```

| 레이어 | 지표 | 데이터 위치 |
|-------|------|----------|
| Input | 상품권 구매→등록 전환율 | (쿠프마케팅 발급 수) / (헬로우봇 등록 수). 분모는 외부 수령 |
| Funnel | 등록 성공률, 에러 코드 분포, 리드타임 | 서버 이벤트 + `coupc_marketing_coupon_usage` |
| Output | 앱/웹 신규 구매자 수 | `union_mart_user_key_actions` + `mart_user_daily_info.user_new_type` + `funnel_from_coop_coupon` |
| Revenue | GMV(상품별/플랫폼별), 정산 대상 | `coupc_marketing_coupon_usage` × `coupc_marketing_product` |
| Ops | L1 레이턴시, 구버전 가드 발동, 동시성 경합 | `coupc_marketing_api_log` + winston 로그 |

---

## 2. 지표 매핑 — 재사용 vs 신규

### 2.1 재사용 가능 (기존 자산)

| 1pager 지표 | 기존 메트릭 (metric-dictionary.md) | 사용 방식 |
|------------|----------------------------------|---------|
| 신규/기존 분기 | `mart_user_daily_info.user_new_type` | 사용자 단위 `new/existing/unknown` 분기 재사용 |
| 유료 구매자 | `num_users_paying`, `num_pay_for_all_users_total` | 기존 쿠폰 Flow(일반 쿠폰) 결제자 포함 |
| 사용자 표준 ID | `user_id_processed` | APP/WEB 플랫폼 통합 key |
| 플랫폼 구분 | `platform_appweb` | app / web 분기 |
| 매출 | `revenue_krw` | 쿠폰 등록은 직접 매출 없음(헬로우봇 입장 무상 지급) → 판매액은 쿠프마케팅 데이터에서 가져옴 |

### 2.2 신규 지표 (metric-dictionary.md 등록 대상)

| 이름 | 정의 | 산식 | 그레인 |
|------|------|------|--------|
| `coop_coupon_register_attempts` | 상품권 등록 시도 수 | COUNT(*) WHERE event=`coop_coupon_register_attempt` | 일 |
| `coop_coupon_register_success` | 등록 성공 수 | COUNT(*) WHERE event=`coop_coupon_register_success` | 일 |
| `coop_coupon_success_rate` | 등록 성공률 | success / attempt | 일/주 |
| `coop_conversion_rate` | 구매→등록 전환율 | success / (쿠프 발급 수) | 월 |
| `coop_new_users` | 쿠폰 경유 신규 구매자 수 | DISTINCT user_id_processed WHERE `funnel_from_coop_coupon`=TRUE AND `user_new_type`='new' | 월 |
| `coop_first_pay_users` | 쿠폰 경유 첫 유료 경험자 수 | DISTINCT user_id_processed WHERE `funnel_from_coop_coupon`=TRUE AND 이전 결제 이력 없음 | 월 |
| `coop_gmv` | 쿠폰 기인 GMV | SUM(`coupc_marketing_product.price`) WHERE status='used' | 월 |
| `coop_l1_latency_p95` | L1 사용 승인 p95 레이턴시 | PERCENTILE(`coupc_marketing_api_log` process=L1 duration, 0.95) | 일 |

> "신규 구매자" 두 정의(신규 가입자 / 첫 유료 경험자) 모두 계산 가능하도록 분리 유지. `planning/success-metrics-kpi.md §2.1` 옵션 C(병행) 권장과 일치.

---

## 3. 이벤트 스펙

### 3.1 설계 원칙

- **매출·정합성 관련**: 서버 이벤트 (`server_events`) — Firebase 유실 가능성으로 매출 계산은 서버만 사용
- **사용자 행동 측정**: Firebase 이벤트 (선택) — Amplitude 등 확장 시 재사용
- **트러블슈팅**: `coupc_marketing_api_log` (DB) — 이미 서버 파트에서 구현 완료

### 3.2 신규 서버 이벤트 (필수)

> 소스: hellobot-server winston → `analytics_164027297.server_events`.
> 트리거: `CouponRegisterService` / `CoopMarketingService.registerOneShot` 내부에서 publish.

#### 3.2.1 `coop_coupon_register_attempt`
- **트리거**: `POST /api/coupon/register` 진입 직후 (prefix 분류 전)
- **파라미터**:
  | key | 타입 | 설명 |
  |-----|------|------|
  | user_id | int | userSeq |
  | coupon_code_prefix | string(2) | `code.slice(0,2)` — PII 회피, 프리픽스만 기록 |
  | matched_coupon_type | string | `coop_marketing` / `none` / `unknown` |
  | app_version | string | 클라이언트 전달값 |
  | platform | string | `app` / `web` |
  | env | string | `production` |

#### 3.2.2 `coop_coupon_register_success`
- **트리거**: register 응답 `resultType="ISSUED"` 직전
- **파라미터**:
  | key | 타입 | 설명 |
  |-----|------|------|
  | user_id | int | userSeq |
  | issued_type | string | `heart` / `skill` / `coupon` |
  | product_code | string | `coupc_marketing_product.product_code` (skill/heart만) |
  | coupc_product_seq | int | `coupc_marketing_product.seq` |
  | heart_quantity | int? | heart만 |
  | fixed_menu_seq | int? | skill만 (union 태깅 핵심 키) |
  | issued_coupon_seq | int? | skill만 |
  | latency_ms | int | 요청 수신~응답까지 경과 |
  | platform | string | `app` / `web` |
  | app_version | string | |
  | env | string | `production` |

#### 3.2.3 `coop_coupon_register_failure`
- **트리거**: register 응답 에러 throw 직전 (가드 포함)
- **파라미터**:
  | key | 타입 | 설명 |
  |-----|------|------|
  | user_id | int? | 로그인 상태면 userSeq |
  | error_code | string | `CM_001`~`CM_010` / `CO_APP_UPDATE_REQUIRED` / `NETWORK` |
  | coupon_code_prefix | string(2) | |
  | matched_coupon_type | string | |
  | platform | string | |
  | app_version | string | |
  | env | string | `production` |

### 3.3 Firebase 이벤트 (선택 — Phase 2 고려)

현 Phase 1에서는 **추가하지 않음**. 이유:
- 매출·전환은 서버 이벤트로 충분
- 쿠폰 등록 진입 화면은 이미 기존 `view_*` 이벤트로 커버 (쿠폰 리스트 노출)
- Firebase 유실 가능성 → 이중 소스로 혼란 유발 위험

Phase 2에서 "등록 화면 진입 → 코드 입력 → 등록 클릭" 퍼널 측정 필요 시 검토.

### 3.4 이벤트 화이트리스트 등록 ⚠️

**필수**: 3종 이벤트 모두 `hlb_staging.staging_key_events_se_events_list`에 INSERT.
- 등록 담당·절차는 [external-tasks.md A-1](../../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md#a-1-이벤트-화이트리스트-관리-iss-011) 확인 필요 (TBD, §9-1 참조)
- 누락 시 staging 단계에서 필터링되어 **일체 수집 안 됨** ([ISS-011](../../../common-data-airflow/docs/hellobot-data/catalog/issues.md))

---

## 4. 파이프라인 설계

### 4.1 전체 흐름

```
hellobot-server (PostgreSQL)
  ├─ coupc_marketing_coupon_usage       ──┐
  ├─ coupc_marketing_product             ──┤ AWS Glue 스냅샷
  ├─ coupon_prefix_rule                  ──┘     ↓
  └─ winston logger → server_events            server_rdb.snapshot_coupc_marketing_*
        ↓                                         ↓
   analytics_164027297.server_events  ←────────────
        ↓
   hlb_staging.staging_key_events_se                   hlb_staging.staging_coupc_marketing_*
        ↓                                                   ↓
   hlb_intermediate.intermediate_coop_coupon_event   ←───────┤
        ↓                                                   │
   hlb_mart.mart_coop_coupon_usage  ──────────────────────────
        ↓
   hlb_mart_integrated.union_mart_user_key_actions
   (funnel_from_coop_coupon + 쿠폰 경유 결제 태깅)
        ↓
   hlb_pre_report / hlb_report
   (report_coop_daily, report_coop_monthly)
        ↓
   Looker Studio / Slack KPI / 정산 리포트
```

### 4.2 staging (`hlb_staging`)

- **기존**: `staging_key_events_se` — 3.4 화이트리스트 등록만 하면 자동 수집
- **신규**: `staging_coupc_marketing_coupon_usage`, `staging_coupc_marketing_product` — Glue 스냅샷 경로 `server_rdb.snapshot_coupc_marketing_*` 정제
  - 테스터 제외(`user_test_group`)는 usage 단계에서 user_seq 기준 LEFT ANTI JOIN
  - env 필터 해당 없음 (RDS 프로덕션 단일)

### 4.3 intermediate (`hlb_intermediate`)

- **신규**: `intermediate_coop_coupon_event`
  - 그레인: 이벤트 1건
  - 조인: `server_events` (coop_* 3종) + `staging_coupc_marketing_product` (product_code로 상품명·타입·가격 enrich)
  - 컬럼 추가: `user_id_processed`(표준 ID 변환), `event_date_kst`, `success_flag`, `revenue_krw`(price 환산 — heart/skill만)

### 4.4 mart (`hlb_mart`)

- **신규**: `mart_coop_coupon_usage`
  - 그레인: 쿠폰 1장 (coupon_code × user_seq)
  - 컬럼:
    | 컬럼 | 타입 | 설명 |
    |------|------|------|
    | event_date | DATE | Asia/Seoul |
    | user_id_processed | STRING | |
    | coupon_code | STRING | |
    | coupc_product_seq | INT | |
    | product_code | STRING | KH00001 등 |
    | product_name | STRING | |
    | product_type | STRING | heart / skill |
    | product_price_krw | INT | |
    | status | STRING | used / canceled |
    | registered_at | TIMESTAMP | Asia/Seoul |
    | canceled_at | TIMESTAMP? | |
    | platform_appweb | STRING | app / web |
    | app_version | STRING | |
    | fixed_menu_seq | INT? | skill만 (union 조인 키) |
    | issued_coupon_seq | INT? | skill만 |
    | heart_log_seq | INT? | heart만 |
    | is_new_user | BOOL | `mart_user_daily_info.user_new_type='new'` 조인 결과 |
    | is_first_paying | BOOL | 등록 이전 결제 이력 없음 (옵션 A) |

- **확장**: `mart_purchase_fb` / `mart_use_skill_se` — **건드리지 않음**. 쿠폰 등록은 내부적으로 무상 지급(헬로우봇 매출 0원)이므로 기존 매출 마트 오염 금지. 별도 매출 환산(쿠프 판매액)은 신규 `mart_coop_coupon_usage.product_price_krw`로만 관리.

### 4.5 mart_integrated — union 태깅 (필수)

- **`union_mart_user_key_actions.sql` 수정**:
  - 신규 컬럼 `funnel_from_coop_coupon BOOLEAN`
  - 태깅 규칙:
    ```sql
    -- heart 등록 후 N시간 내 같은 user의 결제 이벤트를 "쿠폰 경유"로 태깅
    -- skill 등록 후 발급된 issued_coupon_seq를 사용한 결제를 태깅
    funnel_from_coop_coupon := (
      user_id IN (SELECT user_id_processed FROM mart_coop_coupon_usage WHERE event_date = cur_date)
      AND event_name LIKE '%pay_for_%'
      AND (
        -- heart: 등록 이벤트 이후 24시간 내 결제
        (heart 매칭 규칙)
        OR
        -- skill: issued_coupon_seq가 사용된 결제
        (spec.issued_coupon_seq 매칭)
      )
    )
    ```
  - ⚠️ **grain 주의**: 결제 이벤트 행에만 값이 있음(기존 `funnel_from_*` 규약 준수)
  - ⚠️ **union 태깅 없이 신규 지표 산출 불가** — 이 단계를 누락하면 "쿠폰 경유 결제자"가 집계되지 않음

### 4.6 pre_report / report

- **신규 마트 2종**:
  - `report_coop_daily` — 일별 (등록 수/성공률/에러 분포/GMV/구버전 가드 발동)
  - `report_coop_monthly` — 월별 (신규 구매자/전환율/정산 대상 금액/재등록자)
- **기존 `hlb_kpi_noti`**에 주간 요약 추가 (Slack 발송 — 발송 채널은 [external-tasks.md D-4](../../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md#d-4-slack-kpi-알림-채널스케줄) 확정 후)

### 4.7 DAG 신규/확장

| DAG | 변경 | 설명 |
|-----|------|------|
| `hellobot_snapshot_to_bigquery` | Glue 스냅샷 테이블 추가 | `coupc_marketing_coupon_usage`, `coupc_marketing_product` 스냅샷 → BQ |
| `hellobot_datamart_staging_pipeline` | task 추가 | `staging_coupc_marketing_*` SQL 실행 |
| `hellobot_datamart_intermediate_pipeline` | task 추가 | `intermediate_coop_coupon_event` |
| `hellobot_datamart_mart_pipeline` | task 추가 | `mart_coop_coupon_usage` |
| `hellobot_datamart_mart_integrated_pipeline` | SQL 수정 | `union_mart_user_key_actions` `funnel_from_coop_coupon` 태깅 추가 |
| `hellobot_datamart_pre_report_pipeline` + `_report_pipeline` | task 추가 | `report_coop_daily`, `report_coop_monthly` |
| (신규) `hellobot_coop_coupon_issued_ingest` | 신규 DAG | 쿠프마케팅 발급 데이터 CSV/API 수신 → BQ 적재. **수령 방식 확정 후 구현** (§9-3) |

---

## 5. 분석 쿼리 템플릿

### 5.1 일별 등록 추이 (운영 대시보드)

```sql
SELECT
  event_date,
  platform_appweb,
  product_type,
  COUNT(*) AS register_success,
  SUM(product_price_krw) AS gmv_krw,
  COUNTIF(is_new_user) AS new_user_cnt,
  COUNTIF(is_first_paying) AS first_paying_cnt
FROM `hellobot-f445c.hlb_mart.mart_coop_coupon_usage`
WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE('Asia/Seoul'), INTERVAL 30 DAY)
                     AND DATE_SUB(CURRENT_DATE('Asia/Seoul'), INTERVAL 1 DAY)
  AND status = 'used'
GROUP BY 1, 2, 3
ORDER BY 1 DESC, 2, 3;
```

### 5.2 상품권 구매→등록 전환율 (월별)

```sql
WITH registered AS (
  SELECT
    FORMAT_DATE('%Y-%m', event_date) AS month,
    product_code,
    COUNT(*) AS register_cnt
  FROM `hellobot-f445c.hlb_mart.mart_coop_coupon_usage`
  WHERE event_date >= DATE_SUB(CURRENT_DATE('Asia/Seoul'), INTERVAL 90 DAY)
    AND status = 'used'
  GROUP BY 1, 2
),
issued AS (
  SELECT
    FORMAT_DATE('%Y-%m', issued_date) AS month,
    product_code,
    SUM(issued_cnt) AS issued_cnt
  FROM `hellobot-f445c.hlb_staging.staging_coop_marketing_issued`  -- §9-3 수신 후
  GROUP BY 1, 2
)
SELECT
  i.month,
  i.product_code,
  i.issued_cnt,
  r.register_cnt,
  SAFE_DIVIDE(r.register_cnt, i.issued_cnt) AS conversion_rate
FROM issued i
LEFT JOIN registered r USING (month, product_code)
ORDER BY 1 DESC, 2;
```

### 5.3 신규 구매자 집계 (옵션 A + B 병행)

```sql
SELECT
  FORMAT_DATE('%Y-%m', event_date) AS month,
  platform_appweb,
  -- 옵션 A: 첫 유료 경험자
  COUNT(DISTINCT IF(is_first_paying, user_id_processed, NULL)) AS first_paying_users,
  -- 옵션 B: 신규 가입자 (등록 시점 -30일 이내 가입)
  COUNT(DISTINCT IF(is_new_user, user_id_processed, NULL)) AS new_signup_users,
  -- 옵션 C: 공통 집합
  COUNT(DISTINCT IF(is_first_paying AND is_new_user, user_id_processed, NULL)) AS new_first_paying_users
FROM `hellobot-f445c.hlb_mart.mart_coop_coupon_usage`
WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE('Asia/Seoul'), INTERVAL 180 DAY)
                     AND DATE_SUB(CURRENT_DATE('Asia/Seoul'), INTERVAL 1 DAY)
  AND status = 'used'
GROUP BY 1, 2
ORDER BY 1 DESC, 2;
```

### 5.4 쿠폰 경유 후속 결제 — union 마트 활용

```sql
-- skill 이용권을 받고 기존 하트로 추가 결제하는 코호트 (업셀 효과)
SELECT
  DATE_TRUNC(event_date, MONTH) AS month,
  COUNT(DISTINCT user_id_processed) AS users,
  SUM(revenue_krw) AS follow_up_revenue_krw
FROM `hellobot-f445c.hlb_mart_integrated.union_mart_user_key_actions`
WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE('Asia/Seoul'), INTERVAL 90 DAY)
                     AND DATE_SUB(CURRENT_DATE('Asia/Seoul'), INTERVAL 1 DAY)
  AND funnel_from_coop_coupon = TRUE
  AND event_name LIKE 'pay_for_%'
  AND event_name != 'pay_for_coop_coupon'  -- 쿠폰 자체 지급 제외
GROUP BY 1
ORDER BY 1 DESC;
```

### 5.5 운영 이상 탐지

```sql
-- 에러 코드 분포 + 구버전 가드 발동
SELECT
  event_date,
  JSON_VALUE(params, '$.error_code') AS error_code,
  JSON_VALUE(params, '$.matched_coupon_type') AS matched_type,
  COUNT(*) AS occurrences
FROM `hellobot-f445c.hlb_staging.staging_key_events_se`
WHERE event_date >= DATE_SUB(CURRENT_DATE('Asia/Seoul'), INTERVAL 14 DAY)
  AND event_name = 'coop_coupon_register_failure'
GROUP BY 1, 2, 3
ORDER BY 1 DESC, 4 DESC;
```

---

## 6. 대시보드 구성 (Looker Studio 권장, 도구 확정 TBD §9-5)

### 6.1 경영진 월간 (`report_coop_monthly`)
- 신규 구매자 수 (앱/웹, 옵션 A/B/C 병행)
- 상품권 구매→등록 전환율
- 정산 대상 금액 (판매액 × 92%)
- 상품별 Top 5 GMV
- 재등록 사용자 분포

### 6.2 운영 일간 (`report_coop_daily`)
- 일별 등록 건수 (product_type × platform stacked)
- 에러 코드별 발생 분포
- 구버전 가드 발동 건수 (`CO_APP_UPDATE_REQUIRED`) — [ISS-009](../issues.md) 관측
- L1 레이턴시 p50/p95
- 동시성 경합 발생 (Redlock 대기 로그)

### 6.3 상품 성과 월간
- 상품별 등록/GMV
- 스킬 이용권 → 실제 스킬 진입/소비 전환 (`issued_coupon_seq` → `enter_skill`)
- 상품별 재등록 사용자

### 6.4 정산 대사 월간
- 쿠프마케팅 L1 사용 내역 vs 내부 `coupc_marketing_coupon_usage` 일치 건수
- 대사 불일치 건수 (한쪽에만 존재)
- 판매액 합계 (월), 수수료 8% 차감, 정산 대상액

---

## 7. 어트리뷰션 규칙 (확정 제안)

| 항목 | 제안 | 근거 |
|------|------|------|
| 귀속 시점 | **등록 완료 시점** (발급 시점 아님) | 선물 전달·보관 지연으로 등록이 실제 사용 지점 |
| Lookback 창 | N/A — **등록 자체를 전환으로 간주** | 상품권이 곧 구매 행위 (1pager Solution §3) |
| 신규 구매자 정의 | **옵션 C 병행 집계** (A: 첫 유료 경험자, B: 신규 가입자) | `success-metrics-kpi.md §2.1` 권장안 수용 |
| 중복 제거 | 월 단위 `DISTINCT user_id_processed` | 한 사용자의 다중 등록은 재등록자 보조지표로 별도 집계 |
| 취소 처리 | `status='canceled'`는 전환에서 제외 | 상품 회수 완료 건은 실제 사용 아님 |

> 본 규칙은 **데이터 엔지니어링 초안**. 기획 확정 후 `planning/success-metrics-kpi.md §2.1` 의사결정 따라 조정.

---

## 8. 구현 순서 (선행 의존)

```
서버 Phase 1 배포 (완료)
    ↓
[1] 서버 이벤트 3종 publish 구현 (hellobot-server) — 가장 먼저
    └─ winston.info → server_events 자동 적재
    ↓
[2] 이벤트 화이트리스트 등록 (§3.4) — §9-1 절차 확정 후
    ↓
[3] Glue 스냅샷 추가 (coupc_marketing_*) — §9-2 Glue 담당 확인 후
    ↓
[4] staging/intermediate/mart/report SQL 작성 (워크트리 `projects/.../worktrees/common-data-airflow/`)
    ↓
[5] DAG 체인 확장 + 실행 1일 경과 후 데이터 검증
    ↓
[6] union_mart_user_key_actions 태깅 컬럼 추가 — 다운스트림 영향 확인
    ↓
[7] 대시보드 구성 (도구 §9-5 확정 후)
    ↓
[8] 주간 리뷰 정례화 (기획)

(병행) 쿠프마케팅 발급 데이터 수령 방식 합의 → 전환율 분모 확보 (§9-3)
```

**Phase 1 배포 완료 + 프로덕션 데이터 축적** 이후 착수. 개발 환경 데이터로는 검증 불가 (env=production 필터).

---

## 9. 외부 확인 필요 항목 (TBD)

| # | 항목 | 담당 | 영향 |
|---|------|------|------|
| 9-1 | 이벤트 화이트리스트 등록 절차 | 데이터팀 내부 ([external-tasks A-1](../../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md#a-1-이벤트-화이트리스트-관리-iss-011)) | 미등록 시 일체 수집 안 됨 |
| 9-2 | Glue 스냅샷 job 담당 및 신규 테이블 추가 방법 | 인프라팀 ([external-tasks B-1](../../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md#b-1-aws-glue--rds-스냅샷-주기)) | `coupc_marketing_*` BQ 적재 경로 |
| 9-3 | 쿠프마케팅 발급 데이터 수령 방식 (CSV/API/정산파일) | 기획 + 쿠프마케팅 | 전환율 분모 미확보 시 Input 지표 산출 불가 |
| 9-4 | "신규 구매자" 정의 A/B/C 최종 선택 | 기획 | 본 설계는 C(병행) 가정 |
| 9-5 | 대시보드 도구 (Looker / Metabase / GSheet+BQ) | 데이터팀 + 기획 | 7단계 대시보드 구성 |
| 9-6 | 어트리뷰션 기준 "등록=전환" 단순화 승인 | 기획 | 본 설계 수용 시 별도 Lookback 로직 불필요 |
| 9-7 | KRW_PER_HEART 단가 관리 담당 | 데이터팀 ([external-tasks C-3](../../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md#c-3-krw_per_heart-단가-관리)) | 본 프로젝트는 쿠프 판매액 기준 매출 사용(하트 환산 불필요)이므로 영향 경미 |
| 9-8 | Slack KPI 알림 채널·수신 대상 | 기획 + 데이터팀 ([external-tasks D-4](../../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md#d-4-slack-kpi-알림-채널스케줄)) | 주간 요약 발송 대상 |

---

## 10. 리스크 및 함정 (데이터 엔지니어링 관점)

| 리스크 | 영향 | 대응 |
|--------|------|------|
| 화이트리스트 미등록 | 이벤트 일체 미수집 | §3.4 절차 완료 확인 + staging 테이블 카운트 모니터링 |
| `env` 불일치 | dev 이벤트 혼입 | 서버 publish 시 `env='production'` 고정 + staging WHERE 필터 |
| 서버 이벤트와 DB usage 불일치 | 전환 수치 불일치 | 일별 `coupc_marketing_coupon_usage` 스냅샷 건수 vs `coop_coupon_register_success` 이벤트 건수 대사 DAG 추가 |
| 매출 마트 오염 | 기존 KPI 왜곡 | `mart_purchase_fb` / `mart_use_skill_se` 수정 금지 — 별도 `mart_coop_coupon_usage`만 사용 |
| union 태깅 누락 | "쿠폰 경유 결제" 집계 불가 | §4.5 `funnel_from_coop_coupon` 반영 + 하드코딩 리스트(있다면) 관리 |
| 파티션 필터 누락 | BQ 비용 폭증 | 모든 샘플 쿼리에 `WHERE event_date BETWEEN ...` 필수 |
| 구버전 앱 잔존 | 신규 이벤트 미발생 | 서버가 프리픽스 가드로 처리하므로 `coop_coupon_register_failure` error_code=CO_APP_UPDATE_REQUIRED로 별도 집계 가능 |
| 테스터 혼입 | 수치 왜곡 | staging에서 `user_test_group` LEFT ANTI JOIN (기존 컨벤션 그대로) |

---

## 11. Changelog

| 날짜 | 버전 | 변경자 | 내용 |
|------|------|--------|------|
| 2026-04-22 | v0.1 (초안) | /dev-data | 초안 작성 — 1pager + success-metrics-kpi.md + architecture.md 기반. 이벤트 3종·마트 4종·DAG 7종 변경·쿼리 템플릿 5종·어트리뷰션 규칙·외부 확인 8항목 |
