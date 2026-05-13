# F-901 — dbt 마이그레이션 Tier 분류 매트릭스 (★ 후속 dbt 프로젝트 직접 인풋)

| 항목 | 값 |
|---|---|
| Phase | P7 |
| 중요도 | ★★★ — 후속 dbt 마이그 프로젝트의 마스터 인풋 |
| 상태 | 확정 (P1 + P2 종합) — 일부 자산은 사용자 결정 대기 |
| 작성일 | 2026-05-01 |
| 출처 | F-001~F-004 (P1) + F-101~F-106, F-201~F-204, F-301 (P2) 종합 |

## 0. Tier 정의 (재확인)

| Tier | 정의 | dbt 후속 프로젝트 처리 |
|---|---|---|
| **Tier 1** | 시맨틱 명확, 의존 단순 | **그대로 dbt 모델로 이식** (1:1, 스키마·이름 동일) |
| **Tier 2** | 시맨틱 보존하며 재구현 | dbt naming + tests + 표준 패턴. baseline 카드의 "보존 필수" 따름 |
| **Tier 3** | 재정의 + 합의 필요 | **합의 후 신규 정의로 마이그** — 본 프로젝트가 합의 항목 식별만, 합의는 후속 |
| **Tier 4** | dbt 비대상 | dbt 안 옮김. Airflow 잔존 (외부 input·alarm), source 등록만, 또는 정리 (MP-3) |

> [MP-1](../../../readme.md#마이그-정책--2026-04-30-사용자-확정) 적용: Tier 1·2 의 "보존" 은 권장이지 절대 제약이 아님 — 부담이 가치보다 크면 새로 짓는 옵션도 가능. P7 의 분류는 **현재 상태 + dbt 표준 패턴 align 가능성** 기준.

---

## 1. 마트 자산 Tier 분류 (★ 본진)

### Tier 1 — 그대로 이식 (시맨틱 명확, 의존 단순)

| 자산 | 다운스트림 | 컬럼 | 크기 | 핵심 |
|---|---|---|---|---|
| `hlb_intermediate.intermediate_user_daily_info` (F-102) | 26 | 26 | 11 GB | DAU 본진, UNION+ROW_NUMBER 표준 |
| `hlb_staging.staging_fixed_menu_copy` (F-105) | 14 | 50 | 13 MB | 메뉴 마스터 (RDS 스냅샷) |

→ **2건**. dbt 모델로 직접 SQL 이식. dbt config: `materialized='incremental'` + `partition_by=event_date`.

### Tier 2 — 보존하며 재구현 (의존 복잡 + 외부 인터페이스 의존)

| 자산 | 다운스트림 | KPI 알림 직접 의존? | 보존 강도 | MP-2 적용 권장 |
|---|---|---|---|---|
| `hlb_mart.mart_use_skill_se` (F-101) | 47 | ★ | ★★★ | KRW_PER_HEART dbt var, pay_under_750 var |
| `hlb_mart_integrated.union_mart_user_key_actions` (F-106) | 2(내부) + 외부 다수 | ★ LTV | ★★★ | 자기참조 → `{{ this }}`, GSheet → seed |
| `hlb_mart.mart_user_server` (F-104) | 17 | (간접) | ★★ | 파티션 추가 (created_at), types_list dbt seed |

→ **3건**. dbt 표준 패턴 적용 + 시맨틱 보존. baseline 카드의 §6-3 (보존 필수) 따름.

### Tier 3 — 재정의 + 합의 필요 (사용자 결정 대기)

| 자산 | 결정 항목 | 옵션 |
|---|---|---|
| `hlb_mart.mart_skill_funnel_fb` (F-103, **레거시**) | 레거시 vs v2 처리 | A) 레거시 폐기 + v2 만 → report 22 SQL 재작성 / B) 보존 / C) 양쪽 유지 |

→ **1건**. v2 (`mart_v2_skill_funnel_fb`) 와의 시맨틱 차이 비교 후 결정. 후속 dbt 프로젝트 시작 시점에 합의.

### Tier 4 — dbt 비대상 (Airflow 잔존 또는 정리)

본 6 마트 baseline 안에서는 Tier 4 자산 없음 (모두 활성). Tier 4 자산은 [F-903 정리 대상 종합](./F-903-cleanup-targets.md) 참조.

### 마트 영역 Tier 1 차 분류 종합 (P1·P2 baseline 작성 6건)

```
Tier 1: 2 (F-102, F-105)
Tier 2: 3 (F-101, F-104, F-106)
Tier 3: 1 (F-103 레거시 결정)
```

→ **본 6 마트는 모두 활성 마이그 대상**. Tier 4 (정리·잔존) 마트는 별도 (F-903).

### F-001 Top 5 외 마트 (130+ long-tail)

[F-001 §2 Top 30 + F-001-data-mart-downstream.tsv](../../10-usage-frequency/F-001-mart-downstream-map.md) 의 다운스트림 카운트 기반:

| 그룹 | 처리 권장 |
|---|---|
| 다운스트림 6~30위 (~25 마트) | **Tier 1·2** — baseline 카드 추가 작성 시 결정. 현 시점 dbt 마이그는 P1 다운스트림 카운트 + 카탈로그 기반 진행 |
| 다운스트림 1~3위 (40+ 마트) | Tier 1 (단순 이식) — leaf 자산 |
| 다운스트림 0 + 외부 컨슈머 (mart_adhoc 일별 스냅샷 등) | Tier 1 + MP-2 (partitioned table 통합 권장) |
| 다운스트림 0 + 외부 컨슈머 없음 | **Tier 4 정리** ([F-903](./F-903-cleanup-targets.md)) |

→ **장기 보강 영역** — 후속 dbt 프로젝트가 진행하며 baseline 카드 확장 가능.

---

## 2. 이벤트 자산 Tier 분류

### Tier 1·2 — 활성 + 보존

| 그룹 | 이벤트 | Tier |
|---|---|---|
| **결제 본진** | `enter_skill` (Server, F-201), `pay_for_contents` (F-202), `pay_under_750` (파생) | Tier 2 (보존 — KRW_PER_HEART dbt var) |
| **Firebase 신규 스킬 온보딩** (F-203) | `enter_skill` (Firebase), `open_skill_description`, `view_new_*` (5), `touch_new_preview_*` (2), `view_coin_screen` | Tier 1 |

→ Firebase 9 + Server 활성 3 = **12 활성 이벤트**

### Tier 3 — 결정 대기

| 이벤트 | 결정 항목 |
|---|---|
| `skill_feedback_complete` (F-204) | 화이트리스트 등록 여부 (24K/주, 분석 가치 있음) |
| 1차만 등록 57건 (F-002 §2) | 정리 (events_list 제거) vs 2차 추가 (활성화) |

### Tier 4 — 정리 (MP-3) 또는 Airflow 잔존

| 그룹 | 이벤트 | 처리 |
|---|---|---|
| **운영성 Server 이벤트** (F-204) | `use_attribute` (1.58M/주), `update_attribute`, `receive_user_message` | **Tier 4 Airflow 잔존** — dbt source 등록만, 분석 변환 X |
| **Dead 결제 변종** (F-202) | `pay_for_package`, `pay_for_collection`, `pay_for_coaching_program`, `pay_for_chatbot_subscription` | Tier 4 정리 (화이트리스트 deprecation 표기) |
| **Dead whitelist 50건** (F-002 §3) | chatbot_subscription·relation·collection·skill_reward·daily_fortune 카테고리 | Tier 4 정리 |

---

## 3. 지표 자산 Tier 분류 (F-301 종합)

### Tier 1·2 — 활성 + 보존
- 1-1 매출, 1-2 사용자, 1-3 결제자, 1-4 ARPPU/LTV, 1-6 코호트 리텐션, 1-8 RFM, 1-9 콘텐츠·스킬, 1-10 AI 챗봇 — 약 40+ 지표

### Tier 3 — 합의 필요 (★ 사용자 결정)
| 합의 항목 | F-301 §4 |
|---|---|
| 매출 산식 통일 (`revenue_krw` 컬럼 재사용 vs 재계산) | §4-1 |
| DAU 정의 (`union` vs `daily_info` 분기) | §4-2 |
| ARPPU 분모 (기간 결제자 vs 누적) | §4-3 |

### Tier 4 — Airflow 잔존
- 1-5 광고/ROAS — GSheet sync 의존 (dbt source 등록만)
- 1-7 CRM/푸시 — Braze export 의존 (dbt source 등록만)

---

## 4. DAG 자산 Tier 분류

| 그룹 | 처리 |
|---|---|
| `hellobot_datamart_*_pipeline` (5+ DAG, staging→intermediate→mart→pre_report→report 체인) | **Tier 4 (Airflow 잔존)** — dbt 가 마트 변환 담당, DAG 는 dbt 트리거로 단순화 |
| `hellobot_sync_google_sheet`, `hellobot_snapshot_to_bigquery` | Tier 4 (input ETL — dbt 비대상) |
| `hlb_kpi_noti` (Slack KPI 알림) | Tier 4 (외부 출력 — dbt 비대상). 단 SQL 부분 dbt-alerts 패턴 옵션 (선택) |
| `hellobot_japan_*` (8 DAG) | 본 프로젝트 범위 외 (JP 파이프라인) |

→ 모든 DAG 는 **Tier 4 Airflow 잔존**. dbt 마이그 후 DAG 는 dbt 모델 트리거로 단순화.

---

## 5. 외부 의존 자산 Tier 분류

[F-003 외부 인터페이스 매트릭스](../../10-usage-frequency/F-003-external-interfaces.md) 의 입력 5종 + 출력 4종 모두 **Tier 4 (dbt 비대상)**:

### 입력 (dbt source 등록만)
- Firebase GA4 (`analytics_164027297.events_*`)
- Server events (`analytics_164027297.server_events`)
- RDS Snapshot (`server_rdb.snapshot_*`)
- GSheet sync (`google_sheet_sync.*`)
- Braze export (`hellobot_braze.*`)

### 출력 (보존 필수, dbt 외 잔존)
- Slack 실패 알림 (모든 DAG `on_failure_callback`)
- Slack KPI 알림 (`hlb_kpi_noti.py` 5 함수 → 3 채널)
- Notion KPI (tf_report 경유, hellobot 영역 외)
- Hackle 대시보드 (`hackle_dashboard_2023`)
- Looker Studio (메타 부재 — F-003 §1)

---

## 6. 종합 Tier 분류 표 (한눈)

| Tier | 마트 | 이벤트 | 지표 | DAG | 외부 |
|---|---|---|---|---|---|
| **Tier 1** (그대로 이식) | F-102, F-105 + long-tail leaf 다수 | 9 Firebase 신규 스킬 온보딩 (F-203) | 사용자, 결제자 (정의 명확) | - | - |
| **Tier 2** (보존하며 재구현) | F-101, F-104, F-106 | enter_skill (양쪽), pay_for_contents, pay_under_750 | 매출, ARPPU/LTV, RFM, 코호트, 콘텐츠 | - | - |
| **Tier 3** (재정의 + 합의) | F-103 (레거시) | skill_feedback_complete, 1차만 등록 57건 | 매출 산식 통일, DAU 분기, ARPPU 분모 | - | - |
| **Tier 4** (Airflow 잔존 + 정리) | [F-903 정리 대상](./F-903-cleanup-targets.md) | 운영성 Server 4건, dead 50+, dead 결제 4건 | 광고/ROAS (GSheet), CRM/푸시 (Braze) | 모든 DAG | 입력 5 + 출력 4 |

## 7. 핵심 합의 항목 (Tier 3, 사용자 결정 필요)

후속 dbt 마이그 프로젝트 시작 시점에 다음 4건 합의 필요:

| # | 항목 | 영향 | 출처 |
|---|---|---|---|
| 1 | **MP-1 trade-off** for `union_mart_user_key_actions` (F-106) — 보존 vs 새 마트 + 대시보드 새로 짓기 | dbt 마이그의 가장 큰 결정 | F-106 §6-5 |
| 2 | **레거시 vs v2** (F-103) — `mart_skill_funnel_fb` 폐기 vs 보존 | report 22 SQL 영향 | F-103 §0·§7-1 |
| 3 | **지표 합의 3건** — 매출 산식 통일 / DAU 분기 / ARPPU 분모 | KPI 알림 + Looker 영향 | F-301 §4 |
| 4 | **정리 대상 16+50+57** — MP-3 처리 시점 (마이그 전 vs 후) | 마이그 단순화 vs 위험 | F-903 |

## 8. 다음 단계

- [F-902 마이그 권장 순서](./F-902-recommended-migration-order.md) — Tier 1·2 의 leaf → root 순서
- [F-903 정리 대상 종합](./F-903-cleanup-targets.md) — Tier 4 정리 대상 단일 표
- [findings/00-overview.md](../00-overview.md) — 본 프로젝트 종합 + 시니어 1일차 압축본
