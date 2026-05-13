# F-106 — `hlb_mart_integrated.union_mart_user_key_actions` 시맨틱 baseline (★ 외부 진입점)

| 항목 | 값 |
|---|---|
| Phase | P2 |
| 중요도 | ★★★ (분석의 본진, 외부 진입점) — 단 내부 SQL 다운스트림은 단 2개 |
| 상태 | 확정 |
| 작성일 | 2026-05-01 |
| 출처 | 카탈로그 카드 (잘 작성됨) + SQL 본문 + `bq show` 실측 + F-001 §3 / F-003 §2 |
| affects-ssot | yes — 카탈로그 stale 2건 (파티션, 컬럼 수) |
| affects-tier | **Tier 2 후보 (보존하며 재구현)** — 외부 인터페이스 보존 권장, 단 [MP-1](../../../readme.md#마이그-정책--2026-04-30-사용자-확정) trade-off 가능 |

## 0. 외부 진입점 자산 — 본 카드의 핵심 시각

본 마트는 **내부 SQL 다운스트림이 단 2개** 임에도 카탈로그가 "분석의 본진" 으로 표현된 이유:

- **외부 사용자가 진짜 컨슈머**: 분석가 ad-hoc + Looker Studio (메타 부재) + Braze Segment + KPI 알림 (LTV)
- 본 마트가 dbt 마이그에서 **MP-1 trade-off 의 가장 큰 결정 대상** — 보존하면 외부 인터페이스 (분석 진입점) 가 유지됨, 새로 짓는다면 분석가·대시보드 모두 재교육·재작성 필요

→ F-001 §3 결론 + F-003 §1·§5 cross-link.

## 1. 자산 메타 (실측)

| 항목 | 값 | 카탈로그 표현 |
|---|---|---|
| 행 수 | **266,642,980** (2.66억) | "~150컬럼" (행 수 미명시) |
| 크기 | **195.80 GB** | (미명시) |
| **파티션** | **DAY (`event_date`)** ★ | **"*미지정*" (stale)** — v2 인계 |
| 클러스터링 | 없음 | (일치) |
| **컬럼 수** | **131** (실측) | "~150" (stale, 정정 권장) |
| Materialization | `CREATE OR REPLACE TABLE` + 자기참조 (준-증분 패턴, [ISS-005](../../../../../common-data-airflow/docs/hellobot-data/catalog/issues.md)) | (일치) |

→ 카탈로그 stale 2건 (파티션 + 컬럼 수). v2 인계.

## 2. 그레인 (1 row)

```
1 row = (event_date × event_timestamp × user_id × event_name)
```

이벤트 종류 11종 (`event_name` enum):
- 합성: `visit_on_day` (mart_user_daily_info 기반 일별 방문 1회)
- 서버 결제·사용: `enter_skill`, `consume_skill`, `pay_for_contents`, `pay_for_package`, `pay_for_coaching_program`, `pay_for_collection`, `pay_for_chatbot_subscription`, `pay_under_750`
- Firebase 결제: `in_app_purchase`, `purchase`

## 3. 핵심 컬럼 시맨틱 (131개 — 9 그룹)

| 그룹 | 컬럼 수 | 대표 |
|---|---|---|
| 시간 | 8 | event_date (파티션) / event_timestamp / event_weekday |
| 이벤트 식별 | 1 | event_name (11종 enum) |
| 사용자 기본 | 13 | user_id (= user_id_processed) / age_group / age_generation / user_type / acc_type / pay_type |
| 코호트 | 4 | cohort_week / cohort_month |
| 스킬·챗봇 | 10 | menu_seq / chatbot_content_type / skill_target_segment |
| 스킬 태그 (GSheet) | 3 | topic / intents / temporal — `taenyon_temp_skill_tag_info_v2` 의존 ([ISS-006](../../../../../common-data-airflow/docs/hellobot-data/catalog/issues.md)) |
| 가격·결제 | 12 | revenue_krw (보너스 제외 표준) / spent_total_amount_krw / event_value_in_usd |
| 유입 경로 (BOOLEAN, pay_for_* 한정) | 4 | funnel_from_home_banner / funnel_from_home_section / funnel_from_home_category / funnel_from_search_result |
| 사용자 전체 집계 (`user_properties`) | 25+ | user_total_revenue_krw / user_first_paid_menu_* / user_last_paid_menu_* / user_revenue_range_* |
| 누적 매출 (이벤트 날짜 기준) | 8 | user_cumulative_total_revenue / user_revenue_range_total |
| RFM (어제 기준 스냅샷) | 14 | rfm_payment_segment / rfm_R_pay_score / rfm_M_score |

## 4. 비즈 룰 (보존 필수)

### 4-1. UNION 3 소스
| 이벤트 | 출처 |
|---|---|
| `visit_on_day` | `mart_user_daily_info` (합성, 1일 1회) |
| 서버 결제·사용 8종 | `mart_use_skill_se` (F-101 소스) |
| Firebase 결제 2종 | `mart_purchase_fb` |

### 4-2. 자기 참조 — 누적 매출 (ISS-005)
- `user_daily_revenue` CTE 가 자기 자신을 참조해 이전 날짜의 누적값 누적
- **최초 실행 / 전체 재생성 시 누적값 0부터** — historical 복구 어려움
- → dbt 마이그 시 `{{ this }}` 로 변환 + incremental materialized

### 4-3. RFM 스냅샷 — "어제 기준 1개 값이 모든 행에 조인"
- `rfm_*` 컬럼은 **historical RFM 이 아님** — 매일 빌드 시점의 어제 RFM 단일 스냅샷
- 6개월 전 이벤트 행에도 어제 RFM 값이 동일하게 박힘
- → 분석 시 흔한 오해: "이 사용자가 결제 시점에 RFM 어땠나" 답할 수 없음

### 4-4. `funnel_from_*` 4종
- **`pay_for_*` 이벤트 행에만 값 있음** — 다른 `event_name` 은 NULL
- 홈섹션 항목은 SQL 내 하드코딩 리스트 (추천스킬·인기TOP10 등 특정 섹션만 카운트)

### 4-5. `revenue_krw` vs `spent_total_amount_krw`
- 매출 분석은 항상 `revenue_krw` (보너스 하트 제외 — F-101 §4-1 표준 동일)
- `spent_total_amount_krw` 는 사용자가 본 콘텐츠의 표시 가치 (보너스 포함)

### 4-6. `user_properties` 집계는 데이터 전체 기간 기준
- 기간 필터를 걸어도 `user_total_*`, `user_first_paid_*`, `user_last_paid_*` 값 변하지 않음
- → 분석 시 "이 분기 첫 결제 메뉴" 같은 질문은 별도 계산 필요

### 4-7. `pay_under_750` (F-101 §4-2 동일)
- `pay_for_contents` 중 750 KRW 미만 → 별도 분류

## 5. 외부·내부 의존

### 업스트림 (10)
- `mart_user_daily_info` (방문 파생)
- `mart_use_skill_se` (서버 결제·사용)
- `mart_purchase_fb` (Firebase 인앱 구매)
- `mart_fixed_menu_server` (스킬 메타)
- `mart_skill_open_date_se` (스킬 오픈일)
- `mart_home_action_fb` (홈 배너 터치)
- `mart_v2_skill_funnel_fb` (홈섹션·카테고리·검색 유입)
- `adhoc_mart_user_rfm_info_daily` (어제 RFM)
- `google_sheet_sync.taenyon_temp_skill_tag_info_v2` (스킬 태그 GSheet)
- **자기 참조** (누적 매출)

### 다운스트림 (★ 매우 비대칭)

| 영역 | 다운스트림 |
|---|---|
| **내부 SQL** | **단 2개** — `mart_integrated/queries.py` + `mart_integrated/union_mart_use_skill_and_user_daily.sql` |
| **외부 (추정)** | Looker Studio (다수 대시보드 — 메타 부재로 정확한 매핑 불가) |
| **외부 KPI 알림** | LTV (`hlb_monthly_ltv` 함수) → `C06QV5555A7` #div_chatbot_biz |
| **외부 분석가** | ad-hoc 쿼리 (가장 빈번 사용 추정) |
| **Braze Segment** | TBD |

→ **본 마트의 사용자 90%+ 가 외부**. dbt 마이그 시 외부 인터페이스 보존이 곧 호환성.

## 6. dbt 마이그 가이드

### 6-1. Tier 분류 권장: **Tier 2 (보존하며 재구현)** — MP-1 trade-off 결정 핵심

| 평가 축 | 결과 |
|---|---|
| 시맨틱 명확도 | 명확 (카탈로그 카드 매우 잘 작성) |
| 의존 단순도 | **복잡** (업스트림 10 + 자기참조) |
| 외부 인터페이스 | **★★★ 매우 큼** (Looker + 분석가 + KPI LTV + Braze) |
| 시맨틱 변경 가치 (MP-2) | 중간 — 자기참조 패턴 dbt 표준화 가치 + 컬럼 정리 가치 |
| MP-1 trade-off | **본 마트가 가장 큰 결정 대상** |

### 6-2. dbt 모델 설정 권장 (보존 시나리오)

```yaml
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={'field': 'event_date', 'data_type': 'date'},
    unique_key=['event_date', 'event_timestamp', 'user_id', 'event_name'],
) }}

-- 자기참조: {{ this }} 로 user_daily_revenue CTE 변환
WITH user_daily_revenue AS (
    SELECT user_id, event_date, ...
    FROM {{ this }}  -- 자기참조 — dbt 표준 패턴
    WHERE event_date < {{ var('start_date') }}
)
```

### 6-3. 보존 필수 항목

- 131 컬럼 이름·타입 (특히 `revenue_krw`, `rfm_*`, `funnel_from_*`, `user_*`)
- 11 이벤트 enum (`accepted_values` test 권장)
- `revenue_krw` = 유료 하트 + 현금 (보너스 제외) 산식
- `funnel_from_*` 의 홈섹션 하드코딩 리스트
- 자기참조 누적 매출 패턴

### 6-4. 개선 후보 (MP-2)

| # | 개선안 | 영향 | 가치 vs 부담 |
|---|---|---|---|
| 1 | 자기참조 → `{{ this }}` + incremental | dbt 표준 패턴 | 가치 高 / 부담 中 (백필 시 누적 매출 검증) |
| 2 | `taenyon_temp_skill_tag_info_v2` GSheet → dbt seed 또는 정식 dimension | 운영자 의존 ↓ ([ISS-006](../../../../../common-data-airflow/docs/hellobot-data/catalog/issues.md) 해결) | 가치 高 / 부담 中 |
| 3 | RFM 스냅샷 → historical 추적 (별도 마트 추가) | "결제 시점 RFM" 분석 가능 | 가치 高 / 부담 高 (별도 P3 작업) |
| 4 | `funnel_from_home_section` 하드코딩 리스트 → dbt seed | 운영자 자체 갱신 가능 | 가치 中 / 부담 低 |
| 5 | `user_properties` 별도 마트 분리 | 본 마트 단순화 + 컬럼 30+ ↓ | 가치 中 / 부담 高 (외부 분석 영향) |
| 6 | 컬럼 naming 표준화 | 가독성 | 가치 低 / 부담 매우 高 — **권장 X** |

### 6-5. ★ MP-1 trade-off — 본 마트의 결정

본 마트가 [MP-1](../../../readme.md#마이그-정책--2026-04-30-사용자-확정) 의 가장 큰 결정 대상:

| 옵션 | 부담 | 가치 |
|---|---|---|
| **(A) 보존 (현재 카탈로그 그대로 dbt 모델)** | 자기참조 + 131 컬럼 1:1 이식 (시간 ↑) | Looker·분석가·KPI 알림 모두 호환 |
| **(B) 개선 + 일부 분리** | (5) user_properties 분리 + RFM historical → 외부 분석 일부 재작성 | 본 마트 단순화 + dbt 가치 ↑ |
| **(C) 새로 짓기 + 외부 재교육** | 모든 외부 컨슈머 재작성·재교육 | 가장 큰 자유도, 클린 슬레이트 |

→ **추천 (P7 결정 시)**: **A 또는 B 의 중간 — 보존 + 개선 후보 1·2·4 적용**. C 는 외부 부담 너무 큼.

### 6-6. 위험 요소

- **자기참조 백필**: 최초 실행 / 전체 재생성 시 누적 매출 0부터 → dbt 마이그 시 backfill 절차 명확화 필요
- **외부 메타 부재**: Looker 메타 export 필요 ([F-003 §1](../../10-usage-frequency/F-003-external-interfaces.md))
- **GSheet 의존 stale**: `taenyon_temp_skill_tag_info_v2` 운영자 갱신 누락 시 스킬 태그 NULL 다발
- **`pay_under_750` 등 비즈 룰 변경 시 영향 광범위**: 본 마트 + 다운스트림 외부 모두 영향

## 7. 답할 수 있는·없는 질문

### 답할 수 있는 (분석 진입점 본진)
- 기능 성과: 신규 스킬 출시 후 7일 내 결제 유저·매출
- 퍼널 분석: 홈 배너·섹션·카테고리·검색별 결제 비율
- 코호트 × 매출 / 세그먼트별 매출
- RFM 세그먼트별 행동
- 콘텐츠 타입별 매출 (사주·타로·기타)

### 답할 수 없는 (다른 마트 필요)
| 필요 | 가야 할 곳 |
|---|---|
| 상세 스킬 퍼널 (노출→진입→완료 단계) | `mart_v2_skill_funnel_fb` |
| 세션 체류 시간 | `mart_session_start_fb` |
| 마케팅 UTM 최초 접촉 | `mart_marketing_utm_first_fb` |
| 리텐션 코호트 | `report_cohort_retention_*` |
| **결제 시점의 historical RFM** | (현재 부재 — 별도 마트 필요) |

## 8. 후속 액션

- [x] 본 카드 작성 (2026-05-01)
- [ ] **(★ v2 인계 추가)** 카탈로그 카드 stale 정정: "*미지정*" → `DAY (event_date)` / "~150 컬럼" → 131
- [ ] **(P5 외부)** Looker Studio 메타 export — 본 마트의 외부 컨슈머 매핑이 dbt 마이그 결정의 핵심 인풋
- [ ] **(P7) MP-1 trade-off 결정** — A/B/C 중 선택. 본 프로젝트의 가장 큰 결정 대상
- [ ] (후속 dbt) 자기참조 dbt 표준 패턴 (incremental + `{{ this }}`) 검증

## 참조

- 카탈로그: [tables/mart_integrated/union_mart_user_key_actions.md](../../../../../common-data-airflow/docs/hellobot-data/catalog/tables/mart_integrated/union_mart_user_key_actions.md) (매우 잘 작성됨)
- SQL: [scripts/hellobot/mart_integrated/union_mart_user_key_actions.sql](../../../../../common-data-airflow/dags/scripts/hellobot/mart_integrated/union_mart_user_key_actions.sql)
- F-001 §3 (위치 재정의): [F-001-mart-downstream-map.md](../../10-usage-frequency/F-001-mart-downstream-map.md#3-union_mart_user_key_actions-위치-재정의-필요-)
- F-003 §2 (KPI 알림): [F-003-external-interfaces.md](../../10-usage-frequency/F-003-external-interfaces.md#2-slack-kpi-알림--채널소스-마트-매핑-보존-필수)
- ISS-005 자기참조: [issues.md](../../../../../common-data-airflow/docs/hellobot-data/catalog/issues.md)
- ISS-006 GSheet 의존: 동일
