# F-903 — 정리 대상 자산 종합 (MP-3) — 후속 dbt 프로젝트 비대상

| 항목 | 값 |
|---|---|
| Phase | P7 |
| 중요도 | ★★ — Tier 4 정리 대상 단일 표 |
| 작성일 | 2026-05-01 |
| 출처 | F-002 §3, F-004 §6, F-202, F-204 종합 |

## 0. 정리 시점 — 마이그 전 vs 후 (사용자 결정)

| 옵션 | 장점 | 단점 |
|---|---|---|
| **마이그 시작 전 정리** | 마이그 자산 ↓ → 작업량 ↓ | 정리 위험 (사용 흔적 누락 시 회귀) |
| **마이그 후 정리** | 안전 (마이그 검증 후) | 마이그 자산 일부가 정리 대상이라 시간 낭비 |
| **마이그 중 점진** | 자산별 결정 | 운영 복잡도 ↑ |

→ **권장: 마이그 후 정리** (Strangler 의 마지막 단계). 단 dead 명백한 자산 (mart 16건 ~239 GB) 은 마이그 전 정리도 가능.

## 1. 마트 정리 대상 — 16건 (~239 GB)

### 대용량 dead (★ 우선 정리)
| 자산 | 미수정 | rows | size | 출처 |
|---|---|---|---|---|
| `hlb_mart_integrated.union_mart_user_key_actions2` | (활성 갱신 but 사용자 확인 정리) | 265M | **199 GB** | F-004 §5 (사용자 확인 2026-04-30) |
| `hlb_mart_integrated.mart_v2_skill_funnel_fb_with_tag_info` | 602일 | 53M | **19.6 GB** | F-004 §6 |
| `hlb_intermediate.intermediate_v2_mart_funnel_fb` | 919일 | 57M | **14.1 GB** | F-004 §6 |
| `hlb_report.pre_report_cohort_retention_visit` | 884일 | 39M | 5.2 GB | F-004 §6 (잘못된 데이터셋 분류) |

→ **소계 ~238 GB (전체의 99%)**

### 일자 스냅샷 + 소량 dead
| 자산 | 미수정 | size | 출처 |
|---|---|---|---|
| `hlb_mart.mart_web_to_app_install` | 518일 | 226 MB | F-004 §6 |
| `hlb_mart.mart_user_server_types_list` | ~~정정~~ | ~~~~ | **활성 dimension** (F-104 정정 — F-004 표에서 이동) |
| `hlb_pre_report.pre_report_user_revenue_info` | (data error) | - | F-004 §6 |
| `hlb_pre_report.pre_report_skill_with_manual_tagged_info_{20231026,20231103,20240409}` | 일자 스냅샷 | <3 MB | F-004 §6 |
| `hlb_report.pre_report_user_revenue_info` | 932일 | 54 MB | F-004 §6 (분류 모호) |
| `hlb_report.report_cohort_retention_active_weekly_app_{saju,tarot}` | 525일 | 1 MB | F-004 §6 |
| `hlb_report.report_cohort_retention_pay_daily_{app,web}` | 910일 | 0.1 MB | F-004 §6 |
| `hlb_report.report_cohort_retention_visit_by_monthly` `_by_platform_monthly` | 538일 | 0 MB | F-004 §6 |
| `hlb_report.report_dashboard_randombox` | 973일 | 0 MB | F-004 §6 |
| `hlb_report.report_kpi_onboarding_newuser_weekly` | 766일 | 0 MB | F-004 §6 (storyplay 만 사용) |

→ **소계 ~284 MB**

### 합계
- **15건** (`mart_user_server_types_list` F-104 정정으로 활성 분류 이동)
- **~239 GB**

→ **dbt 마이그 비대상**. dbt 모델 작성 X. 정리 시점에 BQ DROP TABLE.

## 2. 이벤트 정리 대상 — 화이트리스트 50건 + 1차만 등록 57건 + dead 결제 4건

### 2-1. Dead whitelist 50건 (F-002 §3) — 등록 but 7일 raw 발화 0
**카테고리별** (전체 list 는 [F-002 §3](../10-usage-frequency/F-002-event-usage-frequency.md#3-dead-whitelist-50건-정리-후보-mp-3)):

| 카테고리 | 건수 | 추정 |
|---|---|---|
| 챗봇 구독 (chatbot_subscription) | 8 | 기능 deprecated 추정 |
| 관계 (relation) | 7 | 기능 deprecated 추정 |
| 일일 운세 (daily_fortune) | 4 | historical 캠페인 |
| 컬렉션·랜덤박스 | 6 | 기능 deprecated 추정 |
| 스킬 리워드 | 4 | 기능 deprecated 추정 |
| 결제 옵션 | 3 | (F-202 dead 결제 4건과 중복) |
| 미션·코칭 | 3 | |
| 기타 | 15 | |

→ **카테고리별 사용자 검토 필요** — 기능 자체 deprecated 여부.

### 2-2. 1차만 등록 57건 (F-002 §2) — events_list 에만 등록, 2차 미등록
- raw 발화량 있는 이벤트 多 (`view_tab_at_home` 205K, `view_home_main` 168K, `view_chatroom` 150K)
- staging 도달 못함 (실효 없음)

**옵션** (사용자 결정):
- A) **events_list 에서 정리** (실효 없으니 제거)
- B) **2차 (fb_2nd / se_2nd) 추가 등록** (분석 의도대로 활성화)

### 2-3. Dead 결제 변종 4건 (F-202 §4)
- `pay_for_package`, `pay_for_collection`, `pay_for_coaching_program`, `pay_for_chatbot_subscription`
- se_2nd 등록 but 7일 raw 0 → 기능 자체 deprecated 추정
- → 카탈로그 deprecated 표기 + 화이트리스트 정리

## 3. 운영성 Server 이벤트 (Tier 4 Airflow 잔존, 정리 X)

| 이벤트 | 7일 발화 | 처리 |
|---|---|---|
| `use_attribute` | 1,577,315 | dbt source 등록만, 분석 변환 X |
| `update_attribute` | 1,410,455 | 동일 |
| `receive_user_message` | 909,795 | 동일 |

→ **정리 X — 운영 시스템 이벤트라 raw 보존 필요**. 단 분석 마이그 비대상.

## 4. 외부 의존 (Tier 4 Airflow 잔존, 정리 X)

| 의존 | 처리 |
|---|---|
| Firebase GA4 export | dbt source 등록만 |
| Server events | 동일 |
| RDS Snapshot (`server_rdb.snapshot_*`) | dbt source + Glue DAG 잔존 |
| GSheet (`google_sheet_sync.*`) | dbt source + sync DAG 잔존 + freshness test |
| Braze export | dbt source 등록만 |

→ 정리 X — 모두 활성 input.

## 5. DAG 정리 대상

| DAG | 처리 |
|---|---|
| `hlb_kpi_noti.py` | **잔존** (Slack KPI 알림 — dbt 비대상) |
| `hellobot_datamart_*_pipeline` (5+) | dbt 마이그 후 dbt 모델 트리거로 단순화 (전체 삭제 X) |
| `hellobot_sync_google_sheet`, `hellobot_snapshot_to_bigquery` | **잔존** (input ETL) |
| `hellobot_japan_*` (8) | 본 프로젝트 범위 외 |
| `hellobot_pay_for_contents_daily{,_v2,_v3}` (3) | v3 만 활성? — 사용자 확인 (정리 후보) |
| `hellobot_okr_2022.py`, `hackle_dashboard_2023.py` | 일자/연도 표기로 봐 historical 추정 — 정리 후보 |

→ **DAG 정리 후보 ~5건** (사용자 확인 필요).

## 6. 정리 절차 (권장)

### Step 1: dbt 마이그 진행 중 (Wave 2~5)
- 정리 대상 자산은 **dbt 모델 작성 X**
- 카탈로그 deprecated 표기 (v2 인계)

### Step 2: dbt 마이그 완료 후 (Post-migration 1~2주)
1. **마트 15건 BQ DROP** — 1주 정도 모니터링 후 (외부 사용 흔적 없는지 사용자 알림 1주 후)
2. **dead whitelist 50건 + dead 결제 4건 화이트리스트 DELETE**
3. **1차만 등록 57건 — 사용자 옵션 A/B 결정 후 처리**
4. **DAG 정리 후보 5건 — 사용자 확인 후 삭제**

### Step 3: 카탈로그 정리 (v2)
- 정리된 자산은 카탈로그에서도 제거 (또는 deprecated 섹션으로 이동)

## 7. 정리하지 않을 것 (의도적 보존)

- `hlb_mart.mart_user_server_types_list` (F-104 정정) — 활성 dimension
- 일별 스냅샷 마트 (`adhoc_banner_order` 854일분, `adhoc_home_section_order` 848일분) — 외부 컨슈머 확인 후 결정 (MP-2 partitioned table 통합 가능성, 다만 단순 정리 대상은 아님)
- 운영성 Server 이벤트 4건 — raw 보존
- Historical 일자 스냅샷 `pre_report_skill_with_manual_tagged_info_{...}` 3건 — 작은 size 라 보존도 가능 (사용자 결정)

## 8. 사용자 결정 항목 (정리 시점)

| # | 결정 | 영향 |
|---|---|---|
| 1 | 마트 15건 정리 시점 (마이그 전 / 후 / 일부 사전) | 위험·작업량 |
| 2 | 1차만 등록 57건 — A 정리 vs B 2차 추가 | 분석 누락 위험 vs 카탈로그 단순화 |
| 3 | Dead whitelist 50건 카테고리별 검토 (chatbot_subscription·relation·collection 등 기능 deprecated 여부) | 카탈로그 정합성 |
| 4 | DAG 5건 정리 (v2/v3 결제 DAG, okr_2022, hackle 등) | 운영 정리 |
| 5 | 일별 스냅샷 마트 (mart_adhoc) partitioned 통합 vs 보존 | MP-2 적용 |

## 9. 참조

- F-002 §3 dead whitelist 50건: [../10-usage-frequency/F-002-event-usage-frequency.md](../10-usage-frequency/F-002-event-usage-frequency.md)
- F-004 §6 dead 마트 16건: [../10-usage-frequency/F-004-orphan-and-dead-marts.md](../10-usage-frequency/F-004-orphan-and-dead-marts.md)
- F-202 dead 결제 4건: [../20-asset-semantics/events/F-202-payment-events-group.md](../20-asset-semantics/events/F-202-payment-events-group.md)
- F-204 운영성 Server 이벤트: [../20-asset-semantics/events/F-204-server-operational-events.md](../20-asset-semantics/events/F-204-server-operational-events.md)
