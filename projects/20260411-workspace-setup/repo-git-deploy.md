# 리포별 Git 브랜치 전략 및 배포 규칙 (조사 결과)

> **이 문서는 임시 정리입니다.** 추후 각 리포의 CLAUDE.md에 개별 문서화할 예정입니다.
>
> 조사일: 2026-04-12

---

## 전체 요약

| 리포 | 메인 브랜치 | 개발 브랜치 | 피쳐 브랜치 | 배포 방식 | 배포 트리거 |
|------|-----------|-----------|-----------|----------|-----------|
| hellobot-server | master | deploy-dev | feature/* | GitHub Actions → ECR → K8s | 브랜치 push (CD) |
| hellobot-studio-server | master | deploy-dev | 자유 | GitHub Actions → ECR → K8s | 브랜치 push |
| hellobot-studio-web | master | deploy-dev | 자유 | GitHub Actions → S3 → CloudFront | 브랜치 push |
| hellobot-web | main | deploy-dev | feat/* | GitHub Actions → ECR → K8s | 브랜치 push |
| hellobot-webview | main | deploy-dev | feat/* | GitHub Actions → ECR → K8s (S3 for staging) | 브랜치 push |
| hellobot-report-webview | main | develop | feat/*, fix/* | 수동 (자동화 미구성) | 수동 |
| hellobot_android | master | develop | feature/* | GitHub Actions → Firebase / Google Play | push + 수동 |
| hellobot_iOS | develop | - | feature/* | GitHub Actions + Fastlane → TestFlight | 수동 (workflow_dispatch) |
| common-data-airflow | develop | Feat/* | Feat/* | 수동 SSH → git pull | 수동 |

---

## 리포별 상세

### hellobot-server

| 항목 | 내용 |
|------|------|
| 메인 브랜치 | `master` (프로덕션) |
| 개발 브랜치 | `deploy-dev` (스테이징) |
| 피쳐 브랜치 | master에서 생성 → PR → Squash merge to master |
| 배포 | GitHub Actions → Docker → ECR → ArgoCD → Kubernetes |
| 트리거 | master merge 시 자동 배포 (CD) |
| 특이사항 | 모든 커밋이 즉시 프로덕션 배포됨. 배포 가능 단위로만 커밋. API 호환성 필수. |

---

### hellobot-studio-server

| 항목 | 내용 |
|------|------|
| 메인 브랜치 | `master` (프로덕션) |
| 개발 브랜치 | `deploy-dev` |
| 피쳐 브랜치 | 자유 네이밍 (예: `ImageAdminBug`, `adjustment-message`) |
| 배포 | GitHub Actions → Docker → ECR (`hlb/studio`) → Kustomize → K8s |
| 트리거 | 브랜치 push |
| 배포 경로 | dev: `overlays/hlb/dev/apn2/studio-api/`, prod: `overlays/hlb/prod/studio-api/` |

---

### hellobot-studio-web

| 항목 | 내용 |
|------|------|
| 메인 브랜치 | `master` (한국 프로덕션) |
| 개발 브랜치 | `deploy-dev` (한국 dev), `ja-deploy-dev` (일본 dev) |
| 프로덕션 배포 브랜치 | `deploy` (한국), `ja-deploy` (일본) |
| 배포 | GitHub Actions → npm build → S3 → CloudFront invalidation |
| 트리거 | 배포 브랜치 push |
| 특이사항 | 한국/일본 별도 빌드 및 배포. NodeJS 16.x. |

**배포 브랜치 정리:**
```
deploy-dev     → 한국 개발환경 (dev.hellobotstudio.com)
deploy         → 한국 프로덕션 (hellobotstudio.com)
ja-deploy-dev  → 일본 개발환경 (dev-jp.hellobotstudio.com)
ja-deploy      → 일본 프로덕션 (jp.hellobotstudio.com)
```

---

### hellobot-web

| 항목 | 내용 |
|------|------|
| 메인 브랜치 | `main` |
| 개발 브랜치 | `develop`, `deploy-dev` |
| 프로덕션 배포 브랜치 | `deploy-prod` |
| 피쳐 브랜치 | `feat/`, `feature/` 접두사 |
| 배포 | GitHub Actions → Docker → ECR → Kustomize → K8s |
| 트리거 | 배포 브랜치 push |
| CI 러너 | self-hosted (`act-hellobot-web`) |
| 배포 경로 | dev: `overlays/hlb/dev/apn2/web/`, prod: `overlays/hlb/prod/web/` |

---

### hellobot-webview

| 항목 | 내용 |
|------|------|
| 메인 브랜치 | `main` (프로덕션) |
| 개발 브랜치 | `develop`, `deploy-dev` |
| 스테이징 브랜치 | `deploy-staging` |
| 피쳐 브랜치 | `feat/` 접두사 (예: `feat/DLT-HLB-96`) |
| 배포 (dev) | GitHub Actions → Docker (Dockerfile-dev) → ECR → K8s |
| 배포 (staging) | GitHub Actions → npm build:staging:ssr → S3 → CloudFront |
| 배포 (prod) | GitHub Actions → Docker (Dockerfile-prod) → ECR → K8s |
| 트리거 | 배포 브랜치 push |
| 배포 경로 | prod: `overlays/hlb/prod/webview/` |

---

### hellobot-report-webview

| 항목 | 내용 |
|------|------|
| 메인 브랜치 | `main` |
| 개발 브랜치 | `develop` |
| 배포 브랜치 | `dev-report-web-deploy` (dev), `prod-report-web-deploy` (prod) |
| 피쳐 브랜치 | `feat/`, `fix/` 접두사 |
| 배포 | 수동 (CI/CD 자동화 미구성) |
| 특이사항 | Dockerfile은 존재하나 GitHub Actions 워크플로우 미설정 |

**수동 배포 절차 (README 기준):**
1. develop 브랜치에 작업 merge
2. package.json 버전 업데이트
3. 배포 브랜치 push (`dev-report-web-deploy` 또는 `prod-report-web-deploy`)
4. main 브랜치에 버전 태그

---

### hellobot_android

| 항목 | 내용 |
|------|------|
| 메인 브랜치 | `master` (프로덕션) |
| 개발 브랜치 | `develop` |
| 피쳐 브랜치 | `feature/`, `chore/` 접두사 |
| 배포 (dev) | GitHub Actions → `assembleDevDebug` → Firebase App Distribution |
| 배포 (prod) | GitHub Actions → `bundlePrdRelease` (AAB) → Google Play |
| 트리거 | dev: 수동/push, prod: master push |
| CI 러너 | self-hosted (`[self-hosted, mac, android]`) |
| 특이사항 | master push 시 Google Play 자동 업로드. develop ← master 자동 동기화 워크플로우. |

**빌드 변형:**
```
dev     → assembleDevDebug      (개발 테스트)
staging → assembleStagingDebug  (QA)
prd     → bundlePrdRelease      (프로덕션, AAB 번들)
```

**주요 워크플로우:**
- `upload-app-distribution-dev.yml` — dev 빌드 → Firebase
- `upload-app-distribution-prod.yml` — prod 빌드 → Firebase (내부 배포)
- `upload-play-store.yml` — master push → Google Play
- `sync-master-to-develop.yml` — master → develop 자동 동기화

---

### hellobot_iOS

| 항목 | 내용 |
|------|------|
| 메인 브랜치 | `develop` (HEAD, 주 개발 브랜치) |
| 피쳐 브랜치 | `feature/` 접두사 (예: `feature/HELLOBOT-1619`) |
| 배포 | GitHub Actions + Fastlane → TestFlight / App Store |
| 트리거 | 수동 (workflow_dispatch) |
| CI 러너 | self-hosted (`[self-hosted, mac, ios]`) |
| 특이사항 | 수동 워크플로우. 빌드 넘버 자동 생성. 실패 시 Slack 알림. |

**빌드 타겟:**
```
Hellobot      → 프로덕션 앱 (App Store)
Hellobot-Beta → 개발/테스트 앱 (TestFlight)
```

**주요 워크플로우:**
- `TestFlight.yml` — 프로덕션 앱 TestFlight 업로드 (수동)
- `TestFlight-Beta.yml` — 베타 앱 TestFlight 업로드 (수동)
- `Submit.yml` — App Store 제출
- `release_start.yml`, `release_finish.yml` — 릴리스 플로우
- `bump_version.yml` — 버전 자동 증가

---

### common-data-airflow

| 항목 | 내용 |
|------|------|
| 메인 브랜치 | `develop` (프로덕션) |
| 피쳐 브랜치 | `Feat/` 접두사 (예: `Feat/hlb_featured_banner_sync`) |
| 배포 | 수동: SSH → git pull → Airflow 자동 로드 |
| CI/CD | 없음 (수리 중, 2024/05 기준) |
| Airflow UI | http://34.170.240.154:8080/home |
| 특이사항 | DAG 파일이 서버에서 자동 감지됨. CI/CD 미운영. |

**수동 배포 절차:**
1. develop 브랜치에 merge
2. SSH로 `main-airflow` 서버 접속
3. `git pull origin develop`
4. Airflow가 DAG 파일 자동 감지/로드

**DAG 규칙:**
- 네이밍: `{service}_{functionality}_{frequency}.py`
- 테스트 DAG: `_test` 접미사
- 필수 태그: `team_name`
- 필수 콜백: `on_failure_callback` (Slack 알림)

---

## 패턴 분류

### 자동 배포 (CD)
- **hellobot-server** — master merge → 즉시 프로덕션
- **hellobot_android** — master push → Google Play

### 배포 브랜치 push 방식
- **hellobot-studio-server** — deploy-dev / master push
- **hellobot-studio-web** — deploy-dev / deploy / ja-deploy-dev / ja-deploy push
- **hellobot-web** — deploy-dev / deploy-prod push
- **hellobot-webview** — deploy-dev / deploy-staging / main push

### 수동 배포
- **hellobot_iOS** — workflow_dispatch (수동 트리거)
- **hellobot-report-webview** — 수동 (자동화 미구성)
- **common-data-airflow** — SSH + git pull (CI/CD 없음)
