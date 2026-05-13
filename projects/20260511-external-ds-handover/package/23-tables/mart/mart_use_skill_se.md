# mart_use_skill_se

> 스킬 진입·소비·결제의 **서버 이벤트 기반** 분석 마트. `union_mart_user_key_actions` 의 핵심 소스 중 하나.

## 개요

- **Full name**: `hellobot-f445c.hlb_mart.mart_use_skill_se`
- **그레인**: 이벤트 단위 (user × event_timestamp × menu_seq)
- **파티션**: *미지정*
- **클러스터링**: 없음
- **머티리얼라이제이션**: `CREATE OR REPLACE TABLE`
- **스케줄**: 매일 1회 (mart pipeline 체인)
- **소스 구분**: `se` = Server Events (서버에서 발행한 이벤트, Firebase와 별도 경로)

## 설명

서버 이벤트에서 스킬 관련 이벤트 7종을 필터링하고, 스킬 메타 / 챗봇 메타 / 블록 메타를 조인하여 분석용으로 정제.

**포함 이벤트 7종 (+파생 1종)**
- `enter_skill` — 스킬 진입
- `consume_skill` — 스킬 소비(콘텐츠 완료 등)
- `pay_for_contents` — 콘텐츠 결제
- `pay_for_package` — 패키지 결제
- `pay_for_coaching_program` — 코칭 프로그램 결제
- `pay_for_collection` — 콜렉션 결제
- `pay_for_chatbot_subscription` — 챗봇 구독
- `pay_under_750` (**파생**): `pay_for_contents` 중 총 결제 금액 750원 미만인 이벤트의 event_name을 재분류

**핵심 특성**
- 서버 이벤트는 Firebase보다 **결제 금액 정확도가 높음** (서버에서 직접 계산한 KRW 값 사용)
- `KRW_PER_HEART` 상수와 GSheet 환율(`google_sheet_sync.currency_rate`)로 cash/heart를 모두 KRW 환산
- `chatbot_*` / `menu_*` 필드는 **우선순위 기반 다단 COALESCE** — 서버 스냅샷(fixed_menu) 존재 시 서버 데이터 우선, 없으면 이벤트 파라미터 폴백

## 업스트림

- `hlb_intermediate.intermediate_use_skill_se` (직접 base)
  - ← `hlb_intermediate.intermediate_key_metrics_se` (서버 이벤트 + 사용자 조인)
- `hlb_staging.staging_fixed_menu_copy` (메뉴 메타)
- `hlb_staging.staging_block_copy_server` (블록 메타)
- `hlb_staging.staging_chatbot_server` (챗봇 메타) — `scs1/scs2/scs3` 3번 서로 다른 키로 조인
- `google_sheet_sync.currency_rate` (환율)

## 다운스트림

- `hlb_mart.mart_skill_open_date_se` (첫 로그 날짜 역집계)
- `hlb_mart_integrated.union_mart_user_key_actions` (대부분 결제 정보가 여기로)
- `hlb_mart_adhoc.adhoc_mart_user_rfm_info_daily` (RFM 계산의 기준 이벤트)

## 컬럼 (그룹별)

### 시간 (6)
`event_date` (**not_null**, 파티션 후보) / `event_timestamp` / `event_month` / `event_week` / `start_of_week` / `end_of_week`

### 이벤트 · 사용자
- `event_name` — 8종 (7 원본 + `pay_under_750` 파생), **accepted_values** 테스트 대상
- `user_id` (**not_null**)

### 챗봇 (5)
- `chatbot_seq` — 다단 COALESCE (서버 chatbot 우선 → 이벤트 파라미터 폴백)
- `chatbot_name` / `chatbot_category` / `chatbot_original_type`

### 메뉴(스킬) / 블록
- `menu_seq` / `menu_name` — 서버 menu 우선, 없으면 이벤트 폴백, block만 있을 땐 `"[스킬 정보 없음] 블록: ..."` 포맷
- `menu_is_open` — 서버 노출 여부 (`staging_fixed_menu_copy.is_open`)
- `block_seq` / `block_name`

### 가격 (4)
- `current_heart_price` / `heart_price` (할인 전) / `current_price` / `price`

### 결제 / 매출 (7)
- `spent_heart_coin` — 유료 구매 하트 수
- `spent_bonus_heart_coin` — 보너스 하트 (프로모션 등)
- `spent_cash_amount` / `spent_cash_currency` (KRW 외 통화 가능)
- `spent_cash_amount_krw` — `cr.rate` 로 환산한 KRW
- `spent_total_amount_krw` — **하트 전체 + 현금** 합산 (프로모션 가치 포함)
- `revenue_krw` — **유료 하트 + 현금** (실제 매출, 보너스 하트 제외)

### 패키지 / 콜렉션
- `package_seq` / `package_title` / `unlock_price` / `current_unlock_price` / `current_procedure`
- `collection_name` / `collection_seq`

### 채널 / 플랫폼 / 사용자 속성
- `channel` / `platform` / `locale`
- `user_country` / `user_language` / `user_gender` / `user_birth_year/month/day` / `user_age`
- `user_type` / `user_created_at` / `user_is_new_month` / `user_is_new_week` / `user_in_app_language`
- `product_category`

## 답할 수 있는 질문

- 일별 유료 결제 건수·금액 (pay_for_* 이벤트 합)
- 스킬별 진입→결제 전환율 (enter_skill → pay_for_contents 비율)
- 저가 결제 비중 (`pay_under_750` 비율)
- 특정 스킬의 총 매출·구매자 수
- 결제 통화별 비중 (KRW/JPY/USD 등)
- 보너스 하트 사용량 vs 실제 매출 괴리

## 답할 수 없는 질문

| 필요 분석 | 가야 할 테이블 |
|---|---|
| Firebase 기반 결제 (인앱 스토어) | `mart_purchase_fb` |
| 이벤트 파라미터 원본 | `intermediate_use_skill_se` 또는 `staging_key_events_se` |
| 비결제 이벤트 (view_*/click_* 등) | `mart_v2_skill_funnel_fb` / `mart_home_action_fb` |
| 누적·코호트 | `union_mart_user_key_actions` |

## 주의사항

### `chatbot_*` / `menu_*` 값 우선순위
SQL의 `CASE WHEN ... END` 다단 조건:
1. `menu_seq` 있고 서버 스냅샷(`sfmc.seq`)에도 있으면 → **서버 chatbot 정보** 사용 (`scs1`)
2. `menu_seq` 있고 서버 스냅샷에 없으면 → **이벤트 파라미터** 폴백
3. `menu_seq` 없고 `block_seq` 있으면 → 블록 기반 chatbot (`scs2`)
4. `collection_seq` 있으면 → `scs3` 체인

이 로직 덕분에 **서버 메뉴 삭제/변경 시에도 과거 이벤트의 문맥이 보존**됨. 반대로 분석 시 "동일 menu_seq인데 이름이 다른 행" 가능성 있음.

### `pay_for_contents` vs `pay_under_750`
- 750원 미만 결제는 event_name이 `pay_under_750` 으로 변환됨 (저가 상품은 분석 분리 필요하다는 판단)
- 원본 `pay_for_contents` 건수만 세려면 `pay_under_750` 포함해야 함

### 환율 의존
- `google_sheet_sync.currency_rate` GSheet이 업데이트되지 않으면 외화 결제의 KRW 환산 값이 부정확

### 레이어 위반 (ISS-003)
- `mart_skill_open_date_se` 가 본 테이블을 소스로 사용 → 같은 mart 레이어 내 참조

## dbt 이식 매핑

```
현재 경로        scripts/hellobot/mart/mart_use_skill_se.sql
dbt 경로        models/marts/hellobot/skill/mart_use_skill_se.sql
materialized    incremental (partition_by=event_date)
vars            KRW_PER_HEART → dbt var
sources         google_sheet_sync.currency_rate → source() 등록
```
