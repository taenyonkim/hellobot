# 과업 목록

> **운영 원칙**:
> - Phase 별로 과업을 분류해 누적합니다.
> - 진행 중 발견되는 추가 과업은 해당 Phase 또는 §누적 발견 에 추가합니다.
> - finding 카드 작성 단위로 체크합니다 (개별 카드 = 개별 과업).
> - SSOT 갱신 가치 발견 시 본 파일에 기록 + v2 (`projects/20260422-data-infra-documentation-v2/tasks.md`) 에도 인계.

---

## P0 셋업

- [x] 프로젝트 디렉토리 생성 (2026-04-30)
- [x] readme / status / tasks / findings/README 작성 (2026-04-30)
- [x] Phase 별 폴더 골격 (10~70) 생성 (2026-04-30)

---

## P1 ★ 사용 빈도 인벤토리

**목적**: 마트·테이블·이벤트별 다운스트림 카운트 → dbt 마이그 우선순위

### 작업 항목

- [x] **마트 다운스트림 인벤토리** — 각 `hlb_mart.*` / `hlb_mart_integrated.*` / `hlb_mart_adhoc.*` / `hlb_pre_report.*` / `hlb_report.*` 테이블이 어디서 참조되는지 카운트 (2026-04-30)
  - 내부 SQL (`scripts/hellobot/**/*.sql` + `queries.py`) 의 FROM/JOIN 카운트 — 완료
  - 다른 DAG (`hlb_dags/**/*.py`) 의 참조 카운트 — **0건 (DAG 는 순수 오케스트레이션, 테이블 직접 참조 X)**
  - INFORMATION_SCHEMA.JOBS 외부 쿼리 카운트 — **F-003 (외부 인터페이스) 로 분리, 권한·비용 별도 검토**
  - 산출: [F-001-mart-downstream-map.md](./findings/10-usage-frequency/F-001-mart-downstream-map.md) + [F-001-data-mart-downstream.tsv](./findings/10-usage-frequency/F-001-data-mart-downstream.tsv)
- [x] **이벤트 사용 빈도 인벤토리** — 화이트리스트 등록 이벤트 중 실제 발화량(7일) + staging 살아남는 비율 (어제) (2026-04-30)
  - 산출: [F-002-event-usage-frequency.md](./findings/10-usage-frequency/F-002-event-usage-frequency.md) + 5개 raw CSV
  - 핵심: ISS-014 실측 검증 (1차만 57건 효과없음) / dead whitelist 50건 / 미등록 고볼륨 10건 / 살아남는 비율 FB 36.7% / SE 7.9%
- [x] **report·tf_report 다운스트림** — Slack 알림·Looker·Notion 까지 도달하는 자산 인벤토리 (외부 인터페이스가 곧 보존 필수 자산) (2026-04-30)
  - 산출: [F-003-external-interfaces.md](./findings/10-usage-frequency/F-003-external-interfaces.md)
  - 출력 4종 (Slack 실패 + Slack KPI + Notion via tf_report + Hackle) / 입력 5종 (Firebase/Server/RDS/GSheet/Braze) 매트릭스 + KPI 알림 채널 매핑 + MP-1 trade-off 권장
- [x] **사용량 sparse 마트 식별** — 0~1회만 참조되는 마트 (마이그 비대상 후보) (2026-04-30)
  - 산출: [F-004-orphan-and-dead-marts.md](./findings/10-usage-frequency/F-004-orphan-and-dead-marts.md)
  - 활성 3건 정정 + Tier 4 후보 (외부 source 6 + dead 15 + historical 3 + mystery 1) 확정

---

## P2 ★ 자산 시맨틱 baseline

**목적**: 마트·이벤트·지표의 정의·그레인·NULL 의미·암묵 가정 → 재정의 시 align 기준

### 작업 항목

- [ ] **마트 시맨틱 baseline 6건** — F-001 Top 5 + `union_mart_user_key_actions`
  - [x] F-101 `mart_use_skill_se` (2026-05-01)
  - [x] F-102 `intermediate_user_daily_info` (2026-05-01)
  - [x] F-103 `mart_skill_funnel_fb` (2026-05-01)
  - [x] F-104 `mart_user_server` (2026-05-01)
  - [x] F-105 `staging_fixed_menu_copy` (2026-05-01)
  - [x] F-106 `union_mart_user_key_actions` (2026-05-01)
- [ ] **사용 빈도 상위 마트 시맨틱 카드** — P1 결과 기준 상위 N개 (P0 외)
  - 산출: `findings/20-asset-semantics/marts/F-110+.md`
- [x] **이벤트 시맨틱 카드** — 4 그룹 (2026-05-01)
  - F-201 enter_skill / F-202 결제 이벤트 / F-203 Firebase 신규 스킬 온보딩 / F-204 운영성 Server
- [x] **지표 시맨틱 카드** — F-301 종합 1 카드 (2026-05-01)
  - 10 도메인 × 50+ 지표 / 보존 필수 6 / 합의 필요 3 / 외부 의존 3

---

## P3 의존 그래프

**목적**: DAG → SQL → 테이블 → 다운스트림 의존 그래프 (현재 카탈로그는 DAG 체인만 명시)

### 작업 항목

- [ ] **SQL 레벨 lineage 추출** — `scripts/hellobot/**/*.sql` 파싱하여 source → target 테이블 매핑
  - 산출: `findings/30-lineage/F-401-sql-lineage.md` (또는 JSON)
- [ ] **DAG → SQL 매핑** — 각 DAG 가 어떤 SQL 을 호출하는지
  - 산출: `findings/30-lineage/F-402-dag-sql-binding.md`
- [ ] **mart_integrated UNION 구조 매핑** — `union_mart_user_key_actions` 의 UNION 소스 마트 명세
  - 산출: `findings/30-lineage/F-403-mart-integrated-union.md`

---

## P4 staging 변환 룰

**목적**: 이벤트 → staging 변환 로직 (화이트리스트·user_id_processed·테스터 제외·시간대 변환·매출 환산)

### 작업 항목

- [ ] **staging_key_events_fb 변환 룰** — events_* → staging_key_events_fb 의 모든 변환 로직 명세
- [ ] **staging_key_events_se 변환 룰** — server_events → staging_key_events_se 의 모든 변환 로직 명세
- [ ] **테스터 제외 룰** — `server_rdb.user_test_group` 적용 위치·방식
- [ ] **user_id_processed 분기 룰** — APP/WEB 시점별 user_id vs user_pseudo_id 매핑

---

## P5 외부 의존 (dbt 비대상)

**목적**: dbt 가 옮길 수 없는 영역 — Airflow 에 잔존해야 할 부분

### 작업 항목

- [ ] **Firebase GA4 export 의존** — `analytics_164027297.events_*` import 메커니즘 (dbt 가 직접 owning 못함)
- [ ] **GSheet sync** — `google_sheet_sync.*` (마케팅 ROAS·KPI 목표) 동기화 절차
- [ ] **Braze export** — `hellobot_braze.*` import 메커니즘
- [ ] **Notion KPI** — Notion 으로 가는 알림·요약
- [ ] **Looker Studio 대시보드** — 데이터셋·테이블 의존 (역방향 매핑 부재 — ISS 등록 후보)

---

## P6 Historical 결정·암묵 룰

**목적**: 코드만 보면 못 바꾸는 룰들 — 재정의 위험 회피

### 작업 항목

- [ ] **`KRW_PER_HEART = 150`** — 출처·결정 시점·재정의 가능 여부 (현재 2곳 중복 — 통합 가능성 검토)
- [ ] **`env IN ('production','prod')` 의 historical** — `prod` 가 historical 에 정말 존재했는지 (이미 v2 의 ISS-013 추적중)
- [ ] **매출 표준 `revenue_krw`** — 유료 하트 + 현금, 보너스 제외의 정의 정착 시점
- [ ] **시간대 KST 고정** — UTC→KST 변환의 historical 결정
- [ ] **Firebase KRW 마이크로단위 (×1e6) 처리** — 정착 시점·예외 케이스
- [ ] **테스터 제외 정책** — `user_test_group` 의 운영 방식 (수동/자동, 갱신 주기)

---

## P7 ★ 마이그레이션 Tier 분류 (후속 dbt 프로젝트 직접 인풋)

**목적**: 자산별 마이그 결정 — Tier 1 (그대로 이식) / Tier 2 (시맨틱 보존하며 재구현) / Tier 3 (재정의 + 합의 필요) / Tier 4 (Airflow 잔존)

### 작업 항목

- [ ] **Tier 분류 기준 합의** (사용자) — 4 Tier 의 정의·기준 합의
- [ ] **각 자산 Tier 분류** — P1~P6 결과 종합
  - 산출: `findings/70-migration-tiers/F-901-tier-table.md` (모든 자산 × Tier 매트릭스)
- [ ] **마이그 권장 순서** — Tier 1·2 내부에서 의존 leaf 부터 순서 제안
  - 산출: `findings/70-migration-tiers/F-902-recommended-order.md`
- [ ] **`findings/00-overview.md` 작성** — 시니어 온보딩 압축본 + dbt 마이그 권장 순서 종합

---

## 누적 발견 (Phase 진행 중 추가)

> 진행 중 발견되는 추가 과업·갭·SSOT 인계 후보를 여기에 누적합니다.
>
> **포맷**: `- [ ] {과업} — Phase: {P?} / 출처: {finding F-NNN 또는 BQ 쿼리·발화·문서}`

- [ ] **`hlb_report` 데이터셋 분류 정합성 점검** — Phase: P3 / 출처: F-001 §6
  - `hlb_report.pre_report_cohort_retention_visit` 가 hlb_pre_report 와 중복? `hlb_report.pre_report_user_revenue_info` 의 데이터셋 분류 모호 (이름 prefix vs 데이터셋 불일치)
- [ ] **`union_mart_user_key_actions2` 정체 확인** — Phase: P3 / 출처: F-001 §6
  - SQL 없이 BQ 에만 존재. v2 후보 / historical / deprecated 어느 쪽인가
- [ ] **orphan intermediate 4건 추적** — Phase: P3 / 출처: F-001 §6
  - `intermediate_ir_dashboard_metrics_fb`, `intermediate_randombox_metrics_fb`, `intermediate_user_recent_info`, `intermediate_v2_mart_funnel_fb` — SQL 위치가 다른 곳? deprecated?
- [x] **`hlb_report` 11건 SQL 없이 BQ 만 존재 추적** — Phase: P3 / 출처: F-001 §6 → F-004 (2026-04-30)
  - 결과: 1건 활성(`report_crm_optin_new`) + 10건 dead (모두 6개월~2.5년 미수정)
- [x] **`union_mart_user_key_actions2` 정체 확인 (1차)** — Phase: P3 / 출처: F-001 §6 → F-004 §5 (2026-04-30)
  - **★★★ 활성 (199GB, 2.65억 행, 2026-04-07 갱신) 인데 코드 흔적 0건** — 외부 노트북 / 수동 INSERT 추정. **사용자 확인 필요**
- [x] **orphan intermediate 4건 추적** — Phase: P3 / 출처: F-001 §6 → F-004 (2026-04-30)
  - `intermediate_ir_dashboard_metrics_fb` (활성 — queries.py), `intermediate_randombox_metrics_fb` (활성 — queries.py), `intermediate_user_recent_info` (storyplay 만), `intermediate_v2_mart_funnel_fb` (dead, 14GB, 2.5년 미수정)
- [x] **`union_mart_user_key_actions2` 정체 확인** — Phase: P3 / 출처: F-004 §5 (2026-04-30)
  - 결과: **유지 불필요 (사용자 확인)** → dead 16건에 합류. 199 GB 의 가장 큰 정리 대상.
- [ ] **dead/orphan 마트 16건 정리 정책 결정** — Phase: P7 / 출처: F-004 §6
  - 누적 **~239 GB** (`union_mart_user_key_actions2` 199 GB + `mart_v2_skill_funnel_fb_with_tag_info` 19.6 GB + `intermediate_v2_mart_funnel_fb` 14.1 GB + 기타). 본 프로젝트 종료 시점에 사용자 일괄 검토 후 결정.
- [ ] **mart_adhoc 일별 스냅샷 외부 컨슈머 확인** — Phase: P5 / 출처: F-004 §8
  - 854/848 일분 누적. Looker SQL 이 직접 참조하는지 확인 후 partitioned table 통합(MP-2) 가능 여부 판단
- [ ] **`C02HMRP42QM` Slack 채널 정체 확인** — Phase: P5 / 출처: F-003 §2
  - KPI noti 5번째 함수가 사용하는 채널인데 코멘트 없음. 어떤 팀·KPI 인지 확인
- [ ] **Looker Studio 메타 export 권한·방법 확인** — Phase: P5 / 출처: F-003 §1·§5
  - Looker SA 의 BQ 쿼리 이력 또는 Looker 자체 메타 export 가능 여부. 가능하면 별도 finding 카드로 자산-대시보드 매핑 확보 (MP-1 trade-off 정확도 ↑)
- [ ] **Hackle 대시보드 출력 확인** — Phase: P5 / 출처: F-003 §1
  - `hackle_dashboard_2023_func.py` 가 어디에 데이터 보내는지. dbt 마이그 영향 평가
- [ ] **GSheet sync 시트 매핑** — Phase: P5 / 출처: F-003 §3
  - `hellobot_sync_google_sheet.py` 가 어떤 GSheet ID·범위와 sync 하는지 코드 확인
- [ ] **★ 1차만 등록 이벤트 57건 처리 결정 (사용자)** — Phase: P5 / 출처: F-002 §1·§2
  - Option A (events_list 에서 정리) vs Option B (fb_2nd/se_2nd 추가). raw 발화량 있는 분석 의도 이벤트가 staging 못 도달 중
- [ ] **★ Dead whitelist 50건 정리 결정 (사용자)** — Phase: P7 / 출처: F-002 §3
  - chatbot_subscription·relation·collection·skill_reward·daily_fortune 카테고리 전체 deprecated 여부 검토
- [ ] **★ 미등록 고볼륨 이벤트 ~10건 분류 (사용자)** — Phase: P5 / 출처: F-002 §4
  - `show_item_in_home_section` (1.6M), `send_msg_by_user` (927K), `start_block` (527K) 등 — 의도된 미등록 vs 누락 구분

---

## SSOT 인계 (v2 로 인계된 과업)

> 본 프로젝트 발견 중 SSOT 갱신 가치가 있어 v2 §신규 과업으로 인계한 항목을 여기에 추적합니다.
>
> **OP-2 정책 (2026-05-01)**: 본 프로젝트는 카탈로그 직접 수정 X. v2 등록만 수행하고 v2 가 추후 일괄 처리.

### 2026-05-01 인계 — 12건 일괄 (P1 finding 결과)

[v2 tasks.md §dbt-migration-prep 인계](../20260422-data-infra-documentation-v2/tasks.md#dbt-migration-prep-인계--시스템-패턴-박스-신설--우선순위-높음) 에 등록 완료.

| # | 분류 | 항목 | 출처 | 우선순위 |
|---|---|---|---|---|
| 1 | 시스템 패턴 | `queries.py` destination 진실원천 박스 | F-004 §1 | ★★★ 높음 |
| 2 | 시스템 패턴 | 화이트리스트 3중 구조 실효 박스 + ISS-014 정량 보강 | F-002 §1·§2 | ★★★ 높음 |
| 3 | 시스템 패턴 | 외부 출력 (Slack KPI) 표 신설 `architecture.md §4-2` | F-003 §2 | ★★★ 높음 |
| 4 | 자산 정정 | `union_mart_user_key_actions` 위치 명료화 | F-001 §3 | 중간 |
| 5 | 자산 정정 | 계층별 인벤토리 정합성 표 신설 | F-001 §4 | 중간 |
| 6 | 자산 정정 | `staging_currency_rate_sheet` GSheet sync 명문화 | F-004 §4 | 중간 |
| 7 | 자산 정정 | `hlb_report` 데이터셋 분류 정합성 | F-001 §6 | 중간 |
| 8 | 이슈 | ISS-014 실측 검증 정량 추가 | F-002 §1 | 중간 |
| 9 | 이슈 | Dead whitelist 50건 deprecation 표기 | F-002 §3 | 중간 |
| 10 | 정책 | dbt 마이그 정책 MP-1·MP-2·MP-3 카탈로그 반영 (후속 dbt 시점) | 사용자 발화 2026-04-30 | 중간 |
| 11 | 정책 | 핵심 테이블 10선 우선순위 갱신 (다운스트림 카운트 기준) | F-001 §2 | 중간 |
| 12 | 갭 | mart_adhoc 일별 스냅샷 안티패턴 표기 | F-004 §8 | 낮음/중간 |

### 2026-05-01 추가 인계 — P2 baseline 작성 중 발견

| # | 분류 | 항목 | 출처 | 우선순위 |
|---|---|---|---|---|
| 13 | 카탈로그 stale | `tables/mart/mart_use_skill_se.md` 의 "파티션: *미지정*" → 실제 `DAY (event_date)` 로 정정 (`bq show` 실측) | F-101 §1 | 중간 |
| 14 | 카탈로그 missing | **`tables/intermediate/` 디렉토리 자체 미작성** — `hlb_intermediate.*` 25개 테이블 카드 부재. 다운스트림 2위 `intermediate_user_daily_info` 포함. F-102 가 1차 보강 후보로 활용 가능 | F-102 §0 | 높음 |
| 15 | 카탈로그 missing | `tables/mart/mart_skill_funnel_fb.md` 카드 부재 (v2 카드만 있음). 레거시 명시지만 다운스트림 23 (report 22 활성) — 카드 신설 + 레거시 표기 권장 | F-103 §0 | 중간 |
| 16 | 코드 결함 | `mart_skill_funnel_fb.sql:36` alias 오타 `pricegit` → `price` 정정 (스키마 영향 없으나 가독성) | F-103 §5-1 | 낮음 |
| 17 | 결정 대기 | **레거시 `mart_skill_funnel_fb` vs v2 `mart_v2_skill_funnel_fb`** Tier 결정 (A 폐기 / B 보존 / C 양쪽). v2 와의 시맨틱 차이 비교 finding 카드 가치 | F-103 §0·§7-1 | 중간 (P7 시점) |
| 18 | 카탈로그 missing | `tables/mart/mart_user_server.md` 카드 부재 (CRM 본진 자산) | F-104 §1 | 중간 |
| 19 | F-004 정정 | `mart_user_server_types_list` 는 dead 가 아닌 **활성 dimension** (mart_user_server.sql 의 cross join 의존). F-004 §6 에 반영 완료 | F-104 §4-3 | 처리 완료 (본 프로젝트 내) |
| 20 | 카탈로그 missing | **`tables/staging/` 디렉토리 자체 미작성** — `hlb_staging.*` 17개 테이블 카드 부재. 메뉴 마스터 dimension `staging_fixed_menu_copy` 포함 | F-105 §0·§1 | 높음 |
| 21 | 외부 의존 갭 | **서버 `server_rdb.snapshot_fixed_menu.create_at` 컬럼 누락** — 본 마트 SQL 이 `fixed_menu` 와 LEFT JOIN 으로 보강 (서버팀 협의 후 단순화 가능) | F-105 §4-2 | 중간 (P5 외부 확인) |
| 22 | 카탈로그 stale | `tables/mart_integrated/union_mart_user_key_actions.md` "파티션: *미지정*" → 실제 `DAY (event_date)` 로 정정 (F-101 과 동일 패턴) | F-106 §1 | 중간 |
| 23 | 카탈로그 stale | 동 카드 "~150 컬럼" → 실측 **131** 로 정정 | F-106 §1 | 낮음 |

### 2026-05-06 추가 인계 — 운영 환경 갭 (90-next-actions §6)

[90-next-actions.md §6](./findings/90-next-actions.md#6-v2-인계-추가-항목--2431-8건) 인계 — **데이터 팀이 일하는 환경 (본질 목표)** 직결. v2 §dbt-migration-prep 인계 — 운영 환경 구축 섹션에 등록 완료.

| # | 분류 | 항목 | 출처 | 우선순위 |
|---|---|---|---|---|
| 24 | 데이터 자산 | F-001 raw TSV → `catalog/data/` 또는 `mart-catalog.md` 표 임베드 (분기 재계산) | F-001 | 중간 |
| 25 | 데이터 자산 | F-002 raw CSV (5개) → `catalog/data/` 또는 `event-catalog.md` 임베드 (분기 재계산) | F-002 | 중간 |
| 26 | cross-link | `infra-map.md §과거 분석 산출` 섹션 신설 (prep 17 카드 진입점) | 90-next-actions §6 | 중간 |
| 27 | **신규 SSOT** | **`catalog/domain-glossary.md` 신규** — 비즈 개념 → 자산 매핑 사전 | 두 예시 시뮬레이션 막힘 | **★★★ 높음 → 2026-05-06 빈 골격 작성 완료 (v2)** |
| 28 | **신규 recipe** | **`catalog/recipes/data-request-handling.md` 신규** — 요청 처리 워크플로우 (+ `request-log.md` 신규) | 두 예시 시뮬레이션 막힘 | **★★★ 높음 → 2026-05-06 작성 완료 (v2)** |
| 29 | 신규 recipe | `catalog/recipes/add-new-metric.md` 신규 (28 §C 작성 중 자연 발생 시) | readme.md placeholder | 중간 |
| 30 | 신규 recipe | `catalog/recipes/add-new-mart.md` 신규 (28 §D 작성 중 자연 발생 시) | readme.md placeholder | 중간 |
| 31 | recipe 보강 | `add-new-event.md` 가 28 운영 워크플로우와 양방향 cross-link 보강 | 28 작성 완료 후 | 낮음 |

---

## 외부 확인 필요

> 사용자·외부 시스템·다른 팀 확인이 필요한 항목.

*아직 없음*
