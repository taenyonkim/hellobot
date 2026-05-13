# 도메인 지식 누적 구조 설계 (1차 시드)

> 본 문서는 1차 설계안. 9개 리포 각각에 적용 가능성을 점검하고, 갱신 흐름을 구체화하는 것이 Phase 1-C 의 후속 과업.

---

## 1. 전제

### 무엇이 "도메인 지식" 인가

본 문서에서 도메인 지식은 다음 4가지로 분류한다.

| 카테고리 | 정의 | 예시 (서버) |
|---------|------|------------|
| **Concepts** (개념) | 도메인의 엔티티, 라이프사이클, 정책 | "쿠폰 = 발급/사용/취소 3 상태. usage 와 chargeHeart 는 별도 트랜잭션" |
| **Patterns** (반복 절차) | 자주 발생하는 작업의 표준 절차 | "TypeORM 마이그레이션 추가: entity 작성 → migration:generate → review → 등록" |
| **Decisions** (의사결정) | 비명시적이지만 영향이 지속되는 결정 | "쿠폰 cancel 시 usage 를 DELETE 하지 않고 status UPDATE — 이력 추적 필요" |
| **Cases** (사례) | 구체적 과거 사례 (참조용) | "ISS-001: 쿠폰 취소 후 재사용 시 CM_007. 트랜잭션 분리 + UPSERT 로 해결" |

### 핵심 원칙

1. **저장은 리포 안에** — 도메인 지식은 코드와 함께 살아간다. 리포 `docs/` 에 보관.
2. **인덱스는 진입점에** — 메모리 시스템 또는 리포 CLAUDE.md 가 인덱스를 가리킨다.
3. **누적 부담 차단** — 잘 알려진 / 코드만으로 충분한 / 한 번 쓰고 버려도 되는 정보는 저장하지 않는다.
4. **갱신이 가벼워야** — 프로젝트 종료 시 갱신 부담이 크면 결국 안 한다.
5. **구식이 위험하지 않게** — 작성일 + 마지막 검증일 명시, 누가 책임지는지 명시.

---

## 2. 리포 구조 제안

각 리포의 `docs/` 아래 다음 디렉토리를 둔다 (필요한 카테고리만 점진 신설).

```
{repo}/
└── docs/
    ├── CLAUDE.md (or README.md)        ← 진입점, domain/index.md 를 가리킴
    │
    ├── domain/                          ← 카테고리 1: Concepts
    │   ├── index.md                    ← 도메인 맵 (어디를 보면 되는가)
    │   ├── overview.md                 ← 리포의 도메인 개요
    │   ├── {domain1}.md                ← 예: heart-coupon.md, payment.md
    │   ├── {domain2}.md
    │   └── glossary.md                 ← 용어집 (선택)
    │
    ├── patterns/                        ← 카테고리 2: Patterns
    │   ├── index.md                    ← 패턴 목록
    │   ├── add-{recurring-task}.md     ← 예: add-api-endpoint.md
    │   └── ...
    │
    ├── decisions/                       ← 카테고리 3: Decisions (ADR)
    │   ├── index.md                    ← ADR 목록 (날짜/제목/상태)
    │   ├── ADR-001-{title}.md
    │   └── ...
    │
    └── features/                        ← 기존: 프로젝트별 구현 기록 (Cases)
        └── YYYYMMDD-{프로젝트}/
            ├── status.md
            └── ...
```

### 점진 도입 원칙

- **모든 리포가 동일하게 가질 필요 없음** — 작은 리포는 `domain/` 만으로 충분할 수 있음
- **신설 자체로 시작하지 않음** — 첫 도메인 자산이 만들어질 때 디렉토리 생성

---

## 3. 카테고리별 명세

### 3-1. Concepts (`docs/domain/`)

**역할**: 리포의 도메인 개요를 설명. 새 에이전트가 작업 시작 시 가장 먼저 읽어야 할 자료.

**작성 시점**:
- 첫 도메인 작업 후 (해당 도메인을 처음 다룬 `/dev-*` 가 작성)
- 이후 의미 있는 도메인 변경 시 갱신 (예: 라이프사이클 변경, 정책 변경)

**문서 형식 (예시)**:

```markdown
# 하트·쿠폰 도메인

> 작성: /dev-server (2026-04-14, ISS-001 학습 기반)
> 마지막 검증: 2026-04-30

## 핵심 엔티티
- HeartLog — 하트 적립/소비 이력. 적립 타입 enum.
- Coupon — 쿠폰 마스터. 발급된 쿠폰은 CouponUsage.
- CouponUsage — 사용 인스턴스. (couponId, userId) 유니크.

## 라이프사이클
1. 발급 (issueCoupon)
2. 사용 (useByGiftCoupon) → CouponUsage INSERT + chargeHeart
3. 취소 (cancelCoupon) → CouponUsage status UPDATE (DELETE 하지 않음)
4. 재사용 → UPSERT 로 유니크 제약 회피

## 핵심 정책 / 함정
- chargeHeart 는 별도 트랜잭션 — 부분 실패 가능. recovery 로직 필요.
- usableDays 36500 = 사실상 무제한 (만료 정책 변경 시 함정).

## 관련 ADR
- ADR-001 — 쿠폰 cancel 시 usage 를 DELETE 하지 않는 결정
- ADR-003 — chargeHeart 트랜잭션 분리 정책

## 관련 Patterns
- patterns/add-coupon-type.md
```

**원칙**:
- 짧게 — 200줄 이내가 좋다
- 코드 링크 — 파일/라인 링크로 깊은 정보 위임
- 예시는 1~2개만

### 3-2. Patterns (`docs/patterns/`)

**역할**: 반복 작업의 표준 절차. 처음 하는 에이전트도 이 문서만 보고 일관되게 수행 가능.

**작성 시점**:
- 같은 작업이 2번 이상 반복되면 패턴 후보
- 단순 코드 패턴은 코드만으로 충분 — 절차에 비코드 단계가 있을 때 가치 있음 (마이그레이션 작성, 등록, 검증, 배포 같은 흐름)

**문서 형식 (예시)**:

```markdown
# Pattern: TypeORM 마이그레이션 추가

> 마지막 검증: 2026-04-22 (coop-integration 적용 시)

## 언제 사용하는가
DB 스키마 변경이 필요할 때.

## 절차
1. Entity 변경 (`src/entity/...`)
2. `npm run migration:generate -- src/migration/{name}` (또는 수동 작성)
3. 생성된 SQL 검토 (특히 컬럼 길이 / 기본값 / 외래키 옵션)
4. 로컬 DB 적용: `npm run migration:run`
5. PR 시 review 자동 포함됨 (CI 가 dev DB 에 검증)

## 함정
- TypeORM 자동 생성 SQL 은 종종 컬럼 길이를 누락 — 수동 보정 필요
- (사례) coop-integration 에서 `processType VARCHAR(2)` 가 필요량 부족, 운영 중 확장됨 → 사전에 충분히

## 관련 코드
- `src/migration/` — 기존 마이그레이션 참고
- `src/entity/Coupc*.ts` — 최근 사례

## 관련 ADR
- ADR-005 — 마이그레이션 명명 규칙
```

### 3-3. Decisions (`docs/decisions/` ADR)

**역할**: 영향이 지속되는 결정의 영속 기록. 다음 프로젝트가 같은 함정을 피하거나 결정 맥락을 이해하는 데 사용.

**작성 시점**:
- 프로젝트 종료 시 — `/workspace 종료` 절차에 "ADR 후보 점검" 단계 추가
- 결정의 영향이 본 프로젝트를 넘어 지속되는 경우만

**문서 형식 (얇게)**:

```markdown
# ADR-001: 쿠폰 cancel 시 usage 를 DELETE 하지 않는다

| 상태 | 채택 |
| 결정일 | 2026-04-14 |
| 결정 주체 | /dev-server (coop-integration ISS-001) |
| 영향 범위 | hellobot-server: coupon, heart |

## 결정
CouponUsage 를 cancel 시 DELETE 하지 않고 status='canceled' UPDATE.

## 이유
- 이력 추적 필요 (재사용 / 분석)
- DELETE 는 chargeHeart 별도 트랜잭션과 정합성 이슈

## 결과 / 트레이드오프
- (+) 이력 보존
- (-) 재사용 시 유니크 제약 회피 위해 UPSERT 필요 — `add-coupon-type.md` 참조

## 관련
- ISS-001 (coop-integration)
- patterns/add-coupon-type.md
```

**원칙**:
- 얇게 — 한 ADR 당 50줄 이하
- 결정/이유/트레이드오프 3가지만
- 상태 유지 — 변경 시 새 ADR 작성, 이전 ADR 은 "대체됨" 표기

### 3-4. Cases (기존 `docs/features/`)

기존 구조 유지. 프로젝트 종료 후 디렉토리는 그대로 보존되어 검색 가능.

**역할 변경**:
- 지금까지: 프로젝트 진행 기록
- 추가: ADR / 도메인 문서가 가리키는 사례 보관소

---

## 4. 갱신 흐름 (자동/반자동)

### 4-1. 프로젝트 진행 중

| 시점 | 동작 |
|------|------|
| `/dev-*` 작업 시작 | 진입점 가이드(CLAUDE.md → domain/index.md → 관련 도메인 문서 + ADR) 로드 |
| 도메인 결정 발생 (ISS 처리 또는 의도적 설계 변경) | 리포 status.md 결정 로그에 기록 (현행 그대로) |
| 반복 작업 발견 | (선택) `docs/patterns/` 후보로 마킹 |

### 4-2. 프로젝트 종료 시 (`/workspace 종료`)

기존 종료 절차에 다음 단계 추가:

```
6. status.md 갱신 (기존)
6.5 도메인 자산 갱신 점검 (NEW)
    - 본 프로젝트의 결정 중 ADR 승격 후보 식별
    - 본 프로젝트에서 학습한 도메인 개념 → docs/domain/ 갱신 후보 식별
    - 사용자와 협의 후 작성/갱신
    - 갱신 결과를 status.md §종료 정보 §승격 산출물 표에 기록
7. 프로젝트 목록 갱신 (기존)
```

**원칙**:
- ADR 승격은 사용자 확인 필수 (자동 작성 금지)
- 작성 부담 최소화 — 50줄 이하 권장
- "이 결정은 다음 프로젝트가 알아야 하는가?" 가 유일한 기준

### 4-3. 새 프로젝트 시작 시

`/analyze` 절차에 다음 단계 추가:

```
4. 영향 파트별 도메인 진입점 로드 (NEW)
   - 영향 리포의 docs/domain/index.md 확인
   - 관련 도메인 문서 / 최근 ADR 후보 확인
   - readme.md 의 §관련 자산 섹션에 기록
```

`/dev-*` 가 처음 호출될 때:
- CLAUDE.md (workspace + repo) → docs/domain/index.md → 관련 도메인 문서 + ADR 순으로 로드
- 이 절차는 커맨드 본문에 명시

---

## 5. 메모리 시스템과의 관계

### 역할 분담

| 채널 | 역할 |
|------|------|
| 메모리 (`MEMORY.md`) | **인덱스 + 단축 메모** — "어디를 보면 된다", "자주 발생하는 1줄 주의사항" |
| 리포 `docs/domain/` | **본문 + 상세** — 개념, 정책, 함정의 본격 설명 |
| 리포 `docs/decisions/` | **결정 로그** — 영구적 결정의 맥락 |
| 리포 `docs/patterns/` | **절차** — 반복 작업의 표준 흐름 |
| 워크스페이스 `docs/` | **상시 문서** — 아키텍처, 작업 가이드, 배포 가이드 |
| 프로젝트 `docs/features/` | **사례** — 진행 기록, 시점 의사결정 |

### 메모리 항목 후보

본 프로젝트 적용 후 메모리에 추가될 항목 예시:

```
- [hellobot-server 도메인 진입](reference_dev_server_domain.md) — 서버 작업 시 hellobot-server/docs/domain/index.md 부터 읽고 관련 도메인/ADR 로 진입
- [common-data-airflow 도메인 진입](reference_dev_data_domain.md) — 데이터 작업 시 catalog/infra-map.md 부터 (이미 있음, 일관성 확보용)
- [반복 결정 패턴](feedback_recurring_decisions.md) — coop 시리즈에서 학습된 비명시적 정책 단축 메모
```

원칙: 본문 복사 금지. 위치만 가리킴.

---

## 6. 컨텍스트 부담 차단 장치

도메인 자산이 누적되면 컨텍스트 비용 증가 위험. 다음 장치 필요.

| 장치 | 설명 |
|------|------|
| **인덱스 우선 로드** | `domain/index.md` (~50줄) 만 디폴트 로드. 본문은 명시 요청 시 |
| **lazy 로딩** | `/dev-*` 본문에 "이 작업이 X 도메인이면 X.md 로드" 식 분기 |
| **검증 메타데이터** | 각 도메인 문서에 마지막 검증일 — 6개월 초과 시 신뢰도 경고 |
| **수익률 점검** | 분기별 1회 "최근 N개월 참조 0회 도메인 문서" 식별 → archive 후보 |

---

## 7. 리포별 적용 가능성 (1차 평가)

| 리포 | domain/ | patterns/ | decisions/ | 비고 |
|------|---------|-----------|-----------|------|
| hellobot-server | **O** (높음) | O | O | 가장 큰 도메인. 우선 파일럿 후보 |
| common-data-airflow | (이미 catalog/) | O | O | 카탈로그 SSOT 가 domain/ 역할 — 재구조화 검토 |
| hellobot-studio-server | O | △ | △ | 도메인 분명하나 작업 빈도 낮음 |
| hellobot-web | △ | O | △ | 페이지/플로우 위주 — patterns/ 가 더 유효 |
| hellobot-webview | (레거시 — 이관 중) | △ | △ | 적극 신설 비추 |
| hellobot-report-webview | △ | O | △ | 리포트 종류별 패턴 누적 가능 |
| hellobot_iOS | △ | O | O | iOS 특수 함정 ADR 가치 큼 |
| hellobot_android | △ | O | O | 동상 |
| hellobot-studio-web | △ | O | △ | |
| common-infra-eks-deploy | △ | **O** (높음) | O | 매니페스트 패턴 / 결정 누적 가치 큼 |
| hellobot-mwaa | △ | △ | △ | DAG 마이그 진행 중 — 안정화 후 |

**파일럿 후보**: `hellobot-server` (코드 본격, 결정 다수) + `common-data-airflow` (이미 SSOT 모델 존재 → 정렬)

---

## 8. 리스크 / 트레이드오프

| 리스크 | 완화 |
|--------|------|
| 도메인 문서가 stale 됨 | 마지막 검증일 표기 + 분기 점검 |
| 작성 부담으로 갱신 안 됨 | 짧게 유지 (50~200줄), 종료 절차에 명시 |
| 인덱스 비대화 | 카테고리별 인덱스 분리, 메모리에는 진입점만 |
| 자동화 false positive | hooks 는 경고 only, 차단 금지 |
| 학습 곡선 | 파일럿 1개 리포에서 충분히 검증 후 확장 |

---

## 9. 후속 보강 (Phase 1-C 후속)

- [ ] 9개 리포 각각 도메인 자산 보유 가능성 정밀 평가 (코드 베이스 규모, 작업 빈도, 도메인 안정성)
- [ ] 갱신 흐름 자동화 가능 영역 식별 (예: 리포 status 결정 로그 → ADR 후보 자동 추출 hook)
- [ ] 인덱스 메타데이터 형식 결정 (카테고리, 마지막 검증일, 책임 에이전트 등)
- [ ] 카탈로그 모델(common-data-airflow) 과 본 모델 정합성 검토 — 모델 통일 vs 차등 유지
