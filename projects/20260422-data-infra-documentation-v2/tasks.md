# 과업 목록 (장기 백로그)

> **운영 원칙**:
> - 과업은 우선순위·기원별로 분류해 누적합니다 (체크박스 갱신은 SSOT 갱신 PR과 함께)
> - 다른 프로젝트가 카탈로그 확장을 요구하는 시점에 §신규 과업 으로 추가
> - 마일스톤 단위로 status.md 에 정리 (본 파일은 historical 백로그 유지)

## 1차에서 인계된 백로그

[1차 프로젝트 §종료 정보 §미완 과업](../20260422-data-infra-documentation/status.md#미완-과업-후일-결정-보류) 에서 이전된 항목.

### 기획 (외부 협의 필요)

- [ ] 주요 지표의 **오너십 확정** — 어떤 팀/담당자가 해당 숫자에 책임지는지
- [ ] 주요 대시보드·알림의 **현업 쓰임새** 수집 — 마트 카탈로그 초안 기반 인터뷰 (선택)

### 카탈로그 확장 (Phase 2 — `tables/`)

- [ ] **P1: intermediate 요약** (`union_mart_user_key_actions` 체인 이해용)
- [ ] **P2: staging 요약** (이벤트 카탈로그의 `staging_key_events_*` 보완)
- [ ] **★★ 추가 마트 카탈로그화** — 1차에서 union 계보로 한정한 스코프 외 확장 필요 시점에 우선순위 재평가

### 카탈로그 보강 (Phase 4·5·9)

- [ ] `report_*` 레이어 쿼리까지 스캔 확장 — 지표 사전 (`report_kpi_total_skill_*`, `report_key_metrics_by_daily` 등)
- [ ] 지표 변경 관리 규약 합의
- [ ] 실제 과거 기능 케이스 스터디 보강 (플레이북) — 기능 선정 후
- [ ] coop-integration 종료 후 템플릿 A(Purchase) 케이스 스터디 보강
- [ ] **recipes 추가** — `add-new-event.md` (이벤트 화이트리스트 등록 절차 — ISS-011 해소), `add-new-metric.md`, `add-new-mart.md` (사용 패턴 관찰 후 작성)
  - [x] `event-design-guide.md` (2026-04-27) — 2023-08 Tony Kim Notion 가이드 카탈로그 통합. 출처: 다른 프로젝트의 이벤트 설계 시 참조 필요

### 선택

- [ ] `/architect` 레이어 원칙·네이밍·태그 체계 검토 및 정비 제안

## 신규 과업 (다른 프로젝트가 요청하는 항목)

> 다른 프로젝트가 진행되면서 식별되는 카탈로그 갭·신규 마트·이벤트·지표 등을 여기에 누적합니다.
>
> **포맷**: `- [ ] {과업} — 출처: {프로젝트명/일자/배경}`
> **우선순위 표기**: §우선순위 높음 / §우선순위 중간 / §우선순위 낮음 으로 분류. 우선순위는 다른 과업과 비교하여 재평가 가능.

### 우선순위: 높음

- [ ] **Firebase 이벤트 파라미터 스펙 보강** — `analytics_164027297.events_*` 직접 조회로 주요 이벤트의 `event_params` 키·타입·필수여부 확인 후 [`catalog/event-catalog.md §4-1`](../../common-data-airflow/docs/hellobot-data/catalog/event-catalog.md) 각 이벤트의 파라미터 표 채우기
  - **출처**: 2026-04-22 v2 시작 시점 식별 — 이벤트 설계 시 파라미터 스펙 부재로 재사용 vs 신규 판별 정확도 저하
  - **외부 의존**: BQ 직접 조회 필요 (쿼리 템플릿: [`catalog/external-tasks.md A-2`](../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md))
  - **영향**: 이벤트 설계 정확성 + 신규 이벤트 재사용 판별 + 향후 dbt sources.yml 자동 생성 기반
  - **산출물**: `event-catalog.md §4-1` 각 이벤트의 파라미터 표 + §5 "파라미터 스키마 확인 범위" 갱신 (현재 6종 → 전체)
  - **권장 범위**: P0 마트(`union_mart_user_key_actions` 계보 9건)에서 사용되는 이벤트 약 20종 우선

#### dbt-migration-prep 인계 — 시스템 패턴 박스 신설 (★★★ 우선순위 높음)

다음 3건은 [dbt-migration-prep](../20260430-dbt-migration-prep/) P1 분석에서 발견된 **카탈로그에 명문화되지 않은 시스템 동작 패턴**. 다음 사람이 같은 함정에 빠지지 않도록 카탈로그 갱신 권장.

- [ ] **`queries.py` 가 destination 진실원천 박스 신설**
  - **출처**: dbt-migration-prep [F-004 §1](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-004-orphan-and-dead-marts.md#1-queriespy-가-destination-의-진실원천--f-001-§6-의-절반은-false-alarm) (2026-04-30)
  - **사실**: SQL 파일은 SELECT 본문, `dags/scripts/hellobot/{layer}/queries.py` 안의 SQL string 이 `INSERT INTO` / `CREATE TABLE` destination DDL 의 진짜 원천
  - **위치**: `catalog/architecture.md §5 공통 규약` 또는 §3 인근에 박스 신설 (~10줄)
  - **영향**: 미명문화로 분석 시 "SQL 파일 == destination" 오해 → false alarm 31건 발생 사례 (F-001 1차)

- [ ] **화이트리스트 3중 구조 실효 박스 + ISS-014 정량 보강**
  - **출처**: dbt-migration-prep [F-002 §1·§2](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-002-event-usage-frequency.md#1-화이트리스트-3중-구조의-실측-동작) (2026-04-30, BQ 어제 1일 + 7일 실측 검증)
  - **사실**: 1차 `events_list` (68건) 는 거의 효과 없음. 실제 게이트는 2차 `staging_key_events_fb_events_list` (44) / `staging_key_events_se_events_list` (7).
  - **정량**: events_list 에만 등록된 57건 중 다수가 raw 발화량 있음에도 staging 도달 못함 (`view_tab_at_home` 205K, `view_home_main` 168K, `view_chatroom` 150K 등)
  - **위치**: `catalog/architecture.md §5` 또는 `event-catalog.md §2` 에 박스 + `issues.md ISS-014` 정량 추가
  - **결정 필요**: A) 1차 게이트 폐기 명시 / B) 1차를 살리는 SQL 변경 제안 (architecture 변경)

- [ ] **외부 출력 (Slack KPI 알림) 표 신설 — `architecture.md §4-2`**
  - **출처**: dbt-migration-prep [F-003 §2](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-003-external-interfaces.md#2-slack-kpi-알림--채널소스-마트-매핑-보존-필수) (2026-04-30)
  - **사실**: `hlb_kpi_noti.py` 가 5개 KPI 함수 → 3개 Slack 채널 (`C06QV5555A7` #div_chatbot_biz, `C06A9JZRNH1` #team_ops-maximize, `C02HMRP42QM` 미상)
  - **소스 마트**: `union_mart_user_key_actions`, `report_kpi_total_skill_*`, `mart_fixed_menu_server`, `mart_use_skill_se` 등
  - **위치**: `catalog/architecture.md §4 데이터 소스` 다음에 `§4-2 외부 출력` 신설 (현재 입력만 명시)
  - **영향**: 마트 변경 시 어떤 외부 출력에 영향 미치는지 추적 가능

#### dbt-migration-prep 인계 — 자산 정정 (우선순위 중간)

- [ ] **`union_mart_user_key_actions` 위치 명료화**
  - **출처**: dbt-migration-prep [F-001 §3](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-001-mart-downstream-map.md#3-union_mart_user_key_actions-위치-재정의-필요-) (2026-04-30)
  - **사실**: 카탈로그가 "분석 본진" 으로 표현했으나 내부 SQL 다운스트림 단 2건 — 실제 사용자는 외부 (Looker · ad-hoc 분석가)
  - **위치**: `infra-map.md §핵심 테이블 10선` + `tables/mart_integrated/union_mart_user_key_actions.md` 설명 보강 ("외부 분석 진입점, 내부 hub 아님")

- [ ] **계층별 인벤토리 정합성 표 신설**
  - **출처**: dbt-migration-prep [F-001 §4](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-001-mart-downstream-map.md#4-계층별-인벤토리-정합성) (2026-04-30)
  - **사실**: BQ 테이블 vs SQL destination vs 참조 비교 표가 카탈로그에 없음. orphan 식별의 도구 역할
  - **위치**: `infra-map.md` 또는 `architecture.md §3` 다음에 표 추가

- [ ] **`hlb_staging.staging_currency_rate_sheet` GSheet sync 명문화**
  - **출처**: dbt-migration-prep [F-004 §4](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-004-orphan-and-dead-marts.md#4-외부-source--운영자-수동-tier-4-dbt-비대상-airflow-잔존) (2026-04-30)
  - **사실**: `hlb_staging.staging_currency_rate_sheet` 가 GSheet sync 인데 카탈로그 §데이터 소스 표는 `google_sheet_sync.*` 만 명시 (다른 데이터셋에 sync 결과가 위치)
  - **위치**: `catalog/architecture.md §4 데이터 소스` 표 보강

- [ ] **`hlb_report` 데이터셋 분류 정합성**
  - **출처**: dbt-migration-prep [F-001 §6](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-001-mart-downstream-map.md) (2026-04-30)
  - **사실**: `hlb_report.pre_report_cohort_retention_visit` 와 `hlb_report.pre_report_user_revenue_info` 의 데이터셋 분류 모호 (이름 prefix `pre_report_*` 와 데이터셋 `hlb_report` 불일치) — 잘못된 분류 또는 historical 잔재
  - **위치**: `mart-catalog.md` 정합성 검토 + 정리 시 `issues.md` 등록

#### dbt-migration-prep 인계 — 이슈 보강 (우선순위 중간)

- [ ] **ISS-014 실측 검증 정량 추가**
  - **출처**: dbt-migration-prep [F-002 §1](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-002-event-usage-frequency.md#1-화이트리스트-3중-구조의-실측-동작) (2026-04-30)
  - **사실**: 운영자 의도(OR union) 와 실 동작(2차 only effective) 갭의 정량 — 1차에만 57건 / 2차만 39건 / 3개 모두 등록 1건. raw 발화 있는데 staging 못 도달 시그널.
  - **위치**: `catalog/issues.md ISS-014` 본문에 실측 정량 추가

- [ ] **Dead whitelist 50건 deprecation 표기**
  - **출처**: dbt-migration-prep [F-002 §3](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-002-event-usage-frequency.md#3-dead-whitelist-50건-정리-후보-mp-3) (2026-04-30)
  - **사실**: 화이트리스트에 등록 but 7일 raw 0건 = 50건 (chatbot_subscription·relation·collection·skill_reward·daily_fortune 카테고리 다수)
  - **위치**: `catalog/event-catalog.md §4` 해당 이벤트 표에 deprecated 표기 (또는 별도 §deprecated 이벤트 섹션)
  - **선결**: 카테고리별 사용자 검토 (기능 자체 deprecated 여부)

#### dbt-migration-prep 인계 — 정책·기타 (우선순위 중간/낮음)

- [ ] **dbt 마이그 정책 MP-1·MP-2·MP-3 카탈로그 반영** (후속 dbt 프로젝트 시작 시점)
  - **출처**: dbt-migration-prep [readme §마이그 정책](../20260430-dbt-migration-prep/readme.md#마이그-정책--2026-04-30-사용자-확정) (2026-04-30 사용자 발화)
  - **정책**:
    - MP-1: 외부 인터페이스 보존은 권장이지만 절대 제약 아님 (trade-off 결정 가능)
    - MP-2: 마트 스키마는 가급적 유지하되 더 나은 구조 가능
    - MP-3: 분석 결과로 정리 대상 식별 → 마이그 비대상 결정
  - **위치**: `catalog/architecture.md` 또는 신규 `recipes/dbt-migration-policy.md`
  - **시점**: 후속 dbt 마이그 프로젝트 시작 시점 (지금은 dbt-migration-prep 한정)

- [ ] **핵심 테이블 10선 우선순위 갱신** (다운스트림 카운트 기준)
  - **출처**: dbt-migration-prep [F-001 §2](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-001-mart-downstream-map.md#2-의존-핫스팟--top-5) (2026-04-30)
  - **사실**: 다운스트림 카운트 실측 결과 — `mart_use_skill_se` (47), `intermediate_user_daily_info` (26), `mart_skill_funnel_fb` (23) 가 실제 의존 무게 1·2·3위. 현재 카탈로그 §핵심 테이블 10선 의 순서·표현과 align 필요
  - **위치**: `infra-map.md §핵심 테이블 10선`

- [ ] **mart_adhoc 일별 스냅샷 안티패턴 표기**
  - **출처**: dbt-migration-prep [F-004 §8](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-004-orphan-and-dead-marts.md#8-mart_adhoc-일별-스냅샷-누적-854--848) (2026-04-30)
  - **사실**: `adhoc_banner_order` 854 일분 / `adhoc_home_section_order` 848 일분 — 일자별 새 테이블 분기 패턴. dbt 안티패턴 (partitioned table 권장)
  - **위치**: `mart-catalog.md` 또는 `architecture.md §5 공통 규약`

#### dbt-migration-prep 인계 — 운영 환경 구축 (★★★ 우선순위 높음 + 중간)

다음 8건은 [dbt-migration-prep 90-next-actions §6](../20260430-dbt-migration-prep/findings/90-next-actions.md#6-v2-인계-추가-항목--2431-8건) 인계 — **"데이터 팀이 일하는 환경" (본질 목표)** 직결. 27·28 이 핵심.

- [x] **★ `catalog/domain-glossary.md` 신규 작성** (인계 #27, ★★★ 우선순위 높음) — 2026-05-06 빈 골격 작성 완료
  - **출처**: dbt-migration-prep [90-next-actions §3](../20260430-dbt-migration-prep/findings/90-next-actions.md#3-갭--본-prep-으로-안-채워진-영역) (2026-05-06) — 두 예시 요청 (월별 잔고 추이 / 충전 하트 재구매율) 시뮬레이션에서 막힘 → "잔고", "재구매율" 같은 비즈 개념 → 자산 매핑 부재 확인
  - **사실**: `metric-dictionary` 가 "지표명 → 정의" 라면 `domain-glossary` 는 "비즈 개념 (잔고·재구매·이탈) → 답할 수 있는 자산"
  - **결정 (2026-05-06 사용자)**: 사전에 채우지 않고 빈 골격 + 점진적 축적 메커니즘으로 출발. 카테고리 §1~§6 fix (RFM 제외 — q2), 본문 0개. 요청 처리 시 `recipes/data-request-handling.md` Step 4 흐름에서만 등록.
  - **산출물**:
    - `catalog/domain-glossary.md` 신규 — 카테고리 §1~§6 + §99 미분류 + 항목 작성 템플릿 + 사용 흐름 다이어그램
    - `catalog/readme.md` §과업·인벤토리 갱신 (cross-link 추가)
    - `catalog/infra-map.md §과업 유형 → 진입 문서` 표 갱신 + 개정 이력
  - **워크트리**: `Feat/data-infra-v2-catalog-event-design`

- [x] **★ `catalog/recipes/data-request-handling.md` 신규 작성** (인계 #28, ★★★ 우선순위 높음) — 2026-05-06 작성 완료
  - **출처**: dbt-migration-prep [90-next-actions §3](../20260430-dbt-migration-prep/findings/90-next-actions.md#3-갭--본-prep-으로-안-채워진-영역) (2026-05-06) — 데이터 요청 해석 → 자산 점검 → 갭 식별 → 액션 결정 흐름의 명문화 부재
  - **사실**: 일상 요청 (지표·추이·세그먼트 분석) 처리 표준 절차 부재 — `/dev-data` 가 매번 즉흥 진행
  - **결정 (2026-05-06 사용자)**: 빈 골격 + 점진적 축적 메커니즘. §D (자산 부재) 분기는 "할 수 없는 이유" 사유 보고로 종결, 새 자산 추가는 별도 의사결정 (q4). 자주 받는 요청 패턴 라이브러리는 누적 후 추가.
  - **산출물**:
    - `catalog/recipes/data-request-handling.md` 신규 — 6 step (수신 → 키워드 추출 → 글로사리 탐색 → 명확화·합의 → 5 유형 분기 → log 갱신) + 질문 템플릿 + 함정 체크리스트
    - `catalog/request-log.md` 신규 — 요청 1건당 1행 누적 (REQ-NNN), 활성·종결 표 분리, 분류·상태 코드
    - `catalog/readme.md` §과업·레시피·참조 표 갱신 (cross-link 추가)
    - `catalog/infra-map.md §과업 유형 → 진입 문서` 표 갱신 + 개정 이력
  - **워크트리**: `Feat/data-infra-v2-catalog-event-design`

- [ ] **`catalog/recipes/add-new-metric.md` 신규 작성** (인계 #29, 우선순위 중간)
  - **출처**: dbt-migration-prep [90-next-actions §6](../20260430-dbt-migration-prep/findings/90-next-actions.md#6-v2-인계-추가-항목--2431-8건) (2026-05-06) — `readme.md §레시피` 표에 placeholder 만 있는 상태
  - **사실**: 신규 지표 합의·등록 절차 부재 — 정의·산식·소스·소비처·오너십 결정 흐름 명문화 필요
  - **위치**: `catalog/recipes/add-new-metric.md` 신규
  - **인접 갱신**: `readme.md §레시피` placeholder 제거 + `metric-dictionary.md` cross-link
  - **권장 작성 시점**: 28 (data-request-handling) Step 5 작성 중 자연 발생 시 — 28 의 §C 가 본 recipe 의 핵심 절차를 결정

- [ ] **`catalog/recipes/add-new-mart.md` 신규 작성** (인계 #30, 우선순위 중간)
  - **출처**: dbt-migration-prep [90-next-actions §6](../20260430-dbt-migration-prep/findings/90-next-actions.md#6-v2-인계-추가-항목--2431-8건) (2026-05-06) — `readme.md §레시피` 표에 placeholder 만 있는 상태
  - **사실**: 신규 마트 추가 절차 부재 — 그레인 결정·소스 lineage·DAG 위치·dbt 매핑·tables/ 카드 작성 흐름 명문화 필요
  - **위치**: `catalog/recipes/add-new-mart.md` 신규
  - **인접 갱신**: `readme.md §레시피` placeholder 제거 + `mart-catalog.md` / `architecture.md §3 DAG 체인` cross-link
  - **권장 작성 시점**: 28 (data-request-handling) Step 6 작성 중 자연 발생 시 — 28 의 §D 가 본 recipe 의 핵심 절차를 결정

- [ ] **`add-new-event.md` 가 운영 워크플로우 (28번) 와 cross-link 보강** (인계 #31, 우선순위 낮음)
  - **출처**: dbt-migration-prep [90-next-actions §6](../20260430-dbt-migration-prep/findings/90-next-actions.md#6-v2-인계-추가-항목--2431-8건) (2026-05-06)
  - **사실**: 28 (data-request-handling) Step 6 (§D) 에서 add-new-event 로 위임될 때 양방향 cross-link 필요
  - **위치**: `catalog/recipes/add-new-event.md` 상단·하단 cross-link 추가
  - **권장 작성 시점**: 28 작성 완료 후 한꺼번에

- [ ] **F-001 raw TSV → 카탈로그 임베드** (인계 #24, 우선순위 중간)
  - **출처**: dbt-migration-prep [F-001](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-001-mart-downstream-map.md) raw TSV (2026-04-30)
  - **사실**: 마트 다운스트림 카운트 raw 데이터가 prep 산출물에만 존재 — 카탈로그에 임베드 시 변경 영향 추적 도구로 상시 활용 가능
  - **위치**: `catalog/data/mart-downstream-counts.tsv` 신규 또는 `mart-catalog.md` 표 임베드
  - **운영**: 분기마다 재계산 권장 (BQ 쿼리 보존 + 갱신 주기 명시)

- [ ] **F-002 raw CSV → 카탈로그 임베드** (인계 #25, 우선순위 중간)
  - **출처**: dbt-migration-prep [F-002](../20260430-dbt-migration-prep/findings/10-usage-frequency/F-002-event-usage-frequency.md) raw CSV 5개 (2026-04-30)
  - **사실**: 이벤트 발화 빈도 + 화이트리스트 정합성 raw 데이터가 prep 산출물에만 존재 — 카탈로그에 임베드 시 dead 이벤트·미관측 이벤트 식별 상시 활용 가능
  - **위치**: `catalog/data/event-frequency-{date}.csv` 신규 또는 `event-catalog.md` 표 임베드
  - **운영**: 분기마다 재계산 권장. #9 (Dead whitelist 50건 deprecation) 와 함께 처리 가능

- [ ] **`infra-map.md §과거 분석 산출` cross-link 섹션 신설** (인계 #26, 우선순위 중간)
  - **출처**: dbt-migration-prep [90-next-actions §6](../20260430-dbt-migration-prep/findings/90-next-actions.md#6-v2-인계-추가-항목--2431-8건) (2026-05-06)
  - **사실**: prep 의 17 finding 카드가 카탈로그에서 접근 안 됨 — infra-map 에 진입점 추가 시 다음 사람이 발견 사용 가능
  - **위치**: `catalog/infra-map.md` 하단에 §과거 분석 산출 섹션 신설 → prep 17 카드 + 90-next-actions cross-link

### 우선순위: 중간

- [x] **`.claude/commands/dev-data.md` §파티션 필터 표 갱신 — `analytics_164027297.server_events` 행** (2026-04-27, [ISS-012](../../common-data-airflow/docs/hellobot-data/catalog/issues.md) 해결)
  - **출처**: 2026-04-27 `/review` 검증 — server_events 파티션 컬럼은 `event_timestamp` (TIMESTAMP) 인데 가이드는 `event_date = ...` 로 잘못 안내. 따라가면 32GB 풀스캔 가능
  - **수정 완료**: 파티션 필터 표의 server_events 행을 `WHERE DATE(TIMESTAMP_TRUNC(event_timestamp, DAY), 'Asia/Seoul') = ...` 로 변경 (검증된 0.9MB 패턴) + ISS-012 cross-link
  - **위치**: 워크스페이스 `.claude/commands/dev-data.md` — 워크스페이스 단일 변경, 데이터 리포 커밋과 별도

- [ ] **ID/이름 페어 발송 규칙 미준수 이벤트 보강** ([ISS-015](../../common-data-airflow/docs/hellobot-data/catalog/issues.md))
  - **출처**: 2026-04-27 페어 규칙 명문화 + Notion 설계 DB 검토 후 케이스 분기
  - **케이스 A** (Notion 설계 누락 — 재설계 필요): `touch_result_image_message`, `delete_result_image_storage`
  - **케이스 B** (설계 준수, 구현 누락 — 발송 코드만 보강, **우선순위 1**): `touch_result_image_item`
  - **케이스 C** (서버 이벤트, 설계 문서 부재): `use_attribute` (299K/일), `update_attribute` (268K/일), `receive_user_message` (161K/일) — 서버 이벤트 설계 문서 위치 확인 후 처리 ([external-tasks A-5](../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md))
  - **케이스 D** (별도 ISS-016): `view_skill_feedback` — 소스·파라미터 모두 불일치, 별도 추적

- [ ] **`view_skill_feedback` 코드↔Notion 설계 불일치 정리** ([ISS-016](../../common-data-airflow/docs/hellobot-data/catalog/issues.md))
  - **출처**: 2026-04-27 Notion 설계 검토 — Notion: Server 발송, 파라미터 menu_title / 실제: Firebase 6,913건/일, menu_seq 1,851건. SSOT(event-catalog) 와 historical(Notion) 불일치
  - **결정 필요**: A) 코드 정정 (설계대로) B) SSOT 기준 카탈로그 정의 (Notion 폐기) C) 양쪽 다 활용 (의미 분리)
  - **임시**: SSOT 정책에 따라 실 운영(Firebase) 기준 카탈로그 §4-1 유지

- [ ] **서버 이벤트 설계 문서 위치 확인** ([external-tasks A-5](../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md))
  - **출처**: 2026-04-27 — Notion DB(📓 이벤트) 는 Firebase 위주. use_attribute/update_attribute/receive_user_message 같은 서버 이벤트 설계 문서가 별도 위치에 있는지 또는 부재인지 확인 필요

- [ ] **이벤트 화이트리스트 의도/구현 정합화** ([ISS-014](../../common-data-airflow/docs/hellobot-data/catalog/issues.md))
  - **출처**: 2026-04-27 Phase 0 G3 — 운영자 의도 (events_list = 1차 / `*_fb_events_list` = 2차) 와 `staging_key_events_fb.sql` 의 OR 통합 패턴이 다름. 다음 단계 SQL 들 (`intermediate_v2_metrics_*` / `staging_marketing_utm_fb` / `adhoc_mart_acquisition_with_utm*`) 은 둘 중 하나만 참조 → 한쪽만 등록 시 일부 마트 미관측 발생 가능
  - **결정 필요**: A) staging SQL 분리 (의도와 맞춤) / B) 의도를 현 구현에 맞게 재정의 / C) 양쪽 등록 권장으로 운영
  - **임시 운영**: `recipes/add-new-event.md` 의 권장대로 **분석/마트 사용 예정이면 양쪽 등록**

- [ ] **`env` 필터 일관성 정리** ([ISS-013](../../common-data-airflow/docs/hellobot-data/catalog/issues.md))
  - **출처**: 2026-04-27 Phase 0 G2 — staging SQL 은 `env IN ("production","prod")` 인데 일부 ad-hoc 함수(`hellobot_ltv_func.py`, `hackle_dashboard_2023_func.py`)는 `env = 'production'` 단일 필터. 7일 실측에 `prod` 미관측이지만 historical 가능
  - **결정 필요**: A) `prod` 폴백 제거 (단순화) vs B) 전체 함수 `IN ("production","prod")` 로 통일
  - **선결**: `prod` 가 historical 에 정말 존재했는지 확인 (예: 30일+ 범위 dry-run)

- [ ] **GCP Service Account 키 파일 `.gitignore` 패턴 추가**
  - **출처**: 2026-04-27 `/review` 검증 — 워크스페이스·common-data-airflow 양쪽 `.gitignore` 모두 SA 키 패턴 부재. `bq-access.md §2-2` 의 "이중 가드" 가 현재 미적용 상태
  - **대상**: 워크스페이스 `hellobot/.gitignore` + `common-data-airflow/.gitignore`
  - **패턴**: `*.json.key`, `*-credentials.json`, `*service-account*.json`, `*service_account*.json`, `gcp-key*.json`, `application_default_credentials.json`
  - **확인 후 처리**: 패턴 추가 후 `bq-access.md §2-2` 의 톤 다운 문구를 적용 완료 표기로 환원

### 완료

- [x] **catalog/bq-access.md 신규 작성** (2026-04-22) — production SA 키 vs 로컬 OAuth 인증 분리 정책 문서화
  - 출처: 2026-04-22 — Claude Code `/dev-data` 가 BQ 직접 조회를 시작하면서 production 자격증명과의 분리 원칙 명문화 필요
  - 산출물: `catalog/bq-access.md` 신규 + `architecture.md §5-7` + `infra-map.md §과업 유형 → 진입 문서` + `readme.md` 문서 목록에 cross-ref 추가
  - 워크트리: `Feat/data-infra-v2-catalog-event-design` (커밋·PR 진행 시점 사용자 결정)

- [x] **catalog/recipes/event-design-guide.md 신규 작성** (2026-04-27) — 2023-08 Tony Kim Notion 가이드 카탈로그 통합 (옵션 A)
  - 출처: 2026-04-27 — 신규 기능의 이벤트 설계 시 참조할 단일 진입점 필요. 기존 가이드는 Notion 비공식 SSOT 였음
  - 원본: `projects/20260422-data-infra-documentation-v2/references/기존문서/[데이터] 이벤트 수집 설계 & 개발 가이드 4ea76a2490b54ff499f1c1281c4c1748.md`
  - 산출물: `catalog/recipes/event-design-guide.md` (§1 사용자 모델 / §2 발송 타이밍 / §3 파라미터 / §4 중요도 / §5 설계 순서 / §6 검증 / §7 안티패턴) + cross-link 3곳 (`recipes/feature-performance-measurement.md` Step 3, `infra-map.md §과업 유형`, `readme.md` 문서 목록)
  - 워크트리: `Feat/data-infra-v2-catalog-event-design` (bq-access 와 별도 커밋으로 분리)

- [x] **`/review` 지적 사항 일괄 수정** (2026-04-27) — Must Fix 4건 + Should Fix #1
  - 깨진 워크스페이스 링크 (`.claude/*`, `references/*`) 3개 → 텍스트 표기로 변경 (외부 클론 사용자에게도 의미 통하도록)
  - `bq-access.md §2-2` 의 .gitignore 사실 불일치 → 톤 다운 + 후속 task 등록 (§우선순위 중간)
  - `event-design-guide.md §6-2` BQ 검증 쿼리 패턴 → 실측 검증 후 정확한 패턴 (`DATE(TIMESTAMP_TRUNC(event_timestamp, DAY), 'Asia/Seoul')`) 으로 교체
  - 신규 발견: [ISS-012](../../common-data-airflow/docs/hellobot-data/catalog/issues.md) — `analytics_164027297.server_events` 파티션 컬럼 가이드 오류 (32GB 풀스캔 위험), 후속 task 등록

- [x] **event-catalog SSOT 정책 명문화 + Notion historical DB 활용 흐름 정의** (2026-04-27)
  - **출처**: taenyon 운영 정책 — event-catalog 가 SSOT, BQ events_list 등록 = 검증된 활성, Notion 설계 DB 는 historical 참고
  - **반영**:
    - `event-catalog.md` 상단 §SSOT 정책 신규 (4단계 활용 흐름 포함)
    - `recipes/add-new-event.md` 사전 조건에 "재사용 검색 → Notion historical 매칭 → 검증 후 SSOT 등록" 흐름 추가
    - `recipes/event-design-guide.md §3-4` 페어 매트릭스 다국어 확장 (chatbot_bundle_seq, chatbot_language)
    - `event-catalog.md §4-1`, `issues.md ISS-015` 케이스 A/B/C/D 분기 + Notion 페이지 ID 출처 명시
    - `issues.md ISS-016` 신규 — view_skill_feedback Notion 설계 vs 실 운영 불일치
    - `external-tasks.md A-5` 신규 — 서버 이벤트 설계 문서 위치 확인
    - `infra-map.md §알려진 갭` ISS-016 추가
  - **검증 출처**: Notion DB ID `ab9172f0-59b3-474e-836d-cfdc0f6fd9b9` 의 5개 이벤트 페이지 fetch + BQ 어제 1일 실측
  - 워크트리: `Feat/data-infra-v2-catalog-event-design`

- [x] **이벤트 설계 §3-4 ID/이름 페어 발송 규칙 명문화** (2026-04-27)
  - **출처**: taenyon 제안 — 이벤트가 `*_seq` 를 보낼 때 `*_name` 도 페어로 보내야 한다 (조인 회피 + rename 시 historical accuracy)
  - **검증**: Firebase + server_events BQ 어제 1일 실측 → 대부분 이벤트가 이미 페어 발송 중, 7건 미준수 발견
  - **결정**: 합리적 규칙 — 명문화 + 미준수 이벤트는 ISS-015 로 추적
  - **반영**:
    - `recipes/event-design-guide.md §3-4` 신규 (페어 규칙 ★ 강제)
    - `recipes/event-design-guide.md §3-5` (기존 §3-4 네이밍·재사용을 §3-5 로)
    - `event-catalog.md §5` ID/이름 페어 발송 규칙 cross-link
    - `recipes/add-new-event.md` 사전 조건 체크리스트에 페어 규칙 항목
    - `infra-map.md §알려진 갭` ISS-015 추가
    - `issues.md ISS-015` 신규 등록 (Firebase 4건 + 서버 3건 미준수 실측)
  - 워크트리: `Feat/data-infra-v2-catalog-event-design`

- [x] **Phase 0 G3 — 이벤트 화이트리스트 등록 절차 확정** (2026-04-27, [ISS-011](../../common-data-airflow/docs/hellobot-data/catalog/issues.md) 해결, [external-tasks A-1](../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md) 해결)
  - **출처**: Phase 0 사전 보강 — 신규 이벤트가 운영 BQ 까지 도달하는 절차 미문서화 → 신기능 출시 시 데이터 누락 위험
  - **방법**: taenyon 운영자 5문항 인터뷰 + staging SQL 코드 스캔 검증
  - **결과**:
    - 등록 방식: BigQuery 수동 INSERT (taenyon 개인 운영). 자동화·승인 절차 없음
    - 의도된 분리: `events_list` (1차) / `staging_key_events_fb_events_list` (2차) / `staging_key_events_se_events_list` (서버 단일)
    - Raw 도달: Firebase D+1 KST 10시 / 서버 즉시 / 마트 D+1 KST 11시
    - 누락 발견: 자동 모니터링 없음 — 사후 발견 (D+1~2)
  - **부산물**: 의도/구현 차이 발견 → ISS-014 신규 등록 (staging_key_events_fb 의 OR 통합과 의도 불일치)
  - **반영**:
    - `recipes/add-new-event.md` (신규, 5단계 워크스루 + 자주 발생하는 실수)
    - `event-catalog.md §2-1` 전면 재구성
    - `event-catalog.md §7` Q&A 갱신
    - `external-tasks.md A-1` 답 채움
    - `infra-map.md §과업 유형` + §알려진 갭 (ISS-011 해결 표기, ISS-014 추가)
    - `readme.md` 인벤토리·"지금 뭘 하려는 건가요" 표
    - `issues.md ISS-011` 해결, `ISS-014` 신규
  - 워크트리: `Feat/data-infra-v2-catalog-event-design`

- [x] **Phase 0 G2 — `server_events` 전체 스키마 + `env` 분포 검증** (2026-04-27, [external-tasks A-3](../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md) 해결)
  - **출처**: Phase 0 사전 보강 — 신기능 성과 분석 설계 정확도 확보를 위해 server_events 의 실제 컬럼·env 분포 확정
  - **방법**: `bq show --format=prettyjson` + `env`/`platform`/`channel` 분포 1쿼리 (어제 26MB) + 7일 env 분포 (89MB)
  - **발견 1**: 카탈로그 §6 의 "주요 컬럼" 리스트(chatbot_seq, menu_seq 등)가 실제로는 staging 변환 후 컬럼 — server_events 원천에는 `event_params` REPEATED RECORD 만 존재. event-catalog.md §6 전면 재구성 (§6-1 원천 / §6-2 staging 변환 후)
  - **발견 2**: env 7일 분포 = production 4.5M / development 3K. `prod` 값 미관측 — staging 폴백의 정합성 검증 필요. ISS-013 신규 등록
  - **반영**: `event-catalog.md §2-3` (env 실측), `§6` (전면 재구성), `§8` (TBD 체크), `external-tasks.md A-3` (답 채움), `issues.md ISS-013` (신규)
  - 워크트리: `Feat/data-infra-v2-catalog-event-design`

### 우선순위: 낮음

- [ ] **iOS · Web bool 파라미터 DebugView 표시 검증**
  - **출처**: 2026-04-27 `/review` — `event-design-guide.md §3-3` 의 BOOL → 1/0 매핑이 Android 만 확인된 상태. iOS·Web 미확정 (원본 Notion 가이드도 미확인)
  - **방법**: 본인 계정으로 테스트 이벤트 발송 후 DebugView · BigQuery 양쪽 표시 형태 확인
  - **반영**: `event-design-guide.md §3-3` 표 갱신

## 영속 이슈 추적

본 프로젝트의 영속 이슈(SSOT 의 ISS-002~011 + 신규 발견)는 [`common-data-airflow/docs/hellobot-data/catalog/issues.md`](../../common-data-airflow/docs/hellobot-data/catalog/issues.md) 에서 추적합니다. 본 파일은 과업 추적 전용.

## 외부 DB / 시스템 확인 과업

[`common-data-airflow/docs/hellobot-data/catalog/external-tasks.md`](../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md) 에서 추적. 본 파일에 중복하지 않음.
