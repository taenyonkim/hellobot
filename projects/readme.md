# 프로젝트 가이드

프로젝트별 문서와 개발 환경(워크트리)을 관리합니다.

> **프로젝트 vs 리포 레벨 문서**
> - **프로젝트** (`projects/`): 요구사항, 전체 설계, 파트별 과업, API 계약 + 워크트리
> - **리포 레벨** (예: `hellobot-server/docs/features/`): 해당 파트의 구현 상세

---

## 디렉토리 구조

```
projects/
├── readme.md                              # 이 문서
└── YYYYMMDD-feature-name/                 # 프로젝트별 디렉토리
    ├── readme.md                          # 요구사항, 배경, 목표, 범위
    ├── status.md                          # 진행 상태, 워크트리/브랜치 현황
    ├── tasks.md                           # 파트별 과업 목록
    ├── design.md                          # 기술 설계 (API 계약, 데이터 흐름)
    ├── api-spec.md                        # 파트 간 API 명세 (필요시)
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
/analyze 실행
  │  readme.md 작성 (요구사항, 배경, 목표, 범위)
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
  │  status.md 최종 업데이트
```

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
| [design.md](./design.md) | 기술 설계 |
| [api-spec.md](./api-spec.md) | API 명세 |
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
| `완료` | 전체 완료 |
| `보류` | 일시 중단 |
| `대기` | 선행 작업 완료 대기 |
| `해당없음` | 이 프로젝트에서 작업 불필요 |

---

### tasks.md (과업 분류)

```markdown
# 과업 목록

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

## 의존 관계
- iOS, Android는 서버 API 완료 후 착수
- 데이터 파이프라인은 서버 테이블 확정 후 착수
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
```

---

## 프로젝트 목록

| 날짜 | 프로젝트명 | 상태 | 설명 |
|------|-----------|------|------|
| 2026-04-11 | [workspace-setup](./20260411-workspace-setup/) | 개발중 | 통합 개발 환경 구축 (에이전트 워크플로우, 프로젝트 구조) |
