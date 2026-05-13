# union_mart_user_key_actions

> **분석의 본진**. HelloBot 사용자의 방문·스킬 사용·결제를 하나로 합치고, 메타/유입경로/RFM/누적매출까지 얹은 종합 테이블. 대다수의 기능 성과 측정은 이 테이블 위에서 쿼리 가능.

## 개요

- **Full name**: `hellobot-f445c.hlb_mart_integrated.union_mart_user_key_actions`
- **그레인**: 이벤트 단위 (1행 = 한 사용자의 한 이벤트 발생 시점)
- **파티션**: *미지정* (향후 `event_date` 파티션 적용 권장)
- **클러스터링**: 없음
- **머티리얼라이제이션**: `CREATE OR REPLACE TABLE` (전체 치환)
  - **주의**: SQL 내부에서 자기 자신을 참조(`user_daily_revenue` CTE)하여 이전 스냅샷 누적 매출을 읽는 **준-증분 패턴** ([ISS-005](../.././issues.md))
  - dbt 이식 시 `materialized='incremental'` + `{{ this }}` 사용 권장
- **스케줄**: 매일 1회, `staging → intermediate → mart → mart_integrated` 체인
- **컬럼 수**: ~150개 (기본 이벤트 + 사용자 속성 + 구매 이력 + 퍼널 태깅 + 누적매출 + RFM)

## 설명

세 가지 이벤트 소스를 동일한 스키마로 UNION 한 뒤, 스킬 메타·유입 경로·사용자 속성을 모두 결합.

**UNION 소스 이벤트**
| 이벤트명 | 출처 테이블 | 트리거 |
|---|---|---|
| `visit_on_day` | `mart_user_daily_info` | 일별 방문 1회 (합성 이벤트 — 실제 로그가 아닌 mart 기반 파생) |
| `enter_skill` / `consume_skill` / `pay_for_contents` / `pay_for_package` / `pay_for_coaching_program` / `pay_for_collection` / `pay_for_chatbot_subscription` / `pay_under_750` | `mart_use_skill_se` | 서버 이벤트 |
| `in_app_purchase` / `purchase` | `mart_purchase_fb` | Firebase 이벤트 |

**핵심 용도**
- 사용자 × 이벤트 단위로 "누가 / 언제 / 어떤 스킬을 / 어느 경로로 / 얼마 쓰고" 모두 한 쿼리로 답
- 퍼널 성과 측정 (홈 배너 → 결제, 홈 섹션 → 결제 등)
- 세그먼트별 매출 (사주/타로/기타 × 코호트 × 연령대)
- RFM 기반 사용자 상태 추적 (어제 기준 RFM 점수가 조인되어 있음)

## 업스트림

### 직접 소스 (Level 1)
- `hlb_mart.mart_user_daily_info` — 방문 이벤트 파생
- `hlb_mart.mart_use_skill_se` — 스킬 사용/결제 이벤트
- `hlb_mart.mart_purchase_fb` — Firebase 인앱 구매
- `hlb_mart.mart_fixed_menu_server` — 스킬 메타 (chatbot_content_type, target, subject)
- `hlb_mart.mart_skill_open_date_se` — 스킬 오픈일
- `hlb_mart.mart_home_action_fb` — 홈 배너 터치
- `hlb_mart.mart_v2_skill_funnel_fb` — 홈섹션/카테고리/검색 유입
- `hlb_mart_adhoc.adhoc_mart_user_rfm_info_daily` — 어제 기준 RFM
- `google_sheet_sync.taenyon_temp_skill_tag_info_v2` — 스킬 태그 (topic/intents/temporal), 운영자 직접 관리 GSheet ([ISS-006](../.././issues.md))
- **자기 참조**: `hlb_mart_integrated.union_mart_user_key_actions` (누적 매출 계산용)

### 의존 상수
- `KRW_PER_HEART` — 하트 코인의 원화 환산 단가 (쿼리 실행 시 파라미터로 바인딩)
- `START_DATE`, `END_DATE` — 집계 범위 (mart_user_daily_info, mart_use_skill_se 등 업스트림 단에서 주입)

## 다운스트림 (알려진 소비자)

- Looker Studio 대시보드: **TBD** — RFM·코호트·퍼널 분석 대시보드에서 활용 추정
- Braze Segment export: **TBD**
- 애드혹 분석: 가장 빈번히 쓰이는 분석 테이블로 추정
- `report_*`: 직접 참조 여부 TBD

## 컬럼 (그룹별 요약)

> 총 ~150컬럼. 전체 컬럼 설명은 `union_mart_user_key_actions.sql` 말미의 `ALTER COLUMN ... SET OPTIONS(description=...)` 섹션 참조. 아래는 그룹별 대표 컬럼과 분석 관점 요약.

### 시간 (8개)
- `event_date` (DATE, KST, **not_null**, 파티션 후보) / `event_timestamp` (TIMESTAMP UTC)
- `event_month` (`YYYY-MM`) / `event_week` (`YYYY-Ww`, 월요일 기준) / `start_of_week` / `end_of_week`
- `event_weekday` (MON~SUN, 대문자 3글자)

### 이벤트 식별
- `event_name` — UNION된 이벤트 종류 (visit_on_day / enter_skill / consume_skill / pay_for_* / pay_under_750 / in_app_purchase / purchase)

### 사용자 기본 (13개)
- `user_id` (**not_null**, `user_id_processed` 표준화 값)
- `user_country` / `platform` (IOS/ANDROID/WEB) / `platform_appweb` (APP/WEB/UNKNOWN 파생) / `operating_system`
- `user_gender` / `user_birth_year` / `user_age` / `age_group` (13-17, 18-24, 25-34, …) / `age_generation` (10대~70대+)
- `user_type` (anonymous / kakao / apple / email / facebook 등)
- `acc_type` (미가입 사용자 / 가입 사용자 파생)
- `user_created_at` / `user_is_new_month` / `user_is_new_week`
- `user_new_type` (신규 / 기존 / 생성일 없음)
- `pay_type` (방문 당일 / 재방문)
- `event_date_diff` (event_date - user_created_at, 일 단위)

### 코호트
- `cohort_week` (가입 주차 `YYYY-Ww`) / `cohort_start_of_week` / `cohort_end_of_week` / `cohort_month`

### 스킬 / 챗봇 (10개)
- `chatbot_seq` / `chatbot_name` / `chatbot_original_type` / `chatbot_content_type` (사주/타로/...)
- `menu_seq` (스킬 ID) / `menu_name`
- `skill_target_segment` (mart_fixed_menu_server의 targets[0]) / `skill_subject` (subjects[0])
- `target` (`union_use_skill_with_skill_info` 중간 CTE 기준, `skill_target_segment`와 동일값)
- `open_date` (스킬 최초 로그 날짜)

### 스킬 태그 (GSheet 연동) — [ISS-006](../.././issues.md)
- `topic`, `intents` (`|` 구분자로 복수 값), `temporal`
- 소스: `google_sheet_sync.taenyon_temp_skill_tag_info_v2`

### 가격·결제 (10+)
- `current_heart_price` / `heart_price` (할인 전) / `current_price` / `price`
- `spent_heart_coin` / `spent_bonus_heart_coin` / `spent_cash_amount` / `spent_cash_amount_krw`
- `spent_total_amount_krw` — 보너스 하트 사용분 포함 총 결제 가치
- `revenue_krw` — **보너스 하트 제외** 실제 매출 (분석의 매출 표준)
- `currency` / `event_value_in_currency` / `event_value_in_usd`
- `product_id` / `product_name` / `product_type` / `transaction_id`

### 유입 경로 (pay_for_* 한정, BOOLEAN)
- `funnel_from_home_banner` — 홈 배너 터치 후 결제
- `funnel_from_home_section` — 홈 섹션 항목 터치 (추천스킬/인기 TOP10/... 특정 섹션 필터 적용 — SQL 내 하드코딩 리스트)
- `funnel_from_home_category` — 홈 카테고리 터치
- `funnel_from_search_result` — 검색 결과 터치

### 사용자 전체 집계 속성 (20+)
> `user_properties` CTE에서 계산된 사용자 전체 기간 집계 값. event 행마다 동일 user_id면 같은 값이 반복됨.

- **방문**: `user_total_day_visited` / `user_total_week_visited` / `user_total_month_visited` / `user_total_day_visited_monthly_avg` / `user_last_visit_date`
- **결제 합**: `user_total_revenue_krw` / `user_total_revenue_krw_monthly_avg` / `user_total_revenue_krw_saju` / `_tarot` / `_else`
- **결제 횟수/타이밍**: `user_number_of_paid_date` / `user_first_paid_date` / `user_second_paid_date` / `user_last_paid_date`
- **첫/두번째/마지막 구매 메뉴** (전체 플랫폼):
  - `user_first_paid_menu_seq/name/content_type/revenue_krw`
  - `user_second_paid_menu_seq/name/content_type/revenue_krw/date_detail`
  - `user_last_paid_menu_seq/name/content_type/revenue_krw/date_detail`
- **첫/두번째/마지막 구매 메뉴** (앱 전용, IOS/ANDROID):
  - `user_first_app_paid_menu_seq/name/content_type/revenue_krw/date`
  - `user_second_app_paid_menu_seq/...`
  - `user_last_app_paid_menu_seq/...`

### 누적 매출 (이벤트 날짜 기준)
- `user_cumulative_total_revenue` / `user_cumulative_saju_revenue` / `user_cumulative_other_revenue`
- `user_revenue_range_total` — 누적 총 매출 구간 (0원 / 17,000원 미만 / 17,000 / 34,000 / 68,000 / 136,000 / 323,000원 이상)
- `user_revenue_range_saju` / `user_revenue_range_other` / `user_revenue_range_final_total`

### RFM (어제 기준)
- Raw: `rfm_R_pay` / `rfm_F_pay` / `rfm_F_pay_freq` / `rfm_M` / `rfm_R_engage` / `rfm_F_engage` / `rfm_F_engage_freq`
- Scores: `rfm_R_pay_score` / `rfm_F_pay_score` / `rfm_M_score` / `rfm_R_engage_score` / `rfm_F_engage_score`
- Composite: `rfm_payment_rfm_score` / `rfm_engagement_rf_score` / `rfm_payment_segment`
- Timestamps: `rfm_last_pay_date` / `rfm_last_engage_date`

## 답할 수 있는 질문

- **기능 성과**: "새 스킬 X 출시 후 7일 내 결제 유저는 몇 명? 누적 매출은?"
- **퍼널 분석**: "홈 배너에서 유입된 결제 비율 vs 검색에서 유입된 결제 비율"
- **코호트 × 매출**: "3월 가입 코호트의 월평균 매출 추이"
- **RFM 세그먼트별 행동**: "RFM `payment_segment` 별로 평균 방문 일수와 평균 매출"
- **콘텐츠 타입 매출**: "사주 vs 타로 매출 비중, 사용자별 누적 매출 구간 분포"
- **신규/기존 결제 패턴**: "방문 당일 결제 vs 재방문 결제 비율"

## 답할 수 없는 질문 (다른 테이블 필요)

| 필요 분석 | 가야 할 테이블 |
|---|---|
| 상세 스킬 퍼널 (노출→진입→완료 각 단계) | `mart_skill_funnel_fb` / `mart_v2_skill_funnel_fb` |
| 세션 체류 시간 | `mart_session_start_fb` |
| 앱 이탈 이벤트 | `mart_leave_fb` |
| 마케팅 UTM 최초 접촉 | `mart_marketing_utm_first_fb` |
| 리텐션 지표 | `report_cohort_retention_*` |
| 이벤트 파라미터 원본 (raw GA4) | `analytics_164027297.events_*` |

## 주의사항

### 자기 참조 (ISS-005)
- `user_daily_revenue` CTE가 자기 자신 테이블을 읽어 누적값 계산
- **최초 실행 또는 테이블 삭제 후**: 누적값이 0부터 다시 누적됨 → 이력 복구 어려움
- 백필 시 순서 주의 — 전체 재생성 필요할 때는 누적 매출 필드가 부정확할 수 있음

### 자주 오해하는 필드
- `spent_total_amount_krw` vs `revenue_krw` — **매출 분석엔 `revenue_krw`** (보너스 하트 사용분 제외)
- `pay_for_contents` 중 750원 미만은 `pay_under_750` 로 재분류됨 (저가 결제 특성 분리)
- `funnel_from_*` 컬럼은 **`pay_for_*` 이벤트 행에만** 값이 있음. 다른 event_name은 NULL
- `user_properties` 의 집계 값(첫/마지막 구매 등)은 **데이터 기간 전체** 기준. 기간 제한 필터를 걸어도 이 값은 변하지 않음
- `rfm_*` 는 **어제 기준 1개 스냅샷이 모든 행에 동일 조인**됨. 역사적 RFM이 아님

### 파티션 없음 → 비용
- 조회 시 반드시 `WHERE event_date BETWEEN …` 로 범위 제한
- 그래도 풀스캔 수준 비용 발생 → 자주 쓰는 분석은 별도 집계 뷰 권장

### GSheet 의존
- `taenyon_temp_skill_tag_info_v2` 에 새 스킬 태그가 빠지면 `topic`, `intents`, `temporal` NULL
- GSheet 업데이트 누락 시 스킬 태그 분석 정확도 저하

## dbt 이식 매핑

```
현재 경로        scripts/hellobot/mart_integrated/union_mart_user_key_actions.sql
dbt 경로        models/marts/hellobot/integrated/union_mart_user_key_actions.sql
materialized    incremental (unique_key=['event_date','event_timestamp','user_id','event_name']
                 또는 파티션 키만 쓰는 단순 증분)
자기 참조       {{ this }}  대체
자유 상수       KRW_PER_HEART는 dbt var 또는 seed로
외부 의존       - source('google_sheet_sync', 'taenyon_temp_skill_tag_info_v2') 등록
                - source('hlb_mart_adhoc', 'adhoc_mart_user_rfm_info_daily') 등록
```

### schema.yml 초안 (요약)

```yaml
version: 2

models:
  - name: union_mart_user_key_actions
    description: |
      사용자 × 이벤트 단위 종합 분석 테이블. 방문(visit_on_day) + 스킬 사용/결제 +
      Firebase 인앱 구매를 UNION한 뒤 스킬 메타·유입경로·누적매출·RFM까지 결합.
      대다수의 기능 성과 측정은 이 테이블로 답 가능.
    config:
      materialized: incremental
      partition_by:
        field: event_date
        data_type: date
      # self-reference pattern — dbt는 {{ this }} 로 표현
    columns:
      - name: event_date
        description: 이벤트 발생일 (KST)
        tests: [not_null]
      - name: user_id
        description: 표준화 사용자 ID (원본 user_id_processed)
        tests: [not_null]
      - name: event_name
        description: 이벤트 종류
        tests:
          - accepted_values:
              values: ['visit_on_day', 'enter_skill', 'consume_skill',
                       'pay_for_contents', 'pay_for_package', 'pay_for_coaching_program',
                       'pay_for_collection', 'pay_for_chatbot_subscription',
                       'pay_under_750', 'in_app_purchase', 'purchase']
      - name: revenue_krw
        description: 보너스 하트 제외 실제 매출 (분석 표준)
      # ... (150+ 컬럼 개별 기입 — SQL의 ALTER COLUMN description 그대로 이식)
```
