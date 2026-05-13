# 90 — 다음 액션 인계 문서

> **언제 읽나**: 본 prep 종료 후 다음 세션을 시작할 때 가장 먼저 읽는 문서.
>
> **작성일**: 2026-05-06 (본 prep 종료 후 사용자 의도 명확화 대화의 종합)

본 문서는 본 prep 산출 + 마지막 4 turn 대화에서 **재정의된 사용자 의도** + **다음 액션 제안** 을 한 곳에 모은 인계 문서. 다음 세션은 본 문서로 시작.

---

## 1. 사용자 의도 — 재정의 (★ 가장 중요)

본 prep 진행 중 표면 목표 (dbt 마이그) 외에 **본질 목표** 가 명확해짐:

```
표면 목표: dbt 마이그레이션 (4~6개월, F-902 5 Wave)
   ↑
   └── 본질 목표: ★ 데이터 팀이 일하는 환경의 재현
        ├─ 일상 데이터 요청을 즉시 처리할 수 있는 운영 절차
        ├─ 도메인 개념 → 데이터 자산 매핑 (지식 기반)
        ├─ 요청 해석·자산 점검·갭 식별·액션 결정의 표준화
        └─ dbt 마이그는 이 환경의 한 산출물 (시맨틱 보존하며 재구축)
```

### 사용자 발화 (2026-05-05·06 핵심)

> "현재 헬로우봇의 데이터 파이프라인 현황을 구체적으로 파악하고, 현재의 데이터 인프라 작업을 하기위한 지식 기반을 구축하려는 목표"
>
> "데이터 팀원들이 하는 것처럼 그런 상황까지 파악하여 무엇을 해야할지를 찾고 최종적으로 요청받은 정보를 제공할 수 있는 상태를 만들고 싶어"

### 검증 사례 — 두 예시 요청

| 요청 | 즉시 처리 가능? | 막힘 |
|---|---|---|
| 월별 유저들의 평균 잔고 추이 | **불가** | "잔고" 도메인 개념 미정의, 신규 마트 절차 부재 |
| 충전 하트 상품별 재구매율 분석 | **부분적** | "재구매율" 정의 합의 부재, "충전 하트 상품" 분류 합의 부재 |

→ 두 요청 모두 본 prep 산출만으로는 "데이터 팀이 일하듯이" 처리 못 함.

---

## 2. 본 prep 의 산출 — 무엇을 했나

### 산출물 인벤토리

```
projects/20260430-dbt-migration-prep/
├── readme.md / status.md / tasks.md  (메타·종료 정보)
└── findings/
    ├── 00-overview.md                ← 시니어 1일차 압축본 + dbt 마이그 권장 순서
    ├── README.md                     ← 17 카드 인덱스
    ├── 10-usage-frequency/  (P1 — 5)
    │   ├── F-001 마트 다운스트림 카운트 (raw TSV 포함)
    │   ├── F-002 이벤트 사용 빈도 + 화이트리스트 정합성 (raw CSV 5개)
    │   ├── F-003 외부 인터페이스 매트릭스 (Slack KPI 채널 매핑)
    │   ├── F-004 Orphan/Dead 자산 16건
    │   └── P1-recap 회고
    ├── 20-asset-semantics/  (P2 — 11)
    │   ├── marts/   F-101 ~ F-106 (시맨틱 baseline 6)
    │   ├── events/  F-201 ~ F-204 (4 그룹)
    │   └── metrics/ F-301 (10 도메인 종합)
    ├── 70-migration-tiers/  (P7 — 3)
    │   ├── F-901 Tier 분류 매트릭스
    │   ├── F-902 마이그 권장 순서 (5 Wave)
    │   └── F-903 정리 대상 종합
    └── 90-next-actions.md            ← 본 문서
```

총 **17 finding 카드 + 본 인계 문서**.

### 본 prep 의 핵심 산출 가치

| 자산 | 지식 기반 가치 | dbt 마이그 가치 |
|---|---|---|
| F-001 (다운스트림) | 마트 변경 영향 추적 ★ | 마이그 우선순위 결정 ★ |
| F-002 (이벤트 빈도) | 이벤트 활성·정리 대상 식별 ★ | dbt source 등록 인풋 |
| F-003 (외부 인터페이스) | "변경 시 어디 깨지나" ★ | MP-1 trade-off 인풋 ★ |
| F-004 (정리 대상) | 사용 X 자산 즉시 식별 ★ | Tier 4 인풋 |
| F-101~F-106 (마트 baseline) | "이 마트가 답하는 질문" ★ | dbt 모델 작성 가이드 ★ |
| F-201~F-204 (이벤트) | 이벤트 활성 분류 | 이벤트 마이그 |
| F-301 (지표 종합) | 지표 정의 + KPI 알림 매핑 ★ | 지표 합의 인풋 |
| F-901·F-902·F-903 | (dbt 한정) | 후속 dbt 직접 인풋 ★ |
| 00-overview | 전체 진입 (★★★) | 후속 dbt 직접 진입 |

→ **17 카드 중 13~14 가 일반 지식 기반에도 가치** — 단, "운영 절차 명문화" 가 빠짐.

---

## 3. 갭 — 본 prep 으로 안 채워진 영역

### 운영 환경 갭 4건 (★ 본질 목표 직결)

1. **도메인 개념 사전 부재** — "잔고", "재구매율", "이탈" 같은 비즈 개념 → 자산 매핑 없음. 카탈로그 키워드 검색이 안 됨.
2. **요청 처리 표준 절차 부재** — 해석 → 점검 → 갭 식별 → 액션 의 명문화된 흐름 없음.
3. **`add-new-metric.md` recipe 부재** — 새 지표 합의·등록 절차. v2 백로그.
4. **`add-new-mart.md` recipe 부재** — 새 마트 추가 절차. v2 백로그.

### 카탈로그 SSOT 보강 갭 (v2 인계 23+ 건)

이미 본 prep tasks.md SSOT 인계 표 1~23 으로 등록됨. 추가로 본 인계 문서가 권장하는 24~31 (운영 환경 솔루션 통합):

| # | 항목 | 출처 |
|---|---|---|
| 24 | F-001 raw TSV → `catalog/data/mart-downstream-counts.tsv` 또는 `mart-catalog.md` 표 임베드 | 분기마다 재계산 권장 |
| 25 | F-002 raw CSV (5개) → `catalog/data/event-frequency-{date}.csv` 또는 event-catalog 임베드 | 동일 |
| 26 | `infra-map.md §과거 분석 산출` cross-link 섹션 | 본 prep finding cross-link |
| 27 | **★ `catalog/domain-glossary.md` 신규 작성** | 운영 환경 1차 진입 |
| 28 | **★ `catalog/recipes/data-request-handling.md` 신규 작성** | 요청 처리 워크플로우 |
| 29 | `catalog/recipes/add-new-metric.md` 신규 작성 | 새 정의 절차 (이미 v2 백로그) |
| 30 | `catalog/recipes/add-new-mart.md` 신규 작성 | 새 자산 절차 (이미 v2 백로그) |
| 31 | `catalog/recipes/add-new-event.md` 보강 (이미 작성됨, 운영 절차와 통합) | 워크플로우 통합 |

→ **27·28 이 핵심** — 사용자 의도 ("데이터 팀이 일하는 환경") 의 직접 산출.

---

## 4. 다음 두 트랙 — 작업 분기

```
본 prep 종료 (2026-05-01)
    ↓
다음 작업 분기
    ├── 트랙 A: dbt 마이그 후속 프로젝트
    │     - 별도 프로젝트: 20260???-dbt-migration
    │     - 1pager → /analyze → /architect → /dev-data (5 Wave)
    │     - F-902 마이그 권장 순서 그대로 사용
    │     - 4~6개월
    │
    └── 트랙 B: 데이터 팀 운영 환경 구축 (★ 본질 목표)
          - 별도 프로젝트 또는 v2 의 §신규 과업으로 처리
          - 도메인 글로사리 + 요청 처리 recipe + add-new-mart/metric recipe
          - 4~6시간 (집중 작업) 또는 점진적
```

---

## 5. 권장 순서 — Option I 또는 II

### Option I: 트랙 B 먼저, 그 후 트랙 A ★ 추천

```
[Step 1] 트랙 B 신속 셋업 (4~6시간 / 1~2 세션)
  - catalog/domain-glossary.md 신규 (도메인 개념 사전)
  - catalog/recipes/data-request-handling.md 신규 (요청 처리 워크플로우)
  - catalog/recipes/add-new-metric.md 신규 (새 정의)
  - catalog/recipes/add-new-mart.md 신규 (새 자산)
  - 두 예시 요청 (잔고 / 재구매율) 으로 절차 검증

[Step 2] 트랙 A 시작 (별도 프로젝트, 4~6개월)
  - 1pager 작성 (Trade off 4건 결정 포함)
  - /analyze → /architect → /dev-data Wave 1~5
```

**왜 추천?**
- 사용자 의도 ("데이터 팀이 일하는 환경") 이 dbt 마이그 보다 본질
- 글로사리·recipe 가 dbt 마이그 중에도 활용됨 (마이그 중 새 발견 → 글로사리·recipe 갱신)
- 4~6시간 투자로 일상 운영 능력 즉시 ↑
- 두 예시 요청을 즉시 처리 가능한 상태가 됨

### Option II: 트랙 A 와 병행

dbt 마이그 진행 중 발견되는 갭을 글로사리·recipe 에 점진적 반영. 시간 분산되지만 운영 환경의 즉시 가치는 늦어짐.

---

## 6. v2 인계 추가 항목 — 24~31 (8건)

[v2 tasks.md §dbt-migration-prep 인계](../../20260422-data-infra-documentation-v2/tasks.md#dbt-migration-prep-인계--시스템-패턴-박스-신설--우선순위-높음) 에 추가 등록 권장. 본 prep tasks.md SSOT 인계 표에도 동일 추가.

| # | 분류 | 항목 | 우선순위 | 비고 |
|---|---|---|---|---|
| 24 | 데이터 자산 | F-001 raw TSV → `catalog/data/` 또는 `mart-catalog.md` 표 임베드 | 중간 | 분기 재계산 |
| 25 | 데이터 자산 | F-002 raw CSV → `catalog/data/` 또는 `event-catalog.md` 임베드 | 중간 | 분기 재계산 |
| 26 | cross-link | `infra-map.md §과거 분석 산출` 섹션 신설 | 중간 | finding 접근성 |
| 27 | **신규 SSOT** | **`catalog/domain-glossary.md` 신규 작성** | **★★★ 높음** | 운영 환경 1차 진입 |
| 28 | **신규 recipe** | **`catalog/recipes/data-request-handling.md` 신규 작성** | **★★★ 높음** | 요청 처리 워크플로우 |
| 29 | 신규 recipe | `catalog/recipes/add-new-metric.md` 신규 작성 | 중간 | 이미 v2 백로그 |
| 30 | 신규 recipe | `catalog/recipes/add-new-mart.md` 신규 작성 | 중간 | 이미 v2 백로그 |
| 31 | recipe 보강 | `add-new-event.md` 가 운영 워크플로우 (28번) 와 cross-link 보강 | 낮음 | 이미 작성됨, 통합 |

→ **27·28 의 우선순위 ★★★** — 본질 목표 직결.

---

## 7. 다음 세션 시작 프롬프트 (★ 사용자가 그대로 입력)

다음 세션에서 사용자가 입력할 프롬프트 (택 1):

### 옵션 A: Option I 진행 (트랙 B 먼저, 추천)

```
/dev-data

본 세션에서 진행할 작업:
projects/20260430-dbt-migration-prep/findings/90-next-actions.md 의 §5 Option I 에 따라
트랙 B (데이터 팀 운영 환경 구축) 를 시작.

순서:
1. 본 인계 문서 (90-next-actions.md) 읽기
2. 카탈로그 SSOT 의 현재 상태 확인 (catalog/infra-map.md, recipes/, event-catalog.md, metric-dictionary.md)
3. v2 tasks.md 에 인계 항목 24~31 등록 (이전 답변에서 권장된 8건)
4. 작업 우선순위 합의:
   - 27 (domain-glossary.md) + 28 (data-request-handling.md) 가 핵심
   - 29·30 (add-new-metric/mart recipe) 은 28 와 동시 작성 효율적
5. 본 prep 의 두 예시 요청 (월별 잔고 추이 / 충전 하트 재구매율) 을 시뮬레이션하면서 글로사리·recipe 의 1차 초안 작성
6. 작성 후 두 예시로 검증 — 절차가 동작하는지 확인

본 세션은 워크트리 작업 — common-data-airflow 워크트리 신규 생성 후 진행:
   git branch Feat/data-ops-knowledge-base
   git worktree add ../projects/{프로젝트명}/worktrees/common-data-airflow Feat/data-ops-knowledge-base

프로젝트 디렉토리:
   projects/20260???-data-ops-knowledge-base/  (★ 신규 생성)
   또는 v2 의 §신규 과업으로 처리 (가벼운 갱신이라 별도 프로젝트 안 만들어도 가능)

먼저 인계 문서 읽고 현재 카탈로그 상태 확인 후, 작업 형태 (별도 프로젝트 vs v2) 와 우선순위 (27·28 만 vs 27~30 모두) 를 사용자에게 확인 요청.
```

### 옵션 B: Option II 진행 (트랙 A 먼저, dbt 마이그 시작)

```
/dev-data 또는 /analyze (1pager 작성 후)

본 세션에서 진행할 작업:
dbt 마이그 후속 프로젝트 시작.

순서:
1. projects/20260430-dbt-migration-prep/findings/00-overview.md 읽기 (시니어 1일차 압축본)
2. F-901 (Tier 분류) + F-902 (마이그 순서) + F-903 (정리 대상) 종합 검토
3. 1pager 작성 (사용자 — Trade off 4건 결정 포함)
4. /analyze → readme/tasks 작성
5. /architect → architecture (Wave 1 청사진)
6. /dev-data → Wave 1 구현 시작 (dbt 셋업)

상세 가이드: 90-next-actions.md §4 트랙 A.
별도 프로젝트 디렉토리: projects/20260???-dbt-migration/ 신규 생성.
```

→ **추천: 옵션 A** (트랙 B 먼저).

---

## 8. 결정 대기 항목 (다음 세션 시작 시 합의)

| # | 항목 | 옵션 | 추천 |
|---|---|---|---|
| 1 | **트랙 순서** | Option I (B → A) / Option II (병행) | Option I |
| 2 | **트랙 B 작업 형태** | (a) 별도 프로젝트 / (b) v2 §신규 과업 직접 처리 (워크트리만) | (b) — 가벼운 작업, 별도 프로젝트 부담 큼 |
| 3 | **우선순위 범위** | 27+28 만 (★★★) / 27~30 모두 (4 문서) | 27~30 모두 (~4~6시간) |
| 4 | **두 예시 요청 시뮬레이션 방식** | (a) 글로사리·recipe 작성 후 검증 / (b) 시뮬레이션 결과를 글로사리·recipe 에 입력 | (b) — 실제 사례로 작성하면 추상도 ↓ |

---

## 9. 본 prep 와의 관계

본 prep 종료 (2026-05-01) 후 후속 작업의 두 갈래:

```
본 prep (완료, 영속 보존)
    ↓ 인풋 제공
    ├── 트랙 A (dbt 마이그) — 17 카드 직접 인풋
    └── 트랙 B (운영 환경) — F-301 §1 도메인 인벤토리 / F-101~F-106 §7 답할 수 있는 질문 / F-002 화이트리스트 → 글로사리·recipe 작성 시 참조
```

→ 본 prep 산출은 **양 트랙 모두에 인풋**. 변경 안 됨 (archive).

---

## 10. 핵심 메시지 — 한 줄

> **본 prep 은 dbt 마이그 인풋 + 데이터 인프라 As-Is 스냅샷의 영속 자산. 다음은 그 위에 "운영 환경 (글로사리·recipe)" 을 얹어 데이터 팀이 일하는 환경을 만드는 단계.**

---

## 참조

- 본 prep 종합: [00-overview.md](./00-overview.md)
- Tier 분류: [70-migration-tiers/F-901-tier-classification.md](./70-migration-tiers/F-901-tier-classification.md)
- 마이그 순서: [70-migration-tiers/F-902-recommended-migration-order.md](./70-migration-tiers/F-902-recommended-migration-order.md)
- 마이그 정책: [readme.md §마이그 정책](../readme.md#마이그-정책--2026-04-30-사용자-확정) (MP-1·MP-2·MP-3)
- 운영 정책: [readme.md §운영 정책](../readme.md#운영-정책--2026-05-01-사용자-확정) (OP-1·OP-2·OP-3)
- v2 인계 표: [tasks.md §SSOT 인계](../tasks.md#ssot-인계-v2-로-인계된-과업) (현재 23건, 24~31 추가 예정)

---

## 부록: 카탈로그 글로사리·recipe 의 1차 초안 스케치 (참조)

다음 세션에서 글로사리·recipe 작성 시 시작점.

### `catalog/domain-glossary.md` 1차 구조

```markdown
# 도메인 개념 사전

## 사용자 행동 (방문 / 사용 / 결제 / 재방문 / 재구매)
## 결제·매출 (revenue_krw / 결제자 / ARPPU / LTV / 충전 / 재구매율)
## 사용자 자산 (★ 잔고 — 신규 마트 필요 / 보너스 / 만료)
## 콘텐츠 (스킬 / 신규 스킬 / 사주·타로·기타)
## CRM·푸시 (opt-in / send / open / CTR)
## 코호트·세그먼트 (cohort_month / RFM 12 세그먼트)

각 개념: 정의 / 답할 수 있는 자산 / 정의 갭 (있으면)
```

### `catalog/recipes/data-request-handling.md` 1차 구조

```markdown
# 데이터 요청 처리 워크플로우

## Step 0: 요청 분류 (5 유형)
## Step 1: 요청 해석 (명확화 질문 템플릿)
## Step 2: 자산 점검 (글로사리 검색)
## Step 3 (§A): 즉시 쿼리
## Step 4 (§B): 새 분석 (1회성)
## Step 5 (§C): 새 정의
## Step 6 (§D): 새 자산 (마트·이벤트)
## Step 7 (§E): 명확화

## 자주 받는 요청 패턴 (라이브러리)
- 월별 추이 / 코호트 / 재구매·재방문 / 사용자 세그먼트
```

→ 두 예시 요청 (잔고 / 재구매율) 을 시뮬레이션하면서 작성하면 추상도 ↓ + 즉시 검증 가능.
