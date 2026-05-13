# mart_purchase_fb

> **Firebase 인앱 스토어 결제** 기반 마트. 서버 결제(`mart_use_skill_se`의 pay_for_*)와 다른 경로의 결제 이벤트.

## 개요

- **Full name**: `hellobot-f445c.hlb_mart.mart_purchase_fb`
- **그레인**: 이벤트 단위 (user × transaction)
- **파티션**: *미지정*
- **머티리얼라이제이션**: `CREATE OR REPLACE TABLE`
- **스케줄**: 매일 1회
- **소스 구분**: `fb` = Firebase Analytics

## 설명

Firebase의 `in_app_purchase` (자동 수집) 및 `purchase` (수동 로깅) 이벤트를 필터링하고, 결제 상품을 **6종 product_type**으로 분류.

**포함 이벤트**
- `in_app_purchase` — 플레이스토어/앱스토어 자동 결제 이벤트
- `purchase` — 서버측에서 Firebase로 수동 전송한 결제 이벤트

**product_type 분류 (CASE WHEN)**
| 값 | 조건 |
|---|---|
| `heart` | `purchase` + product_type=heart OR `in_app_purchase` + staging_coin_product에 매칭 |
| `skill` | `purchase` + (bundle_fixed_menu / fixed_menu / premium_skill / quick_reply) |
| `randombox` | `purchase` + (collection_multiple_draw / collection_reset_draw / collection_single_draw) |
| `package` | `purchase` + product_type=package |
| `subscription` | `in_app_purchase` + manual_server_rdb.product에 매칭 ([ISS-007](../.././issues.md)) |
| `_UNKNOWN` | 매칭되지 않은 purchase/in_app_purchase |
| `_ERROR` | 로직 밖 (정상 상황에선 발생 X) |

## 업스트림

- `hlb_intermediate.intermediate_ir_dashboard_metrics_fb` (base table) — ⚠️ `.sql` 파일 없음, `queries.py` inline ([ISS-004](../.././issues.md))
- `hlb_staging.staging_fixed_menu_copy` (메뉴 메타 조인)
- `hlb_staging.staging_chatbot_server` (챗봇 메타)
- `hlb_staging.staging_coin_product_copy` (하트 상품 매칭)
- `hlb_staging.staging_payment_copy_server` (transaction_id → user_seq 매핑, product_type 결정)
- `manual_server_rdb.product` (수동 업로드, 구독 상품 식별) — ⚠️ [ISS-007](../.././issues.md)

## 다운스트림

- `hlb_mart_integrated.union_mart_user_key_actions` (purchase/in_app_purchase 이벤트 소스)
- `report_*` 중 매출 관련 리포트 (확인 필요)

## 컬럼 (그룹별)

### 시간
`event_date` / `event_timestamp` (UTC TIMESTAMP) / `event_month` / `event_week` / `start_of_week` / `end_of_week`

### 이벤트 · 사용자
- `event_name` — `in_app_purchase` | `purchase`
- `user_id_processed` — `ikmf.user_id_processed` 우선, NULL이면 `p.user_seq` 폴백 (서버 payment 조인)

### 결제 금액
- `currency` — 통화
- `event_value_in_currency` — 원 통화 값
  - **in_app_purchase & currency=KRW** 케이스는 `/1000000` 변환 (Firebase 자동 수집 특성 — 마이크로단위)
- `event_value_in_usd` — USD 환산 (Firebase 자동)

### 상품
- `menu_seq` (event_params에서 추출) / `menu_name` (staging_fixed_menu_copy JOIN)
- `product_id` / `product_name` / `product_type` (6종 분류, 위 참조)
- `transaction_id`
- `deposit_heart_amount` — 하트 결제 시 충전된 하트 수 (`staging_coin_product_copy.quantity`)

### 챗봇 메타
- `chatbot_id` / `chatbot_created_at_date` / `chatbot_type` / `chatbot_category` / `chatbot_channel`

### 기기 · 플랫폼
- `country` / `platform` / `language` / `operating_system` / `operating_system_version` / `version`

### 사용자 속성
- `user_gender` / `user_birth_year/month/day` / `user_age` / `user_type` / `user_created_at`
- `user_is_new_month` / `user_is_new_week` / `user_in_app_language`

## 답할 수 있는 질문

- 인앱 스토어 결제 매출 (USD 기준)
- 상품 타입별(heart/skill/randombox/package/subscription) 매출 비중
- 국가별·플랫폼(iOS/Android)별 인앱 결제 비교
- 구독 결제자 수 및 MRR 추정 (subscription 필터)
- randombox 뽑기 빈도 및 매출
- transaction_id 기반 결제 재현 (환불·이상거래 추적)

## 답할 수 없는 질문

| 필요 분석 | 가야 할 테이블 |
|---|---|
| 서버 결제 (스킬·콘텐츠 하트 소비 등) | `mart_use_skill_se` |
| 사용자 누적 매출 | `union_mart_user_key_actions` |
| 결제 취소/환불 | **파이프라인에 없음** (원본 서버 RDS 필요) |
| 결제 실패 / 중단 | **파이프라인에 없음** |

## 주의사항

### `in_app_purchase` 의 KRW 마이크로단위
- Firebase 자동 수집 시 KRW 값은 1,000,000 배로 들어옴 (예: 990,000,000 = 990 KRW)
- SQL에서 `currency=KRW AND event_name=in_app_purchase` 조건으로 `/1000000` 보정
- 다른 통화는 보정 없음 → 통화별 스케일 확인 필요

### product_type 분류의 취약점
- `_UNKNOWN` 으로 분류된 결제는 **manual_server_rdb.product 미등록 또는 staging_coin_product 미매칭** 건
- 신규 product_type 추가 시 본 SQL의 CASE WHEN 업데이트 필요 → 누락 시 `_UNKNOWN` 급증

### `manual_server_rdb.product` 수동 의존 ([ISS-007](../.././issues.md))
- 수동 업로드 테이블 → 업로드 주체·주기·스키마 변경 불투명
- 구독 상품 매출 분석은 이 테이블 업데이트 지연에 영향 받음

### `intermediate_ir_dashboard_metrics_fb` 파일 이슈 (ISS-004)
- 이 테이블의 정의는 `scripts/hellobot/intermediate/queries.py` inline으로만 존재
- 검색·lineage 추출 시 놓칠 가능성

## dbt 이식 매핑

```
현재 경로        scripts/hellobot/mart/mart_purchase_fb.sql
dbt 경로        models/marts/hellobot/purchase/mart_purchase_fb.sql
materialized    incremental (partition_by=event_date)
sources         - manual_server_rdb.product → source() 등록 (freshness 정책 확인 후)
                - hlb_staging.* 4종
종속 모델        - intermediate_ir_dashboard_metrics_fb 를 먼저 .sql로 이관 필요 (ISS-004)
```
