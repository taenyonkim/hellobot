# 리포지토리별 배포 가이드

에이전트가 배포 요청 시 참조하는 문서. 각 리포의 개발/운영 배포 절차를 정리.

> 배포 브랜치 전체 현황은 [architecture.md](./architecture.md#배포)를 참조.

---

## hellobot-server

| 환경 | 배포 브랜치 | 트리거 | 비고 |
|------|-----------|--------|------|
| 피쳐 개발 기준 | `master` | - | 피쳐 브랜치를 `master`에서 분기 |
| 개발 | `deploy-dev` | push (자동) | 피쳐 브랜치를 머지 후 푸시 |
| 운영 | `master` | PR 머지 (담당자) | 피쳐 브랜치 푸시 → `master`에 PR 생성 → 담당자 머지 |

```bash
# 개발 배포
git checkout deploy-dev && git merge feat/xxx && git push
# → GitHub Actions 빌드 → ArgoCD 자동 배포

# 운영 배포
git push origin feat/xxx
gh pr create --base master --head feat/xxx
# → 담당자 PR 리뷰/머지 → GitHub Actions 빌드 → ArgoCD 자동 배포
```

**배포 후 필수**: DB 마이그레이션이 포함된 경우 `npm run typeorm:migration` 실행 필요.

파이프라인: GitHub Actions → Docker(ECR `hlb/api`) → ArgoCD/EKS

---

## hellobot-web

| 환경 | 브랜치 | 트리거 |
|------|--------|--------|
| 개발 | `deploy-dev` | push |
| 운영 | `deploy-prod` | push |

```bash
# 개발 배포
git checkout deploy-dev && git merge feat/xxx && git push

# 운영 배포
git checkout deploy-prod && git merge feat/xxx && git push
```

파이프라인: GitHub Actions → Docker(ECR `hlb/web`) → ArgoCD/EKS

---

## hellobot-webview

| 환경 | 브랜치 | 트리거 |
|------|--------|--------|
| 개발 (한국) | `deploy-dev` | push |
| 운영 (한국) | `main` | push |
| 개발 (일본) | `ja-deploy-dev` | push |
| 운영 (일본) | `ja-deploy` | push |

```bash
# 개발 배포
git checkout deploy-dev && git merge feat/xxx && git push

# 운영 배포
git checkout main && git merge feat/xxx && git push
```

파이프라인: GitHub Actions → Docker(ECR `hlb/webview`) → ArgoCD/EKS

---

## hellobot-report-webview

| 환경 | 브랜치 | 트리거 |
|------|--------|--------|
| 개발 | `dev-report-web-deploy` | push |
| 운영 | `prod-report-web-deploy` | push |

```bash
# 개발 배포
git checkout dev-report-web-deploy && git merge feat/xxx && git push

# 운영 배포
git checkout prod-report-web-deploy && git merge feat/xxx && git push
```

파이프라인: GitHub Actions → Docker → EKS

---

## hellobot-studio-server

| 환경 | 브랜치 | 트리거 |
|------|--------|--------|
| 개발 | `deploy-dev` | push |
| 운영 | `master` | push |

```bash
# 개발 배포
git checkout deploy-dev && git merge feat/xxx && git push

# 운영 배포
git checkout master && git merge feat/xxx && git push
```

파이프라인: GitHub Actions → Docker(ECR) → ArgoCD/EKS

---

## hellobot-studio-web

| 환경 | 브랜치 | 트리거 |
|------|--------|--------|
| 개발 (한국) | `deploy-dev` | push |
| 운영 (한국) | `deploy` | push |
| 개발 (일본) | `ja-deploy-dev` | push |
| 운영 (일본) | `ja-deploy` | push |

```bash
# 개발 배포
git checkout deploy-dev && git merge feat/xxx && git push

# 운영 배포 (릴리스 포함)
git checkout master && yarn release    # 버전 태그 + CHANGELOG 생성
git push && git push --tags
git checkout deploy && git merge master && git push
```

파이프라인: GitHub Actions → S3 + CloudFront 무효화

---

## hellobot_android

| 환경 | 방법 | 트리거 | 비고 |
|------|------|--------|------|
| 피쳐 개발 기준 | `develop` | - | 피쳐 브랜치를 `develop`에서 분기 |
| 개발 | Firebase App Distribution | GitHub Actions 수동 dispatch | 피쳐 브랜치 푸시 후 GitHub UI에서 수동 실행 |
| 운영 | Firebase App Distribution | GitHub Actions 수동 dispatch | 동일 파이프라인 (릴리스 빌드 변형 기반) |

```bash
# 피쳐 브랜치 생성
git checkout develop && git pull
git checkout -b feat/xxx

# 개발 / 운영 배포 모두 Firebase App Distribution
git push origin feat/xxx
# → GitHub UI에서 해당 워크플로우 수동 실행 (브랜치 선택)
#   - 개발: upload-app-distribution-dev (Dev 빌드 변형)
#   - 운영: upload-app-distribution (Prd 빌드 변형)
```

로컬 빌드:
```bash
./gradlew :app:assembleDevRelease      # 개발 APK
./gradlew :app:bundlePrdRelease        # 운영 AAB
```

---

## hellobot_iOS

| 환경 | 방법 | 명령어 | 비고 |
|------|------|--------|------|
| 피쳐 개발 기준 | `develop` | - | 피쳐 브랜치를 `develop`에서 분기 |
| 개발 (Beta) | TestFlight (수동) | `bundle exec fastlane testflight_beta_upload` | 피쳐 브랜치에서 로컬 수동 실행 |
| 운영 (TestFlight) | TestFlight | `bundle exec fastlane testflight_upload` | 운영 빌드 TestFlight 배포 |
| 운영 (App Store) | App Store | `bundle exec fastlane submit` | App Store 심사 제출 |

```bash
# 피쳐 브랜치 생성
git checkout develop && git pull
git checkout -b feat/xxx

# 개발 배포 (TestFlight Beta)
bundle exec fastlane testflight_beta_upload

# 운영 배포 (TestFlight)
bundle exec fastlane testflight_upload

# App Store 심사 제출
bundle exec fastlane submit
```

사전 준비: `./get_started.sh` (인증서, 의존성 설치)

---

## common-data-airflow

| 환경 | 방법 |
|------|------|
| 운영 | 수동 (`git pull`) |

```bash
# Airflow 서버에서 직접 실행
git pull origin develop
```

---

## 공통 인프라

| 항목 | 값 |
|------|-----|
| 컨테이너 레지스트리 | Amazon ECR |
| 오케스트레이션 | AWS EKS |
| 배포 도구 | Kustomize (common-infra-eks-deploy) |
| CI/CD | GitHub Actions (self-hosted runners) |
| ArgoCD 대시보드 | `https://argocd.thingsflow.com/applications/{앱명}` |
| 정적 웹 호스팅 | CloudFront + S3 |
