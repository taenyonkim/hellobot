# dbt 마이그레이션 As-Is 분석 (Pre-work)

## 배경

HelloBot 데이터 파이프라인은 `common-data-airflow` (Airflow + BigQuery) 위에서 5계층(staging → intermediate → mart → mart_integrated → report) 으로 운영되고 있다. 카탈로그(SSOT) 1·2차 작업으로 핵심 자산은 문서화되어 있으나, **자산별 사용 빈도·시맨틱 baseline·SQL 레벨 의존 그래프**는 아직 흩어져 있어 dbt 재구축 프로젝트의 우선순위·범위 결정이 어렵다.

본 프로젝트는 후속 dbt 마이그레이션 프로젝트의 **인풋(As-Is 베이스라인)** 을 만드는 사전 작업이다.

## 목표

후속 dbt 재구축 프로젝트가 시작될 때 다음을 즉시 사용 가능하도록 준비한다:

1. **무엇을 옮길지** — 자산별 사용 빈도 → 마이그 우선순위
2. **어떻게 보존할지** — 자산별 시맨틱 baseline (그레인·NULL 의미·암묵 가정) → 재정의 시 align 기준
3. **무엇을 안 옮길지** — 외부 의존(Firebase 직접 export·GSheet sync·Braze 등)·dbt 비대상 영역
4. **마이그레이션 Tier 분류표** — Tier 1 (그대로 이식) / Tier 2 (시맨틱 보존하며 재구현) / Tier 3 (재정의 + 합의 필요) / Tier 4 (Airflow 잔존)
5. **정리 대상 목록** (MP-3) — 전체 인벤토리 + 참조 레벨 분석 결과로 **불필요 자산 식별** → 사용자 검토 → 마이그 비대상 결정. 정리 후 남은 자산만 Tier 분류로 진입.

## 마이그 정책 (★ 2026-04-30 사용자 확정)

본 프로젝트의 분석은 다음 정책을 전제로 진행한다. 후속 dbt 프로젝트도 같은 전제.

| # | 정책 | 의미 |
|---|---|---|
| **MP-1** | **외부 인터페이스 보존은 권장이지만 절대 제약은 아니다** | 마트 스키마·이름 호환을 유지하면 기존 Looker·ad-hoc 분석이 그대로 살지만, 보존 부담이 너무 크면 **dbt 로 새 마트를 만들고 그에 맞춰 대시보드를 새로 구축하는 옵션**도 가능. 즉 "보존 비용 vs 재구축 비용" 의 trade-off 결정. |
| **MP-2** | **최종 마트 스키마는 가급적 유지하되, 더 나은 구조가 있으면 변경 가능** | naming·컬럼 구조의 개선이 가치 있으면 변경 채택. baseline 카드는 "현재 스키마" 와 "개선 제안" 두 축으로 작성. |
| **MP-3** | **분석 결과로 정리 대상(불필요 자산)을 식별 → 마이그 대상에서 제외** | 전체 테이블 인벤토리 + 참조 레벨 + 활성 검증 결과 → 사용자 검토 후 정리 대상 결정. dbt 마이그 prep 의 산출물은 (a) 마이그 Tier 분류 + (b) 정리 대상 목록. 정리 후 남은 자산만 마이그 후보. |

**finding 카드 작성 시 적용**:
- 시맨틱 baseline (P2) 카드는 "현재 정의" + "개선 후보" 두 섹션으로
- Tier 분류 (P7) 시 **Tier 2 = "보존" 단일 의미가 아니라 "보존 vs 새로 짓기"** 의 결정 단위
- "보존 강제" 표현 사용 금지 — 항상 "보존 권장 / 부담 대비 가치 평가" 톤

## 운영 모드

- **연구·문서화 위주** — 코드 변경 최소화. **OP-1 적용**: 본 프로젝트 자체는 직접 코드·SSOT 수정 X, 백로그/이슈 등록만.
- **누적 finding 카드** — 발견사항을 `findings/` 하위에 카드 단위로 누적, 후속 세션이 이어받기 쉬운 구조.
- **Phase 별 진행** — P1~P7. ★ 표시 (P1·P2·P7) 은 dbt 인풋 직결, 우선 진행.

## 운영 정책 (★ 2026-05-01 사용자 확정)

| # | 정책 | 의미 |
|---|---|---|
| **OP-1** | **1차 목표는 코드 수정 없이 인프라 디테일 정확 파악** | 본 프로젝트는 분석·문서화 전용. 발견하는 개선점·룰·갭은 **백로그(tasks.md) 또는 이슈로 등록만** 하고, 실제 작업은 별도 프로젝트(v2 / 후속 dbt 마이그) 에서 처리 |
| **OP-2** | **SSOT 인계는 v2 §신규 과업 등록만** | 본 프로젝트는 카탈로그 직접 수정·PR 금지. v2 가 추후 일괄 처리 (C-1 선택, 2026-05-01) |
| **OP-3** | **카탈로그 갱신 프로토콜의 적용 방식** | 트리거 발생 시 (1) 본 프로젝트 finding 카드에 기록 + (2) v2 tasks.md §신규 과업으로 인계 + (3) 본 프로젝트 tasks.md SSOT 인계 섹션 추적. 직접 카탈로그 파일 수정 단계는 생략 |

## 범위

- **포함**
  - HelloBot 영역 (`hlb_*` 데이터셋, `hlb_dags/`, `scripts/hellobot/`)
  - As-Is 분석 + dbt 마이그 우선순위·시맨틱 baseline·Tier 분류
  - 코드만으로는 알 수 없는 운영 룰·암묵 가정·historical 결정 수집
- **제외**
  - 다른 서비스 영역 (`stp_dags`/StoryPlay, `btw_dags`/Between, `tf_dags`/ThingsFlow)
  - 실제 dbt 모델 작성 (후속 프로젝트)
  - 데이터 파이프라인 코드 변경 (별도 개선 프로젝트)

## 관련 프로젝트

| 프로젝트 | 관계 |
|---|---|
| [data-infra-documentation](../20260422-data-infra-documentation/) | 1차 카탈로그 구축 (완료) — SSOT 시드 |
| [data-infra-documentation-v2](../20260422-data-infra-documentation-v2/) | 카탈로그 점진 보강 (진행중) — **본 프로젝트의 발견 중 SSOT 가치 항목은 v2 §신규 과업으로 인계** |
| (후속) `dbt-migration` | 본 프로젝트의 산출물(Tier 분류·시맨틱 baseline)을 입력으로 사용 |

```
본 프로젝트 finding
   ├─ 카탈로그 SSOT 가치 (시맨틱 정의·운영 룰 명문화) → v2 §신규 과업 + SSOT 갱신
   ├─ dbt 마이그 직접 인풋 (Tier 분류·의존 그래프·baseline) → findings/ 보존 → 후속 dbt 프로젝트 인풋
   └─ 둘 다 (예: 그레인·NULL 의미 명문화) → 양쪽 반영
```

## 영향 범위

| 파트 | 영향 | 설명 |
|------|------|------|
| 기획 | 보조 | 지표 정의·합의 필요 시 사용자 협의 |
| 서버 | X | |
| iOS | X | |
| Android | X | |
| 웹 | X | |
| 스튜디오 | X | |
| 데이터 | O | `/dev-data` 주도 |
| QA | X | |

## 산출물 위치

- **본 프로젝트 (As-Is 분석)**: `findings/` — 카드 단위 누적 (Phase 별 폴더, 중요도 메타데이터)
- **카탈로그 SSOT 갱신**: `common-data-airflow/docs/hellobot-data/catalog/` (v2 의 §신규 과업으로 인계 후 갱신)
- **후속 dbt 프로젝트 인풋**: `findings/70-migration-tiers/` (Tier 1~4 분류표)
- **워크트리**: SSOT 갱신 발생 시점에만 생성 (상시 워크트리 없음)

## 문서 목록

| 문서 | 설명 |
|------|------|
| [status.md](./status.md) | Phase 진행 상태 |
| [tasks.md](./tasks.md) | Phase 별 과업 + 누적 발견 과업 |
| [findings/README.md](./findings/README.md) | finding 카드 인덱스 + 중요도/Tier 가이드 |
| [findings/00-overview.md](./findings/00-overview.md) | 전체 그림 (P7 완료 시점에 작성, As-Is 시니어 온보딩 압축본 + dbt 마이그 권장 순서) |

## Phase 개요

| Phase | 영역 | 산출 산출 폴더 | dbt 인풋 |
|---|---|---|---|
| **P1** ★ | 사용 빈도 인벤토리 | [10-usage-frequency](./findings/10-usage-frequency/) | 마이그 우선순위 |
| **P2** ★ | 자산 시맨틱 baseline | [20-asset-semantics](./findings/20-asset-semantics/) | 재정의 시 align 기준 |
| P3 | DAG → SQL → 테이블 의존 | [30-lineage](./findings/30-lineage/) | 마이그 순서 (leaf → root) |
| P4 | 이벤트 → staging 변환 룰 | [40-staging-transforms](./findings/40-staging-transforms/) | dbt source/staging 청사진 |
| P5 | 외부 의존 (dbt 비대상) | [50-external-deps](./findings/50-external-deps/) | dbt vs Airflow 잔존 분기 |
| P6 | Historical 결정·암묵 룰 | [60-historical](./findings/60-historical/) | 재정의 위험 회피 |
| **P7** ★ | 마이그레이션 Tier 분류 | [70-migration-tiers](./findings/70-migration-tiers/) | **후속 dbt 프로젝트 직접 인풋** |

진행 순서: **P1 → P2 → (P3~P6 필요한 만큼 보강) → P7** (계획. 진행 중 조정 가능)
