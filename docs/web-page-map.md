# 웹 페이지 매핑

헬로우봇 웹 프론트엔드는 3개 프로젝트가 페이지를 나눠 서빙합니다.
새 기능 개발이나 수정 시 **대상 페이지가 어느 프로젝트에 있는지** 이 문서에서 확인합니다.

> 이 문서는 개발 진행에 따라 지속 업데이트합니다.
> 마이그레이션이 완료되면 해당 행의 프로젝트를 변경해주세요.

## 도메인 구성

| 도메인 | 프로젝트 | 포트(dev) |
|--------|---------|-----------|
| hellobot.co | hellobot-webview (기본) + hellobot-web (일부 경로) | 4000 / 4500 |
| report.hellobot.co | hellobot-report-webview | 4400 |
| hellobotstudio.com | hellobot-studio-web | — |

Nginx가 URL 경로 기반으로 hellobot-webview / hellobot-web을 분기합니다.

---

## 페이지 매핑 (hellobot.co)

### hellobot-web (Next.js) — 마이그레이션 완료 페이지

| 경로 | 기능 | 비고 |
|------|------|------|
| `/features` | 피쳐 탐색/쇼케이스 | |
| `/features/skills` | 추천 스킬 목록 | |
| `/features/skills/:seq` | 추천 스킬 상세 | |
| `/features/skills/:seq/details` | 스킬 상세 정보 | |
| `/features/skills/:seq/question` | 스킬 질문 플로우 | |
| `/features/skills/:seq/result` | 스킬 결과 | |
| `/skills-new` | 스킬 목록 (신버전) | webview의 `/skills`에서 리다이렉트 |
| `/skills-new/:seq` | 스킬 상세 | |
| `/skills-new/:seq/reviews` | 스킬 리뷰 | |
| `/skills-new/reviews` | 전체 리뷰 | |
| `/skills-new/reviews/:reviewSeq` | 리뷰 상세 | |
| `/skills-new/test` | 스킬 테스트/샌드박스 | |
| `/daily-fortune` | 일일운세 | |
| `/daily-fortune/:seq` | 일일운세 상세 | |
| `/saju` | 사주 선택/목록 | |
| `/saju/:birthdaySeq` | 사주 결과 | |
| `/chatrooms-new` | 채팅방 목록 (신버전) | webview의 `/chatrooms`에서 리다이렉트 |
| `/chatrooms-new/:seq` | 채팅방 상세 | |
| `/payment` | 결제 | |
| `/payment/coupons` | 결제 쿠폰 | |
| `/coupon` | 쿠폰 관리 | |
| `/summary-reports/view` | 요약 리포트 보기 | |

### hellobot-webview (Angular SSR) — 기존 페이지

| 경로 | 기능 | 비고 |
|------|------|------|
| `/` | 홈/스토어 랜딩 | |
| `/store` | 스토어 메인 | |
| `/store/featured` | 추천 스킬 | |
| `/store/free` | 무료 스킬 | |
| `/store/feeds/reviews` | 스킬 피드 리뷰 | |
| `/login` | 로그인 | |
| `/join` | 회원가입 | |
| `/user` | 사용자 프로필/설정 | |
| `/user-info` | 사용자 정보 | |
| `/user-more-info` | 추가 사용자 정보 | |
| `/user-dormant` | 휴면 계정 | |
| `/skills` | 스킬 목록 (레거시) | `/skills-new`로 리다이렉트 (A/B) |
| `/skills/:skillSeq` | 스킬 상세 (레거시) | |
| `/skills/:skillSeq/reviews` | 스킬 리뷰 (레거시) | |
| `/chatrooms` | 채팅방 (레거시) | `/chatrooms-new`로 리다이렉트 (A/B) |
| `/chatrooms/:seq` | 채팅방 상세 (레거시) | |
| `/categories` | 스킬 카테고리 | |
| `/categories/:id` | 카테고리 상세 | |
| `/search` | 스킬 검색 | |
| `/reports` | 리포트 목록/보관함 | |
| `/reports/:reportId` | 리포트 상세 | |
| `/results` | 결과 페이지 | |
| `/relation-reports` | 궁합 리포트 | |
| `/relation-report-bridge` | 궁합 리포트 브릿지 | |
| `/summary-reports` | 요약 리포트 목록 | |
| `/purchase-inquiry` | 구매 문의 | |
| `/packages` | 패키지 정보 | |
| `/present` | 선물 관리 | |
| `/presents` | 선물 목록 | |
| `/aiprofile` | AI 프로필 | |
| `/coin` | 코인/재화 관리 | |
| `/birthday` | 생일 설정 | |
| `/language` | 언어 선택 | |
| `/offerwall` | 오퍼월 (리워드) | |
| `/mybot` | 마이봇/캐릭터 | |
| `/training` | 튜토리얼 | |
| `/notices` | 공지사항 | |
| `/faqs` | FAQ | |
| `/terms` | 이용약관 | |
| `/download` | 앱 다운로드 | |
| `/exhibition` | 스킬 전시 | |
| `/random-box` | 랜덤박스/가챠 | |
| `/events/*` | 이벤트 페이지들 | |

---

## 페이지 매핑 (report.hellobot.co)

### hellobot-report-webview (Next.js)

| 경로 | 기능 | 비고 |
|------|------|------|
| `/report/:purchasedReportSeq` | 구매 리포트 상세 | |
| `/summary-reports/:id` | 요약 리포트 | |
| `/relationreport/:reportSeq` | 궁합 리포트 상세 | |
| `/relationreport/start/:fixedMenuSeq` | 궁합 리포트 시작 | |
| `/relationreport/create/:fixedMenuSeq` | 궁합 리포트 생성 | |
| `/relationreport/permissionerror` | 권한 오류 | |
| `/exhibition/:exhibitionSeq` | 전시 상세 | |
| `/exhibition/promotion/:promotionSeq` | 프로모션 | |
| `/bridge/:bridgeSeq` | 브릿지 페이지 | 서비스 간 연결 |
| `/preview` | 프리뷰/테스트 | |

---

## 마이그레이션 현황

```
hellobot-webview (Angular) ──마이그레이션──▶ hellobot-web (Next.js)

완료:
  ✓ 스킬 목록/상세 (/skills → /skills-new)
  ✓ 채팅방 (/chatrooms → /chatrooms-new)
  ✓ 피쳐 탐색 (/features)
  ✓ 일일운세 (/daily-fortune)
  ✓ 사주 (/saju)
  ✓ 결제/쿠폰 (/payment, /coupon)

미완료 (webview에 남아있는 주요 페이지):
  · 홈/스토어 (/store)
  · 로그인/회원 (/login, /join, /user)
  · 카테고리/검색 (/categories, /search)
  · 리포트 보관함 (/reports)
  · 설정 관련 (/birthday, /language, /coin)
  · 이벤트 (/events)
  · 기타 유틸리티
```

## 참고: 라우팅 설정 파일 위치

| 프로젝트 | 라우팅 설정 파일 |
|---------|----------------|
| hellobot-webview | `src/app/app-routing.module.ts` |
| hellobot-web | `app/` 디렉토리 (Next.js App Router) |
| hellobot-report-webview | `src/app/` 디렉토리 (Next.js App Router) |
| Nginx (프록시) | `hellobot-webview/conf/nginx_prod.conf` |
