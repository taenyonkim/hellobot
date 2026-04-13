# 프로젝트 가이드

프로젝트별 문서와 개발 환경(워크트리)을 관리합니다.

> **프로젝트 vs 리포 레벨 문서**
> - **프로젝트** (`projects/`): 기획 문서, 전체 설계, 파트별 과업, API 계약 + 워크트리
> - **리포 레벨** (예: `hellobot-server/docs/features/`): 해당 파트의 구현 상세

---

## 디렉토리 구조

```
projects/
├── readme.md                              # 이 문서
└── YYYYMMDD-feature-name/                 # 프로젝트별 디렉토리
    │
    │  ── 입력 문서 (사용자 제공) ──
    ├── 1pager.md                          # 프로젝트 1-pager
    ├── designs/                           # 외부 디자인 파일 (이미지, Figma, 와이어프레임)
    │
    │  ── 기획 문서 (모든 파트 공통 참조) ──
    ├── requirements.md                    # 요구사항 정의서
    ├── user-stories.md                    # 사용자 스토리
    ├── screen-plan.md                     # 화면 기획서
    ├── references/                        # 외부 참조 자료 (API 문서, 제안서, 프로세스 등)
    ├── planning/                          # 기획 과업 산출물 (리서치, 분석, 협의 결과)
    │
    │  ── 에이전트 생성 문서 ──
    ├── readme.md                          # 프로젝트 개요 (/analyze 작성)
    ├── status.md                          # 진행 상태, 워크트리/브랜치 현황
    ├── tasks.md                           # 파트별 과업 목록
    ├── issues.md                          # 이슈 추적 (QA/리뷰/개발 중 발견, 모든 에이전트 작성)
    ├── design.md                          # 기술 설계 (/design 작성)
    ├── api-spec.md                        # 파트 간 API 명세
    ├── qa-test-cases.md                   # QA 테스트 케이스 (/qa 작성)
    │
    │  ── 개발 환경 ──
    └── worktrees/                         # 개발용 워크트리 (필요시 생성)
        ├── hellobot-server/               # git worktree (feat/feature-name)
        └── hellobot_iOS/                  # git worktree (feat/feature-name)
```

### 디렉토리 네이밍
- 형식: `YYYYMMDD-feature-name` (날짜-케밥케이스)
- 날짜는 프로젝트 분석 시작일 기준

---

## 워크플로우

```
프로젝트 생성
  │  프로젝트 디렉토리 생성, designs/ 디렉토리 생성
  │  사용자에게 1pager.md 작성 요청
  ▼
1pager.md 작성 (사용자)
  │  Problem, Customer Job, Solution, Success Metric 등
  ▼
/analyze 실행
  │  1pager.md를 기반으로 readme.md 작성
  │  tasks.md 작성 (파트별 과업 분류)
  │  status.md 생성 (초기 상태)
  ▼
/design 실행
  │  design.md 작성 (기술 설계, 데이터 흐름, 시퀀스)
  │  api-spec.md 작성 (파트 간 API 계약)
  │  status.md 업데이트
  ▼
/dev-* 실행 (파트별)
  │  워크트리 생성 (필요시, 사용자 확인 후)
  │  worktrees/ 내에서 코드 구현
  │  status.md 업데이트 (브랜치/워크트리 현황 포함)
  ▼
/review 실행
  │  변경사항 검토
  │  status.md 업데이트
  ▼
/qa 실행
  │  qa-test-cases.md 작성 (요구사항/설계 기반)
  │  테스트 수행 결과 기록
  │  status.md 최종 업데이트
  │
  ▼
이슈 발견 시 (어떤 단계에서든)
  │  issues.md에 기록
  │  설계 변경 필요 → design.md/api-spec.md 수정 + Changelog 기록
  │  tasks.md에 과업 추가 (ISS-NNN 참조)
  │  /dev-* 수정 → qa-test-cases.md 보강 → issues.md 상태 업데이트
```

> **피드백 루프**: 위 워크플로우는 순방향이지만, 개발·리뷰·QA 중 이슈가 발견되면
> 설계 문서를 수정하고 과업을 추가하는 역방향 흐름이 발생합니다.
> 이슈 관리 절차는 CLAUDE.md의 "이슈 관리" 섹션을 참조하세요.

---

## 문서 분류 규칙

프로젝트 문서는 **모든 파트가 공통으로 참조하는 문서**입니다. 특정 파트의 구현 상세는 해당 리포에 둡니다.

### 프로젝트 레벨 (projects/해당프로젝트/)

| 문서 | 작성자 | 설명 |
|------|--------|------|
| `1pager.md` | 사용자 | 프로젝트 목표, 솔루션, 지표 |
| `designs/` | 사용자 | 디자인 파일, 와이어프레임 |
| `requirements.md` | /analyze 또는 사용자 | 요구사항 정의서 — 전체 기능 요구사항 |
| `user-stories.md` | /analyze 또는 사용자 | 사용자 스토리 — UX 흐름, 예외 시나리오 |
| `screen-plan.md` | /analyze 또는 사용자 | 화면 기획서 — 화면 구성, 분기 조건 |
| `references/` | 사용자 또는 에이전트 | 외부 참조 (API 문서, 제안서, 연동 가이드) |
| `planning/` | 사용자 또는 에이전트 | 기획 과업 산출물 (리서치, 데이터 분석, 상품 정의, 협의 결과, 기존 시스템 검토) |
| `readme.md` | /analyze | 프로젝트 개요, 영향 범위 |
| `status.md` | 모든 에이전트 | 진행 상태, 브랜치/워크트리 현황 |
| `tasks.md` | /analyze | 파트별 과업 목록 |
| `issues.md` | 모든 에이전트 | 이슈 추적 (QA/리뷰/개발 중 발견된 버그, 예외, 개선사항) |
| `design.md` | /design | 기술 설계 (데이터 모델, 처리 로직) |
| `api-spec.md` | /design | 서버↔클라이언트 API 계약 |
| `qa-test-cases.md` | /qa | QA 테스트 케이스 및 검수 결과 |

### 리포 레벨 ({리포}/docs/features/해당피쳐/)

각 `/dev-*` 에이전트는 자기 리포에 피쳐 문서를 생성하여 구현 상세와 작업 로그를 기록합니다.

| 리포 | 문서 예시 | 작성자 |
|------|----------|--------|
| hellobot-server | `backend-design.md`, `backend-guide.md`, `testing/`, `deployment/`, `status.md` | /dev-server |
| hellobot-web | `web-guide.md`, `status.md` | /dev-web |
| hellobot_iOS | `ios-guide.md`, `status.md` | /dev-ios |
| hellobot_android | `android-guide.md`, `status.md` | /dev-android |
| hellobot-studio-* | `studio-guide.md`, `status.md` | /dev-studio |
| common-data-airflow | `data-guide.md`, `status.md` | /dev-data |

**필수 파일**: `status.md` — 해당 파트의 과업 체크리스트와 작업 로그
**선택 파일**: `{파트}-guide.md` — 구현 가이드 (수정 대상 파일, 컴포넌트 구조 등)

#### 2레벨 추적 원칙

```
프로젝트 레벨 (projects/.../status.md)
  → 파트별 상태 요약, 블로커, 마일스톤
  → /workspace가 관리

리포 레벨 ({리포}/docs/features/.../status.md)
  → 해당 파트 구현 상세, 과업 체크리스트, 작업 로그
  → /dev-* 가 관리
```

- `/dev-*` 에이전트는 자기 리포의 status.md를 업데이트
- `/workspace`는 각 리포 status를 모아서 프로젝트 status.md에 요약 반영
- 프로젝트 status.md에서 리포 status.md로 링크

> **원칙**: "iOS 개발자가 이 문서를 참고해야 하는가?" → Yes면 프로젝트 레벨, No면 리포 레벨.

---

## 입력 문서

### 1pager.md (프로젝트 1-pager)

프로젝트 시작 시 사용자가 작성하는 문서입니다. 에이전트가 작성하지 않습니다.
`/analyze`는 이 문서를 기반으로 요구사항을 구체화합니다.

```markdown
## **Problem**
{해결하려는 문제와 root cause}

## **Customer Job**
{고객/회사가 달성하고 싶은 것}

## **Solution / Feature**
{제안된 솔루션과 주요 기능}

## **Success Metric**
input metric
{투입 지표}

output metric
{성과 지표}

## **Benchmark**
{참고 사례, 시장 상황}

## **Trade off**
{필요한 리소스, 트레이드오프}

## **Unhappy Path**
{실패 시나리오, 리스크}

## **Feedback loop**
{성과 측정 및 피드백 방법}
```

### designs/ (디자인 파일)

기획 완료 후 외부에서 작성된 디자인 파일을 넣는 디렉토리입니다.
- Figma 링크를 담은 markdown 파일
- 스크린샷, 목업 이미지
- 디자인 스펙 문서

`/design` 에이전트가 기술 설계 시 이 디렉토리의 파일을 참고합니다.

### planning/ (기획 과업 산출물)

개발 외적인 기획 과업의 산출물을 모아두는 디렉토리입니다.
필요할 때마다 문서를 추가하며, 프로젝트에 따라 없을 수도 있습니다.

**대상 작업 예시**:
- 상품/가격 정의 (예: 하트 상품 구성, 스킬 이용권 라인업)
- 데이터 분석 (예: 사용자 소비 패턴, 전환율 분석)
- 시장 리서치 (예: 경쟁사 벤치마크, 규제 검토)
- 이해관계자 협의 결과 (예: 파트너사 회의록, 내부 의사결정)

**운영 원칙**:
- 문서는 주제별로 자유롭게 추가 (파일명은 내용을 알 수 있도록)
- `/dev-*` 에이전트는 `planning/`을 직접 참조하지 않음 — 컨텍스트 효율성 유지
- 기획 결과 중 개발에 필요한 사항은 프로젝트 문서로 승격:
  - 요구사항에 영향 → `readme.md` 또는 `requirements.md`에 반영
  - 설계에 영향 → `design.md`에 반영
  - 데이터/설정에 영향 → `tasks.md`에 과업으로 추가
- `tasks.md`의 "기획" 섹션에서 과업 진행을 추적

---

## 워크트리 운영

### 생성 시점
- 프로젝트 시작 시 자동 생성하지 않음
- `/dev-*` 에이전트가 코드 수정이 필요할 때 사용자에게 확인 후 생성
- 작업 도중 추가 리포 수정이 필요해지면 그때 워크트리 추가

### 생성 방법

```bash
# 예: hellobot-server 워크트리 생성
cd hellobot-server
git checkout master && git pull          # 메인 브랜치 최신화
git branch feat/{프로젝트명}              # 피쳐 브랜치 생성
git worktree add ../projects/YYYYMMDD-feature-name/worktrees/hellobot-server feat/{프로젝트명}
```

### 정리
- 프로젝트 완료 후 바로 삭제하지 않음 (후속 hotfix 가능)
- 별도 정리 단계에서 제거:
  ```bash
  cd hellobot-server
  git worktree remove ../projects/YYYYMMDD-feature-name/worktrees/hellobot-server
  # 필요시 브랜치도 삭제
  git branch -d feat/{프로젝트명}
  ```

---

## 문서별 템플릿

### readme.md (요구사항)

```markdown
# {프로젝트명}

## 배경
{왜 이 기능이 필요한지}

## 목표
{달성하려는 목표}

## 범위
- 포함: {구현할 내용}
- 제외: {구현하지 않을 내용}

## 영향 범위
| 파트 | 영향 | 설명 |
|------|------|------|
| 서버 | O | {어떤 변경이 필요한지} |
| iOS | O | {어떤 변경이 필요한지} |
| Android | O | {어떤 변경이 필요한지} |
| 웹 | X | 해당없음 |
| 스튜디오 | X | 해당없음 |
| 데이터 | X | 해당없음 |

## 문서 목록
| 문서 | 설명 |
|------|------|
| [status.md](./status.md) | 전체 진행 상태 |
| [tasks.md](./tasks.md) | 파트별 과업 목록 |
| [issues.md](./issues.md) | 이슈 추적 |
| [design.md](./design.md) | 기술 설계 |
| [api-spec.md](./api-spec.md) | API 명세 |
| [qa-test-cases.md](./qa-test-cases.md) | QA 테스트 케이스 |
```

---

### status.md (상태 관리)

```markdown
# 개발 상태

## 현재 상태: {분석중|설계중|개발중|리뷰중|완료|보류}

## 워크트리/브랜치 현황

| 파트 | 리포 | 브랜치 | 워크트리 | PR |
|------|------|--------|---------|-----|
| 서버 | hellobot-server | feat/feature-name | worktrees/hellobot-server/ | - |
| iOS | hellobot_iOS | feat/feature-name | worktrees/hellobot_iOS/ | - |

## 파트별 진행 상태

| 파트 | 상태 | 담당 | 비고 |
|------|------|------|------|
| 서버 | 대기 | /dev-server | |
| iOS | 대기 | /dev-ios | 서버 API 완료 후 착수 |
| Android | 대기 | /dev-android | 서버 API 완료 후 착수 |
| 웹 | 해당없음 | - | |
| 스튜디오 | 해당없음 | - | |
| 데이터 | 해당없음 | - | |
| QA | 대기 | /qa | 개발 완료 후 착수 |

## 작업 로그

### YYYY-MM-DD — /에이전트명
{작업 내용 요약}
- 완료: {완료된 항목}
- 이슈: {발생한 이슈}
- 다음: {다음에 해야 할 작업}
```

**상태값 정의**:
| 상태 | 설명 |
|------|------|
| `분석중` | /analyze가 요구사항 분석 중 |
| `설계중` | /design이 기술 설계 중 |
| `개발중` | /dev-* 가 구현 중 |
| `리뷰중` | /review가 검토 중 |
| `QA중` | /qa가 테스트 케이스 작성 또는 검수 중 |
| `완료` | 전체 완료 |
| `보류` | 일시 중단 |
| `대기` | 선행 작업 완료 대기 |
| `해당없음` | 이 프로젝트에서 작업 불필요 |

---

### tasks.md (과업 분류)

```markdown
# 과업 목록

## 기획 (planning/)
- [ ] {상품 정의, 데이터 분석, 리서치 등 개발 외 과업}
- [ ] {결과물은 planning/ 디렉토리에 기록}

## 서버 (/dev-server)
- [ ] {과업 1 설명}
- [ ] {과업 2 설명}

## iOS (/dev-ios)
- [ ] {과업 1 설명}

## Android (/dev-android)
- [ ] {과업 1 설명}

## 웹 (/dev-web)
해당없음

## 스튜디오 (/dev-studio)
해당없음

## 데이터 (/dev-data)
해당없음

## QA (/qa)
- [ ] 테스트 케이스 작성 (qa-test-cases.md)
- [ ] 테스트 수행 및 결과 기록

## 의존 관계
- iOS, Android는 서버 API 완료 후 착수
- 데이터 파이프라인은 서버 테이블 확정 후 착수
- {기획 과업 확정 → 개발 착수 등의 의존 관계}
```

---

### issues.md (이슈 추적)

QA, 리뷰, 개발 등 어떤 단계에서든 발견된 이슈를 추적합니다.
프로젝트 시작 시 생성하지 않으며, 첫 이슈 발생 시 생성합니다.

```markdown
# 이슈 목록

## 이슈 분류
- **bug**: 구현이 설계와 다름
- **edge-case**: 설계에서 고려하지 못한 예외 상황
- **enhancement**: 기존 요구사항 범위 밖의 개선

---

## 미해결 이슈

### ISS-001: {이슈 제목}

| 항목 | 내용 |
|------|------|
| 분류 | {bug / edge-case / enhancement} |
| 발견일 | YYYY-MM-DD |
| 발견 단계 | {QA / 리뷰 / 개발 / 운영} |
| 심각도 | {P1 / P2 / P3} |
| 영향 파트 | {서버, 웹, iOS 등} |
| 상태 | {등록 / 분석중 / 설계수정 / 구현중 / 검증} |

**현상**: {무엇이 발생하는지}

**원인**: {왜 발생하는지 (분석 후 기재)}

---

## 해결된 이슈

{해결 완료된 이슈를 이동. 해결 방안, 관련 문서 변경 내역을 포함.}

### ISS-NNN: {이슈 제목}

...기존 필드...

**해결 방안**: {어떻게 수정했는지}

**관련 문서 변경**:
- design.md §{섹션} — {변경 내용}
- tasks.md — {추가된 과업}
- qa-test-cases.md — {추가/수정된 테스트 케이스}
```

**심각도 정의**:
| 심각도 | 설명 | 대응 |
|--------|------|------|
| P1 | 데이터 무결성/보안, 핵심 기능 장애 | 즉시 대응 |
| P2 | 주요 기능 오류 | 릴리스 전 수정 |
| P3 | 사소한 이슈 | 후속 수정 가능 |

**상태 흐름**:
```
등록 → 분석중 → 설계수정 → 구현중 → 검증 → 완료
                    │                       ↑
                    └── (단순 버그) ─────────┘
```

---

### design.md (기술 설계)

```markdown
# 기술 설계

## 1. 개요
{기능의 기술적 개요}

## 2. 데이터 흐름
{시스템 간 데이터 흐름 설명 또는 다이어그램}

## 3. API 계약
{서버-클라이언트 간 주요 API 요약}
상세 스펙: [api-spec.md](./api-spec.md)

## 4. 데이터 모델
{새로 추가되는 테이블/컬렉션 설계}

## 5. 처리 로직
{주요 비즈니스 로직 흐름}

## 6. 파트별 구현 포인트
### 서버
{서버에서 구현할 핵심 사항}

### iOS
{iOS에서 구현할 핵심 사항}

### Android
{Android에서 구현할 핵심 사항}

---

## Changelog

| 날짜 | 이슈 | 변경 내용 |
|------|------|----------|
```

> **Changelog 규칙**: 이슈로 인한 설계 변경 시 반드시 기록합니다.
> api-spec.md에도 동일한 Changelog 섹션을 둡니다.

---

## 프로젝트 목록

| 날짜 | 프로젝트명 | 상태 | 설명 |
|------|-----------|------|------|
| 2026-04-11 | [workspace-setup](./20260411-workspace-setup/) | 시범운영 | 통합 개발 환경 구축 — 구조/문서/커맨드 완료, coop-integration으로 검증 중 |
| 2026-03-24 | [coop-integration](./20260324-coop-integration/) | 개발중 | 카카오 선물하기 상품권 연동 — 기획(상품 정의 진행중), 서버/웹 개발중, iOS/Android 대기 |
