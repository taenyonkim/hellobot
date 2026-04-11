# HelloBot 서비스 아키텍처

## 서비스 개요

HelloBot은 AI 챗봇 기반 운세/점술 서비스로, 사용자에게 사주, 타로, 궁합 등 다양한 스킬(점술 콘텐츠)을 제공합니다.

## 시스템 구성도

```
┌─────────────────────────────────────────────────────────┐
│                      클라이언트                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │ Android  │  │   iOS    │  │   Web    │  │ Studio  │ │
│  │ (Kotlin) │  │ (Swift)  │  │(Next.js) │  │(Angular)│ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘ │
│       │              │             │              │      │
│  ┌────┴──────────────┴─────┐      │         ┌────┴────┐ │
│  │  WebView (Angular SSR)  │      │         │         │ │
│  │  Report WebView(Next.js)│      │         │         │ │
│  └────┬────────────────────┘      │         │         │ │
└───────┼───────────────────────────┼─────────┼─────────┘
        │                           │         │
        ▼                           ▼         ▼
┌───────────────────────────┐  ┌──────────────────────┐
│    hellobot-server        │  │ hellobot-studio-     │
│    (Node.js/Express)      │  │ server (Spring Boot) │
│                           │  │                      │
│  ┌─────┐ ┌─────┐ ┌─────┐ │  │  ┌───────┐ ┌──────┐ │
│  │ PG  │ │Redis│ │ S3  │ │  │  │MongoDB│ │Redis │ │
│  └─────┘ └─────┘ └─────┘ │  │  └───────┘ └──────┘ │
└───────────┬───────────────┘  └──────────────────────┘
            │
            ▼
┌───────────────────────────┐
│  common-data-airflow      │
│  (Python/Airflow)         │
│         │                 │
│         ▼                 │
│    ┌──────────┐           │
│    │ BigQuery │           │
│    └──────────┘           │
└───────────────────────────┘
```

## 주요 컴포넌트 상세

### 백엔드

#### hellobot-server (메인 API)
- **스택**: Node.js 14 / Express / TypeORM (Active Record) / TypeDI / routing-controllers
- **DB**: PostgreSQL (메인), Redis (캐싱/세션)
- **주요 기능**: 사용자 인증(JWT, OAuth2), 스킬 관리, 결제, 푸시 알림, 관리자 대시보드(AdminJS)
- **외부 연동**: AWS S3/CloudFront, Braze, BigQuery, Google Analytics
- **배포**: Docker → ArgoCD/Kubernetes

#### hellobot-studio-server (스튜디오 API)
- **스택**: Java / Spring Boot 2.1 / Spring Data MongoDB
- **DB**: MongoDB (챗봇 정의/스크립트), Redis, PostgreSQL (동기화용)
- **주요 기능**: 챗봇 생성/편집/배포, 팀/권한 관리, 엑셀 임포트(Apache POI)
- **외부 연동**: AWS S3/SES
- **배포**: ArgoCD/Kubernetes

### 프론트엔드

#### hellobot-web (메인 웹)
- **스택**: Next.js 14 / React 18 / Tailwind / Redux Toolkit / SWR
- **주요 기능**: 스킬스토어, 운세, 쿠폰, 결제(TossPayments)
- **신규 기능 개발 대상** (hellobot-webview에서 이관 중)

#### hellobot-webview (레거시 웹뷰)
- **스택**: Angular 13 / Angular Universal (SSR)
- **모바일 앱에 WebView로 임베딩**
- **점진적으로 hellobot-web(Next.js)으로 이관 중**

#### hellobot-report-webview (리포트)
- **스택**: Next.js 14 / React 18 / Tailwind / Reactflow / Recharts
- **주요 기능**: 사용자 리포트, 궁합 분석, 인터랙티브 차트

#### hellobot-studio-web (스튜디오 프론트)
- **스택**: Angular 13 / Angular Material / ng-bootstrap
- **주요 기능**: 챗봇 빌더 UI, PWA 지원

### 모바일

#### hellobot_android
- **스택**: Kotlin / MVVM / Dagger Hilt / Jetpack Compose (부분)
- **네트워킹**: Retrofit / OkHttp
- **로컬 DB**: Room (현재), Realm (레거시)
- **빌드 변형**: dev / staging / prd
- **최소 SDK**: API 가변, Target SDK: API 34

#### hellobot_iOS
- **스택**: Swift / ReactorKit / RxSwift / Tuist (모듈화)
- **네트워킹**: Alamofire / RxAlamofire
- **UI**: UIKit + SnapKit + PinLayout/FlexLayout
- **모듈 구조**: Common / Feature / Service / Main App
- **최소 iOS**: 16.0

### 데이터

#### common-data-airflow
- **스택**: Python / Apache Airflow 2.x / CeleryExecutor
- **데이터 웨어하우스**: Google BigQuery
- **처리 단계**: staging → intermediate → mart → mart_integrated → report
- **대상 서비스**: HelloBot, StoryPlay, Between, ThingsFlow
- **알림**: Slack API, Notion API

## 환경

| 환경 | 용도 |
|------|------|
| dev | 개발/테스트 |
| staging | QA/프리프로덕션 (모바일) |
| prod | 운영 |

## 도메인

| 서비스 | 개발 | 운영 |
|--------|------|------|
| 웹/웹뷰 | dev.hellobot.co | hellobot.co |
| 리포트 | report.dev.hellobot.co | report.hellobot.co |
| 스튜디오 | dev.hellobotstudio.com | hellobotstudio.com |
| 일본 웹 | dev-jp.hellobot.co | jp.hellobot.co |
| 일본 스튜디오 | dev-jp.hellobotstudio.com | jp.hellobotstudio.com |
