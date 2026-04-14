# 개발 상태

## 현재 상태: 개발중

## 워크트리/브랜치 현황

| 파트 | 리포 | 브랜치 | 워크트리 | PR |
|------|------|--------|---------|-----|
| 서버 | hellobot-server | feat/coupnc-integration | worktrees/hellobot-server/ | - |
| iOS | hellobot_iOS | - | - | - |
| Android | hellobot_android | - | - | - |
| 웹 | hellobot-web | feat/coop-integration | worktrees/hellobot-web/ | - |

## 파트별 진행 상태

| 파트 | 상태 | 담당 | 상세 기록 |
|------|------|------|----------|
| 기획 | 진행중 | - | [planning/kakao_coupon_product/](./planning/kakao_coupon_product/) |
| 서버 | 개발완료 (정산 통계 제외) | /dev-server | [worktrees/hellobot-server/docs/features/.../status.md](./worktrees/hellobot-server/docs/features/20260324-coupc-marketing-kakao-gift/status.md) |
| iOS | 대기 | /dev-ios | - |
| Android | 대기 | /dev-android | - |
| 웹 | 개발완료 | /dev-web | [worktrees/hellobot-web/docs/features/.../status.md](./worktrees/hellobot-web/docs/features/20260324-coupc-marketing-kakao-gift/status.md) |
| 스튜디오 | 해당없음 | - | - |
| 데이터 | 해당없음 | - | - |
| QA | 검수대기 | /qa | qa-test-cases.md 작성 완료 (74건), 검수 미수행 |

> 각 파트의 구현 상세 및 작업 로그는 리포 레벨 status.md에 기록합니다.
> 이 문서에는 프로젝트 전체 요약과 파트 간 조율 사항만 기록합니다.

## 파트별 요약

| 파트 | 진행 요약 |
|------|----------|
| 기획 | 카카오 선물하기 상품 정의 진행중. 스킬 목록 분류, 하트 가격 현황 정리, 하트 상품 가격 초안 완료. 잔여: 스킬 이용권 라인업 선정, 최종 상품 구성 확정. |
| 서버 | 핵심 기능 + 이슈 6건(ISS-001~006) 모두 해결. 잔여: Admin 정산 통계 custom page. |
| 웹 | 구현 + 디자인 반영 + 이슈 2건(ISS-002, ISS-003) 해결 완료. 잔여: 웹뷰 환경 검증, 일본어 번역 검수. |
| iOS | 대기. api-spec.md, client-guide.md 준비 완료. |
| Android | 대기. api-spec.md, client-guide.md 준비 완료. |

## 확정 사항

| 항목 | 상태 | 내용 |
|------|------|------|
| 상용 인증키 (Auth_Key) | 확정 | 개발/상용 동일 |
| 쿠폰번호 프리픽스 | 확정 | 90, 91 |

## 블로커

현재 없음.

## 작업 로그

### 2026-04-15 — ISS-007 웹 구현 완료

- ISS-002에서 `goToLogin()` 직접 호출로 구현된 미로그인 처리를 Figma 디자인대로 팝업 방식으로 변경
- `coopLoginGuidePopup.tsx` 신규 생성: 경고 아이콘, 안내 문구, "로그인하기"/"다음에 할래요" 버튼
- `couponCodeRegister.tsx`: `handleInputFocus`에서 `goToLogin()` → `setShowLoginGuide(true)` 변경
- 에셋 추가: `icon_warning_24.svg` (빨간 원형 느낌표)
- 번역 키 4건 추가 (ko/en/ja): `coop_login_guide_title`, `_message`, `_button`, `_dismiss`
- 리뷰 반영: dim 클릭 닫기 차단 (`closeModal={undefined}`), 불필요한 `inputRef` 제거
- 1회 노출 제한: sessionStorage로 dismissed 상태 관리 — "다음에 할래요" 클릭 시 세션 내 재노출 안 함

### 2026-04-14 — ISS-006 서버 구현 완료

- CM_PAYMENT_CANCELED_COUPON(CM_010) 에러코드 추가 (code.ts)
- 한국어 메시지 "결제가 취소된 쿠폰입니다" (ko.ts), ja/en은 빈 문자열 (추후 번역)
- check API + useCoupon L0 재검증 모두에 8099 → CM_010 매핑 추가

### 2026-04-14 — ISS-003/004/005 서버 구현 완료

- ISS-003: check API 응답에서 expiryDate 필드 제거 (DTO + Service heart/skill 응답)
- ISS-004: useCoupon L0 재검증 에러코드 세분화 — UseYN→CM_003, 8003→CM_002, 8005→CM_003 (check와 동일)
- ISS-005: admin locale cancel "사용취소" → "사용 취소" 띄어쓰기 통일

### 2026-04-14 — ISS-003 웹 구현 완료

- 하트 충전 완료 팝업: expiryDate prop 및 유효기간 표시 제거, formatExpiryForDisplay 함수 삭제
- 스킬 이용권 카드: expiryDate 만료일/남은 일수 표시 제거, parseExpiryDate/formatExpiryDate 함수 삭제
- couponCodeRegister: expiryDate 전달 체인 제거 (savedExpiryDate, CoopPopupState, onSkillVoucherIssued)
- types/coop.ts: CoopSkillVoucher에서 expiryDate 필드 제거
- 번역 키 coop_heart_complete_expiry 제거 (ko/en/ja)
- (서버 expiryDate 제거는 ISS-003 서버 구현에서 완료)

### 2026-04-14 — ISS-002 웹 구현 완료

- `couponCodeRegister.tsx`에 미로그인(anonymous) 체크 추가
- 입력창 포커스 시: blur + `goToLogin('?fallbackUrl=/coupon')` 호출 (입력 자체를 차단)
- 기존 `LoginGuideBadge`와 동일한 `goToLogin` 패턴 사용

### 2026-04-14 — ISS-001 구현 완료

- **방안 확정**: UPSERT + 처리 순서 변경 + Admin 수동 취소 상품 회수
- **requirements.md**: F4 업데이트 (F4-1 자동 취소, F4-2 Admin 수동 취소 분리)
- **design.md**: §5-2~§5-5 업데이트 (UPSERT 우선, 자동 복구 명시, Admin 취소 추가)
- **서버 구현**:
  - `HeartLog.ts`: `UseByGiftCouponRecovery` 타입 추가
  - `coupc-marketing.ts`: `upsertUsage()` 메서드 추가, processHeartCoupon/processSkillCoupon 순서 변경, `adminCancelCoupon()` + `getAdminCancelInfo()` 메서드 추가
  - `CoupcMarketingCouponUsage.options.ts`: cancel handler → adminCancelCoupon 호출, before hook으로 guard 정보 조회

### 2026-04-14 — /review 코드 리뷰 → ISS-004, ISS-005 등록

- 리뷰 대상: hellobot-server 워크트리 변경분 (에러 메시지 매핑, Admin 라벨, description 접두사 제거)
- ISS-004: useCoupon L0 재검증 에러코드가 check와 불일치 (P2)
- ISS-005: admin locale 띄어쓰기 불일치 unuse/cancel (P3)
- 다음: 각 이슈 해결 방안 논의 필요

### 2026-04-14 — ISS-003 등록

- 발견: 사용 완료 모달에 쿠폰 유효기간(EndDay)이 교환 상품의 유효기간으로 오인되어 표시됨
- EndDay는 쿠폰 사용 기한이며, 교환된 상품(하트/이용권)에는 유효기간 없음
- 영향 파트: 서버(check API expiryDate 제거 검토), 웹/iOS/Android(모달 표시 제거), 디자인
- 다음: 해결 방안 논의 필요

### 2026-04-14 — ISS-002 등록

- 발견: 미로그인 상태에서 쿠폰 입력창/등록 버튼에 로그인 체크 없음 → 401 에러가 토스트로 표시
- 원인: couponCodeRegister.tsx에 anonymous 체크 누락, 설계 문서의 "로그인 후만 접근 가능" 전제가 실제와 다름
- 다음: 해결 방안 논의 필요

### 2026-04-13 — ISS-001 등록

- 발견: 쿠폰 취소(L2) 후 재사용 시 usage 유니크 제약 위반 → CM_007 에러 + 하트 누수
- 원인: usage DELETE 없이 status UPDATE만, chargeHeart가 별도 트랜잭션이라 롤백 안됨
- 취소 로직(cancelCoupon)도 함께 검토 필요 (하트/쿠폰 원복 미처리)
- 다음: 해결 방안 논의 필요

### 2026-04-13 — 카카오 선물하기 상품 기획

- 스킬 목록 데이터 취합: 카테고리별 스킬 목록 CSV + 가격/노출 정보 CSV Left Join
- 스킬 목록 topic/intent별 분류: xlsx 멀티시트 생성 (19개 시트, 노출 스킬 3,319건)
- 하트 상품 현행 가격 정리: 앱/웹 전 상품 단가 비교 (heart_pricing_asis.md)
- 카카오 선물하기 하트 상품 가격 초안: 5천/1만/3만/5만원 4종, 웹 단가 커브 기준 (kakao_gift_heart_pricing_draft.md)
- 다음: 스킬 이용권 상품 라인업 선정

### 2026-04-13 — /qa QA 테스트 케이스 작성

- qa-test-cases.md 작성 완료 (74개 케이스)
- P1 41건, P2 27건, P3 6건
- 범위: 기능 테스트(하트/스킬), 에러/예외, UI/디자인, 서버 API, Admin, 크로스 파트, 다국어, 보안, 웹뷰
- 테스트 데이터: 쿠프마케팅 제공 테스트 쿠폰번호 10개 포함

### 2026-04-13 — 웹 파트 Figma 디자인 반영

- Figma 확정 디자인 비교 후 전면 수정
- 팝업 3종 재설계: 크기(288px), 스타일(rounded-20, shadow), 아이콘(SVG), 노란 버튼, 텍스트 갱신
- 이용권 카드: 보라색 → 기존 쿠폰 카드 형식 (이용권 태그, 100%, 만료일, 스킬 보러가기)
- 에러 표시: 팝업 → 토스트 변경, coopErrorPopup.tsx 삭제
- 이미지 에셋 3종 추가 (icon_heart_24.svg, icon_coupon_24.svg, img_heart_complete.png)
- 번역 키 갱신 (ko/en/ja)

### 2026-04-13 — 웹 파트 1차 구현 + 리뷰

- 웹 파트 구현: 타입, API 훅, 팝업 4종, 이용권 카드, CouponCodeRegister 통합, 번역 키
- 코드 리뷰 5건 수정: use API 에러 처리, 등록 버튼 중복 방지, S2 취소 비활성화, 이용권 카드 스타일, 타입 통합
- 잔여: 웹뷰 환경 검증, 일본어 번역 검수

### 2026-04-12 — 프로젝트 구조 정비

- 2레벨 문서 추적 도입 (프로젝트 요약 + 리포별 상세)
- hellobot-web 피쳐 문서 생성 (web-guide.md, status.md)
- 쿠폰번호 프리픽스 확정 (90, 91), 인증키 확정 (개발/상용 동일)
- api-spec.md, client-guide.md 작성 완료 → 클라이언트 착수 가능

### 2026-04-12 — 워크스페이스 프로젝트 세팅

기존 hellobot-server의 feat/coupnc-integration 브랜치에서 진행 중이던 프로젝트를 워크스페이스 프로젝트로 등록.

### 2026-03-24 ~ 2026-04-09 — 서버 개발

서버 상세 로그: worktrees/hellobot-server/docs/features/20260324-coupc-marketing-kakao-gift/status.md
