# 과업 목록

## 디자인 (/design)
- [x] design-spec.md 작성 (기존 designs/ 스펙 + Figma 추출 통합)
- [x] designs/designs.md 경량화 (입력 문서로 정리)

## 기획 (planning/)

### 카카오 선물하기 상품 정의 (planning/kakao_coupon_product/)
- [x] 스킬 목록 데이터 취합 (카테고리별 스킬 목록 + 가격/노출 정보 조인)
- [x] 스킬 목록 topic/intent별 분류 (xlsx 멀티시트 생성)
- [x] 현행 하트 상품 가격 정리 (앱/웹 플랫폼별 단가 비교)
- [x] 카카오 선물하기 하트 상품 가격 초안 (5천/1만/3만/5만원, 웹 단가 기준)
- [ ] 카카오 선물하기 스킬 이용권 상품 라인업 선정
- [ ] 최종 상품 구성 확정

## 서버 (/dev-server)
- [x] 요구사항 정의 및 기존 시스템 검토
- [x] 백엔드 설계 (테이블, API, 처리 로직)
- [x] 사용자 스토리 및 화면 기획서
- [x] Entity 3개 + Migration (CoupcMarketingProduct, CouponUsage, ApiLog)
- [x] HeartLogType.ChargeByGiftCoupon + config + ErrorCode
- [x] DTO + Service (API 호출, check, use, cancel, networkCancel)
- [x] Controller (POST /api/coupc-marketing/check, /use)
- [x] Admin 페이지 (상품 관리 + 스킬 이용권 자동 생성, 사용 이력, API 로그)
- [x] API 테스트 (필수 동작 + 전체 테스트)
- [x] ISS-021: 스킬 이용권 발급 시 유효기간 무제한 설정 — `calculateCouponExpiresAt` Date|null 반환 + `findUsableCoupon(s)` NULL 허용 + Coop skill spec `usableDays = null` + `CouponDto.expiresAt: Date | null`. 기 발급분(dev)은 1회성 수동 SQL로 보정
- [ ] Admin 정산 통계 custom page
- [x] ISS-001: useCoupon 처리 순서 변경 — usage UPSERT 우선 + chargeHeart/issueCoupon 후속
- [x] ISS-001: Admin 수동 취소 시 상품 회수 (하트 차감 + 회수 로그, 이용권 삭제)
- [x] ISS-001: architecture.md §5-2, §5-3, §5-4, §5-5 변경 반영
- [x] 명칭 변경: coupc-marketing → coop-marketing (파일명, 클래스명, 설정키 등. DB 테이블명은 유지)
- [x] ISS-003: check API 응답에서 expiryDate 필드 제거 (DTO + Service)
- [x] ISS-004: useCoupon L0 재검증 에러코드를 check와 동일하게 세분화 (8003→CM_002, 8005→CM_003, UseYN→CM_003)
- [x] ISS-005: admin locale 띄어쓰기 통일 — cancel "사용취소" → "사용 취소"
- [x] ISS-006: 결제취소 쿠폰(8099) → CM_010 "결제가 취소된 쿠폰입니다" 에러코드 추가
- [x] ISS-008: Admin 쿠폰 사용 취소 팝업에 상품 상태 정보 표시 (커스텀 컴포넌트 + custom API)
- [x] api-spec.md 작성 (클라이언트용 API 명세)
- [x] client-guide.md 작성 (클라이언트 개발 가이드)
- [x] ISS-010: CouponDto에 fixedMenuSeq optional 필드 추가 (/api/coupon 응답) — 단일 skillSeqs 보유 쿠폰에 한해 노출

## iOS (/dev-ios)
- [x] 쿠폰 등록 화면에 상품권 코드 판별 로직 연동
- [x] 하트 충전권 확인 팝업 (S2-A) + 충전 완료 팝업 (S3)
- [x] 스킬 교환권 확인 팝업 (S2-B) + 토스트 + 이용권 카드 (S4)
- [x] 에러 토스트 (S5) — 만료/사용완료/미존재 등
- [ ] 카카오 딥링크 진입 처리
- [x] 프로필 탭 이동 (S3 완료 후)
- [x] ISS-010: 이용권 카드 탭 → 스킬 상세 페이지 이동 (Coupon/CouponModel 필드 추가 + CouponListViewController adapter.rx.touch 바인딩, 2026-04-18)
- [x] 미로그인 시 로그인 안내 배너 + 입력 시도 시 로그인 화면 직접 이동 + 로그인 후 쿠폰 페이지 복귀 (S6)
- [x] ISS-019: 스킬 이용권 카드에 "스킬 보러가기 >" 링크 텍스트 추가 — CouponItemCell violet400 12px Bold (2026-04-21)
- [x] ISS-021 클라이언트 대응: `Coupon.expiresAt: Date?` nullable 전환 — 쿠폰 리스트 디코딩 실패 방지 + 만료일 행 nil 가드 + remainDays Int.max fallback (2026-04-21)

## Android (/dev-android)
- [x] 쿠폰 등록 화면에 상품권 코드 판별 로직 연동
- [x] 하트 충전권 확인 팝업 (S2-A) + 충전 완료 팝업 (S3)
- [x] 스킬 교환권 확인 팝업 (S2-B) + 토스트 + 이용권 카드 (S4)
- [x] 에러 토스트 (S5) — 만료/사용완료/미존재 등
- [ ] 카카오 딥링크 진입 처리 (스킴 미확정 — 기존 COUPON 딥링크 재사용)
- [x] 프로필 탭 이동 (S3 완료 후) / 스킬 상세 페이지 이동
- [x] 미로그인 시 로그인 안내 배너 + 입력 시도 시 로그인 화면 직접 이동 + 로그인 후 쿠폰 페이지 복귀 (S6)
- [x] ISS-010: 이용권 카드 탭 → 스킬 상세 페이지 이동 (CouponData.fixedMenuSeq 추가 + 카드 onClick 핸들러)
- [ ] ISS-019: 스킬 이용권 카드에 "스킬 보러가기 >" 링크 텍스트 추가 (12px Bold, #BE7AFE SUB PURPLE)
- [ ] ISS-020: 스킬 이용권 등록 후 스킬 팝업 즉시 노출 제거 → 토스트 + 리스트 업데이트 방식으로 수정

## 웹 (/dev-web)
- [x] 쿠폰 등록 UI에 상품권 코드 처리 연동
- [x] 하트 충전 / 스킬 교환 결과 화면
- [x] ISS-002: 미로그인 상태에서 쿠폰 입력/등록 시 로그인 안내 처리 (입력 포커스+등록 버튼에서 goToLogin)
- [x] ISS-003: 완료 모달/이용권 카드에서 유효기간 표시 제거
- [x] ISS-007: 미로그인 시 입력 포커스 → 로그인 안내 팝업 표시 (goToLogin 직접 호출 → Figma 디자인 팝업으로 변경)
- [x] 미로그인 시 쿠폰 입력창 포커스 → 로그인 화면 직접 이동 + 로그인 후 쿠폰 페이지 복귀 (S6 팝업 → 직접 리다이렉트로 기획 변경)
- [x] S3 하트 충전 완료 → 프로필 탭(/user) 이동으로 변경 (design-spec 정합성)
- [x] ISS-010: Coupon 타입에 `fixedMenuSeq?: number` optional 필드 추가 (hellobot-web `types/coupon.ts`. hellobot-webview는 `/api/coupon` 미사용으로 영향 없음. UI 동작 변경 없음)

### Phase 1 — ISS-011/ISS-009 (신규 단일 진입점 `/api/coupon/register` 전환, 2026-04-19)
- [x] `couponCodeRegister.tsx` 프리픽스 분기 제거 (`COOP_PREFIXES`, `isCoopCouponCode`, `handleCoopCheck`, `handleCoopUse` 삭제)
- [x] 신규 hook `usePostCouponRegister` 추가 (`POST /api/coupon/register`), 기존 `usePostCoopCheck`/`usePostCoopUse` 호출 제거
- [x] `usePostCoupon` hook 파일 유지 — 배너 클레임 등 `couponSpecSeq` 경로용 (현재 워크트리에서는 호출자 없음)
- [x] 컴포넌트 삭제: `coopHeartConfirmPopup.tsx`, `coopSkillConfirmPopup.tsx` (1단계 원샷 — 확인 팝업 불필요)
- [x] 타입 정리: `CoopCheckResponse`/`CoopUseResponse`/`CoopUseHeartResponse`/`CoopUseSkillResponse` 제거 → `CouponRegisterResponse` discriminated union 신설 (`types/coop.ts`)
- [x] 응답 `issuedType` 기반 UI 분기 — `coupon` → 리스트 갱신, `heart` → S3 완료 팝업, `skill` → 토스트 + 카드 + 쿠폰 수 +1
- [x] 번역 키 정리: 확인 팝업 관련 키 9개(`coop_heart_confirm_*`, `coop_skill_confirm_*`, `coop_button_*`) 제거 — ko/ja/en
- [x] 일본어 번역 검수 — 잔존 키(complete/toast/voucher) 자연스러움 확인 완료
- [x] ISS-017: 일반 쿠폰 등록 완료 후 리스트 즉시 반영되지 않는 버그 — 원인(page.tsx 렌더링이 SWR 캐시 직접 사용) 확인 후 `useSWRConfig.mutate('/api/coupon')` 호출 추가 (coupon 분기만; skill 분기는 중복 노출 방지로 제외)
- [ ] 웹뷰 환경 검증 (모바일 앱 내 WebView에서 동작 확인)

## 스튜디오 (/dev-studio)
해당없음

## 데이터 (/dev-data)
해당없음 (추후 정산 데이터 파이프라인 필요 시 추가)

## Phase 1 — ISS-011 + ISS-009 해결 (2026-04-19 설계 확정)

> 설계 근거: architecture.md §3/§5, api-spec.md `POST /api/coupon/register`, client-guide.md
> 해결 이슈: ISS-011(프리픽스 판별 주체 통일), ISS-009(구버전 앱 대응), ISS-013(CM_005 문구 통일), ISS-014(S3 팝업 문서 정합성)

### 서버 (/dev-server)
- [x] `CouponPrefixRule` 엔티티 생성 (src/models/entities/CouponPrefixRule.ts) + 마이그레이션 `CreateCouponPrefixRule1776948000000` + 시드 데이터 (90, 91 / coop_marketing). 시드 INSERT는 `thingsflow.` 스키마 prefix 포함 Raw SQL로 작성
- [x] AdminJS에 `CouponPrefixRule` 관리 페이지 추가 (CRUD, SIDEBAR.COOP_MARKETING)
- [x] `ErrorCode.CO_APP_UPDATE_REQUIRED` 추가 + i18n ko 메시지 — "앱 업데이트가 필요한 쿠폰이에요." (ja/en은 번역 검수 잔여 — 빈 문자열 placeholder)
- [x] `POST /api/coupon/register` 컨트롤러 구현 (src/controllers/coupon.ts에 추가)
- [x] `CouponRegisterService` 신설 — prefix 분류 → coop/일반 분기 → 원샷 처리
- [x] Coop 원샷 처리: `CoopMarketingService.registerOneShot` — `checkCoupon` + `useCoupon` 재사용, Redlock(`locks:coop:${code}`) 보상 완료 후 해제 (ISS-015 동시 해소)
- [x] 폴리모픽 응답 DTO: `CouponRegisterResponseDto` — `resultType: "ISSUED"`/`issuedType: "coupon"|"heart"|"skill"` + `data` 내부 nested 필드 (issuedCoupon 포함)
- [x] `POST /api/coupon` 진입 가드 추가 — `code`가 비어있지 않은 문자열일 때만 `CouponPrefixRule` 조회 후 requiresNewFlow=true 매칭 시 HTTP 406 `CO_APP_UPDATE_REQUIRED` throw. `couponSpecSeq` 경로 영향 없음
- [x] 가드 발동 로그에 `code` 마스킹 처리 (`CoopMarketingService.maskCouponCode` 재사용)
- [x] `POST /api/coop/check`, `POST /api/coop/use` Deprecated 주석 (@deprecated JSDoc, Phase 2 제거 조건 명시). 기존 응답 스키마 유지
- [ ] 로그/메트릭: 가드 발동(프리픽스, 앱버전, userSeq), register resultType별 카운트 — winston.info 기본 로그만 추가됨, 메트릭은 별도 인프라 작업 필요
- [ ] API 테스트 추가 (일반/하트/스킬/에러/구버전 가드/couponSpecSeq 경로 무영향)

### iOS (/dev-ios)
- [x] `CouponListViewController.swift:156-161` 프리픽스 if문 + `checkCoopCoupon` 메서드 삭제 (2026-04-19)
- [x] 신규 `CouponRegisterRequestBuilder` + `CouponRegisterResponse` 추가 — `POST /api/coupon/register` 호출 (2026-04-19)
- [x] 응답 `resultType`/`issuedType` 분기 — coupon/heart/skill (2026-04-19)
- [x] S2 확인 팝업 컴포넌트 삭제 (CoopConfirmPopupView/VC) + Coop check/use RequestBuilder & Response 삭제 (2026-04-19)
- [x] 에러 처리는 기존 ReasonServerError 토스트 로직 재사용 (2026-04-19)
- [x] ISS-018: S3 하트 완료 팝업 이미지 노출 수정 — `UIImage(named: "_Coop/img_heart_complete")` 네임스페이스 반영 (2026-04-19)
- [x] ISS-018: S3 확인 버튼 프로필 탭 이동 수정 — onConfirm handler를 strong 캡처 후 dismiss completion에서 호출 (2026-04-19)
- [x] ISS-019: 스킬 이용권 카드에 "스킬 보러가기 >" 링크 라벨 추가 — CouponItemCell에 violet400 12px Bold 라벨 추가, `fixedMenuSeq != nil`일 때만 노출 (2026-04-21)
- [ ] QA 시나리오 대응 (Phase 1 배포 후)

### Android (/dev-android)
- [x] `CouponListViewModel.kt:114-123` 프리픽스 분기 + `isCoopCouponCode`/`coopCheck`/`coopUse` 메서드 삭제
- [x] `CoopRepository.register(code)` 신규 메서드 추가 — `POST /api/coupon/register` 호출
- [x] `CoopEvent.ShowHeartConfirm`/`ShowSkillConfirm` 이벤트 제거, Heart/Skill Confirm Dialog 컴포넌트 제거
- [x] 응답 `resultType`/`issuedType` 기반 UI 분기
- [x] 에러 처리는 기존 `extractServerMessage` 토스트 로직 재사용 (신규 에러 포맷 { error: { code, message } } 대응 추가)
- [ ] QA 시나리오 대응

### 웹 (/dev-web)
> ✅ Phase 1 웹 과업은 상단 "## 웹 (/dev-web)" 섹션의 "Phase 1" 서브섹션에서 관리 (중복 방지)

### 웹뷰 (/dev-web, hellobot-webview/hellobot-report-webview)
- [x] 영향 없음 확인 (2026-04-19) — 두 리포 모두 `/api/coupon`, `/api/coop/*` 호출 경로 없음. Phase 1에서 수정 대상 아님

### 디자인 (/design)
- [x] design-spec.md §S2 섹션 취소선 처리 + 제거 사유 명시 (2026-04-19 /architect 반영)
- [x] design-spec.md 상단에 Figma 폐기 프레임 경고문 추가 (2026-04-19 /review 반영)
- [ ] Figma 파일의 S2 프레임(`23:4064`, `23:4095`)에 `@Deprecated` 표기 또는 별도 섹션으로 이동 (선택, 권장)

### QA (/qa)
- [x] qa-test-cases.md 상단에 Phase 1 재작성 고지 + 재작성/폐기 대상 TC 분류 추가 (/workspace 2026-04-19)
- [x] §Phase1-신규 섹션 17건 신규 TC 골격 추가 (P1-R01~R05 register 기본 동작, P1-G01~G03 가드, P1-E01~E03 에러 토스트, P1-A01~A04 Admin CRUD, P1-C01~C02 구버전 회귀) (/workspace 2026-04-19)
- [x] 기존 191건 TC 순회하여 [Phase1 폐기]/[Phase1 재작성] 마커 부착 (폐기 27, 재작성 36, Deprecated 15, 재사용 113) (/qa 2026-04-19)
- [x] Phase1-신규 17건 상세 스펙 완성 (사전조건/테스트 단계/기대 결과 + 회귀 영향 + 검증 도구) (/qa 2026-04-20)
- [x] xlsx v4 재생성 (2 시트 분리: Phase 1 신규 17건 + Phase 0 기존 191건, 마커 컬럼 추가, 색상 범례) (/qa 2026-04-20)
- [x] 플랫폼별 재편성 — 폐기 63건 제거, Web 44 / iOS 20 / Android 20 / Admin·Server 47 구조로 재구성 + TC ID 체계 변경 (TC-W-*, TC-I-*, TC-A-*) (/qa 2026-04-20)
- [x] xlsx v5 생성 (5 시트: Web, iOS, Android, Admin·Server, 요약 + 색상 코딩 강화) (/qa 2026-04-20)
- [ ] Phase 1 서버 배포 후 P1-R01~R05 검증
- [ ] Phase 1 클라이언트 배포 후 P1-E01, P1-C01/C02 (구버전 회귀) 검증
- [ ] 동시성 시나리오: P1-R05 (Redlock + usage UNIQUE)
- [ ] 에러 시나리오: CM_001~CM_010 각 에러별 토스트 메시지 검증 (기존 TC 재활용)
- [ ] Admin CRUD: P1-A01~A04 실행

## Phase 2 — 후속 (별도 릴리스)

### 제거 착수 조건 (architecture.md §9 참조)
- Phase 1 배포 후 최소 4주 경과
- 최근 2주간 `/api/coop/*` 호출률 ≤ 0.1%
- 구버전(Phase 1 이전 빌드) 사용자 비율 ≤ 5%

### 서버
- [ ] `POST /api/coop/check`, `POST /api/coop/use` 엔드포인트 제거
- [ ] 관련 deprecated controller/service/dto 정리

## 리뷰 발견 이슈 (2026-04-18 /review) — 이번 Phase에서 동시 해소

### 계약 문서 정합성 (architect)
- [x] ISS-011: 프리픽스 판별 주체 통일 — 서버 단일 진입점으로 해결 (2026-04-19)
- [x] ISS-012: api-spec.md 에러코드 표 + client-guide.md 에러 매핑표에 CM_010 포함 확인 완료 (2026-04-19 /review 반영) — 양쪽 모두 CM_010 "결제가 취소된 쿠폰이에요" 기술됨
- [x] ISS-013: CM_005 사용자 메시지 통일 — "일시적인 서비스 오류가 발생했어요"로 확정, 양쪽 동기화 완료 (2026-04-19)

### 기획 문서 정합성 (analyze)
- [x] ISS-014: screen-plan.md S3 완료 팝업 기술을 design-spec 확정본 기준으로 갱신 — screen-plan.md §3 S3 재작성 완료 (2026-04-19)

### 서버 (dev-server)
- [ ] ISS-015: Redlock 미구현 해소 — `POST /api/coupon/register` 구현 시 Coop 원샷 처리에 Redlock 필수 적용으로 통합 해소 (위 Phase 1 서버 과업에 포함)

### 클라이언트 (dev-web, dev-android)
- [ ] ISS-016 (web): 에러 토스트 지속시간 2.5초 적용 — components/toast.tsx:5 DURATION_TIME 또는 coop 영역 전용 설정. Phase 1 재작업과 함께 처리 권장
- [ ] ISS-016 (android): 에러 토스트 지속시간 2.5초 적용 — CouponListActivity.kt:148,164 커스텀 타이머/SafeToast 설정 확인. Phase 1 재작업과 함께 처리 권장

## 의존 관계

### 완료된 선행 조건
- ~~서버 api-spec.md 작성 완료 → iOS, Android, Web 착수 가능~~ ✅ 완료
- ~~쿠프마케팅 상용 인증키 수령 → 프로덕션 배포 가능~~ ✅ 개발/상용 동일
- ~~쿠폰번호 프리픽스 확정 → 코드 판별 로직 최종 확정~~ ✅ 90, 91 확정 (DB 시드)
- ~~ISS-009 대응방안 확정 → 서버/클라이언트 추가 구현 범위 결정~~ ✅ 2026-04-19 확정
- ~~ISS-010 해결 (서버 CouponDto fixedMenuSeq 추가) → iOS/Android S4 스킬 상세 이동 구현 착수 가능~~ ✅ 전파트 완료

### Phase 1 배포 순서 (엄수)

**1. 서버 프로덕션 배포 선행** (엄수 필수)
- 신규 `/api/coupon/register` + 가드 + CouponPrefixRule + 시드 + 에러코드
- 기존 `/api/coop/*`는 deprecated 주석만, 동작 유지
- 헬스체크 + 스모크 테스트 통과 후 다음 단계

**2. 웹 배포** (서버 배포 완료 후)
- `/api/coupon/register` 호출 전환 + UI 정리

**3. iOS / Android 앱스토어 제출** (서버 배포 완료 후)
- 심사 완료 후 순차 릴리스

> **위험**: 클라이언트가 서버보다 먼저 배포되면 존재하지 않는 엔드포인트 호출로 기능 장애. 서버 선행 필수.
> **롤백 시**: 클라이언트를 서버보다 먼저 롤백해야 안전 (클라이언트가 신버전인데 서버가 구버전이면 기능 동작 불가)

### 기타 의존
- Phase 1 서버 `POST /api/coupon/register` 구현 완료 → 웹/iOS/Android 클라이언트 작업 착수 가능
- Phase 1 전파트 배포 완료 + §Phase 2 제거 착수 조건 충족 → Phase 2 착수 가능
- 서버 Admin 정산 통계 완료 → 운영 배포 가능 (Phase 1 블로커 아님)
