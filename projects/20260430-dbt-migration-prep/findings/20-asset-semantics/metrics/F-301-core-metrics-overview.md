# F-301 — 핵심 지표 종합 시맨틱 baseline

| 항목 | 값 |
|---|---|
| Phase | P2 |
| 중요도 | ★★★ — 모든 KPI 알림·Looker·CRM 의 정의 baseline |
| 상태 | 확정 (카탈로그 잘 정리됨) |
| 작성일 | 2026-05-01 |
| 출처 | 카탈로그 [metric-dictionary.md](../../../../../common-data-airflow/docs/hellobot-data/catalog/metric-dictionary.md) (10 도메인 × 50+ 지표) + F-101/F-106 매출 산식 |
| affects-ssot | no (카탈로그 매우 잘 작성됨) |
| affects-tier | **Tier 1·2 (보존 권장)** + 3개 합의 항목 (Tier 3) |

## 1. 본 카드의 시각

본 카드는 **카탈로그 metric-dictionary.md 를 1:1 재기록 X** — dbt 마이그 시각으로 **재정의 / 합의 필요 / 보존 필수** 만 추출. 상세 산식은 카탈로그 직접 참조.

## 2. 지표 도메인 인벤토리 (10 도메인 × ~50 지표)

| 도메인 | 핵심 지표 | 소스 마트 | KPI 알림 의존 | dbt Tier |
|---|---|---|---|---|
| **1-1 매출** | `total_revenue_paying`, `*_revenue` (채널별) | `union_mart_user_key_actions` (F-106) + GSheet | ★ 직접 | **Tier 1·2 보존 (revenue_krw 표준)** |
| **1-2 사용자** | DAU/WAU/MAU, num_users_web/app | `union_mart_user_key_actions` 또는 `intermediate_user_daily_info` (F-102) | ★ 직접 | Tier 1 |
| **1-3 결제자** | num_users_paying, _web/_app, _new/_existing | `union_mart_user_key_actions` | ★ 직접 | Tier 1 |
| **1-4 ARPPU/LTV** | ARPPU (주별), LTV (12개월 코호트) | `union_mart_user_key_actions` | ★ 직접 (LTV) | Tier 2 |
| **1-5 광고/ROAS** | {channel}_revenue, _roas, contribution_margin | GSheet (`google_sheet_sync.*`) + union 마트 | ★ 직접 (마케팅) | **Tier 4 (GSheet 잔존) + Tier 1 (계산)** |
| **1-6 코호트 리텐션** | retention_visit/pay/active | `report_cohort_retention_*` | 간접 (대시보드) | Tier 2 |
| **1-7 CRM/푸시** | send_users/open_users/CTR, push_optin | `hellobot_braze.*` (Tier 4) + `mart_user_server` (F-104) | ★ 직접 (opt-in) | **Tier 1 (계산) + Tier 4 (Braze)** |
| **1-8 RFM** | payment_segment (12종 enum), R/F/M 스코어 | `adhoc_mart_user_rfm_info_daily` | 간접 | Tier 2 (시맨틱 보존) |
| **1-9 콘텐츠·스킬** | new_skill_counts/pay_amounts, *_revenue_saju/tarot | `mart_fixed_menu_server` + `mart_use_skill_se` (F-101) | ★ 직접 | Tier 1·2 |
| **1-10 AI 챗봇** | ai_chatbot_spent_krw/users | `mart_use_skill_se` + `staging_chatbot_server` (`is_ai_chatbot`) | ★ 직접 (챗봇 프로덕트팀) | Tier 2 |

## 3. 핵심 정의 — 보존 필수 (변경 X)

### 3-1. `KRW_PER_HEART = 150` (★ 이미 P1·P2 에서 다수 발견)
- 카탈로그 §0 + 메타 관찰 §3 명시
- **현재 2곳에 다른 방식**: `kpi_noti` SQL `* 150` 하드코딩 / `mart_use_skill_se` 파라미터 바인딩
- → MP-2 개선 후보 1순위 (dbt var 통합)

### 3-2. `user_id_processed` 표준
- APP 19/4+ + WEB 22/12+ 기점으로 user_id, 그 전 user_pseudo_id
- **모든 사용자 지표의 분모** (F-102 §4-2 동일)

### 3-3. `revenue_krw` 매출 표준 (★)
- = 유료 하트 + 현금 (보너스 제외)
- vs `spent_total_amount_krw` (보너스 포함, "사용자가 본 가치")
- → **분석 시 `revenue_krw` 가 표준** (카탈로그 §0 + F-101 §4-1 동일)

### 3-4. 시간대 = Asia/Seoul (KST)
- staging 변환에서 UTC → KST
- 모든 일/주/월 집계는 KST 기준
- 주차 기준 = MONDAY (F-102 §4-3 동일)

### 3-5. RFM 12 세그먼트 enum
```
Champions / Loyal Customers / Potential Loyalists / New Customers /
Promising / Need Attention / About to Sleep / At Risk /
Cannot Lose Them / Hibernating / Lost / Others
```
- [ISS-009](../../../../../common-data-airflow/docs/hellobot-data/catalog/issues.md): "About to Sleep" dead branch 가능성 (확인 필요)
- → dbt 마이그 시 enum 보존, ISS-009 해결 시점에 정리

### 3-6. LTV = 12개월 코호트 기준
- `hlb_kpi_noti.hlb_monthly_ltv` 쿼리 패턴
- → KPI 알림 직결 (F-003 §2)

## 4. 합의 필요 항목 (Tier 3 — 후속 dbt 시점)

### 4-1. 매출 계산식 2종 병존 (★ 카탈로그 §3 메타 관찰)
- `revenue_krw` 컬럼 재사용 vs `spent_cash + spent_heart * 150` 재계산
- 값은 동일해야 하나 KPI noti 쿼리들이 직접 계산 — KRW_PER_HEART 변경 시 위험
- → **합의: revenue_krw 컬럼 재사용 표준** (변경 시 dbt 모델 통일)

### 4-2. DAU 정의 분기 (★ 카탈로그 §3)
- `union_mart_user_key_actions` (방문+사용+결제 UNION) vs `mart_user_daily_info` (방문 중심)
- 카탈로그가 union 표준 권고 — 하지만 일부 KPI 알림은 daily_info 사용 가능성
- → **합의: union 표준** + KPI noti SQL 검증 (현재 어느 쪽 쓰는지)

### 4-3. ARPPU 분모 정의
- `COUNT(DISTINCT user_id) WHERE pay_for_*` — 결제자 수
- "결제자" 의 정확한 정의: 본 기간 결제자만? 누적 결제자? — KPI 알림에서 어느 쪽 쓰는지 확인 필요

## 5. 외부 의존 (Tier 4 — Airflow 잔존)

| 의존 | 영향 도메인 | dbt 마이그 처리 |
|---|---|---|
| **GSheet** (`google_sheet_sync.*`) | 광고/ROAS (1-5), 마케팅 매출 (1-1) | dbt source 등록 + freshness test |
| **Braze export** (`hellobot_braze.*`) | CRM/푸시 (1-7) | dbt source 등록만 (output 측 없음) |
| **수동 GSheet** (`taenyon_temp_skill_tag_info_v2`) | 스킬 태그 (콘텐츠 분석) | dbt source 또는 dbt seed (ISS-006) |

## 6. dbt MetricFlow 이식 (카탈로그 §4 참조)

카탈로그가 이미 MetricFlow 형식 예시 작성:
```yaml
metrics:
  - name: total_revenue_paying
    label: 하트·현금 결제 매출
    type: simple
    type_params:
      measure: revenue_krw
    filter: "{{ Dimension('event_name') }} LIKE 'pay_%'
              OR {{ Dimension('event_name') }} = 'pay_under_750'"
```

→ dbt 마이그 시 핵심 지표 ~10개를 MetricFlow 로 정의 + 그 외는 SQL 모델로 보존.

## 7. KPI 알림 의존 매핑 (F-003 §2 cross-link)

[hlb_kpi_noti/queries.py](../../../../../common-data-airflow/dags/scripts/hellobot/kpi_noti/queries.py) 에서 사용하는 핵심 지표:

| KPI 알림 함수 | 사용 지표 | 소스 마트 | 채널 |
|---|---|---|---|
| `hlb_monthly_ltv` | LTV (1-4) | `union_mart_user_key_actions` | #div_chatbot_biz |
| `new_purchase_user_opt_in` | new_push_os_on_user_rate (1-7) | `report_kpi_total_skill_*` | 동일 |
| `hlb_fs_new_skill_pay_amounts` | new_skill_pay_amounts (1-9) | `mart_use_skill_se` + `mart_fixed_menu_server` | 동일 |
| `hlb_marketing_contribution_margins` | 매출 + 광고비 (1-1·1-5) | union + GSheet | 동일 |
| `hlb_whole_roas` | ROAS (1-5) | GSheet | 동일 |
| `hlb_saju_pay_user_data` | 사주 결제자 (1-3·1-9) | `mart_use_skill_se` | 동일 |

→ **본 6 지표가 가장 큰 외부 출력 의존 — 변경 시 KPI 알림 SQL 동시 수정 필요 (MP-1 trade-off 핵심)**

## 8. dbt 마이그 가이드 (지표 영역)

### 8-1. Tier 분류 권장
| 그룹 | 처리 |
|---|---|
| Tier 1 (그대로 이식) | 1-2 사용자, 1-3 결제자 (정의 명확) |
| Tier 2 (보존하며 재구현) | 1-1 매출, 1-4 ARPPU/LTV, 1-6 코호트, 1-7 CRM, 1-8 RFM, 1-9 콘텐츠, 1-10 AI 챗봇 |
| Tier 3 (재정의 + 합의) | §4 합의 3건 (매출 산식 통일, DAU 분기, ARPPU 분모) |
| Tier 4 (Airflow 잔존) | 1-5 광고/ROAS 의 GSheet sync, 1-7 의 Braze export |

### 8-2. 보존 필수 (요약)
- KRW_PER_HEART = 150 (단일 소스로 통일하되 값 보존)
- user_id_processed 표준
- revenue_krw 매출 표준
- KST 시간대 + MONDAY 주차 기준
- RFM 12 세그먼트 enum
- LTV 12개월 코호트

### 8-3. 개선 후보 (MP-2)
| # | 개선 | 가치 vs 부담 |
|---|---|---|
| 1 | **KRW_PER_HEART dbt var 통합** (현재 2곳 분리) | 가치 高 / 부담 中 (KPI noti SQL 동시 수정) |
| 2 | 매출 계산식 통일 — KPI noti 가 mart 의 `revenue_krw` 컬럼 재사용 | 가치 高 / 부담 中 |
| 3 | DAU 분기 통일 — union 표준으로 강제 | 가치 中 / 부담 低 |
| 4 | dbt MetricFlow 로 핵심 10개 지표 정의 | 가치 中 / 부담 中 (학습) |

### 8-4. 위험 요소
- **GSheet 의존 stale**: 광고비·매출 GSheet 미갱신 시 ROAS 계산 부정확
- **수동 입력 위험**: GSheet 입력 담당자·주기 미명문화 (메트릭 사전 §2 외부 확인 과업)
- **Braze export 의존**: Braze 측 변경 시 CRM 지표 영향
- **계산식 2종 병존**: 같은 지표인데 다른 SQL 로 계산되면 값 불일치 가능성

## 9. 후속 액션

- [x] 본 카드 작성 (2026-05-01)
- [ ] (P5) GSheet 입력 담당자·주기 확인 (광고/ROAS — 카탈로그 §2 외부 과업)
- [ ] (P7 합의) Tier 3 3건 — 매출 산식 통일 / DAU 분기 / ARPPU 분모
- [ ] (후속 dbt) MetricFlow 로 핵심 10 지표 정의
- [ ] (후속 dbt) KRW_PER_HEART dbt var 통합 (F-101 §6-4 #1 + 본 §8-3 #1 통합 작업)

## 참조

- 카탈로그: [metric-dictionary.md](../../../../../common-data-airflow/docs/hellobot-data/catalog/metric-dictionary.md) (매우 잘 작성됨)
- F-101 매출 산식: [F-101-mart_use_skill_se.md §4-1](../marts/F-101-mart_use_skill_se.md#4-1-revenue_krw-매출-표준)
- F-106 본진: [F-106-union_mart_user_key_actions.md](../marts/F-106-union_mart_user_key_actions.md)
- F-003 KPI 알림: [F-003-external-interfaces.md §2](../../10-usage-frequency/F-003-external-interfaces.md#2-slack-kpi-알림--채널소스-마트-매핑-보존-필수)
