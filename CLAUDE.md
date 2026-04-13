# HelloBot Workspace

HelloBot은 AI 챗봇 기반 운세/점술 서비스입니다. 이 워크스페이스는 헬로우봇 서비스 전체를 구성하는 개별 리포지토리들의 상위 디렉토리입니다.

## 리포지토리 구성

| 리포지토리 | 스택 | 역할 | 배포 |
|-----------|------|------|------|
| `hellobot-server` | Node.js / Express / TypeORM / PostgreSQL | 메인 API 서버 | GitHub Actions → ArgoCD |
| `hellobot-studio-server` | Java / Spring Boot / MongoDB | 스튜디오(챗봇 빌더) 백엔드 | GitHub Actions → ArgoCD |
| `hellobot-studio-web` | Angular 13 / TypeScript | 스튜디오 프론트엔드 | GitHub Actions → S3/CloudFront |
| `hellobot-web` | Next.js 14 / React 18 / Tailwind | 메인 웹 (스킬스토어) | GitHub Actions → ArgoCD |
| `hellobot-webview` | Angular 13 SSR / TypeScript | 앱 내 웹뷰 (레거시, 점진적으로 hellobot-web으로 이관 중) | ArgoCD |
| `hellobot-report-webview` | Next.js 14 / React 18 / Tailwind | 리포트/분석 웹뷰 | GitHub Actions |
| `hellobot_android` | Kotlin / MVVM / Hilt / Jetpack Compose | Android 앱 | GitHub Actions → Firebase/Play Store |
| `hellobot_iOS` | Swift / ReactorKit / RxSwift / Tuist | iOS 앱 | Fastlane → TestFlight/App Store |
| `common-data-airflow` | Python / Apache Airflow / BigQuery | 데이터 파이프라인 (ETL) | 수동 배포 |

> 배포 상세 (브랜치, 절차): [docs/architecture.md](docs/architecture.md#배포)

## 의존 관계

```
hellobot-server (메인 API)
  ├── hellobot-web (Next.js 웹)
  ├── hellobot-webview (Angular 웹뷰)
  ├── hellobot-report-webview (리포트 웹뷰)
  ├── hellobot_android (Android 앱)
  ├── hellobot_iOS (iOS 앱)
  └── common-data-airflow (데이터 수집)

hellobot-studio-server (스튜디오 API)
  ├── hellobot-studio-web (스튜디오 프론트)
  └── 모바일 앱들 (챗봇 설정 데이터 제공)

hellobot-webview / hellobot-report-webview
  └── 모바일 앱들에 WebView로 임베딩
```

## 공유 인프라

- **DB**: PostgreSQL (메인), MongoDB (스튜디오), Redis (캐싱/세션)
- **클라우드**: AWS (S3, CloudFront, SES), Firebase, Google BigQuery
- **배포**: ArgoCD/Kubernetes (서버), Vercel (웹), Fastlane (iOS), GitHub Actions (CI/CD)
- **분석**: Braze, Amplitude, BigQuery

## 다국어

- 한국어 (기본): hellobot.co, hellobotstudio.com
- 일본어: jp.hellobot.co, jp.hellobotstudio.com

---

## 워크스페이스 구조

```
hellobot/                              ← 워크스페이스 루트
├── CLAUDE.md                          ← 이 파일 (전체 규칙)
├── docs/                              ← 프로젝트와 무관한 상시 문서
│   ├── architecture.md
│   ├── how-to-work.md
│   └── web-page-map.md
├── projects/                          ← 프로젝트별 디렉토리
│   ├── readme.md                      ← 프로젝트 문서 가이드 및 템플릿
│   └── YYYYMMDD-feature-name/         ← 프로젝트
│       ├── readme.md                  ← 요구사항, 배경, 목표
│       ├── status.md                  ← 진행 상태, 브랜치/워크트리 현황
│       ├── tasks.md                   ← 파트별 과업
│       ├── design.md                  ← 기술 설계
│       ├── api-spec.md                ← API 명세
│       ├── qa-test-cases.md           ← QA 테스트 케이스
│       ├── planning/                  ← 기획 과업 산출물 (필요시 생성)
│       └── worktrees/                 ← 개발용 워크트리 (필요시 생성)
│           ├── hellobot-server/       ← git worktree (feat/feature-name)
│           └── hellobot_iOS/          ← git worktree (feat/feature-name)
├── scripts/
│   └── setup.sh
│
├── hellobot-server/                   ← 원본 리포 (메인 브랜치 고정)
├── hellobot-studio-server/
├── hellobot-studio-web/
├── hellobot-web/
├── hellobot-webview/
├── hellobot-report-webview/
├── hellobot_android/
├── hellobot_iOS/
└── common-data-airflow/
```

---

## 프로젝트 및 워크트리 운영 규칙

### 원본 리포지토리

- 원본 리포(`hellobot-server/`, `hellobot_iOS/` 등)는 **항상 메인 브랜치에 고정**
- 원본에서 직접 피쳐 개발하지 않음 — 참조/조사 용도로만 사용
- 코드 수정은 반드시 프로젝트의 워크트리에서 수행

### 피쳐 브랜치

- 네이밍: `feat/{프로젝트명}` (예: `feat/share-result`)
- 각 리포의 메인 브랜치에서 생성

### 워크트리 생성

- 프로젝트 시작 시 자동으로 만들지 않음 — 개발 단계에서 필요시 사용자에게 확인 후 생성
- 작업 진행 중 추가 리포 수정이 필요하면 그때 워크트리 추가
- 생성 명령:
  ```bash
  cd hellobot-server
  git worktree add ../projects/20260412-share-result/worktrees/hellobot-server feat/share-result
  ```

### 워크트리 정리

- 프로젝트 완료 후 바로 삭제하지 않음 (후속 hotfix 가능)
- 별도 정리 단계에서 제거:
  ```bash
  cd hellobot-server
  git worktree remove ../projects/20260412-share-result/worktrees/hellobot-server
  ```

### 개발 에이전트의 작업 디렉토리

`/dev-*` 에이전트는 **워크트리 경로**에서 작업합니다:
```
원본 참조:  hellobot-server/                              ← 읽기 전용 (기존 코드 참고)
코드 수정:  projects/20260412-share-result/worktrees/hellobot-server/  ← 여기서 개발
```

---

## 에이전트 워크플로우

이 워크스페이스에서는 역할별 에이전트 커맨드를 사용하여 피쳐를 개발합니다.

### 워크플로우 단계

```
요구사항 접수
    │
    ▼
/analyze (PM/기획)        → 요구사항 분석, 영향 범위, 과업 분류
    │
    ▼
/design (기술 설계)        → API 계약, 데이터 모델, 시퀀스
    │
    ▼
/dev-server               ┐
/dev-ios                  │
/dev-android              ├ 병렬 구현 (워크트리에서 작업)
/dev-web                  │
/dev-studio               │
/dev-data                 ┘
    │
    ▼
/review (검토)             → 크로스 리포 정합성 검증
    │
    ▼
/qa (QA)                   → 테스트 케이스 작성, 검수 결과 관리
    │
    ▼
/workspace (관리)          → 문서 정합성 점검, 상태 최신화 (수시)
```

### 에이전트 역할

| 커맨드 | 역할 | 담당 리포 |
|--------|------|-----------|
| `/analyze` | PM/기획자 — 요구사항 분석, 과업 분류, 우선순위 | 전체 (읽기만) |
| `/design` | 기술 설계자 — API 계약, 데이터 모델, 시퀀스 | 관련 리포 (읽기만) |
| `/dev-server` | 서버 개발자 | hellobot-server |
| `/dev-ios` | iOS 개발자 | hellobot_iOS |
| `/dev-android` | Android 개발자 | hellobot_android |
| `/dev-web` | 웹 개발자 | hellobot-web, hellobot-webview, hellobot-report-webview |
| `/dev-studio` | 스튜디오 개발자 | hellobot-studio-server, hellobot-studio-web |
| `/dev-data` | 데이터 엔지니어 | common-data-airflow |
| `/review` | 코드 리뷰어 | 변경된 리포 전체 |
| `/qa` | QA 담당자 — 테스트 케이스 작성, 검수 결과 관리 | 프로젝트 문서 (읽기) + qa-test-cases.md (작성) |
| `/workspace` | 워크스페이스 관리자 — 문서 정합성, 상태 최신화 | 워크스페이스 문서 전체 |

### 에이전트 간 커뮤니케이션

에이전트들은 **프로젝트 문서**를 통해 소통합니다:

1. `/analyze` → `projects/YYYYMMDD-feature-name/readme.md`, `tasks.md` 작성
2. `/design` → `design.md`, `api-spec.md` 작성
3. `/dev-*` → 워크트리에서 구현 후 `status.md` 업데이트
4. `/review` → 변경사항 + 프로젝트 문서 대조 검증
5. `/qa` → `qa-test-cases.md` 작성, 검수 결과 관리
6. `/workspace` → 문서 정합성 점검, 오래된 문서 최신화

### 프로젝트 문서 구조

프로젝트 문서는 `projects/` 디렉토리에 관리합니다.
각 리포 내 구현 상세(예: hellobot-server/docs/features/)는 해당 리포에서 관리합니다.

상세 가이드: [projects/readme.md](projects/readme.md)

---

## 컨텍스트 관리 규칙 (필수)

리포지토리 전체는 매우 거대합니다. **필요한 데이터만 정확히 참조**하세요.

### 컨텍스트 로딩 순서

```
1단계 (필수): 워크스페이스 CLAUDE.md (이 파일)
2단계 (필수): 프로젝트 문서 (projects/해당프로젝트/)
3단계 (역할별): 담당 리포의 CLAUDE.md 또는 README.md
4단계 (필요시): 담당 리포 내 관련 소스 파일 (Grep/Glob으로 타겟팅)
```

### 금지 사항

- **담당 외 리포의 소스코드 탐색 금지** — 필요한 정보는 프로젝트 문서나 API 스펙으로 전달
- **리포 전체를 훑는 광범위 탐색 금지** — 항상 파일명/키워드로 타겟팅 검색
- **불필요한 파일 읽기 금지** — 구현에 직접 관련된 파일만 읽기
- **`/dev-*` 에이전트는 `planning/` 디렉토리 탐색 금지** — 개발에 필요한 사항은 프로젝트 문서(readme, design, tasks 등)로 승격되어 있음
- **원본 리포에서 코드 수정 금지** — 반드시 프로젝트 워크트리에서 작업

### 탐색 전략

```
좋은 예:
  Grep("FeatureName", path="hellobot-server/src/services/")
  Glob("**/feature-name*.ts", path="hellobot-server/src/")

나쁜 예:
  Glob("**/*.ts")  ← 전체 탐색
  Read("hellobot-server/src/services/") ← 디렉토리 전체
```

### 크로스 리포 참조가 필요할 때

다른 파트의 정보가 필요하면:
1. 먼저 프로젝트 문서의 `design.md`, `api-spec.md`를 확인
2. 문서에 없으면 해당 리포의 CLAUDE.md만 확인
3. 그래도 부족하면 해당 리포에서 특정 파일만 타겟팅 검색

---

## 작업 가이드

- 각 리포지토리는 독립된 Git 저장소입니다. 원본은 메인 브랜치에 고정하고, 개발은 프로젝트 워크트리에서 수행합니다.
- 프로젝트 문서는 `projects/` 디렉토리에, 서비스 상시 문서는 `docs/` 디렉토리에 기록합니다.
- 각 리포지토리의 상세 개발 가이드는 해당 리포의 CLAUDE.md 또는 README.md를 참조하세요.
- **처음 사용한다면**: [docs/how-to-work.md](docs/how-to-work.md) — 워크스페이스 사용법, 에이전트 커맨드, 실전 예시 포함
