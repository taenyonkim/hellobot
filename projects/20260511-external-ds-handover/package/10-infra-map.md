# HelloBot 데이터 인프라 — 1페이지 지도

> **이 문서를 언제 쓰나요?** 데이터 관련 과업 시작 시 **맨 먼저** 읽는 3분짜리 전체 지도.
> 상세는 각 섹션의 "상세" 링크로 이동.

---

## 1줄 요약

```
Firebase / 서버 이벤트 + RDS 스냅샷 + GSheet → BigQuery → Airflow DAG 체인 → 마트 → Looker / Braze / Slack
```

- 프로젝트: `hellobot-f445c` (GCP)
- 주 리포: `common-data-airflow` (Python / Airflow)
- 담당 DAG 경로: `hlb_dags/`, 스크립트: `scripts/hellobot/`, 대상 BQ 데이터셋 접두어: `hlb_*`

---

## 레이어 (한 줄씩)

| 레이어 (데이터셋) | 무엇을 하는가 | 누가 쓰는가 |
|---|---|---|
| `hlb_staging` | 원본 정제 + 테스터 제외 + 이벤트 화이트리스트 필터 | 내부 파이프라인 |
| `hlb_intermediate` | 비즈 로직 (조인·세션화·유저 정보 병합) | 내부 파이프라인 |
| `hlb_mart` | 도메인별 분석 마트 (skill, purchase, home, ...) | 분석가 · 대시보드 |
| `hlb_mart_integrated` | 사용자×이벤트 통합 (`union_mart_user_key_actions` 본진) | **분석의 진입점** |
| `hlb_mart_adhoc` | RFM · UTM · 스냅샷 | 타겟팅 · 세그먼트 |
| `hlb_pre_report` → `hlb_report` → `tf_report` | KPI 리포트 · Slack 알림 · 경영 요약 | 대시보드 · 경영진 |

상세: [architecture.md §1~2](./architecture.md)

---

## 데이터 소스 (어디서 들어오는가)

| 소스 | 경로 | 성격 |
|---|---|---|
| Firebase GA4 | `analytics_164027297.events_*` (일별) + `events_intraday_*` (실시간) | 클라이언트 UX 이벤트 |
| 서버 이벤트 로거 | `analytics_164027297.server_events` | 비즈니스 로직 이벤트 (결제·스킬) |
| AWS Glue | `server_rdb.snapshot_*` | RDS 마스터 데이터 스냅샷 |
| Google Sheets | `google_sheet_sync.*` | 마케팅 ROAS · 광고매출 · KPI 목표 (수기) |
| Braze Export | `hellobot_braze.*` | 푸시 발송/오픈 |
| Manual | `manual_server_rdb.product` | 상품 마스터 수동 업로드 |

상세: [architecture.md §4](./architecture.md)

---

## 핵심 테이블 10선 (쓰임 빈도 순)

| 테이블 | 그레인 | 쓰임 한 줄 | 상세 |
|---|---|---|---|
| `hlb_mart_integrated.union_mart_user_key_actions` | event | **사용자 분석 본진** — 방문·스킬·결제 UNION + 메타/퍼널/RFM | [📄](./tables/mart_integrated/union_mart_user_key_actions.md) |
| `hlb_mart.mart_user_daily_info` | user×date | DAU·리텐션·신규/기존 분기 | [📄](./tables/mart/mart_user_daily_info.md) |
| `hlb_mart.mart_use_skill_se` | event | 서버 스킬 사용·결제 (매출 정합 기준) | [📄](./tables/mart/mart_use_skill_se.md) |
| `hlb_mart.mart_purchase_fb` | transaction | Firebase 스토어 인앱 결제 | [📄](./tables/mart/mart_purchase_fb.md) |
| `hlb_mart.mart_fixed_menu_server` | menu | 스킬(메뉴) 메타 마스터 — 디멘션 | [📄](./tables/mart/mart_fixed_menu_server.md) |
| `hlb_mart.mart_home_action_fb` | event | 홈 배너·섹션·탭 액션 | [📄](./tables/mart/mart_home_action_fb.md) |
| `hlb_mart.mart_v2_skill_funnel_fb` | event | 스킬 퍼널 (홈·카테고리·검색·추천·상세) | [📄](./tables/mart/mart_v2_skill_funnel_fb.md) |
| `hlb_mart.mart_skill_open_date_se` | menu | 스킬 첫 등장일 | [📄](./tables/mart/mart_skill_open_date_se.md) |
| `hlb_mart_adhoc.adhoc_mart_user_rfm_info_daily` | user | RFM 스코어·12세그먼트 | [📄](./tables/mart_adhoc/adhoc_mart_user_rfm_info_daily.md) |
| `hlb_staging.staging_key_events_fb` / `_se` | event | 정제된 원천 이벤트 (화이트리스트 통과) | 미작성 |

전체 인덱스: [mart-catalog.md](./mart-catalog.md)

---

## 이벤트 그룹 (용도별)

| 그룹 | 대표 이벤트 | 소스 | 소비 마트 | 상세 |
|---|---|---|---|---|
| **홈·네비게이션** | `view_home_main`, `view_tab_at_home` | Firebase | `mart_home_action_fb`, `mart_v2_skill_funnel_fb` | [event-catalog §4-1](./event-catalog.md#홈--네비게이션) |
| **홈 배너·섹션** | `touch_featured_banner`, `touch_home_section_item` | Firebase | 동일 + `union_mart_user_key_actions` 퍼널 태깅 | [event-catalog §4-1](./event-catalog.md#홈-배너--섹션) |
| **카테고리·검색·추천** | `touch_category_item`, `touch_search_result`, `click_recommend_skill` | Firebase | `mart_v2_skill_funnel_fb` | [event-catalog §4-1](./event-catalog.md#카테고리) |
| **스킬 상세·미리보기** | `open_skill_description`, `enter_skill` (Firebase) | Firebase | `mart_v2_skill_funnel_fb` | [event-catalog §4-1](./event-catalog.md#스킬-상세--미리보기-신규-스킬-온보딩) |
| **스킬 사용·결제** | `enter_skill`, `consume_skill`, `pay_for_contents/package/...` | Server | `mart_use_skill_se` (매출 정합 기준) | [event-catalog §4-2](./event-catalog.md#스킬-사용--결제) |
| **인앱 결제** | `in_app_purchase`, `purchase` | Firebase (자동 수집) | `mart_purchase_fb` | [event-catalog §4-1](./event-catalog.md#인앱-결제) |
| **오늘의 운세·광고** | `view_daily_fortune`, `start_ad_on_daily_fortune` | Firebase | `mart_home_action_fb` | [event-catalog §4-1](./event-catalog.md#오늘의-운세-탭-2025-10-13-추가) |

상세: [event-catalog.md](./event-catalog.md)

---

## 지표 도메인 10종

| 도메인 | 대표 지표 | 계산 소스 | 상세 |
|---|---|---|---|
| 매출 | `total_revenue_paying`, ARPPU | `union_mart_user_key_actions` | [metric-dict §1-1~4](./metric-dictionary.md#1-1-매출--수익-revenue) |
| 사용자 | DAU / WAU / MAU | 동일 | [metric-dict §1-2](./metric-dictionary.md#1-2-사용자-users) |
| 결제자 | `num_users_paying` 외 | 동일 | [metric-dict §1-3](./metric-dictionary.md#1-3-결제자-paying-users) |
| 광고 / ROAS | `{channel}_roas`, `contribution_margin` | GSheet + `union_mart_user_key_actions` | [metric-dict §1-5](./metric-dictionary.md#1-5-광고--roas) |
| 리텐션 | `retention_visit/pay/active` | `report_cohort_retention_*` | [metric-dict §1-6](./metric-dictionary.md#1-6-코호트--리텐션) |
| CRM / 푸시 | `send_users`, `open_users`, CTR | `hellobot_braze.*` | [metric-dict §1-7](./metric-dictionary.md#1-7-crm--푸시) |
| RFM | `payment_segment` 등 | `adhoc_mart_user_rfm_info_daily` | [metric-dict §1-8](./metric-dictionary.md#1-8-rfm-세그먼트-12종) |
| 콘텐츠·스킬 | `new_skill_counts`, `new_skill_pay_amounts` | `mart_fixed_menu_server` | [metric-dict §1-9](./metric-dictionary.md#1-9-콘텐츠--스킬) |
| AI 챗봇 | `ai_chatbot_spent_krw`, `ai_chatbot_users` | `mart_use_skill_se` + chatbot 메타 | [metric-dict §1-10](./metric-dictionary.md#1-10-ai-챗봇) |

전체: [metric-dictionary.md](./metric-dictionary.md)

---

## DAG 체인 (배치 실행 순서)

```
KST 11:00 (cron "0 2 * * *" UTC)
  └─ hellobot_datamart_staging_pipeline
     └─ trigger → intermediate_pipeline
        └─ trigger → mart_pipeline
           └─ trigger → mart_integrated_pipeline + mart_adhoc_pipeline
              └─ trigger → pre_report_pipeline
                 └─ trigger → report_pipeline + tf_report_pipeline
```

- 신규 이벤트는 **배포 다음날 KST 11시 이후** 분석 가능
- 부속 DAG: `hellobot_ltv`, `hellobot_daily`, `hellobot_snapshot_to_bigquery`, `hlb_kpi_noti`, `hellobot_sync_google_sheet`
- JP 파이프라인(`hellobot_japan_*`)은 별도 — 본 카탈로그 범위 외

상세: [architecture.md §3](./architecture.md#3-dag-체인)

---

## 결정적 컨벤션 (꼭 알아둘 것)

| 주제 | 규칙 |
|---|---|
| **시간대** | 모든 `event_date` 는 Asia/Seoul (staging 에서 UTC→KST 변환) |
| **사용자 표준 ID** | `user_id_processed` — APP 2019-04-01+ / WEB 2022-12-01+ 부터 `user_id`, 그 전은 `user_pseudo_id` |
| **이벤트 게이트키핑** | Firebase/서버 모두 `*_events_list` 화이트리스트 테이블에 등록된 이벤트만 수집 ([ISS-011](./issues.md)) |
| **서버 이벤트 env** | `env IN ('production','prod')` 만 수집 — dev/staging 배제 |
| **테스터 제외** | `server_rdb.user_test_group` 전체 자동 제외 |
| **매출 표준** | `revenue_krw` (유료 하트 + 현금, 보너스 제외) — 대부분 지표의 기본 |
| **하트 환산** | `KRW_PER_HEART = 150` (현재 2곳 중복 정의 — 변경 시 양쪽) |
| **KRW 마이크로단위** | Firebase `in_app_purchase + currency=KRW` 는 `value` 가 1,000,000× → 파이프라인에서 /1e6 처리 |
| **파티션** | 대부분 마트 파티션 없음 → 조회 시 `WHERE event_date BETWEEN …` 필수 |
| **실패 알림** | 모든 DAG `on_failure_callback` → Slack `#데이터-장애알림` |

상세: [architecture.md §5](./architecture.md#5-공통-규약)

---

## 과업 유형 → 진입 문서

| 지금 하려는 일 | 시작 문서 |
|---|---|
| **신기능 데이터 분석 시작 — 사용자 입력 정리** | [_templates/feature-data-analysis-input.md](./_templates/feature-data-analysis-input.md) (사용자가 채워서 `/dev-data` 에 던지는 입력서) |
| 새 기능 성과 측정 설계·구축 | [recipes/feature-performance-measurement.md](./recipes/feature-performance-measurement.md) |
| **이벤트 신규 설계 · 발송 시점 · 파라미터 · 검증 원칙** | [recipes/event-design-guide.md](./recipes/event-design-guide.md) |
| **신규 이벤트 등록 절차** (화이트리스트 INSERT, 도달 시점, 검증) | [recipes/add-new-event.md](./recipes/add-new-event.md) |
| 이벤트 이미 있나? 재사용 판단 | [event-catalog.md §유스케이스 색인](./event-catalog.md#유스케이스-색인) |
| 지표 정의 확인 / 계산식 확인 | [metric-dictionary.md](./metric-dictionary.md) |
| 새 지표 추가 | [metric-dictionary.md](./metric-dictionary.md) + (recipe 추후) |
| 마트에 뭐가 있는지 탐색 | [mart-catalog.md](./mart-catalog.md) |
| 새 마트 추가 | [playbook.md §Step 4](./playbook.md#step-4--파이프라인-반영) + (recipe 추후) |
| 파이프라인 흐름 상세 이해 | [architecture.md](./architecture.md) |
| 알려진 갭·제약·이슈 | [./issues.md](./issues.md) |
| 외부 확인 필요 사항 | [external-tasks.md](./external-tasks.md) |
| BigQuery 직접 조회 (로컬 OAuth · production SA 분리) | [bq-access.md](./bq-access.md) |

---

## 알려진 갭 (작업 시 인지)

★★ 이슈 (코드 설계 전 반드시 인지):
- ~~**이벤트 화이트리스트 관리 절차 부재**~~ ([ISS-011](./issues.md)) — **2026-04-27 해결** ([recipes/add-new-event.md](./recipes/add-new-event.md))
- ~~**기존 `docs/hellobot-data/tables/` 문서 실제 SQL 불일치**~~ ([ISS-001](./issues.md)) — **해결**, 참조 금지
- **Looker Studio 대시보드 역방향 매핑 없음** — 마트 변경 시 영향 범위 수동 파악
- **이벤트 화이트리스트 의도/구현 차이** ([ISS-014](./issues.md)) — 신규 이벤트 등록 시 양쪽 INSERT 권장
- **ID/이름 페어 발송 규칙 미준수 이벤트** ([ISS-015](./issues.md)) — Notion 설계 DB 검토 후 케이스 A/B/C/D 로 분기. 케이스별 처리
- **`view_skill_feedback` 코드↔설계 불일치** ([ISS-016](./issues.md)) — Notion=Server / 실제=Firebase, 파라미터 menu_title vs menu_seq 불일치

전체: [./issues.md](./issues.md), 우선순위: [architecture.md §9](./architecture.md#9-현재-알려진-갭-우선순위)

---

## 개정 이력

| 날짜 | 변경 | 작성자 |
|---|---|---|
| 2026-04-22 | 초안 — 전체 카탈로그·사전·플레이북·아키텍처 기반 요약 | /dev-data |
