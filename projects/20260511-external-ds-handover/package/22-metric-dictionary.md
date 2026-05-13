# 지표 사전 (Metric Dictionary)

> 현재 파이프라인·알림·대시보드에서 계산되는 지표의 **정의·계산식·소스 테이블·주의사항** 을 한 곳에 모은 문서.
>
> dbt MetricFlow / Semantic Layer로 이식 가능하도록 구조화. 오너십은 외부 확인 과업.

---

## 0. 용어·상수

### 공통 상수
- **`KRW_PER_HEART`** = `150` (KPI 알림 쿼리에선 하드코딩, mart 레이어에선 파라미터로 주입)
  - 1하트 ≈ 150원 (하트 패키지 가격 기준)
  - 주의: 단가가 변경되면 두 곳 모두 업데이트 필요 ([메타 관찰](#메타-관찰-상수-중복-정의))

### 사용자 식별 표준
- **`user_id_processed`** — 분석의 표준 사용자 ID
  - APP: 2019-04-01 이후 `user_id` (서버 발급), 이전은 `user_pseudo_id`
  - WEB: 2022-12-01 이후 `user_id`, 이전은 `user_pseudo_id`
  - 상세: [event-catalog.md §3](./event-catalog.md#3-user_id_processed-규칙)

### 시간대
- `event_date` 는 **Asia/Seoul** 기준 (staging 변환에서 UTC → KST)
- 모든 일별/주별/월별 집계 지표는 KST 기준

### 결제 이벤트 정의
- **`pay_for_*`** — 서버 이벤트 (`mart_use_skill_se`), `event_name LIKE 'pay_for_%'` 로 결제 필터
- **`pay_under_750`** — `pay_for_contents` 중 총 결제금액 750원 미만 (저가 상품 분석 분리 목적 파생 이벤트)
- **`in_app_purchase` / `purchase`** — Firebase 이벤트 (`mart_purchase_fb`), 스토어 인앱 결제 경로

### 매출 정의 2종 (중요)
| 컬럼 | 의미 | 사용처 |
|---|---|---|
| `revenue_krw` | **하트(유료) + 현금. 보너스 하트 제외** — 실제 회수 매출 | 대부분의 매출 지표 (표준) |
| `spent_total_amount_krw` | **하트(전체) + 보너스 하트 + 현금** — 상품 가치 총액 | 소비 가치 분석 |

분석 시 **기본은 `revenue_krw`**. "사용자가 경험한 가치" 는 `spent_total_amount_krw`.

---

## 1. 메트릭 도메인별 인벤토리

### 1-1. 매출 · 수익 (Revenue)

| 지표 | 정의 | 계산식 / 소스 | 집계 주기 |
|---|---|---|---|
| **total_revenue** | 총 매출 (결제 + 광고) | `total_revenue_paying + revenue_hellobot` (GSheet 광고매출) | daily |
| **total_revenue_paying** | 하트·현금 결제 매출 | `SUM(revenue_krw)` WHERE `event_name LIKE 'pay_%' OR pay_under_750` from `union_mart_user_key_actions` | daily/weekly/monthly |
| **total_revenue_paying_750_plus** | 750원 이상 결제 매출 | `SUM(revenue_krw) WHERE event_name LIKE 'pay_for_%'` | daily |
| **total_revenue_paying_under_750** | 저가(750원 미만) 결제 매출 | `SUM(revenue_krw) WHERE event_name = 'pay_under_750'` | daily |
| **total_revenue_network_ad** | 네트워크 광고 매출 (AdSense·AdMob 등) | `google_sheet_sync.ad_revenue_network_daily.revenue_hellobot` | daily |
| **hellobot_ad_direct_revenue** | 직접 광고 매출 | `google_sheet_sync.ad_revenue_direct_daily.gross_sales WHERE product='헬로우봇'` | daily |
| **{channel}_revenue** | 광고 채널별 귀속 매출 (facebook / google / kakao / naver / else) | `google_sheet_sync.marketing_roas_daily.*_revenue` | daily |
| **{channel}_revenue_new** | 신규 유저 귀속 매출 (동일 채널) | 동일 (`*_revenue_new`) | daily |

### 1-2. 사용자 (Users)

| 지표 | 정의 | 계산식 / 소스 | 집계 주기 |
|---|---|---|---|
| **num_users** / **DAU** | 일별 활성 사용자 수 | `COUNT(DISTINCT user_id) FROM union_mart_user_key_actions` (모든 이벤트 = 방문+사용+결제) | daily |
| **WAU** | 주별 활성 | 동일 구조, event_week 집계 | weekly |
| **MAU** | 월별 활성 | 동일 구조, event_month 집계 | monthly |
| **num_users_web** / **_app** | 플랫폼별 AU (`platform_appweb`) | `platform_appweb = 'WEB' OR 'APP'` 필터 | daily |
| **num_users_web_new** / **_app_new** | 플랫폼별 **신규** AU | `user_created_at = event_date` 조건 추가 | daily |

> 주의: `num_users` 는 `union_mart_user_key_actions` 기준. 동일 값이 `mart_user_daily_info` 에서도 계산 가능하지만 약간 차이 있을 수 있음 (union 은 결제/사용 이벤트 없는 날은 `visit_on_day` 합성으로 커버).

### 1-3. 결제자 (Paying Users)

| 지표 | 정의 | 계산식 | 집계 주기 |
|---|---|---|---|
| **num_users_paying** | 결제자수 | `COUNT(DISTINCT user_id) WHERE event_name LIKE '%pay_for_%'` | daily/weekly/monthly |
| **num_users_paying_web** / **_app** | 플랫폼별 결제자수 | `platform_appweb` 필터 | daily |
| **num_users_paying_web_new** / **_app_new** | 플랫폼별 **신규** 결제자수 | `user_created_at = event_date` | daily |
| **num_users_paying_web_existing** / **_app_existing** | 플랫폼별 **기존** 결제자수 | `user_created_at != event_date` | daily |
| **app_new_users** (사주 전용) | 앱 신규 사용자 중 사주 결제자 | `chatbot_content_type='사주' AND user_is_new_week AND platform != 'WEB'` | weekly |

### 1-4. ARPPU / LTV

| 지표 | 정의 | 계산식 | 집계 주기 |
|---|---|---|---|
| **ARPPU** | 결제자당 평균 매출 | `SUM(revenue_krw) / COUNT(DISTINCT user_id)` WHERE pay_for_* | weekly |
| **LTV** | 가입 월별 누적 매출/가입자수 | `SUM(revenue_krw) / COUNT(DISTINCT user_id) PARTITION BY cohort_month` | monthly cohort |

> LTV는 최근 12개월 코호트 기준 (`hlb_kpi_noti` `hlb_monthly_ltv` 쿼리)

### 1-5. 광고 / ROAS

| 지표 | 정의 | 계산식 | 집계 주기 |
|---|---|---|---|
| **ad_spent_total** | 전체 광고비 | 5개 채널(`facebook/google/naver/kakaotalk/else`) 일반+신규 합 | daily |
| **ad_spent_total_new** | 신규 유저 대상 광고비 | 동일 채널의 `*_new` 합 | daily |
| **{channel}_roas** | 채널별 ROAS | `{channel}_revenue / {channel}_ad_spent` (SAFE_DIVIDE) | daily |
| **{channel}_roas_new** | 신규 유저 ROAS | `{channel}_revenue_new / {channel}_ad_spent_new` | daily |
| **contribution_margin** | 기여 이익 | `total_revenue_paying - hellobot_ad_spent` (월) | monthly |

> 광고비/채널 매출은 **GSheet 수기 입력** (`google_sheet_sync.marketing_roas_daily`, `ad_revenue_*_daily`). 입력 담당자·주기 확인 필요 (외부 과업).

### 1-6. 코호트 · 리텐션

| 지표 | 정의 | 소스 |
|---|---|---|
| **cohort_month / cohort_week** | 가입 월/주 (`FORMAT_DATE('%Y-%m', user_created_at)`) | `union_mart_user_key_actions` 또는 마트 레이어 파생 |
| **retention_visit** | 방문 리텐션 (N+1일 재방문 비율 등) | `report_cohort_retention_visit_*` |
| **retention_pay** | 결제 리텐션 (결제자의 N+1일 재결제) | `report_cohort_retention_pay_*` |
| **retention_active** | 활성 리텐션 (스킬 진입 기준) | `report_cohort_retention_active_*` |

> 상세 계산식은 report 레이어 쿼리 확인 (현재 문서화 대상 아님 — 별도 확장 시 추가).

### 1-7. CRM · 푸시

| 지표 | 정의 | 계산식 | 집계 주기 |
|---|---|---|---|
| **send_users** | 푸시 발송 유저수 | `COUNT(DISTINCT external_user_id) FROM hellobot_braze.hellobot_braze_push_send WHERE canvas_id IS NOT NULL` | weekly |
| **open_users** | 푸시 오픈 유저수 | 동일 테이블, `..._push_open` | weekly |
| **CTR** | 클릭률 | `open_users / send_users` | weekly |
| **num_pay_for_skill_by_push** | 푸시 오픈 후 60분 내 결제 건수 | `INNER JOIN pay_for_skill ON event_timestamp <= push_time AND datetime_diff ≤ 60min` | weekly |
| **info_push_user_cnt** | 정보성 푸시 수신 동의자 | `report_crm_optin_total_weekly.info_push_user_cnt` | weekly |
| **marketing_push_user_cnt** | 마케팅 푸시 수신 동의자 | 동일 테이블 | weekly |
| **info_push_user_rate** | AU 대비 정보성 opt-in 비율 | `info_push_user_cnt / AU` | weekly |
| **marketing_push_user_rate** | AU 대비 마케팅 opt-in 비율 | `marketing_push_user_cnt / AU` | weekly |
| **new_push_os_on_user_rate** | 신규 결제자 중 푸시 OS 허용 비율 | `new_push_os_on_user_cnt / num_pay_for_all_users_total` | weekly/monthly |

### 1-8. RFM 세그먼트 (12종)

| 지표 | 정의 | 소스 |
|---|---|---|
| **payment_segment** | 결제 RFM 기반 12 세그먼트 | `adhoc_mart_user_rfm_info_daily.payment_segment` |
| **R_pay_score / F_pay_score / M_score** | 결제 R/F/M 점수 (0~5) | 동일 |
| **R_engage_score / F_engage_score** | 참여 R/F 점수 (0~5) | 동일 |

세그먼트 목록: Champions / Loyal Customers / Potential Loyalists / New Customers / Promising / Need Attention / About to Sleep ([ISS-009](./issues.md): dead branch 가능성) / At Risk / Cannot Lose Them / Hibernating / Lost / Others

### 1-9. 콘텐츠 · 스킬

| 지표 | 정의 | 소스 |
|---|---|---|
| **new_skill_counts** | 월별 신규 오픈 스킬 수 | `mart_fixed_menu_server WHERE menu_create_at_date` 최근 월, `chatbot_original_type='original'` |
| **new_skill_pay_amounts** | 신규 스킬 결제 금액 TOP N | `SUM(spent_cash + spent_heart*150) GROUP BY menu_seq` |
| **total_revenue_krw_saju** / **_tarot** / **_else** | 콘텐츠 타입별 매출 | `union_mart_user_key_actions` 유저 단위 집계 |
| **사주 결제자수 (주별)** | 사주 콘텐츠 결제 주간 결제자 | `mart_use_skill_se JOIN staging_chatbot_server WHERE content_type='사주'` |

### 1-10. AI 챗봇

| 지표 | 정의 | 소스 |
|---|---|---|
| **ai_chatbot_spent_krw** | AI 챗봇별 주별 매출 (TOP 3) | `mart_use_skill_se JOIN staging_chatbot_server WHERE is_ai_chatbot=TRUE` |
| **ai_chatbot_users** | AI 챗봇별 주별 사용자 | 동일 (`COUNT DISTINCT user_id`) |
| **ai_chatbot_purchase_users** | AI 챗봇별 주별 결제 사용자 | 동일 + `event_name LIKE '%pay_for%'` |

---

## 2. 메트릭 오너십 *(외부 확인 필요)*

| 메트릭 도메인 | 추정 오너 | 확인 과업 |
|---|---|---|
| 매출 / 광고 | 경영지원·마케팅 | GSheet 소유자·입력 주체 |
| 사용자 / DAU | 데이터팀 | 정의 공유 여부 확인 |
| ARPPU / LTV | PM·기획 | 정의 사용처 확인 |
| CRM / 푸시 | CRM 운영팀 | Braze 관리 주체 |
| RFM | 데이터·CRM | 세그먼트 해석 담당자 |
| 콘텐츠 · 스킬 | 콘텐츠 PM | 정의 동의 여부 |

---

## 3. 메타 관찰

### 상수 중복 정의
- `KRW_PER_HEART = 150` 이 두 곳에 **다른 방식**으로 정의:
  - `kpi_noti/queries.py`: SQL에 `* 150` 하드코딩
  - `mart/mart_use_skill_se.sql`: `KRW_PER_HEART` 파라미터 바인딩
- 단가 변경 시 두 군데 모두 수정 필요 → 불일치 리스크
- **개선 방향 (별도 프로젝트 제안)**: Airflow Variable 또는 dbt var로 단일 소스 관리

### 매출 계산식 2종 병존
- `revenue_krw` 컬럼 (mart_use_skill_se 에서 파생) — 표준
- `spent_cash_amount + spent_heart_coin * 150` 재계산 — kpi_noti 쿼리들이 직접 계산
- 값은 동일해야 하나, 소스의 `revenue_krw` 를 재사용하는 것이 일관성 측면에서 권장
- 본 프로젝트 범위는 문서화만이므로 지표 정의에서 "표준: revenue_krw" 명시

### 사용자 정의 분기
- DAU 는 `union_mart_user_key_actions` vs `mart_user_daily_info` 둘 다 사용 가능
- 차이: `union`은 결제/스킬/방문 이벤트 전부 UNION, `daily_info`는 방문 중심
- 실제 값은 거의 동일하나 엣지 케이스 (결제만 있고 방문 로그 없는 유저)에서 차이 가능
- **표준**: `union_mart_user_key_actions` 의 `COUNT(DISTINCT user_id)` 를 기본

---

## 4. dbt MetricFlow 이식 예시

```yaml
# metrics.yml (MetricFlow 형식)
version: 2

metrics:
  - name: total_revenue_paying
    label: 하트·현금 결제 매출
    description: |
      pay_for_* 및 pay_under_750 이벤트의 revenue_krw 합. 보너스 하트 제외.
    type: simple
    type_params:
      measure: revenue_krw
    filter: "event_name LIKE '%pay_for_%' OR event_name = 'pay_under_750'"
    source: union_mart_user_key_actions
    dimensions:
      - event_date
      - platform_appweb
      - chatbot_content_type
      - user_new_type
      - age_group

  - name: num_users
    label: DAU
    description: 일별 활성 사용자수 (visit + 스킬 + 결제 이벤트 발생 유저)
    type: simple
    type_params:
      measure:
        name: user_id
        agg: count_distinct
    source: union_mart_user_key_actions
    dimensions:
      - event_date
      - platform_appweb
      - country
      - user_new_type

  - name: num_users_paying
    label: 결제자수
    description: pay_for_* 이벤트 발생 유저수 (중복 제거)
    type: simple
    type_params:
      measure:
        name: user_id
        agg: count_distinct
    filter: "event_name LIKE '%pay_for_%'"
    source: union_mart_user_key_actions

  - name: arppu
    label: ARPPU
    description: 결제자 1인당 평균 매출
    type: ratio
    type_params:
      numerator: total_revenue_paying
      denominator: num_users_paying

  - name: ltv_by_cohort_month
    label: LTV (코호트 월 기준)
    description: 가입 월별 누적 매출 / 가입자수
    type: ratio
    type_params:
      numerator: total_revenue_paying
      denominator:
        count_distinct: user_id
    source: union_mart_user_key_actions
    dimensions:
      - cohort_month
```

---

## 5. 남은 과업

- [ ] `report_*` 레이어 쿼리의 지표들까지 스캔 (특히 `report_kpi_total_skill_*` 는 공식 KPI 대시보드용)
- [ ] Looker Studio 대시보드에 실제 노출되는 지표명과 본 사전의 지표명 매칭
- [ ] **오너십 확정** (기획팀 협의)
- [ ] 지표 변경 관리 규약 (변경 시 누구에게 알리고 언제 반영)
- [ ] 과거 이슈·의사결정으로 정의가 변경된 이력 수집

---

## 개정 이력

| 날짜 | 변경 | 작성자 |
|---|---|---|
| 2026-04-22 | 초안 (kpi_noti/queries.py + report_kpi_metrics_daily.sql + adhoc_mart_user_rfm_info_daily.sql 기반 역추출) | /dev-data |
