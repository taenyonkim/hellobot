# 이벤트 스펙 (Event Spec)

> 작성일: 2026-04-28
> 작성자: /dev-data
> 상태: v1.0 — 클라이언트 발주·QA 검증용 계약 문서
> 역할: 본 프로젝트의 **이벤트 발화 SSOT**. 클라이언트(iOS/Android/Web)가 그대로 발주받아 구현하고, QA 가 검증할 단일 진실 원천. 측정 의도(KPI·정의)는 [data-measurement-plan.md](./data-measurement-plan.md) 참조.

## 0. 문서 관계

| 문서 | 역할 |
|------|------|
| [`data-measurement-plan.md`](./data-measurement-plan.md) | **무엇을** 측정할지 (KPI·정의·정책) |
| **본 문서 (`event-spec.md`)** | **어떻게** 발화할지 (이벤트 명·파라미터·발화 시점·검증) |
| [api-spec.md](./api-spec.md) | 서버 API 응답 DTO (이벤트 파라미터 소스) |
| [client-guide.md](./client-guide.md) | 클라이언트 구현 가이드 (이벤트 발화 통합) |

---

## 1. 이벤트 명명 컨벤션

- **화면 이벤트**: `view_*` (Firebase 자동 수집 보강)
- **액션 이벤트**: 동사 시작 (`register_*`, `pay_for_*`, `touch_*`)
- **채널 분류**: 이벤트명에 박지 않고 `coupon_type` 파라미터로 (kakao | hellobot | giftiel)
  - 이유: 3채널 통합 단일 진입점(`POST /api/coupon/register`)이므로 채널과 무관하게 동일 이벤트 — 분석은 파라미터 필터로

---

## 2. 발화 원칙

### 2.1 발화 주체

본 프로젝트는 **모든 이벤트를 Firebase(클라이언트)에서 발화**.

| 데이터 종류 | 진실 원천 | 활용 |
|---|---|---|
| 사용자 행동 (등록 시도·진입) | Firebase 이벤트 | 분석 KPI, funnel |
| 트랜잭션 결과 (성공·실패·DB 상태) | RDS 테이블 (`coupon`, `coop_marketing_coupon_usage`, `coop_marketing_api_log`) | 정산·운영, 사후 검증 |
| 매출 인식 | `pay_for_contents` 서버 이벤트 (기존) + Q1 인젝션 ([data-measurement-plan.md §5](./data-measurement-plan.md)) | 매출 집계 |

서버 이벤트 신규 발화 없음 — DB 가 이미 진실 원천이므로 중복 불필요.

### 2.2 클라이언트가 서버 응답에서 읽는 파라미터

성공/실패 이벤트 발화 시 클라이언트는 `POST /api/coupon/register` 응답 DTO 의 필드를 그대로 파라미터에 매핑한다. 응답 DTO 가 필드를 제공하지 않으면 이벤트도 채울 수 없으므로 §5 의 서버 의존성 점검 필수.

---

## 3. 이벤트 정의

### 3.1 EVT-1. `view_coupon_register` (화면 진입)

| 항목 | 값 |
|------|----|
| 발화 주체 | 클라이언트 (iOS/Android/Web Firebase) |
| 발화 시점 | 쿠폰 등록 화면(iOS `CouponListViewController` / Android `CouponListActivity` / Web `/coupon`) 진입 시 1회 |
| 데이터셋 | `analytics_164027297.events_*` |
| 파라미터 | (없음 — Firebase 자동 수집 user_id, platform 만 사용) |

### 3.2 EVT-2. `register_coupon_success` (등록 성공)

| 항목 | 값 |
|------|----|
| 발화 주체 | 클라이언트 (iOS/Android/Web Firebase) |
| 발화 시점 | `POST /api/coupon/register` 200 응답 직후 |
| 데이터셋 | `analytics_164027297.events_*` |

| 파라미터 | 타입 | 필수 | 소스 (응답 DTO) | 설명 |
|---|---|---|---|---|
| `coupon_number` | string | ✅ | (클라이언트 입력값) | 입력한 쿠폰번호 |
| `coupon_type` | string | ✅ | 응답 `data.couponType` | `kakao` \| `hellobot` \| `giftiel` (서버 항상 제공 — D1=a) |
| `issued_type` | string | ✅ | 응답 `data.issuedType` | `heart` \| `skill` \| `coupon` |
| `product_code` | string | conditional | 응답 `data.productCode` | 카카오 한정 (`coupon_type=kakao`). `hellobot`/`giftiel` 은 NULL |
| `fixed_menu_seq` | int | conditional | 응답 `data.fixedMenuSeq` | 스킬 교환권일 때만 (`issued_type=skill`) |
| `heart_quantity` | int | conditional | 응답 `data.heartQuantity` | 하트 충전권일 때만 (`issued_type=heart`). `CoopMarketingProduct.heartQuantity` 그대로 노출 (paid 100% 적립 — Q2 결정) |
| `latency_ms` | int | ✅ | 클라이언트 측정 | 등록 버튼 탭 → 응답 수신 ms |

### 3.3 EVT-3. `register_coupon_failure` (등록 실패)

| 항목 | 값 |
|------|----|
| 발화 주체 | 클라이언트 (iOS/Android/Web Firebase) |
| 발화 시점 | `POST /api/coupon/register` non-200 응답 또는 네트워크 에러 직후 |
| 데이터셋 | `analytics_164027297.events_*` |

| 파라미터 | 타입 | 필수 | 소스 | 설명 |
|---|---|---|---|---|
| `coupon_number` | string | ✅ | (클라이언트 입력값) | |
| `coupon_type` | string | nullable | 클라이언트 prefix 룩업 (`coupon_prefix_rule` 시드) | 에러 응답에는 미포함 (D3=a) — prefix 매칭 실패 시 NULL |
| `coupon_prefix` | string | ✅ | (클라이언트 입력값 앞 2자리) | `coupon_type` NULL 일 때 1차 분석 키 |
| `error_code` | string | ✅ | 응답 `code` 또는 클라이언트 분류 | `CM001`~`CM010`, `CO012`, `NETWORK_ERROR`, `UNKNOWN`. 분석·대시보드 1차 키 |
| `reason` | string | ✅ | 응답 `message` 또는 에러 객체 | 자유 텍스트. CS 케이스별 문맥 |
| `latency_ms` | int | ✅ | 클라이언트 측정 | |

---

## 4. 파라미터 사전 (공통 enum)

| 파라미터 | 값 |
|---|---|
| `coupon_type` | `kakao`, `hellobot`, `giftiel` |
| `issued_type` | `heart`, `skill` |
| `error_code` | `CM001`~`CM010` (서버 표준), `CO012`, `NETWORK_ERROR`, `UNKNOWN` |
| `coupon_prefix` | 2자리 숫자 문자열 (예: `90`, `91` 등 — `coupon_prefix_rule` 시드 참조) |
| `product_code` | `coop_marketing_product.product_code` 의 값 — 카카오 상품 코드 체계 (planning/product-code-scheme.md 참조) |

---

## 5. 서버 응답 DTO 의존성

클라이언트가 EVT-2 파라미터를 채울 수 있도록 응답 DTO 보강 필요. **2026-04-29 결정 (D1~D5)**:

| 응답 필드 | 현재 상태 | 필요 보강 | 비고 |
|---|---|---|---|
| `data.issuedType` | 이미 존재 (api-spec.md §Response) | — | `coupon` \| `heart` \| `skill` |
| `data.couponType` | **없음** | **신규 추가 (모든 issuedType 공통)** | `kakao` \| `hellobot` \| `giftiel`. EVT-2 의 `coupon_type` 1차 소스 (D1=a) |
| `data.productCode` | **없음** | **신규 추가 (heart/skill 한정)** | `coop_marketing_product.product_code`. 카카오 한정 — `couponType=hellobot/giftiel` 은 NULL |
| `data.fixedMenuSeq` | 스킬 교환권 응답에 존재 | — | skill 한정 |
| `data.heartQuantity` | 하트 충전권 응답에 존재 | **유지 (D2=a)** | `CoopMarketingProduct.heartQuantity` 그대로. paid/bonus 분리 불필요 — Q2 결정상 카카오 하트 충전권은 paid 100% |
| 에러 응답 `code`, `message` | 표준 에러 포맷 존재 | — | 에러 응답에는 `couponType` 추가 안 함 (D3=a) |

> 서버 측 응답 DTO 보강 과업: [tasks.md §서버](./tasks.md) + api-spec.md 갱신 동반. **변경 범위는 신규 필드 2개만** (`couponType`, `productCode`).

---

## 6. 화이트리스트 등록

3건 모두 클라이언트(Firebase) 이벤트 — `staging_key_events_fb_events_list` 또는 `events_list` 에 INSERT (1차 게이트와 OR 처리이므로 한 곳이면 staging 통과):

```sql
INSERT INTO `hellobot-f445c.hlb_staging.staging_key_events_fb_events_list` (event_name) VALUES
  ('view_coupon_register'),
  ('register_coupon_success'),
  ('register_coupon_failure');
```

> 절차: 카탈로그 [event-catalog.md §2-1](../../common-data-airflow/docs/hellobot-data/catalog/event-catalog.md) + [recipes/add-new-event.md](../../common-data-airflow/docs/hellobot-data/catalog/recipes/add-new-event.md) 참조.

---

## 7. 검증 절차

클라이언트 dev/staging 배포 후 단계별 검증:

### Step 1. Firebase DebugView (즉시, ~5초 지연)

테스트 디바이스에서 GA4 디버그 모드 활성화:
- iOS: `-FIRDebugEnabled` 런치 인자
- Android: `adb shell setprop debug.firebase.analytics.app PACKAGE`
- Web: `?debug_mode=1` 쿼리

Firebase 콘솔 → Analytics → DebugView 에서 실시간 확인. 파라미터 키·값·타입 즉시 검증 (오타·null 누락 발견에 가장 빠름).

### Step 2. BQ `events_intraday_*` (당일, ~수십분 지연)

당일 데이터로 BQ 도달 검증:
```sql
SELECT
  TIMESTAMP_MICROS(event_timestamp) AS ts,
  event_name,
  user_pseudo_id,
  ARRAY(SELECT AS STRUCT key, value FROM UNNEST(event_params)) AS params
FROM `hellobot-f445c.analytics_164027297.events_intraday_*`
WHERE event_name IN ('view_coupon_register','register_coupon_success','register_coupon_failure')
ORDER BY ts DESC
LIMIT 20;
```
> intraday 는 파티션 1개(오늘) 만 — `_TABLE_SUFFIX` 필터 불필요.

### Step 3. BQ `events_*` (D+1)

정식 파티션 도달 + 파라미터 결측률·분포:
```sql
SELECT
  event_name,
  COUNT(*) AS events,
  COUNTIF((SELECT value.string_value FROM UNNEST(event_params) WHERE key='coupon_type') IS NULL) AS missing_coupon_type,
  COUNTIF((SELECT value.string_value FROM UNNEST(event_params) WHERE key='error_code')  IS NULL) AS missing_error_code
FROM `hellobot-f445c.analytics_164027297.events_*`
WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE('Asia/Seoul') - 1)
  AND event_name IN ('view_coupon_register','register_coupon_success','register_coupon_failure')
GROUP BY event_name;
```

### Step 4. 화이트리스트 등록 후 `staging_key_events_fb` 도달

INSERT 후 다음 DAG run(매일 새벽) 후:
```sql
SELECT event_name, COUNT(*) AS cnt
FROM `hellobot-f445c.hlb_staging.staging_key_events_fb`
WHERE event_date = CURRENT_DATE('Asia/Seoul') - 1
  AND event_name IN ('view_coupon_register','register_coupon_success','register_coupon_failure')
GROUP BY event_name;
```
> 0건 시 화이트리스트 누락 — [event-catalog.md §2-1](../../common-data-airflow/docs/hellobot-data/catalog/event-catalog.md) FAQ 진단.

### Step 5. 카탈로그 SSOT 반영

실측 결과로 정식 등록:
- `event-catalog.md §4-1` 에 신규 이벤트 표 추가 (실측 파라미터·소스·소비 마트)
- `event-catalog.md §유스케이스 색인` 에 행 추가
- 출처 명시 (쿼리·실행일·스캔 바이트)

---

## 8. 분석 쿼리 예시

### 8.1 일별 등록 funnel (전환·성공률)

```sql
WITH events AS (
  SELECT
    DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Seoul') AS event_date,
    event_name,
    user_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key='coupon_type') AS coupon_type,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key='error_code')  AS error_code
  FROM `hellobot-f445c.analytics_164027297.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20260501' AND '20260531'
    AND event_name IN ('view_coupon_register','register_coupon_success','register_coupon_failure')
)
SELECT
  event_date,
  COUNT(DISTINCT IF(event_name='view_coupon_register', user_id, NULL))            AS viewers,
  COUNTIF(event_name='register_coupon_success')                                   AS success,
  COUNTIF(event_name='register_coupon_failure')                                   AS failure,
  SAFE_DIVIDE(
    COUNTIF(event_name='register_coupon_success'),
    COUNTIF(event_name IN ('register_coupon_success','register_coupon_failure'))
  ) AS success_rate
FROM events
GROUP BY event_date
ORDER BY event_date;
```

### 8.2 카카오 채널 등록 분포 (상품별)

```sql
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key='product_code') AS product_code,
  COUNT(*) AS register_count
FROM `hellobot-f445c.analytics_164027297.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20260501' AND '20260531'
  AND event_name = 'register_coupon_success'
  AND (SELECT value.string_value FROM UNNEST(event_params) WHERE key='coupon_type') = 'kakao'
GROUP BY product_code
ORDER BY register_count DESC;
```

### 8.3 에러 코드 분포 (운영 R1 일일 리포트)

```sql
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key='error_code') AS error_code,
  COUNT(*) AS occurrences
FROM `hellobot-f445c.analytics_164027297.events_*`
WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE('Asia/Seoul') - 1)
  AND event_name = 'register_coupon_failure'
GROUP BY error_code
ORDER BY occurrences DESC;
```

---

## 9. 후속 마트 반영

출시 후 데이터 축적 후:
- `intermediate_coop_coupon_event.sql` (신규) — 3종 이벤트 + `coop_marketing_product` 조인 view
- `mart_coop_coupon_usage.sql` (신규) — 그레인: 쿠폰 1장. `is_new_user`, `is_first_paying`, `success/failure` 컬럼
- `union_mart_user_key_actions.funnel_from_coop_coupon` 컬럼 — 기존 [tasks.md §164](./tasks.md) 설계 유지

---

## 10. 보류·확장

- **`register_coupon_attempt` (등록 버튼 탭 시점)**: 네트워크 끊김 측정용. 운영 중 의미있게 발생 시 추가
- **서버 이벤트 추가**: DB 진실 원천 활용 가능하므로 불필요로 판단

---

## 11. Changelog

| 날짜 | 버전 | 변경자 | 내용 |
|------|------|--------|------|
| 2026-04-28 | v1.0 | /dev-data | 신규 작성. architecture.md §11 이전. Firebase 클라이언트 이벤트 3종 (`view_coupon_register`, `register_coupon_success`, `register_coupon_failure`) — 명명 컨벤션, 파라미터, 발화 시점, 화이트리스트 등록, 검증 절차(DebugView → intraday → events_* → staging_key_events_fb → 카탈로그), 분석 쿼리 통합. |
| 2026-04-28 | v1.0.1 | /dev-server | **ISS-050 정합화**. `register_coupon_failure.error_code` enum 표기 갱신: `CM_001~CM_010` → `CM001~CM010`, `CO_APP_UPDATE_REQUIRED` → `CO012` (의미 중복 코드 `UPDATE_APP`로 통합). 서버 코드 적용 완료. 발화 미시작 단계라 다운스트림 영향 없음. |
| 2026-04-29 | v1.1 | /dev-data | **응답 DTO 의존성 픽스 (D1~D5 결정)**. ① §3.2 EVT-2 `coupon_type` 소스 = 응답 `data.couponType` 단일 (D1=a, 서버 항상 제공 / 클라이언트 prefix 룩업 폴백 제거). ② §3.2 EVT-2 `heart_amount`+`bonus_heart_amount` 2행 → `heart_quantity` 1행으로 통합 (D2=a, 응답 DTO `heartQuantity` 그대로 사용. bonus 필드 도입 불필요 — 카카오 하트 충전권은 Q2 결정상 paid 100% 적립). ③ §3.3 EVT-3 `coupon_type` 소스 = 클라이언트 prefix 룩업 (D3=a, 에러 응답에는 `couponType` 미포함). ④ §5 응답 DTO 보강 항목 2개로 축소 — `couponType`(모든 issuedType 공통) + `productCode`(heart/skill 한정). `heartAmount`/`bonusHeartAmount` 행 제거. api-spec.md 동반 갱신. |
