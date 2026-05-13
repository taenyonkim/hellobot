# 00 — As-Is 종합 + dbt 마이그 권장 순서 (시니어 1일차 압축본)

> **언제 읽나**: HelloBot 데이터 인프라에 처음 들어왔거나, 후속 dbt 마이그 프로젝트를 시작할 때.
>
> **목적**: 본 프로젝트 (`20260430-dbt-migration-prep`) 의 16 finding 카드를 **3분~10분 안에 종합 파악**.

## 1. 1줄 요약

```
HelloBot 데이터 인프라 = Airflow + BigQuery 5계층 + queries.py destination 패턴
                       + 화이트리스트 3중 게이트 (1차 events_list 비활성)
                       + revenue_krw 매출 표준 (KRW_PER_HEART = 150)
                       + Slack KPI 알림 + Looker (메타 부재)
```

## 2. 5계층 데이터 파이프라인 (As-Is)

```
[Layer 0] sources                                              (외부 input — dbt 비대상)
  ├─ Firebase GA4    analytics_164027297.events_*
  ├─ Server events   analytics_164027297.server_events
  ├─ RDS Snapshot    server_rdb.snapshot_*  (AWS Glue 일일)
  ├─ GSheet          google_sheet_sync.*    (마케팅 ROAS·환율·태그)
  └─ Braze export    hellobot_braze.*       (CRM 분석 input)
        ↓ (테스터 제외 + events_list 게이트 + KST 변환 + user_id_processed)

[Layer 1] hlb_staging         (17 테이블)
[Layer 2] hlb_intermediate    (25 테이블)
[Layer 3] hlb_mart            (24 테이블)
[Layer 4] hlb_mart_integrated (7), hlb_pre_report (5), hlb_mart_adhoc (10 + 일별 스냅샷)
[Layer 5] hlb_report (64), tf_report (2)                       (외부 output)
        ↓
   ├─ Slack 알림: hlb_kpi_noti (5 함수 → 3 채널)               #div_chatbot_biz, #team_ops-maximize
   ├─ Looker Studio (메타 부재)
   ├─ Notion KPI (tf_report 경유, hellobot 영역 외)
   └─ Hackle 대시보드 (1건)
```

→ 총 154 테이블 (BQ 데이터셋 기준).

## 3. 핵심 자산 Top 10 (사용 빈도 + 매출 영향)

| # | 자산 | 다운스트림 | 본진 | dbt Tier |
|---|---|---|---|---|
| 1 | `hlb_mart.mart_use_skill_se` | **47** | 매출/스킬 사용 | Tier 2 |
| 2 | `hlb_intermediate.intermediate_user_daily_info` | 26 | DAU | Tier 1 |
| 3 | `hlb_mart.mart_skill_funnel_fb` (★ **레거시**) | 23 | 스킬 퍼널 v1 | **Tier 3 결정** |
| 4 | `hlb_mart.mart_user_server` | 17 | CRM 본진 | Tier 2 + 파티션 추가 |
| 5 | `hlb_staging.staging_fixed_menu_copy` | 14 | 메뉴 마스터 | Tier 1 |
| 6 | `hlb_mart_integrated.union_mart_user_key_actions` | 2 (내부) + 외부 多 | **외부 분석 진입점** | **Tier 2 (★ MP-1 결정)** |
| 7 | `hlb_mart.mart_purchase_fb` | 8 (39회) | Firebase 인앱 결제 | Tier 2 |
| 8 | `hlb_mart.mart_user_daily_info` | 11 | DAU mart 레이어 | Tier 2 |
| 9 | `hlb_mart.mart_leave_fb` | 10 | 이탈 분석 | Tier 1·2 |
| 10 | `hlb_mart.mart_fixed_menu_server` | 9 | 메뉴 마스터 (mart) | Tier 2 |

## 4. 결정적 컨벤션 (꼭 알아야 할 것)

| # | 룰 | 출처 |
|---|---|---|
| 1 | **`KRW_PER_HEART = 150`** — 1하트 = 150 KRW (코드 7곳 중복, dbt var 통합 권장) | F-101 §4-1, F-301 §3-1 |
| 2 | **`revenue_krw` 매출 표준** — 유료 하트 + 현금, 보너스 제외 | F-101 §4-1 |
| 3 | **`user_id_processed`** — APP 19/4+ + WEB 22/12+ 이후 user_id, 그 전 user_pseudo_id | F-102 §3 |
| 4 | **시간대 = Asia/Seoul (KST)** — staging 에서 UTC→KST | F-101 §3 |
| 5 | **주차 기준 = MONDAY** | F-102 §4-3 |
| 6 | **env 필터** — Server events 는 `env IN ('production','prod')` 만 | catalog event-catalog.md §2-3 |
| 7 | **테스터 제외** — `server_rdb.user_test_group` 자동 제외 | catalog event-catalog.md §2-2 |
| 8 | **★ `queries.py` 가 destination 진실원천** — SQL 파일은 SELECT 본문 / `{layer}/queries.py` 가 INSERT/CREATE | F-004 §1 |
| 9 | **★ 화이트리스트 1차 비활성** — events_list (1차) 단독 등록만으로는 staging 도달 못함, 2차 fb_2nd / se_2nd 가 실제 게이트 | F-002 §1 |
| 10 | **ID/이름 페어 규칙** — `*_seq` 발송 시 `*_name` 도 함께 발송 | catalog event-catalog.md §5 |

## 5. 알려진 갭·암묵 룰

### 5-1. 카탈로그 stale (2026-05-01 기준)
- 파티션 표기 stale 2건 (F-101 mart_use_skill_se, F-106 union_mart_user_key_actions — 둘 다 실제는 `DAY (event_date)`)
- 컬럼 수 stale 1건 (F-106 — "~150" 실제 131)
- `tables/intermediate/` 디렉토리 자체 missing (F-102)
- `tables/staging/` 디렉토리 자체 missing (F-105)
- `mart_skill_funnel_fb` 카드 missing (레거시이지만 23 다운스트림 활성)
- `mart_user_server` 카드 missing

### 5-2. 코드 결함
- `mart_skill_funnel_fb.sql:36` alias 오타 `pricegit` (스키마는 정상이지만 가독성)

### 5-3. 외부 의존 갭
- `server_rdb.snapshot_fixed_menu.create_at` 컬럼 누락 — `fixed_menu` 와 LEFT JOIN 으로 보강 (서버팀 협의 후 단순화)
- GSheet 의존 다수 (광고/ROAS, 환율, 스킬 태그) — 운영자 수동 갱신, freshness 알림 부재

### 5-4. Historical 미명문화 (P6 미진행)
- `KRW_PER_HEART = 150` 의 출처
- `test_group` A/B 가격 실험의 historical (`mart_user_server.test_group`)
- `chatbot_seq != "0"` 필터 (F-103 §4-2)

## 6. dbt 마이그 권장 순서 (5 Wave, 약 4~6개월)

[F-902 마이그 권장 순서](./70-migration-tiers/F-902-recommended-migration-order.md) 상세:

```
Wave 1: 인프라 셋업 + sources                                      (1~2주)
Wave 2: Layer 1·2 — staging + intermediate                         (3~4주)
Wave 3: Layer 3 — mart  ★ KPI 알림 영향 시작 (이중 운영 필수)      (3~5주)
Wave 4: Layer 4 — mart_integrated + pre_report                      (4~6주)
        ★ MP-1 trade-off 결정 (union_mart_user_key_actions)
Wave 5: Layer 5 — report                                            (3~4주)
Post:  정리 (마트 15건 + dead whitelist 50건 + DAG 5건)            (1~2주)
```

→ Strangler Pattern (점진적, 이중 운영 + 결과 비교 PASS 후 컷오버).

## 7. 후속 dbt 프로젝트 시작 시 가장 먼저 합의할 항목

[F-901 §7](./70-migration-tiers/F-901-tier-classification.md#7-핵심-합의-항목-tier-3-사용자-결정-필요) 4건:

| # | 항목 | 영향 |
|---|---|---|
| 1 | **MP-1 trade-off** for `union_mart_user_key_actions` (F-106) — 보존 vs 새 마트 + 대시보드 새로 짓기 | dbt 마이그의 가장 큰 결정 |
| 2 | **레거시 vs v2** (F-103 mart_skill_funnel_fb) — 폐기 vs 보존 | report 22 SQL 영향 |
| 3 | **지표 합의 3건** — 매출 산식 통일 / DAU 분기 / ARPPU 분모 | KPI 알림 + Looker 영향 |
| 4 | **정리 대상 처리 시점** (마이그 전 / 후 / 점진) | 위험 vs 작업량 trade-off |

→ 이 4건 합의 + dbt 도구·환경 결정 후 마이그 시작.

## 8. dbt 비대상 (Tier 4) — Airflow 잔존

[F-903 정리 대상](./70-migration-tiers/F-903-cleanup-targets.md) + Airflow 잔존:

### Airflow 잔존 (정리 X)
- 모든 sources (Firebase / Server events / RDS / GSheet / Braze)
- Slack 실패 알림 (모든 DAG `on_failure_callback`)
- Slack KPI 알림 (`hlb_kpi_noti`)
- Sync DAG (`hellobot_sync_google_sheet`, `hellobot_snapshot_to_bigquery`)
- 운영성 Server 이벤트 raw (`use_attribute`, `update_attribute`, `receive_user_message`)

### 정리 대상 (~239 GB + 화이트리스트 100+)
- 마트 15건 (대용량 dead 4: union_mart_user_key_actions2 199 GB / mart_v2_skill_funnel_fb_with_tag_info 19.6 GB / intermediate_v2_mart_funnel_fb 14.1 GB / pre_report_cohort_retention_visit 5.2 GB)
- Dead whitelist 50건 (chatbot_subscription·relation·collection·skill_reward·daily_fortune)
- 1차만 등록 57건 (사용자 결정: 정리 vs 2차 추가)
- Dead 결제 변종 4건 (pay_for_package/collection/coaching_program/chatbot_subscription)

## 9. 본 프로젝트 산출물 인덱스

```
findings/
├── 00-overview.md                          (본 문서)
├── README.md                               (16 카드 인덱스 + 중요도 가이드)
├── 10-usage-frequency/  (P1 — 5)
│   ├── F-001 마트 다운스트림 카운트
│   ├── F-002 이벤트 사용 빈도 + 화이트리스트 정합성 ISS-014 검증
│   ├── F-003 외부 인터페이스 매트릭스
│   ├── F-004 Orphan/Dead 자산
│   └── P1-recap 회고
├── 20-asset-semantics/  (P2 — 11)
│   ├── marts/  (6 — F-101 ~ F-106)
│   ├── events/ (4 — F-201 ~ F-204)
│   └── metrics/ (1 — F-301 종합)
└── 70-migration-tiers/  (P7 — 3)
    ├── F-901 Tier 분류 매트릭스
    ├── F-902 마이그 권장 순서 (5 Wave)
    └── F-903 정리 대상 종합
```

총 **17 finding 카드** + 본 overview.

## 10. 본 프로젝트 SSOT 인계 (v2 — 23건)

본 프로젝트 발견 중 SSOT 갱신 가치가 있어 v2 (`20260422-data-infra-documentation-v2`) 의 §신규 과업으로 인계된 항목 23건. [tasks.md §SSOT 인계](../tasks.md#ssot-인계-v2-로-인계된-과업) 참조.

3 시스템 패턴 박스 (★★★) + 자산 정정 4 + 카탈로그 missing 4 + 코드 결함 1 + 정책 3 + 기타.

## 11. 다음 단계

1. **본 프로젝트 종료** (`/workspace 종료 dbt-migration-prep`)
2. **후속 dbt 마이그 프로젝트 시작** — `projects/20260???-dbt-migration/`
   - 1pager 작성 (도구 결정 + BQ 환경 + 마이그 범위·일정)
   - /analyze → readme/tasks
   - /architect → dbt 프로젝트 구조 + sources.yml + Wave 1 계획
   - /dev-data → Wave 2 부터 모델 작성

## 참조

- 본 프로젝트 readme: [../readme.md](../readme.md)
- 카탈로그 SSOT: `common-data-airflow/docs/hellobot-data/catalog/`
- 카탈로그 진입점: `infra-map.md` (3분 종합)
- dbt 마이그 정책: [readme §마이그 정책](../readme.md#마이그-정책--2026-04-30-사용자-확정) (MP-1·MP-2·MP-3)
- 본 프로젝트 운영 정책: [readme §운영 정책](../readme.md#운영-정책--2026-05-01-사용자-확정) (OP-1·OP-2·OP-3)
