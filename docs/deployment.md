# 리포지토리별 배포 가이드

에이전트가 배포 요청 시 참조하는 문서. 각 리포의 개발/운영 배포 절차를 정리.

> 배포 브랜치 전체 현황은 [architecture.md](./architecture.md#배포)를 참조.

---

## hellobot-server

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

| 환경 | 방법 | 트리거 |
|------|------|--------|
| 개발 | Firebase App Distribution | GitHub Actions 수동 dispatch |
| 운영 | Google Play Store | `master` push 또는 수동 dispatch |

```bash
# 개발 배포 — GitHub Actions 수동 트리거
# (GitHub UI에서 upload-app-distribution-dev 워크플로우 실행)

# 운영 배포
git checkout master && git merge feat/xxx && git push
# 또는 GitHub UI에서 upload-play-store 워크플로우 수동 실행
```

로컬 빌드:
```bash
./gradlew :app:assembleDevRelease      # 개발 APK
./gradlew :app:bundlePrdRelease        # 운영 AAB (Play Store용)
```

---

## hellobot_iOS

| 환경 | 방법 | 명령어 |
|------|------|--------|
| 개발 (Beta) | TestFlight | `bundle exec fastlane testflight_beta_upload` |
| 운영 | TestFlight | `bundle exec fastlane testflight_upload` |
| App Store 제출 | App Store | `bundle exec fastlane submit` |

```bash
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
