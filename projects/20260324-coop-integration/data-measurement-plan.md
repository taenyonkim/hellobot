# 데이터 측정 계획 (Data Measurement Plan)

> 작성일: 2026-04-28
> 작성자: /dev-data
> 상태: v1.0 — Q1~Q4 결정 통합본
> 역할: 본 프로젝트의 **데이터 측정 SSOT**. KPI 정의·정책·소스 매핑·분석 정의를 단일 진실 원천으로 보유. 모든 파트(서버·클라이언트·QA·분석)가 참조.

## 0. 문서 관계

| 문서 | 역할 |
|------|------|
| **본 문서 (`data-measurement-plan.md`)** | **무엇을** 측정할지 (KPI·정의·정책·소스 매핑) |
| [`event-spec.md`](./event-spec.md) | **어떻게** 발화할지 (이벤트 스펙·파라미터·검증 절차) |
| [`planning/launch-performance-report-plan.md`](./planning/launch-performance-report-plan.md) | **누가/언제** 보고 의사결정할지 (리포트 운영 R1~R5) |
| [architecture.md](./architecture.md) | 시스템 아키텍처 (서버·클라이언트 처리 로직). §10/§11 본 문서로 이전 |

선행 정의서:
- [planning/success-metrics-kpi.md](./planning/success-metrics-kpi.md) (v0.1 초안 — 본 문서로 통합되어 deprecated)
- [planning/performance-analysis-design.md](./planning/performance-analysis-design.md) (초안 — 본 문서 + event-spec.md 로 분할 흡수되어 deprecated)

---

## 1. 측정 목표

### 1.1 1pager Success Metric ↔ 측정 가능 KPI 매핑

| 1pager 항목 | 측정 가능 KPI |
|------|--------------|
| Input — 상품권 구매 전환율 | §3.2 등록 전환율 (분모는 외부 발급 데이터 의존, §6 갭 참조) |
| Output — 앱 신규 구매자 수 | §3.3 카카오 채널 신규 구매자 (앱) |
| Output — 웹 신규 구매자 수 | §3.3 카카오 채널 신규 구매자 (웹) |

### 1.2 측정 범위

**포함**:
- 카카오 선물하기 출시 이후의 모든 쿠폰 등록(카카오·헬로우봇 일반·giftiel)
- 등록 후 즉시 결제·하트 사용·스킬 소진 funnel
- 카카오 진입 사용자의 기존 사용자 vs 신규 사용자 분류

**제외**:
- 카카오 selling 측 데이터 (쿠프마케팅·카카오 측 발급 분포·노출 영역) — 외부 데이터 도입 결정 후 보강
- 부분 사용 funnel — 본 프로젝트 범위 외 (전액 1회 소진만 지원)
- 재무·회계 매출 인식 시점 — 본 문서 범위 외

---

## 2. 핵심 정의

### 2.1 "신규 구매자" 정의

본 프로젝트의 신규 구매자 = **첫 카카오 쿠폰 등록일 기준 시간 단위 신규**:

| 시간 단위 | 조건 (KST) |
|---|---|
| **일간 신규** | 첫 카카오 쿠폰 등록일 = 사용자 계정 생성일 |
| **주간 신규** | 첫 카카오 쿠폰 등록주(ISO Week) = 사용자 계정 생성주 |
| **월간 신규** | 첫 카카오 쿠폰 등록월 = 사용자 계정 생성월 |

→ ISO Week 기준 (월요일 시작), KST 시간대. `coop_kakao_first_used_date` 가 NULL 이면 카카오 미경험.

### 2.2 어트리뷰션 — 등록 시점 = 전환

- 상품권 **등록 시점**을 성과 귀속 시점 (발급 시점이 아님 — 발급↔등록 사이 선물 전달·보관 지연)
- 등록 자체를 전환으로 간주 (상품권 등록 = 구매 행위)
- Lookback 별도 설정 없음 (등록 전후 행동은 funnel 분석으로 별도)

### 2.3 카카오 진입 판정 정책

- **등록일만 사용**: `coop_marketing_coupon_usage.used_at` 의 `MIN()` (사용자별)
- `status` 필터 없음 (`used` + `canceled` 모두 포함). 카카오로 진입한 사실 자체를 유입으로 인정
- 결제로 이어졌는지(구매자/미구매자)는 `pay_for_*` 이벤트로 자연 분류

### 2.4 시간대·달력 컨벤션

- 모든 일자 집계는 **KST**(`Asia/Seoul`)
- 주 단위는 **ISO Week** (월요일 시작)
- 카탈로그 `infra-map.md` 결정적 컨벤션과 일치

---

## 3. KPI 인벤토리

### 3.1 North Star (최상위)

| 지표 | 정의 | 산출 |
|------|------|------|
| **카카오 채널 신규 구매자 수 (MAU)** | 상품권 등록을 통해 첫 헬로우봇 유료 이용이 발생한 사용자 (월) | DISTINCT user_id WHERE 첫 카카오 등록 ∧ 이전 유료 이력 없음 |

### 3.2 Input Metric — 등록 전환·성공률

| 지표 | 정의 | 수식 | 단위 |
|------|------|------|------|
| **상품권 구매→등록 전환율** | 카카오 발급 중 헬로우봇 등록 완료 비율 | `등록 완료 / 쿠프 발급` | 일/주/월 |
| **등록 리드타임** | 발급일~등록일 사이 경과 시간 중앙값 | (등록 시각 − 발급 시각) median | 월 |
| **등록 성공률** | 시도 대비 성공 비율 | `register_coupon_success / (register_coupon_success + register_coupon_failure)` | 일 |

> 분모 `쿠프 발급 건수`는 외부 데이터 의존 — §6 갭 참조

### 3.3 Output Metric — 신규 구매자

| 지표 | 정의 | 수식 (mart 기반) |
|------|------|-----------------|
| **카카오 신규 구매자 (앱)** | 카카오 등록 경로로 첫 유료 이용한 앱 사용자 | DISTINCT user_id WHERE platform ∈ {ios,android} ∧ kakao 신규 (§2.1) ∧ pay_for_* 이력 |
| **카카오 신규 구매자 (웹)** | 동상 (web) | platform = web 외 동일 |
| **재등록자 수 (보조)** | 2회차 이상 등록 사용자 (LTV 추정) | COUNT user_id WHERE 등록 건수 ≥ 2 |

### 3.4 상품 성과 (보조)

| 지표 | 정의 | 단위 |
|------|------|------|
| 상품별 등록 건수 | `product_code` 별 등록 성공 건수 | 일/월 |
| 상품별 GMV | `product_code` 별 판매 금액 합계 | 월 |
| 상품 타입 믹스 | heart vs skill 등록 건수 비율 | 월 |
| 스킬 이용권 소진율 | 스킬 교환권 등록 후 실제 스킬 구매 비율 | 월 |

### 3.5 운영 지표 (대시보드)

| 지표 | 단위 |
|------|------|
| 일별 등록 트렌드 | 시간/일 |
| 에러 코드별 실패 건수 (CM001~CM010) | 일 |
| 구버전 앱 가드 발동 건수 (CO012, ISS-009) | 일 |
| 동시성 경합 발생 건수 (Redlock 대기·실패) | 일 |
| L1 사용 승인 평균 응답시간 (쿠프마케팅 API) | 일 |

### 3.6 정산 지표

| 지표 | 정의 | 단위 |
|------|------|------|
| 정산 대상 금액 | 월 판매 총액 × 92% (수수료 8%) | 월 |
| 정산 건수 대사 | 쿠프마케팅 L1 사용 내역 vs 내부 `coop_marketing_coupon_usage` 일치 건수 | 월 |
| 대사 불일치 건수 | 한쪽에만 존재하는 건수 | 월 |

---

## 4. 데이터 소스 매핑

| KPI 영역 | 1차 소스 | 2차 소스 |
|---|---|---|
| 등록 건수·성공/실패 | Firebase `events_*` (`view_coupon_register`, `register_coupon_success/failure`) | RDS `coop_marketing_coupon_usage` 스냅샷 |
| 매출(GMV) | `pay_for_contents` 서버 이벤트 + `mart_use_skill_se` (Q1 인젝션) | RDS `coupon`/`heart_log`/`payment` |
| 카카오 진입 분류 | `coop_marketing_coupon_usage` → `mart_user_daily_info.coop_kakao_first_used_date` | — |
| 신규 구매자 | `union_mart_user_key_actions` (event_name LIKE '%pay_for%' + `coop_kakao_first_used_date`) | — |
| 상품 마스터 | `coop_marketing_product` (`current_price`, `price`, `product_code`) | — |
| 에러·가드 | `register_coupon_failure.error_code` | 서버 winston 로그 |
| 레이턴시 | `register_coupon_*.latency_ms` (클라이언트 측) | `coop_marketing_api_log` (서버 측 — L1 별도) |
| 발급 데이터 (분모) | (외부 — §6 미정) | — |

상세 이벤트 스펙: [event-spec.md](./event-spec.md)

---

## 5. 거래액·매출 인식 정책 (Q1 결정, 2026-04-27)

### 5.1 문제

기존 [mart_use_skill_se.sql:26-32](../../common-data-airflow/dags/scripts/hellobot/mart/mart_use_skill_se.sql:26) 의 `pay_under_750` 자동 격리 규칙에 의해, 카카오 100% 할인 쿠폰 결제는 모든 `spent_*` 가 0이 되어 다음에서 자동 누락:

- 구매자수 집계 (`event_name LIKE '%pay_for%'`) — `pay_under_750` 미매칭
- 거래액 집계 (`SUM(spent_heart_coin*150 + spent_cash_amount)`) — 모두 0이라 합산 영향 없음

### 5.2 결정

서버는 카카오 쿠폰 사용 결제 시 `pay_for_contents` 이벤트의 `spent_cash_amount` 파라미터에 **쿠폰 판매가** (`coop_marketing_product.current_price ?? coop_marketing_product.price`) 를 인젝션. 효과:

- `revenue_krw > 0` 으로 `pay_under_750` 재분류 회피
- 모든 다운스트림 매출/구매자 공식이 변경 없이 자동 합산
- 카카오 정산금 = HelloBot 매출 (회계 원칙 일치)

### 5.3 시멘틱 변경

| 항목 | 변경 전 | 변경 후 |
|---|---|---|
| `spent_cash_amount` | 사용자가 콘텐츠 구매에 실제 지불한 현금 | 이 트랜잭션의 현금 매출 (사용자 직접 결제 + 외부 결제 채널 환산금) |
| `revenue_krw` | 유료 하트 + 현금 (실제 회수 매출) | 유료 하트 + 현금 (외부 결제 채널 환산금 포함) |

→ 데이터 카탈로그 [ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md) 등록.

### 5.4 인젝션 트리거 조건

서버는 결제 흐름에서 다음 조건을 모두 만족할 때 `spent_cash_amount` 인젝션:

1. `usedCouponSeq` 존재
2. 사용한 쿠폰이 **카카오 쿠폰** — `coop_marketing_coupon_usage.issued_coupon_seq` 매칭
3. **인젝션 값**: `coop_marketing_product.current_price ?? coop_marketing_product.price` (KRW)

### 5.5 하트 충전권 매출 인식 (Q2)

카카오 하트 충전권 등록 시 [coop-marketing.ts:383-393](../worktrees/hellobot-server/src/services/coop-marketing.ts:383) 의 `chargeHeart` 호출은 `expiredAt` 미전달 → HeartLog `expiredAt = NULL` → [heart.ts:155-189](../worktrees/hellobot-server/src/services/heart.ts:155) `useHeartLogic` 의 보너스 분기 (`willBeExpiredAt`) 미진입 → **유료 하트 (`spent_heart_coin`) 적립**.

→ 콘텐츠 소비 시 `pay_for_contents` 의 `spent_heart_coin > 0` 으로 자연 매출 인식. **별도 인젝션 불필요**.

> 카탈로그 신규 enum [`HeartLogType.ChargeByGiftCoupon`](../worktrees/hellobot-server/src/models/entities/HeartLog.ts:32) 로 충전 logType 분류 가능.

### 5.6 데이터 측 변경 사항

| 레이어 | 파일 | 변경 |
|---|---|---|
| mart_integrated | [union_mart_user_key_actions.sql:1098-1101](../../common-data-airflow/dags/scripts/hellobot/mart_integrated/union_mart_user_key_actions.sql:1098) | BQ 컬럼 description 4건 갱신 (외부 채널 환산금 명시) |
| mart | [mart_use_skill_se.sql:103-108](../../common-data-airflow/dags/scripts/hellobot/mart/mart_use_skill_se.sql:103) | 인라인 코멘트 갱신 |
| 카탈로그 | [tables/mart/mart_use_skill_se.md](../../common-data-airflow/docs/hellobot-data/catalog/tables/mart/mart_use_skill_se.md), [event-catalog.md](../../common-data-airflow/docs/hellobot-data/catalog/event-catalog.md), [metric-dictionary.md](../../common-data-airflow/docs/hellobot-data/catalog/metric-dictionary.md), [issues.md](../../common-data-airflow/docs/hellobot-data/catalog/issues.md) | description 갱신 + ISS-017 등록 |

**SQL 변경 0건 (다운스트림 무영향)**.

---

## 6. 카카오 유입자 식별 (Q4 결정, 2026-04-28)

### 6.1 정의

§2.1 "신규 구매자 정의" 의 시간 단위 분류를 마트 컬럼 `coop_kakao_first_used_date` 로 구현:

| 시간 단위 | 조건 (KST) |
|---|---|
| **일간 신규** | `coop_kakao_first_used_date = DATE(user_created_at, 'Asia/Seoul')` |
| **주간 신규** | `DATE_TRUNC(coop_kakao_first_used_date, ISOWEEK) = DATE_TRUNC(DATE(user_created_at, 'Asia/Seoul'), ISOWEEK)` |
| **월간 신규** | `DATE_TRUNC(coop_kakao_first_used_date, MONTH) = DATE_TRUNC(DATE(user_created_at, 'Asia/Seoul'), MONTH)` |

### 6.2 파이프라인 변경

| 레이어 | 파일 | 변경 |
|---|---|---|
| RDS 스냅샷 | [hellobot_snapshot_to_bigquery DAG](../../common-data-airflow/hlb_dags/) | `coop_marketing_coupon_usage` 일 1회 인입 → `server_rdb.snapshot_coop_marketing_coupon_usage` |
| staging | `hlb_staging.staging_coop_marketing_coupon_usage` (신규) | 정제 SQL 신규 |
| intermediate | `hlb_intermediate.intermediate_coop_kakao_first_used` (신규) | 사용자별 `MIN(used_at)` 집계 SQL 신규 (~10줄) |
| mart | [mart_user_daily_info.sql](../../common-data-airflow/dags/scripts/hellobot/mart/mart_user_daily_info.sql) | `coop_kakao_first_used_date` (DATE, NULL 허용) 컬럼 1개 추가 + LEFT JOIN |
| mart_integrated | [union_mart_user_key_actions.sql](../../common-data-airflow/dags/scripts/hellobot/mart_integrated/union_mart_user_key_actions.sql) | 동일 컬럼 propagate |
| 카탈로그 | `tables/mart/mart_user_daily_info.md` 외 | 컬럼 description 갱신 |

---

## 7. 측정 갭·보류 항목

### 7.1 외부 데이터 (의사결정 필요)

- **카카오·쿠프마케팅 발급 데이터 (Q3 결정 재논의)**
  - 현재 결정: "정산 데이터 인입 불필요" — Q1 인젝션으로 매출 자동 집계 충족
  - 갭: §3.2 등록 전환율(상품권 구매→등록) 분모(쿠프 발급) 측정 불가 → 1pager Input Metric 직접 측정 차단
  - 옵션:
    | 옵션 | 트레이드오프 |
    |---|---|
    | A. 등록 전환율 KPI 폐기 | Input Metric 미측정 |
    | B. 월 1회 발급 CSV 수동 인입 | 운영 부담, 월간 리뷰 R4 가능 |
    | C. 일일 자동 인입 (DAG 신설) | 일일 모니터링 가능, 구축 부담 |
  - **권장**: B (월간 R4 만 충족) — [planning/launch-performance-report-plan.md §5.1](./planning/launch-performance-report-plan.md) 의 권장과 동기

### 7.2 운영 지표 인프라

- **에러 코드 분포·가드 발동·L1 레이턴시** — 출시 직후 R1 일일 모니터링 필수 항목
- 현재: BQ 임시 쿼리만 가능 (정식 마트 미구축)
- 출시 전: BQ 임시 쿼리로 시작 (`register_coupon_failure` 화이트리스트 등록 후 즉시 가능)
- D+30 내 정식 운영 마트 구축 권장

### 7.3 환불·취소 시 처리 (C2)

- 현재 인젝션은 `pay_for_contents` 발화 시점 1회만 처리하며 **사후 정정 메커니즘 없음**
- 발생 시점에 정책 추가 검토

### 7.4 마트 컬럼 추출 보류

- `used_coupon_seq`·`used_coupon_spec_seq` 마트 컬럼 추출 — 사용자 결제 vs 외부 환산금 분리 분석용
- 보류: 분석 필요 시점에 추가

### 7.5 재무·회계

- 매출 인식 시점 컨펌 — 본 프로젝트 범위 외
- 익월 10일 정산은 운영 워크플로우 (별도 운영 문서 필요)

---

## 8. 분석 쿼리 템플릿

### 8.1 카카오 신규 구매자 KPI (4/30 출시 후 +20명/일 검증)

```sql
SELECT
  event_date,
  COUNT(DISTINCT CASE
    WHEN coop_kakao_first_used_date = DATE(user_created_at, 'Asia/Seoul')
    THEN user_id END) AS kakao_new_user_daily_paying,
  COUNT(DISTINCT CASE
    WHEN DATE_TRUNC(coop_kakao_first_used_date, ISOWEEK)
       = DATE_TRUNC(DATE(user_created_at, 'Asia/Seoul'), ISOWEEK)
    THEN user_id END) AS kakao_new_user_weekly_paying,
  COUNT(DISTINCT CASE
    WHEN DATE_TRUNC(coop_kakao_first_used_date, MONTH)
       = DATE_TRUNC(DATE(user_created_at, 'Asia/Seoul'), MONTH)
    THEN user_id END) AS kakao_new_user_monthly_paying,
  COUNT(DISTINCT CASE WHEN coop_kakao_first_used_date IS NOT NULL
                      THEN user_id END) AS kakao_total_paying
FROM `hellobot-f445c.hlb_mart_integrated.union_mart_user_key_actions`
WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE('Asia/Seoul'), INTERVAL 30 DAY)
                     AND DATE_SUB(CURRENT_DATE('Asia/Seoul'), INTERVAL 1 DAY)
  AND event_name LIKE '%pay_for%'
GROUP BY event_date
ORDER BY event_date DESC;
```

### 8.2 거래액·구매자수 (변경 없음, 카카오 자동 합산)

```sql
SELECT
  event_date,
  SUM(spent_heart_coin * 150 + spent_cash_amount) AS revenue_krw,
  COUNT(DISTINCT user_id) AS num_users_paying
FROM `hellobot-f445c.hlb_mart.mart_use_skill_se`
WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE('Asia/Seoul'), INTERVAL 30 DAY)
                     AND DATE_SUB(CURRENT_DATE('Asia/Seoul'), INTERVAL 1 DAY)
  AND event_name LIKE '%pay_for%'
GROUP BY event_date
ORDER BY event_date DESC;
```

### 8.3 등록 funnel (이벤트 기반)

상세 쿼리: [event-spec.md §8](./event-spec.md)

---

## 9. 일정

- **2026-04-30 까지 데이터 인프라 구현 완료** 목표
- 출시 4/30, D+1 (5/1) 부터 카카오 데이터 측정 가능
- 분석 시작 일자(5/11)까지 안정화 기간 확보

---

## 10. Changelog

| 날짜 | 버전 | 변경자 | 내용 |
|------|------|--------|------|
| 2026-04-28 | v1.0 | /dev-data | 신규 작성. architecture.md §10 + planning/success-metrics-kpi.md v0.1 + planning/performance-analysis-design.md 통합. Q1(거래액 인젝션)·Q2(하트 충전권)·Q3(정산 데이터 — 보류)·Q4(카카오 유입자 식별) 결정 통합 기록. |
