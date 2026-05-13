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
- [ ] 카카오 선물하기 스킬 이용권 상품 라인업 선정 — [planning/kakao_coupon_product/product-lineup.md §2](planning/kakao_coupon_product/product-lineup.md)
- [ ] 최종 상품 구성 확정 — product-lineup.md §1(하트)/§2(스킬) + [planning/product-code-scheme.md](planning/product-code-scheme.md) ProductCode 매핑 확정
- [ ] 쿠프마케팅 상품 등록·테스트 쿠폰 요청서 송부 — [planning/coop-request-form.md](planning/coop-request-form.md)

## 서버 (/dev-server)

### ISS-050 에러 코드 컨벤션 정합화 (2026-04-28 결정·구현)
- [x] `src/common/code.ts` — `CO_APP_UPDATE_REQUIRED` 항목 삭제, `CM_001~CM_010` enum value를 `CM001~CM010`로 변경, 의미 일치 enum 이름을 `CP` 접미사와 통일(`CM_INVALID_COUPON`→`CM_COUPON_NOT_FOUND`, `CM_EXPIRED_COUPON`→`CM_COUPON_EXPIRED`, `CM_ALREADY_USED_COUPON`→`CM_COUPON_ALREADY_USED`)
- [x] `src/locales/{ko,ja,en}.ts` — `CO_APP_UPDATE_REQUIRED` 키 삭제, `CM_001~010` 키 → `CM001~010`, ko 어미 "~이에요"→"~습니다" 정합화 + 의미 일치(CM001/002/003) ja/en은 CP 문구 그대로 채택
- [x] `src/controllers/coupon.ts` — `ErrorCode.CO_APP_UPDATE_REQUIRED` → `ErrorCode.UPDATE_APP`, 가드 winston 로그 텍스트 갱신
- [x] `src/services/coop-marketing.ts` — 변경된 enum 식별자 반영 (16개 호출부)
- [x] `src/services/coupon-register.ts` — `ErrorCode.CO_APP_UPDATE_REQUIRED` → `ErrorCode.UPDATE_APP`, JSDoc 주석 갱신
- [x] `CouponPrefixRule` Entity + 마이그레이션 코멘트 텍스트 갱신
- [x] tsc 통과 확인 (eslint `object` 타입 경고는 본 변경 범위 밖 — 2026-04-07 최초 구현분 잔존)

### Q1 거래액 인식 인젝션 (2026-04-27 결정, ISS-049)
- [x] **마이그레이션** — `coop_marketing_product` 에 `current_price INTEGER NULL` 컬럼 추가 (2026-04-28 /dev-server, `1777968000000-AddCurrentPriceToCoopMarketingProduct.ts` + Entity `currentPrice` 필드 + AdminJS 옵션 노출)
- [x] **카카오 쿠폰 식별 메커니즘** — `CoopMarketingService.findUsageByIssuedCouponSeq(issuedCouponSeq)` 추가 (2026-04-28 /dev-server). `coop_marketing_coupon_usage.issued_coupon_seq` 매칭으로 카카오 발급 여부 판별
- [x] **`pay_for_contents` 발화 시 `spent_cash_amount` 인젝션** — `purchaseFixedMenu` 의 `sendPayForContentsEvent` 호출 직전에 `resolveCoopSpentCash` 헬퍼로 `coop_marketing_product.current_price ?? price` 를 `{ amount, currency: "KRW" }` 로 전달 (2026-04-28 /dev-server, `src/services/fixed-menu.ts:2583`)
- [x] **인젝션 트리거 조건 검증** — 카카오 쿠폰(=`coop_marketing_coupon_usage` 매칭)이면 무조건 인젝션. 현재 카카오 쿠폰은 100% 할인뿐이므로 동일 효과. 부분 할인 카카오 쿠폰 도입 시 정책 재논의 필요 (architecture.md §10-2)
- [ ] **테스트 환경 검증** — 100% 할인 쿠폰 사용 후 BQ `analytics_164027297.server_events` 의 `pay_for_contents` 이벤트에 `spent_cash_amount` 가 채워졌는지 확인 (배포 후 실시)

### 기존 과업
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
- [x] ISS-022: ISS-021 호환성 위반 시정 — `CouponDto.expiresAt`을 다시 `Date`(non-null)로 복귀, NULL은 직렬화 시 sentinel `2099-12-31T23:59:59.000Z`로 변환, 신규 `CouponDto.isUnlimited?: boolean` 필드 추가(true면 무제한). `UNLIMITED_EXPIRES_AT_SENTINEL` 상수 정의. SkillCouponDto에도 동일 패턴 propagate. DB NULL 유지 + `findUsableCoupons` 쿼리 유지(현행). 클라이언트 분기 대기
- [ ] Admin 정산 통계 custom page
- [x] ISS-001: useCoupon 처리 순서 변경 — usage UPSERT 우선 + chargeHeart/issueCoupon 후속
- [x] ISS-001: Admin 수동 취소 시 상품 회수 (하트 차감 + 회수 로그, 이용권 삭제)
- [x] ISS-001: architecture.md §5-2, §5-3, §5-4, §5-5 변경 반영
- [x] 명칭 변경: coupc-marketing → coop-marketing (파일명, 클래스명, 설정키 등. DB 테이블명은 유지)
- [x] ISS-003: check API 응답에서 expiryDate 필드 제거 (DTO + Service)
- [x] ISS-004: useCoupon L0 재검증 에러코드를 check와 동일하게 세분화 (8003→CM002, 8005→CM003, UseYN→CM003)
- [x] ISS-005: admin locale 띄어쓰기 통일 — cancel "사용취소" → "사용 취소"
- [x] ISS-006: 결제취소 쿠폰(8099) → CM010 "결제가 취소된 쿠폰입니다" 에러코드 추가
- [x] ISS-008: Admin 쿠폰 사용 취소 팝업에 상품 상태 정보 표시 (커스텀 컴포넌트 + custom API)
- [x] api-spec.md 작성 (클라이언트용 API 명세)
- [x] client-guide.md 작성 (클라이언트 개발 가이드)
- [x] ISS-010: CouponDto에 fixedMenuSeq optional 필드 추가 (/api/coupon 응답) — 단일 skillSeqs 보유 쿠폰에 한해 노출
- [x] ISS-029: AdminJS 사이드바 `Coupon Prefix Rule` 메뉴명 한글화 ("쿠폰 분류 규칙 설정") — `src/admin/locale.ts` labels에 `CouponPrefixRule: "쿠폰 분류 규칙 설정"` 추가 (2026-04-22)

### Firebase 이벤트 응답 DTO 보강 (2026-04-29 결정, D1~D5)

> 결정 근거: [event-spec.md §5](event-spec.md) + [api-spec.md §Response](api-spec.md). 클라이언트 3사가 EVT-2 `register_coupon_success` 의 `coupon_type`/`product_code` 파라미터를 채울 수 있도록 응답 DTO 에 신규 필드 2개 추가. 에러 응답은 변경 없음 (D3=a). 4/30 데드라인 직전이라 최소 침습 보강.

- [x] **`couponType` 필드 추가 (모든 issuedType 공통)** — `CouponRegisterResponseDto` 의 모든 variant(coupon/heart/skill)에 `couponType: "kakao" | "hellobot" | "giftiel"` 항상 포함. 산출: 표준 쿠폰 경로(prefix 미매칭) → `"hellobot"`, coop_marketing 경로 → `"kakao"` 직접 매핑. giftiel 은 prefix rule 시드 도입 시 분기 추가 (현재 미시드 — D3=a 에러 응답 미보강이므로 영향 없음). (2026-04-29 /dev-server, `src/dtos/coupon-register.dto.ts` + `src/services/coupon-register.ts`)
- [x] **`productCode` 필드 추가 (issuedType=heart/skill 한정)** — 카카오 채널일 때 `coop_marketing_product.product_code` 노출. 매핑: `processHeartCoupon`/`processSkillCoupon` 의 product 객체에서 직접 추출하여 `UseCoopMarketingCouponResponseDto.productCode` 로 전파 → `buildCoopResponse` 가 `productCode ?? null` 직렬화. `findUsageByIssuedCouponSeq` 우회(인-플로우 product 객체 보유로 추가 쿼리 불필요). hellobot/giftiel 응답에는 필드 미포함(coupon variant). (2026-04-29 /dev-server, `src/services/coop-marketing.ts` + `src/dtos/coop-marketing.dto.ts`)
- [x] **`heartQuantity` 유지** — 변경 없음. paid 100% 적립 정책(Q2 결정) 상 bonus 분리 불필요. `bonusHeartAmount` 등 신규 필드 도입 안 함
- [x] **api-spec.md 정합 검증** — §Response 의 성공 예시 3건(coupon/heart/skill) + 필드 설명 표가 코드와 일치 (couponType: kakao/hellobot, productCode: HEART_5000/SKILL_VOUCHER_001 예시 동일)
- [x] **회귀 테스트** — 신규 필드는 모두 추가형(기존 필드 변경 X). 미사용 클라이언트는 JSON 미등록 필드를 자동 무시하므로 동작 영향 없음. 단위 테스트 TC-1 에서 명시적으로 productCode 미포함을 assert 함
- [x] **통합 테스트 (3 케이스)** — `src/tests/services/coupon-register.test.ts` 신규 (TC-1 표준 쿠폰=hellobot/productCode 미포함, TC-2 카카오 heart=kakao/HEART_5000, TC-3 카카오 skill=kakao/SKILL_VOUCHER_001, TC-4 productCode 누락 시 null 폴백). `npm run tsc` + `npx tsc -p tsconfig.jest.json` 통과 확인 (실행은 사용자가 `npm run test:jest:part src/tests/services/coupon-register.test.ts`)

### 운영 배포 준비 (2026-04-29)
- [x] 배포 가이드 환경변수 키 정합화 — `COUPC_MARKETING_AUTH_KEY` → `COOP_MARKETING_AUTH_KEY` 잔존 참조 6곳 일괄 갱신 (`backend-design.md`, `backend-guide.md` 4곳, `testing/20260409-api-test-plan.md`, `deployment/dev-deploy-guide.md` 2곳). 코드는 2026-04-14 커밋 `dc9af487`로 이미 정합화 완료, 잔재는 가이드 문서뿐
- [x] 운영 배포 가이드 신규 작성 — `docs/features/20260324-coupc-marketing-kakao-gift/deployment/prod-deploy-guide.md`. master 머지(회귀 회피), 사전 DB 진단(B-2/B-3), Secrets Manager 운영 등록(`COOP_MARKETING_AUTH_KEY`), 마이그레이션 4건 수동 실행, AdminJS 초기 데이터, 스모크 테스트, 모니터링, 롤백 시나리오, 체크리스트 16항목 포함
- [x] 설계 가이드 옛 표기(coupc/Coupc/COUPC_MARKETING) 잔재 일괄 정합화 — `backend-design.md` 약 60곳(DDL 테이블/컬럼/인덱스명, Entity/Service 클래스명, SIDEBAR 키, custom API path), `backend-guide.md` 약 60곳(Entity/DTO/Service/Controller 클래스·파일 경로, Service 내부 호출, Admin Options, config 키, 체크리스트). 마이그레이션 식별자 `CreateCoupcMarketing` (3곳, 실제 git 파일명 일치 필요) 보존
- [ ] 운영 배포 실행 — prod-deploy-guide.md 체크리스트 진행 (사용자 검토 후)

### 운영 핫픽스 #1 — coop-marketing api_log varchar(4) 위반 (2026-04-30, hotfix/coop-error-logging-issue, ISS-053)
- [x] `src/services/coop-marketing.ts` catch 3곳 (L0:154-164 / L1:312-334 / L3:677-686) — `saveApiLog({resultCode:"TIMEOUT",...})` 제거, `winston.error` 로 stack + masked couponCode + originalAuthCode + userSeq 기록. throw 의미 유지 (L0/L1: `CM_NETWORK_ERROR`, L3: throw 없음 — 보상 케이스). 마이그레이션·entity 변경 없음 (2026-04-30)
- [x] master PR #2401 → squash merge (commit `f2f12a84`) → 운영 ArgoCD sync 완료 (2026-04-30)
- [x] deploy-dev 동기화 — cherry-pick (commit `c5245d05`) 완료 (2026-04-30)
- [x] ISS-052 등록 (L1+L3 동시 실패 시 (나) 시나리오 자동 복구 불가 — CS 유의미 발생 시 구현) (2026-04-30)
- [x] ISS-053 등록 (해결 상태로 추적성 보장) (2026-04-30)

### 운영 핫픽스 #2 — coop-marketing 운영 URL 스킴 오류 (2026-04-30, hotfix/coop-marketing-url-scheme, ISS-054)
- [x] `src/common/config.ts:591` 운영 URL 스킴 수정 — `http://authapi.inumber.co.kr:443/AuthUse` → `https://authapi.inumber.co.kr/AuthUse`. dev URL (`http://test.authapi.inumber.co.kr:9999/AuthUse`) 무변경 (2026-04-30)
- [x] master PR #2403 → squash merge (commit `8372dadc`) → 운영 ArgoCD sync 완료 (2026-04-30)
- [x] ISS-054 등록 (해결 상태로 추적성 보장) (2026-04-30)
- [x] 운영 통신 정상 검증 — 사용자 로컬 curl 로 `https://authapi.inumber.co.kr/AuthUse` 호출 시 TLS 1.2 + HTTP/2 200 + 정상 ResultCode 응답 확인 (2026-04-30)
- [ ] deploy-dev 동기화 — cherry-pick (단순 코드 정합성, dev URL 변경 없어 동작 영향 없음, 우선순위 낮음)

### 운영 핫픽스 #3 — coop-marketing CompCode 환경변수화 (2026-05-05, hotfix/coop-marketing-comp-code-env, ISS-055)
- [x] `src/common/config.ts:594` `compCode: "A911"` → `compCode: process.env.COOP_MARKETING_COMP_CODE` (기본값 없음, 미설정 시 `undefined` → JSON 직렬화에서 누락되어 쿠프마케팅 측 인증 실패로 즉시 표면화) (2026-05-05)
- [x] tsc 통과 확인 (tsconfig strict 미적용 — 타입 호환성 영향 없음) (2026-05-05)
- [ ] EKS 매니페스트 환경변수 등록 — `/dev-infra` 협업, dev `COOP_MARKETING_COMP_CODE=A911` / prod `COOP_MARKETING_COMP_CODE=X259` 추가 (`common-infra-eks-deploy/overlays/hlb/{dev,prod}/[apn1]/api/`)
- [ ] 배포 순서 준수 — **인프라 매니페스트 머지·sync 선행 → 서버 코드 머지·배포 후행** (역순 시 운영에서 빈 CompCode 송신으로 전 쿠폰 등록 실패)
- [ ] master PR 생성·머지 → 운영 ArgoCD sync
- [ ] deploy-dev cherry-pick → dev ArgoCD sync
- [ ] dev/운영 통신 정상 검증 — 90/91 prefix 쿠폰 등록 → ResultCode `8001` 또는 정상 처리 확인

## iOS (/dev-ios)

### Firebase 이벤트 발화 (2026-04-29 완료)
- [x] `view_coupon_register` (EVT-1) — `CouponListViewController.viewDidLoad`에서 `fAnalytics.fire(.viewCouponRegister)` (2026-04-29 /dev-ios)
- [x] `register_coupon_success` (EVT-2) — `registerCoupon(code:)` onNext 핸들러에서 `coupon_number/coupon_type/issued_type/fixed_menu_seq/heart_amount/latency_ms` 발화 (2026-04-29 /dev-ios) — **2026-04-29 스펙 픽스 후 재조정 필요 (아래)**
- [x] `register_coupon_failure` (EVT-3) — `registerCoupon(code:)` onError 핸들러에서 `coupon_number/coupon_type/coupon_prefix/error_code/reason/latency_ms` 발화 (2026-04-29 /dev-ios)
- [x] `latency_ms` 측정 — `.do(onSubscribe:)` 시점에 `Date()` 캡처, 응답/에러 수신 ms 차이 (2026-04-29 /dev-ios)
- [x] ~~`coupon_type` 추론 규칙 — 성공: heart/skill ⇒ kakao, coupon ⇒ hellobot. 실패: prefix `90/91` ⇒ kakao, 그 외 nil~~ (2026-04-29 D1~D5 픽스로 성공 분기 추론 제거 → 응답 `data.couponType` 직접 매핑. 실패 분기는 prefix 룩업 유지)
- [ ] DebugView 실기기 발화 검증 (3종 모두) — `-FIRDebugEnabled` 런치 인자 + Firebase 콘솔 DebugView 대조 (배포·QA 단계)
- [x] **2026-04-29 D1~D5 스펙 픽스 반영** — ① `CouponRegisterResponse` 에 `couponType: String?` + `productCode: String?` 옵셔널 디코딩 추가(서버 보강 PR 머지 전에도 무해). ② `RegisterSuccessPayload.couponType`/`productCode` 응답 직접 매핑(EVT-2 `coupon_type` 추론 로직 제거, D1=a). ③ `RegisterSuccessPayload.heartAmount` → `heartQuantity` 리네임 + 발화 키 `heart_amount` → `heart_quantity` (값은 응답 `heartQuantity` 그대로). ④ `RegisterSuccessPayload.bonusHeartAmount` 필드/발화 키 제거 (D2=a). EVT-3 의 prefix 룩업은 유지(D3=a). 수정 파일: `Hellobot/Feature/Coupon/Network/CouponRegisterResponse.swift`, `Hellobot/Legacy/Analytics/Firebase/HellobotAnalytics + Coupon.swift`, `Hellobot/Feature/Coupon/CouponList/CouponListViewController.swift` (2026-04-29 /dev-ios)

### ISS-050 매퍼 동기 (2026-04-28 완료)
- [x] `Hellobot/Feature/Coupon/Network/CouponRegisterErrorMapper.swift:21-31` `codeMessages` 사전 키 11건 일괄 갱신: `CM_001~CM_010` → `CM001~CM010`, `CO_APP_UPDATE_REQUIRED` → `CO012` (2026-04-28 /dev-ios)
- [x] 매퍼 메시지 값 ko 어미 정합화: 어미 "~이에요"→"~습니다" + CM001/002/003은 일반 쿠폰 CP 시리즈 문구 그대로 채택, CO012는 "앱을 최신 버전으로 업데이트 해주세요" (2026-04-28 /dev-ios)
- [x] ISS-026/039 판정 로직(non-empty 서버 message 우선, 빈/offline 시 codeMessages 폴백) 유지 — 키·값만 교체, 다른 iOS 코드 변경 0건 확인 (2026-04-28 /dev-ios)
- [ ] 서버·iOS 동시 배포 후 회귀 확인 (배포 시점 도래 시 QA 매트릭스 검증)
- [ ] (선택) 단위 테스트 추가 — 키 변경 회귀 방지

### 기존 과업
- [x] 쿠폰 등록 화면에 상품권 코드 판별 로직 연동
- [x] 하트 충전권 확인 팝업 (S2-A) + 충전 완료 팝업 (S3)
- [x] 스킬 교환권 확인 팝업 (S2-B) + 토스트 + 이용권 카드 (S4)
- [x] 에러 토스트 (S5) — 만료/사용완료/미존재 등
- [ ] 카카오 딥링크 진입 처리
- [x] 프로필 탭 이동 (S3 완료 후)
- [x] ISS-010: 이용권 카드 탭 → 스킬 상세 페이지 이동 (Coupon/CouponModel 필드 추가 + CouponListViewController adapter.rx.touch 바인딩, 2026-04-18)
- [x] 미로그인 시 로그인 안내 배너 + 입력 시도 시 로그인 화면 직접 이동 + 로그인 후 쿠폰 페이지 복귀 (S6)
- [x] ISS-019: 스킬 이용권 카드에 "스킬 보러가기 >" 링크 텍스트 추가 — CouponItemCell violet400 12px Bold (2026-04-21)
- [x] ISS-023: 스킬 이용권 카드 하단 "스킬 보러가기 >" 링크를 **우측 정렬**로 수정 — CouponItemCell 하단을 row 레이아웃(좌측 grow wrapper + skillLinkLabel)으로 리팩토링 (2026-04-21)
- [x] ISS-021 클라이언트 대응: `Coupon.expiresAt: Date?` nullable 전환 — 쿠폰 리스트 디코딩 실패 방지 + 만료일 행 nil 가드 + remainDays Int.max fallback (2026-04-21)
- [x] ISS-022 클라이언트 대응: `Coupon.expiresAt: Date` (non-null) 복귀 + 신규 `isUnlimited: Bool?` 디코딩 추가 — 카드 UI 만료일/만료임박 행을 `coupon.isUnlimited == true`일 때 숨김 (sentinel 비교 금지). remainDays도 `isUnlimited` 기반 재작성 (2026-04-21)
- [x] ISS-026: 쿠폰 코드 등록 에러 메시지 표시 로직 수정 — `CouponRegisterErrorMapper` 신설, 서버 `error.message`(ko)에 Hangul 포함 시 그대로 사용하고 빈/영문/네트워크 오류는 client-guide.md S5 ko 상수(CM001~CM010, CO012)로 폴백, 오프라인은 "인터넷 연결이 오프라인 상태입니다." 고정 메시지로 치환 (2026-04-21)
- [x] ISS-027: S4 "스킬 보러가기 >" 우측 화살표를 이미지(아이콘) 리소스로 교체 — 텍스트 `>` 제거 + SF Symbol `chevron.right` (violet400 틴트) 이미지뷰 horizontal stack 구성 (2026-04-21)

## Android (/dev-android)
- [x] 쿠폰 등록 화면에 상품권 코드 판별 로직 연동
- [x] 하트 충전권 확인 팝업 (S2-A) + 충전 완료 팝업 (S3)
- [x] 스킬 교환권 확인 팝업 (S2-B) + 토스트 + 이용권 카드 (S4)
- [x] 에러 토스트 (S5) — 만료/사용완료/미존재 등
- [ ] 카카오 딥링크 진입 처리 (스킴 미확정 — 기존 COUPON 딥링크 재사용)
- [x] 프로필 탭 이동 (S3 완료 후) / 스킬 상세 페이지 이동
- [x] 미로그인 시 로그인 안내 배너 + 입력 시도 시 로그인 화면 직접 이동 + 로그인 후 쿠폰 페이지 복귀 (S6)
- [x] ISS-010: 이용권 카드 탭 → 스킬 상세 페이지 이동 (CouponData.fixedMenuSeq 추가 + 카드 onClick 핸들러)
- [x] ISS-019: 스킬 이용권 카드에 "스킬 보러가기 >" 링크 텍스트 추가 (12px Bold, #BE7AFE SUB PURPLE) — `CouponItem.kt` 카드 하단 우측 링크 (2026-04-21)
- [x] ISS-020: 스킬 이용권 등록 후 스킬 팝업 즉시 노출 제거 → 토스트 + 리스트 업데이트 방식으로 수정 — `CouponListActivity.SkillIssued` 분기에서 자동 SkillDescriptionBottomSheet 호출 제거 (2026-04-21)
- [x] ISS-016: Android 토스트 지속시간 2.5초 — `SafeToast.showToastForDurationMs(durationMs)` 신규 추가 (Toast.LENGTH_LONG + Handler.cancel best-effort) + `CouponListActivity` 토스트 3건(toastEvent/SkillIssued/ShowError) 모두 `COOP_TOAST_DURATION_MS=2500L`로 적용 (2026-04-21)
- [x] ISS-022 클라이언트 대응: `CouponData.expiresAt: Date` (non-null) + 신규 `isUnlimited: Boolean?` 디코딩 추가 — 카드 UI 만료일/만료임박 행을 `coupon.isUnlimited == true`일 때 숨김 (2026-04-21)
- [x] ISS-024: S4 카드 하단 "스킬 보러가기 >" 링크 우측 정렬 — `CouponItem.kt` 하단을 좌(유효기간/isUnlimited 분기)+우(링크) `space-between` Row로 재구성 (2026-04-21)
- [x] ISS-028: S3 하트충전완료 모달 디자인 정합성 — design-spec "공통 컴포넌트 팝업"(288dp / radius 20 / padding 24 / shadow `0 8 24 rgba(0,0,0,0.24)`) 준수. 외곽 `Box(fillMaxSize, Center)` + 카드 `Column.width(288.dp)` 고정 + `shadow(elevation = 24.dp, ambient/spotColor alpha 0.24)` 추가 + 일러스트 240×117dp (`CoopConfirmScreen.kt`, 2026-04-21)
- [x] ISS-027 (Android): S4 "스킬 보러가기 >" 우측 화살표를 이미지(아이콘) 리소스로 교체 — `coop_link_view_skill` 문자열 3종(ko/ja/en)에서 ` >` 제거, `CouponItem.kt` 우측 링크를 `Row(Text + Icon)`으로 재구성. chevron 아이콘은 기존 벡터 드로어블 `R.drawable.icon_arrow_right_16` 재사용(하드코딩된 `#C6C8CC` fillColor는 `Icon(tint = violet400)`으로 오버라이드). 라벨 12sp Bold, 아이콘 12×12dp, 틴트 `#BE7AFE` (2026-04-22)
- [x] ISS-045 (Android): `CouponListActivity.CoopEvent.ShowError` 분기에서 `event.message.isNotEmpty()` 가드를 `event.message.ifBlank { getString(R.string.coop_error_generic) }` 폴백으로 교체. `strings.xml` ko/ja/en 3종에 `coop_error_generic`("오류가 발생했어요" / "エラーが発生しました" / "Something went wrong") 추가. 서버 `error.message` 누락/공백 시 빈 토스트 대신 generic 피드백 보장 (2026-04-23)

## 웹 (/dev-web)
- [x] 쿠폰 등록 UI에 상품권 코드 처리 연동
- [x] 하트 충전 / 스킬 교환 결과 화면
- [x] ISS-002: 미로그인 상태에서 쿠폰 입력/등록 시 로그인 안내 처리 (입력 포커스+등록 버튼에서 goToLogin)
- [x] ISS-003: 완료 모달/이용권 카드에서 유효기간 표시 제거
- [x] ISS-007: 미로그인 시 입력 포커스 → 로그인 안내 팝업 표시 (goToLogin 직접 호출 → Figma 디자인 팝업으로 변경)
- [x] 미로그인 시 쿠폰 입력창 포커스 → 로그인 화면 직접 이동 + 로그인 후 쿠폰 페이지 복귀 (S6 팝업 → 직접 리다이렉트로 기획 변경)
- [x] S3 하트 충전 완료 → 프로필 탭(/user) 이동으로 변경 (design-spec 정합성)
- [x] ISS-010: Coupon 타입에 `fixedMenuSeq?: number` optional 필드 추가 (hellobot-web `types/coupon.ts`. hellobot-webview는 `/api/coupon` 미사용으로 영향 없음. UI 동작 변경 없음)
- [x] ISS-022 클라이언트 대응: `Coupon` 타입의 `expiresAt: string`(non-null) 유지 + 신규 `isUnlimited?: boolean` 추가 — 쿠폰 카드(coupon/payment/skill-detail 3곳) 만료일 행/만료임박 표시를 `isUnlimited === true`일 때 숨김. sentinel 직접 비교 금지 주석 추가. hellobot-web만 영향 (2026-04-21)
- [x] ISS-016: 공통 `components/toast.tsx`의 `DURATION_TIME` 3000ms → 2500ms로 변경 — design-spec/client-guide S5 계약 반영. 공유 컴포넌트라 전역 토스트 지속시간에 적용 (2.5초는 업계 표준 범위로 타 피쳐 UX 영향 경미) (2026-04-21)
- [x] ISS-025: 스킬 이용권 카드 재진입 시 하단 "스킬 보러가기" 영역/탭 동작 유실 수정 — `/coupon` page.tsx에서 `couponData.coupons` 중 `fixedMenuSeq`가 있는 항목을 `CoopSkillVoucherItem`으로 렌더링(서버 재조회 후에도 이용권 카드 UI 유지). 로컬 `skillVouchers` optimistic 상태는 `fixedMenuSeq` 기준 dedup. 스킬 등록 직후 `mutate('/api/coupon')` 호출 추가하여 재진입 전부터 서버 데이터와 동기화 (2026-04-21)

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
- [x] ~~웹뷰 환경 검증 (모바일 앱 내 WebView에서 동작 확인)~~ — **해당 없음으로 종결 (2026-04-21)**. 아키텍처 확정 결과 iOS는 `CouponListViewController`, Android는 `CouponListActivity`로 쿠폰 화면을 네이티브 직접 구현하며 hellobot-web `/coupon`을 앱 WebView로 임베딩하지 않음. hellobot-webview(Angular)도 `/api/coupon` 미사용. 따라서 웹 변경이 앱 동작에 미치는 WebView 경로 없음. (필요 시 별개 과업으로 "모바일 브라우저 반응형 QA(iOS Safari/Android Chrome)" 재정의 가능)

## 스튜디오 (/dev-studio)
해당없음

## 데이터 (/dev-data)

> 목적: 1pager Success Metric 측정 — (input) 상품권 구매 전환율, (output) 앱/웹 신규 구매자수. 추가로 정산 대사 및 운영 대시보드 데이터 제공.
> 설계 문서:
> - [planning/success-metrics-kpi.md](planning/success-metrics-kpi.md) — KPI 프레임워크 (PM 작성)
> - [planning/performance-analysis-design.md](planning/performance-analysis-design.md) — 데이터 엔지니어링 설계 (이벤트 스펙·마트·DAG·SQL)
> - **[architecture.md §10 데이터 분석 설계](architecture.md#10-데이터-분석-설계)** — 거래액 인식 정책 (Q1 결정, 2026-04-27)

### Q1 거래액 인식 — `spent_cash_amount` 인젝션 (2026-04-27 결정, ISS-049)
- [x] 카탈로그 [ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md) 등록 — `spent_cash_amount` 시멘틱 확장 (2026-04-27 /dev-data)
- [x] BQ 컬럼 description 갱신 — `union_mart_user_key_actions.sql:1098-1101` ALTER COLUMN 4건 (외부 채널 환산금 포함 명시) (2026-04-27 /dev-data)
- [x] 인라인 SQL 코멘트 갱신 — `mart_use_skill_se.sql:103-108` revenue_krw / spent_total_amount_krw 의미 (2026-04-27 /dev-data)
- [x] 카탈로그 markdown 갱신 — `mart_use_skill_se.md`, `event-catalog.md`, `metric-dictionary.md` (2026-04-27 /dev-data)
- [ ] common-data-airflow PR 머지 → develop 배포
- [ ] (서버 인젝션 배포 후) BQ에서 카카오 결제 행 검증 — `pay_for_contents` 중 `spent_cash_amount > 0 AND spent_heart_coin = 0` 새 패턴 등장 여부 확인

### Q2 하트 충전권 매출 인식 (2026-04-27 검증 완료)
- [x] 서버 코드 검증 — [coop-marketing.ts:383](../worktrees/hellobot-server/src/services/coop-marketing.ts:383) `chargeHeart` 호출에 `expiredAt` 미전달 → `expiredAt = NULL` → 유료 하트 적립 (2026-04-27 /dev-data)
- [x] `useHeartLogic` 분류 검증 — [heart.ts:155-189](../worktrees/hellobot-server/src/services/heart.ts:155) `willBeExpiredAt` 체크로 유료/보너스 분기, NULL 인 하트는 `spent_heart_coin` 으로 분류 (2026-04-27 /dev-data)
- → 별도 인젝션 불필요. 하트 사용 시 자연 매출 인식.

### Q4 카카오 유입자 식별 (2026-04-28 결정, 4/30 구현 완료 목표)
설계: [architecture.md §10-7](architecture.md#10-7-카카오-유입자-식별-q4-결정-2026-04-28)
- [ ] **RDS 스냅샷 인입** — `hellobot_snapshot_to_bigquery` DAG 에 `coop_marketing_coupon_usage` 일 1회 인입 추가 → `server_rdb.snapshot_coop_marketing_coupon_usage`
- [ ] **`hlb_staging.staging_coop_marketing_coupon_usage.sql`** 신규 — 스냅샷 정제 (테스터 제외 등 표준 가공)
- [ ] **`hlb_intermediate.intermediate_coop_kakao_first_used.sql`** 신규 — 사용자별 `MIN(used_at, 'Asia/Seoul')` 집계, status 무관 (`used`+`canceled` 모두 포함)
- [ ] **`mart_user_daily_info.sql` 확장** — `coop_kakao_first_used_date` (DATE, NULL 허용) 컬럼 추가 + intermediate LEFT JOIN
- [ ] **`union_mart_user_key_actions.sql` 확장** — `coop_kakao_first_used_date` 컬럼 propagate
- [ ] **카탈로그 갱신** — `tables/mart/mart_user_daily_info.md`, `tables/mart_integrated/union_mart_user_key_actions.md` 컬럼 추가 + ALTER COLUMN description SQL 추가
- [ ] **DAG 체인 검증** — staging → intermediate → mart → mart_integrated 1회 실행 후 BQ에서 카카오 사용자 표본 검증
- [ ] **분석 쿼리 템플릿 작성** — KPI 측정 SQL (architecture.md §10-7 본문) 을 운영 대시보드/Slack 알림에 등록

### 성과 측정 지표 정의 (선행 — 기획/데이터 합의)
- [x] KPI 정의서 초안 작성 — [planning/success-metrics-kpi.md](planning/success-metrics-kpi.md) (2026-04-22 /analyze) — 2026-04-28 deprecated, [data-measurement-plan.md](data-measurement-plan.md) 로 통합
- [x] 데이터 엔지니어링 설계서 초안 — [planning/performance-analysis-design.md](planning/performance-analysis-design.md) (2026-04-22 /dev-data) — 2026-04-28 deprecated, [data-measurement-plan.md](data-measurement-plan.md) + [event-spec.md](event-spec.md) 로 분할 흡수
- [x] **데이터 측정 계획 v1.0 확정** — [data-measurement-plan.md](data-measurement-plan.md) (2026-04-28 /dev-data). Q1·Q2·Q4 결정 통합. Q3 갭은 §7.1 에 옵션 A/B/C 명시 (B 권장)
- [x] **이벤트 스펙 v1.0 확정** — [event-spec.md](event-spec.md) (2026-04-28 /dev-data). Firebase 클라이언트 이벤트 3종 + 검증 절차
- [x] 어트리뷰션 규칙 확정 — Q4 결정 (등록일 기준 일/주/월) 완료 ([data-measurement-plan.md §2.1, §6](data-measurement-plan.md))
- [ ] **Q3 등록 전환율 옵션 확정** — A(KPI 폐기) / B(월 1회 CSV) / C(일일 자동 인입) 중 결정 ([data-measurement-plan.md §7.1](data-measurement-plan.md))
- [ ] ~~쿠프마케팅 측 발급/판매 데이터 수령 방식 합의 — CSV/API/정산파일~~ → 위 Q3 결정과 통합

### 이벤트 스펙 (Firebase 클라이언트 — 2026-04-28 결정)
설계: [event-spec.md](event-spec.md)

서버 이벤트는 발화하지 않음 — DB(`coupon`, `coop_marketing_coupon_usage`, `coop_marketing_api_log`)가 진실 원천. 클라이언트 Firebase 3종만:
- [x] **iOS** — `view_coupon_register` (화면 진입), `register_coupon_success`, `register_coupon_failure` 발화 구현 (2026-04-29 /dev-ios)
- [x] **Android** — Firebase 이벤트 3종 발화 신규 구현 (2026-04-29 /dev-android, event-spec.md v1.1 EVT-1/2/3 + D1~D5 결정 반영). 신규 파일 `app/src/main/java/com/thingsflow/hellobot/util/analytics/event/firebase/FirebaseCoupon.kt` (`FirebaseCoupon` sealed class + `ViewCouponRegister`/`RegisterCouponSuccess`/`RegisterCouponFailure` + `companion object` prefix 룩업 유틸 `PREFIX_TO_COUPON_TYPE`/`classifyCouponType`/`extractPrefix`). `CouponListActivity.onCreate` 에서 `savedInstanceState == null` 가드로 EVT-1 발화(회전·재생성 중복 방지). `CouponListViewModel.register` 에서 `requestStartedAt = System.currentTimeMillis()` 캡처 후 `fireRegisterSuccessEvent`/`fireRegisterFailureEvent` 호출, `latencyMs = now - requestStartedAt`. `CouponRegisterResponse` 에 `couponType`/`productCode` 옵셔널 필드 추가(D1=a 서버 보강 PR 머지 시 자동 채워져 발화). 에러 분류 — `parseServerError` + `parseErrorBody` 신설: `HttpException` → 응답 `error.code`(CM001~CM010·CO012·CP*), `IOException` → `NETWORK_ERROR`, 그 외 → `UNKNOWN`. EVT-3 `coupon_type` 은 D3=a(에러 응답 미보강) 따라 클라이언트 prefix 룩업(`90`/`91` → kakao). null 파라미터는 Bundle 키 자체 omit. `:app:ktlintCheck` + `:app:assembleDevDebug` BUILD SUCCESSFUL. **의존**: 서버 D1=a 보강 PR 머지 전엔 EVT-2 의 `coupon_type`/`product_code` 두 파라미터 omit 송신 → 머지 후 클라이언트 변경 없이 자동 채워짐.
- [x] **Web** — `lib/features/coupon/couponGoogleAnalytics.ts` 신규(채널 분기: `webview.isWebView()` → `webview.logEvent` 또는 `window.gtag('event', ...)`, `skillsGoogleAnalytics.ts` 패턴 동일). `app/coupon/page.tsx` 마운트 1회 `view_coupon_register` 발화. `app/coupon/components/couponCodeRegister.tsx` 등록 버튼 탭 → 응답까지 `performance.now()` 차이로 `latency_ms` 측정 후 success/failure(network·empty body·unsupported issuedType 포함 4분기) 발화. `coupon_type`은 클라이언트 prefix 룩업 표(`90/91→kakao`, `coupon_prefix_rule` 시드 동기)로 도출. **hellobot-webview(Angular)는 발화 추가 없음** — `coupon.component.ts`가 `ngOnInit`에서 즉시 `${origin}/coupon`(Next.js) 리다이렉트만 수행하는 stub이라 화면 미노출, 단일 발화 지점으로 누락 없음. 응답 DTO 한계로 `product_code`(kakao 한정), `bonus_heart_amount`는 키째 누락 — 서버 DTO 보강(아래 항목)과 함께 자동 채워짐. 2026-04-29 /dev-web
- [ ] **서버 응답 DTO 보강** (2026-04-29 D1~D5 픽스 — 신규 필드 2개) — `POST /api/coupon/register` 성공 응답 `data` 에 ① `couponType` (string, 항상; `kakao`/`hellobot`/`giftiel`), ② `productCode` (string\|null, issuedType=heart/skill 시; 카카오 한정, 일반/giftiel NULL) 추가. `heartQuantity` 유지 (bonus 필드 도입 안 함 — Q2 paid 100% 결정). 에러 응답은 변경 없음 (D3=a). 상세: [api-spec.md §Response](./api-spec.md) + [event-spec.md §5](./event-spec.md). /dev-server 담당
- [x] **Web — 2026-04-29 D1~D5 스펙 픽스 반영** — `types/coop.ts` 의 `CouponRegisterResponse` 디스크리미네이티드 유니언에 `couponType: 'kakao'|'hellobot'|'giftiel'`(모든 issuedType 공통) + `productCode: string|null`(heart/skill 한정) 필드 추가 (api-spec.md §Response 동기, 신규 `CouponChannelType` 별칭). `couponGoogleAnalytics.ts`: ① `RegisterCouponSuccessParams.couponType` 비-nullable(`CouponChannelType`) — D1=a 응답 직접 사용 의미상 prefix 룩업 폴백 불필요, ② 파라미터 키 `heart_amount` → `heart_quantity` (값 = 응답 `heartQuantity`, D2=a), ③ `productCode` 파라미터 활성화(`undefined` 시 키째 누락 — null 매핑 D4), ④ `bonusHeartAmount` 필드/송신 제거. EVT-3 의 `inferCouponTypeFromPrefix`(`coupon_prefix_rule` 시드 룩업) 유지 — 에러 응답 미보강(D3=a). `couponCodeRegister.tsx`: heart/skill 분기에서 `couponType: data.couponType`, `productCode: data.productCode ?? undefined`, `heartQuantity: data.heartQuantity` 로 매핑(prefix 룩업 폴백 제거). hellobot-webview 는 stub 이므로 영향 없음. `tsc --noEmit` 통과(기존 `details.test.tsx` 1건 pre-existing 무관). **의존**: 서버 응답 DTO 보강 PR 머지 + 배포 후 효과(이전 까지는 `data.couponType` 미정의로 런타임 undefined 송신 — 서버 동시 배포 권장). 2026-04-29 /dev-web
- [ ] **이벤트 화이트리스트 등록** — `hlb_staging.staging_key_events_fb_events_list` (또는 `events_list`) 에 3건 INSERT

### BigQuery ETL (common-data-airflow)
설계: [data-measurement-plan.md §6](data-measurement-plan.md) (Q4 마트 변경) + [event-spec.md §9](event-spec.md) (이벤트 후속 마트)
- [ ] Glue 스냅샷 추가 — `coupc_marketing_coupon_usage`, `coupc_marketing_product` (§9-2)
- [ ] `staging_coupc_marketing_coupon_usage`, `staging_coupc_marketing_product` SQL + DAG task
- [ ] `intermediate_coop_coupon_event` SQL — server_events 3종 + product 조인
- [ ] `mart_coop_coupon_usage` SQL + DAG task — 그레인: 쿠폰 1장, is_new_user/is_first_paying 컬럼 포함
- [ ] `union_mart_user_key_actions.sql` 수정 — `funnel_from_coop_coupon` 컬럼 추가 (heart 24시간 창 + skill issued_coupon_seq 매칭)
- [ ] `report_coop_daily`, `report_coop_monthly` SQL + DAG task
- [ ] `hellobot_coop_coupon_issued_ingest` DAG 신규 (쿠프마케팅 발급 데이터 적재, 수령 방식 확정 후)
- [ ] 정산 대사 로직 — 쿠프마케팅 L1 사용 내역 vs `coupc_marketing_coupon_usage` 일치 검증
- [ ] 데이터 카탈로그 갱신 — mart-catalog.md, event-catalog.md, metric-dictionary.md (common-data-airflow/docs/hellobot-data/catalog/, 코드 PR 동시 반영 필수)

### 대시보드/리포트
설계: [planning/launch-performance-report-plan.md](planning/launch-performance-report-plan.md) (R1~R5 운영 계획)
- [ ] 대시보드 도구 결정 (§9-5 — Looker 권장)
- [ ] 경영진 월간 대시보드 (신규 구매자/전환율/정산대상액/상품별 Top5)
- [ ] 운영 일간 대시보드 (등록추이/에러분포/구버전 가드 발동/L1 레이턴시)
- [ ] 상품 성과 월간 (상품별 GMV/스킬 이용권→진입 전환/재등록자)
- [ ] 정산 대사 월간 (대사 불일치 탐지)
- [ ] Slack KPI 주간 요약 발송 (§9-8 채널 확정 후 `hlb_kpi_noti` 확장)

### 의존 관계
- KPI 정의서 확정 → 이벤트 스펙 확정 → 서버 이벤트 publish 구현 → 프로덕션 배포 → 1일 이상 데이터 축적 → BQ ETL 개발
- 서버 Phase 1 배포 완료 및 프로덕션 데이터 축적 이후 실 DAG 개발 의미 있음 (dev 환경 데이터로 검증 불가 — env=production 필터)
- 쿠프마케팅 발급 데이터 수령 방식 합의는 정산 시작 전 완료 필요 (익월 10일 정산)

## Phase 1 — ISS-011 + ISS-009 해결 (2026-04-19 설계 확정)

> 설계 근거: architecture.md §3/§5, api-spec.md `POST /api/coupon/register`, client-guide.md
> 해결 이슈: ISS-011(프리픽스 판별 주체 통일), ISS-009(구버전 앱 대응), ISS-013(CM005 문구 통일), ISS-014(S3 팝업 문서 정합성)

### 서버 (/dev-server)
- [x] `CouponPrefixRule` 엔티티 생성 (src/models/entities/CouponPrefixRule.ts) + 마이그레이션 `CreateCouponPrefixRule1776948000000` + 시드 데이터 (90, 91 / coop_marketing). 시드 INSERT는 `thingsflow.` 스키마 prefix 포함 Raw SQL로 작성
- [x] AdminJS에 `CouponPrefixRule` 관리 페이지 추가 (CRUD, SIDEBAR.COOP_MARKETING)
- [x] `ErrorCode.CO012` 추가 + i18n ko 메시지 — "앱 업데이트가 필요한 쿠폰이에요." (ja/en은 번역 검수 잔여 — 빈 문자열 placeholder)
- [x] `POST /api/coupon/register` 컨트롤러 구현 (src/controllers/coupon.ts에 추가)
- [x] `CouponRegisterService` 신설 — prefix 분류 → coop/일반 분기 → 원샷 처리
- [x] Coop 원샷 처리: `CoopMarketingService.registerOneShot` — `checkCoupon` + `useCoupon` 재사용, Redlock(`coop:lock:${code}`) 보상 완료 후 해제 (ISS-015 동시 해소)
- [x] 폴리모픽 응답 DTO: `CouponRegisterResponseDto` — `resultType: "ISSUED"`/`issuedType: "coupon"|"heart"|"skill"` + `data` 내부 nested 필드 (issuedCoupon 포함)
- [x] `POST /api/coupon` 진입 가드 추가 — `code`가 비어있지 않은 문자열일 때만 `CouponPrefixRule` 조회 후 requiresNewFlow=true 매칭 시 HTTP 406 `CO012` throw. `couponSpecSeq` 경로 영향 없음
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
- [ ] 에러 시나리오: CM001~CM010 각 에러별 토스트 메시지 검증 (기존 TC 재활용)
- [x] **ISS-050 xlsx v13 생성 (2026-04-28 /qa)**: v12 → v13 — 코드 표기 `CM_001~CM_010`/`CO_APP_UPDATE_REQUIRED` → `CM001~CM010`/`CO012` 일괄, 기대 메시지 컬럼 ko 어미 "~습니다" 정합 + CM001/002/003 ja/en은 CP 시리즈 문구 통일, ISS-050 회귀 TC 추가. v12 감사 추적 보존.
- [ ] **ISS-050 회귀 검증** (서버·iOS 동시 배포 후): 각 에러 토스트가 v13 기대 ko 문구와 일치 + CM001/002/003은 일반 쿠폰 CP 시리즈와 동일 문구 + 구버전 앱 가드 토스트 = "앱을 최신 버전으로 업데이트 해주세요". ja/en 디바이스 회귀 포함.
- [x] **TC 커버리지 보강 (2026-04-21 계약 반영)** (2026-04-21 오후): qa-test-cases.md 상단에 "2026-04-21 보강" 섹션 신설 — 7건 추가. qa-test-cases-v11.xlsx 생성 (Flow V 신설, 사용자 시트 54→61건). 전체 145→152건.
  - [x] (a) **ISS-022 isUnlimited 분기** — TC-V-UL01 (만료일 텍스트 미표시), TC-V-UL02 (N일 남음 배지 미표시), TC-V-UL03 (일반 쿠폰 만료일 회귀), TC-V-UL04 (만료 임박 조건 회귀). Web/iOS/Android 매트릭스.
  - [x] (b) **ISS-016 토스트 지속시간 2.5초** — TC-V-TD01. Web/iOS/Android 모두 2.5초 ±0.3초 기대. Android도 2026-04-21 SafeToast(COOP_TOAST_DURATION_MS=2500L) 해결로 통과 기대.
  - [x] (c) **ISS-017 Web 즉시 반영** — TC-V-WR01 (일반 쿠폰 리스트 즉시 반영 + 헤더 카운트 +1), TC-V-WR02 (스킬 이용권 중복 렌더 없음). Web 단독, iOS/AOS N/A.
- [x] **플랫폼 매트릭스 주석 추가** (2026-04-21 오후): qa-test-cases.md 상단 "📌 플랫폼 매트릭스 주석" 섹션 신설 + v11 xlsx 요약 시트 3행 + 사용자 시트 Flow V 헤더에 주석 삽입 완료. architecture.md §6 기반 "앱 내 WebView 임베딩 없음, WebView 유형 TC는 N/A" 명시.
- [x] **기존 TC 상태 업데이트** (2026-04-21 오후): TC-W-D08 Android 비고에 ISS-016 Android 해결(SafeToast) 반영. TC-A-S07/S08 기대 결과를 ISS-019/020 Android 해결 반영으로 "Pass 예상"으로 전환.
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
- [x] ISS-012: api-spec.md 에러코드 표 + client-guide.md 에러 매핑표에 CM010 포함 확인 완료 (2026-04-19 /review 반영) — 양쪽 모두 CM010 "결제가 취소된 쿠폰이에요" 기술됨
- [x] ISS-013: CM005 사용자 메시지 통일 — "일시적인 서비스 오류가 발생했어요"로 확정, 양쪽 동기화 완료 (2026-04-19)

### 기획 문서 정합성 (analyze)
- [x] ISS-014: screen-plan.md S3 완료 팝업 기술을 design-spec 확정본 기준으로 갱신 — screen-plan.md §3 S3 재작성 완료 (2026-04-19)

### 서버 (dev-server)
- [x] ISS-015: Redlock 미구현 해소 — `POST /api/coupon/register` 구현 시 Coop 원샷 처리에 Redlock 필수 적용으로 통합 해소 (위 Phase 1 서버 과업에 포함, 2026-04-19)

### 클라이언트 (dev-web, dev-android)
- [x] ISS-016 (web): 에러 토스트 지속시간 2.5초 적용 완료 (2026-04-21, 위 웹 파트 참조)
- [x] ISS-016 (android): 에러 토스트 지속시간 2.5초 적용 완료 (2026-04-21, `SafeToast.showToastForDurationMs` + `COOP_TOAST_DURATION_MS=2500L`)

## 개발환경 QA 이슈 (2026-04-22 /qa — Notion 스프린트 트래커 연동)

> 출처: Notion 스프린트 "[스쿼드A] 카카오 선물하기 쿠폰 등록" 중 Done이 아닌 태스크 전수 이관 (DLT-HLB-1034, 1045, 1047, 1049, 1051~1053, 1055~1061)
> 상태: 각 이슈의 근본 원인·해결 방안 미확정 → 담당 에이전트별 **분석·해결방안 구상 → 사용자 확인 → 구현**의 단계로 진행
> 공통 이슈(ISS-030/033/036/039/040/042)는 파트별로 분리 기재 — 각 파트가 독립 판단/구현

### 서버 (/dev-server)
- [x] ISS-029: AdminJS 사이드바 `Coupon Prefix Rule` 메뉴명 한글화 ("쿠폰 분류 규칙 설정") — 위 "## 서버 (/dev-server)" 섹션과 중복 (해당 과업의 분석/구현 시 함께 처리). 2026-04-22 완료
- [x] ISS-039 (서버 i18n): `CO012` ja/en 메시지 번역 리소스 보강 — `src/locales/en.ts`에 "Please update to the latest version.", `src/locales/ja.ts`에 "アプリを最新バージョンにアップデートしてください" 채움 (2026-04-22)
- [ ] ISS-043 (서버 분석): 신규 가입자 스킬이용권 사용 시 스킬 인트로 대신 챗봇 인트로 출력 원인 분석 — **보류 (2026-04-22)**: 사용자 지시로 진행 보류. 분석 결과는 issues.md에 기록됨 (스튜디오 설정 검증/재현 로그 수집이 선행 필요)
- [x] ISS-044 (서버 i18n): coop-integration 사용자 노출 문구 ja/en 번역 누락 11건 리소스 반영 — `src/locales/ja.ts` / `src/locales/en.ts`의 `CM001`~`CM010`(ERROR) + `COUPON_POPUP_TITLE`(CONFIG) 11개 키를 api-spec.md §i18n 번역 세트 표 값으로 치환. 추가로 ko `CM001`~`CM010` 표기 친근체("~이에요") 통일(정책 A). TS 컴파일 통과. 본 변경 파일에 lint 위반 없음 (2026-04-23)

### iOS (/dev-ios)

> **분석 완료 (2026-04-22)**: 9건 모두 issues.md에 `**분석 (2026-04-22 iOS)**` 블록 기록.
> **즉시 착수 5건 구현 (2026-04-22)**: ISS-030/033/035/038/041 일괄 구현 완료.
> **결정 수령분 1건 구현 (2026-04-22)**: ISS-042 — 스피너 없이 disable + 회색만 구현(디자인 결정 반영).
> **서버 배포 후속 1건 구현 (2026-04-23)**: ISS-039 — `CouponRegisterErrorMapper` 판정 완화(서버 non-empty 값 그대로, 빈 문자열만 폴백). 서버 ja/en 배포(2026-04-23 ISS-044 포함) 확인 후 착수.
> **2026-04-23 추가 QA 피드백 3건 일괄 구현**: ISS-040(이용권 배지 client-derive) + ISS-041 재조정(collapse → reserve) + ISS-047(스킬 보러가기 en/ja 번역) — 동일 `CouponItemModel.swift` + ResourceKit 3개 Localizable.strings에서 함께 처리.
> **선결 대기 1건**: ISS-036(iOS 앱 실기기 재현 확인).

- [x] ISS-030 (iOS): `CouponListViewController`의 `editingDidBegin`/`sendCouponCode()` 2개 `presentSingup()` 호출부에 `AppString.toastPlzLogin` 전달 → `goSignupModal` 토스트 경로 활성화 — 2026-04-22 해결
- [x] ISS-033 (iOS): `handleRegisterResponse(_:)` `.coupon` 분기에 `showCouponToast(.Coupon.Register.successToast)` 추가 + 로컬라이즈 `coupon_register_success_toast` ko/en/jp 신규 (Android 문구와 통일). 스킬 성공 토스트도 `.Coupon.Register.skillSuccessToast`로 분리 — 2026-04-22 해결
- [x] ISS-035 (iOS): `CoopHeartCompletePopupView.illustrationImageView`를 `ImageContentView` + 기존 하트충전 Lottie(`imgHeartchargeComplete`, loop)로 교체 — 2026-04-22 해결
- [ ] ISS-036 (iOS): 스킬이용권 사용 후 대화방 뒤로가기 시 쿠폰함 갱신 — **iOS 앱 실기기 재현 확인 선결** (정적 분석상 viewWillAppear→refreshCoupon 바인딩 기존재로 미재현 가능성 높음). 재현 확인 후 결정
- [x] ISS-038 (iOS): `CouponListViewController.showCouponToast(_:)` 헬퍼 신설 → `Toast(text:, config: ToastConfig(displayTime: 2.5)).show()`. 레거시 `showToast(msg:)` 2개 호출부 + ISS-033 신규 호출을 일원화 — 2026-04-22 해결
- [x] ISS-039 (iOS): `CouponRegisterErrorMapper.resolve()` / `ReasonServerError` 경로에서 `containsHangul` 게이트 제거 → 서버 non-empty 값 그대로 사용, 빈 문자열만 `codeMessages[code]` 폴백. `nonEmpty(_:)` 헬퍼 도입으로 trim/empty 가드 통일. `codeMessages` 테이블은 safety net으로 존속(빈 응답·신규 에러코드 미지원 시 최후 방어선). 서버 ja/en 배포(2026-04-23 ISS-044 포함) 확인 후 착수 — 2026-04-23 해결
- [x] ISS-040 (iOS): 스킬 이용권 카드 우상단 "이용권" 배지 클라이언트 derive 구현 — `CouponItemCell.bind()`의 tags 렌더 직전 `effectiveTags` 파생(`isSkillVoucher && !coupon.tags.contains(voucherTag)` 조건에서 prepend). ResourceKit 3개 Localizable.strings에 `coop_label_voucher` 키 추가(ko "이용권" / en "Voucher" / ja "利用券" — Android 통일). `String+Coupon.swift` `View.skillVoucherTag` property 신규. 서버 tags에 이미 "이용권" 포함 시 중복 노출 방지 가드 포함 — 2026-04-23 해결
- [x] ISS-041 (iOS): `CouponItemCell.bind()`에서 스킬 이용권(`fixedMenuSeq != nil && isUnlimited == true`) 시 "0하트 이상 결제 시" 문구 숨김 — (초기 2026-04-22: `isHidden = true` + `flex.isIncludedInLayout = false`로 행 collapse). **2026-04-23 재조정**: 사용자 QA 피드백으로 reserve 방식 전환 → `flex.isIncludedInLayout = false` 라인 제거, `isHidden = true`만 유지. 카드 전체 높이는 일반 쿠폰과 동일 유지 + 문구만 숨김(웹 ISS-031 reserve 전략 정합)
- [x] ISS-042 (iOS): 쿠폰 등록 버튼 탭 시 비활성화 + 회색 표시 — `CouponInputFieldView`에 `isInputFilledRelay`/`isRegisteringRelay` BehaviorRelay 2개 도입, `setupContext()` combineLatest(`filled && !registering`) → `sendButton.rx.isEnabled`. 회색은 기존 disabled 토큰(gray400/gray200) 재사용. `CouponListViewController.registerCoupon(code:)` `.do(onSubscribe:/onDispose:)` 훅으로 성공/실패/취소 모든 경로에서 리셋 보장. 스피너/GIF/오버레이 미도입 — 2026-04-22 해결
- [x] ISS-047 (iOS): 스킬 이용권 카드 "스킬 보러가기" 링크 en/ja 번역 반영 — `CouponItemModel.swift`의 한글 리터럴 `"스킬 보러가기"`를 ResourceKit 경유(`String.Coupon.View.skillLink`)로 치환. `String+Coupon.swift`의 `View` 구조체에 `skillLink` public property 추가(key: `coop_link_view_skill`) + `Modules/Common/ResourceKit/Resources/Localizable/{ko,en,ja}.lproj/Localizable.strings` 3종에 키 추가(ko "스킬 보러가기" / en "View Skill" / ja "スキルを見る" — Android `coop_link_view_skill`와 완전 통일, ISS-027 해결 시 `>` 제거 정합). chevron 이미지(`skillLinkChevron`, SF Symbol)는 그대로 유지 — 2026-04-23 해결
- [x] ISS-048 (iOS): `/architect` design-spec §S4 "스킬 이용권 카드 렌더 분기 규칙" 재정의(2026-04-24) 사후 점검 — `/dev-ios` 정적 점검 결과 17/17 항목 중 15 Pass, 1 Fail(B2, 단일 기준 모순)은 본 이슈 재정의로 해소, 1 N/A(G1, 실기기 QA). iOS 현 구현(ISS-019/022 단독 조건 + ISS-040/041 AND)이 api-spec.md 규약 및 재정의된 2종 분기 구조와 **이미 정합** → **코드 수정 없음**. 리포 status.md 결정 로그에 재정의 반영 메모 1줄 기록 — 2026-04-24 확인 완료

### Android (/dev-android)

> **분석 완료 (2026-04-22)**: 6건 모두 issues.md에 `**분석 (2026-04-22 Android)**` 블록 기록. ISS-033/ISS-039 방향 결정 완료 (2026-04-22).
> **실행 순서**: Step 1(4건 병렬) → Step 2(ISS-033 A안) → ISS-039는 서버 의존, Android 코드 수정 없음

**Step 1 — 즉시 수행 가능 (4건, 병렬)**
- [x] ISS-030 (Android): `CouponListActivity.CoopEvent.NavigateToLogin` 분기에서 `SafeToast.showToastForDurationMs(ctx, R.string.common_toast_plz_login, 2500L)` 호출 후 `SignupActivity.enterForResult(ctx, null, "coop_coupon_input")` 전달 (Intent extra toast = null) — 2026-04-22 해결
- [x] ISS-036 (Android): `CouponListActivity.onResume` 오버라이드 → `viewModel.load()` 호출. `loadData()`를 no-op로 변경해 onCreate 경로 중복 load 방지 (dedupe 가드보다 단순/명시적). onStart→onResume 시퀀스에서 실질 지연 없음 — 2026-04-22 해결
- [x] ISS-040 (Android): `CouponItem.kt` 우상단 태그 Row에서 `isUnlimited && fixedMenuSeq != null` 조건 검출 시 `R.string.coop_label_voucher`(ko/ja/en 기존 보유)를 `coupon.tagList` 앞에 prepend + 중복 제거 렌더 — 2026-04-22 해결
- [x] ISS-042 (Android): `CouponListViewModel`에 `_isRegistering: MutableStateFlow<Boolean>` 신설 → register 진입/완료 전환. Activity가 `collectAsState` 후 `CouponInputSection`에 전달 → 버튼 `enabled = !isInputEmpty && !isRegistering` + 비활성 톤(Gray400 배경 + White 텍스트)으로 disabled 노출. `doFinally`로 상태 리셋 보장 — 2026-04-22 해결, **2026-04-23 rollback**(스피너 분기 제거, iOS와 동일한 "disable + gray" UX로 단순화하여 플랫폼 일관성 확보)

**Step 2 — 결정 수령 후 (1건)**
- [ ] ISS-033 (Android): **A안 확정** — `CoopEvent.GeneralCouponIssued` 신규 케이스 추가. `CouponListViewModel.register` `IssuedType.COUPON` 분기의 `_toastEvent.value = Event(...)`를 `_coopEvent.emit(CoopEvent.GeneralCouponIssued)`로 교체. `CouponListActivity` observeUi에 `is CoopEvent.GeneralCouponIssued -> SafeToast.showToastForDurationMs(ctx, R.string.coupon_description_coupon_registered_successfully, COOP_TOAST_DURATION_MS)` 추가. `_toastEvent` LiveData는 본 이슈 범위 내에서는 유지(다른 사용처 영향 회피)

**ISS-039 — 서버 의존, Android 코드 수정 없음**
- [ ] ISS-039 (Android, 무코드): 서버 `src/locales/en.ts` / `src/locales/ja.ts` `CO012` 번역 배포 후 **QA 회귀 확인**만 수행. Android `strings.xml` 추가/클라이언트 폴백 추가하지 않음(2026-04-22 결정). 서버 배포 지연되거나 회귀 표면화 시 별도 enhancement로 분리

**Step 3 — 사용자 QA 재보고 (1건)**
- [x] ISS-046 (Android): 스킬 이용권 카드에서 "0하트 이상 결제 시 사용 가능" description 노출 제거 (공간은 reserve) — `CouponItem.kt`에서 `isSkillVoucher = coupon.isUnlimited && coupon.fixedMenuSeq != null` 판별을 Box scope 상단으로 승격(ISS-040 태그 prepend 로직과 공유). description `Text`에 `Modifier.alpha(0f) + clearAndSetSemantics { }`를 조건부 체이닝 — 문구는 투명 처리되나 측정/높이는 유지되어 **카드 높이는 일반 쿠폰과 동일**. 웹 ISS-031 invisible reserve와 정합, iOS ISS-041 collapse와는 플랫폼 차이 잔존(`/architect` design-spec §S4 통일 결정 대기). 신규 import 2건(`androidx.compose.ui.draw.alpha`, `androidx.compose.ui.semantics.clearAndSetSemantics`). 검증 `:app:assembleDevDebug` + `:app:ktlintCheck` BUILD SUCCESSFUL (2026-04-23)
- [x] ISS-048 (Android 확인): `/architect` design-spec §S4 "스킬 이용권 카드 렌더 분기 규칙" 재정의(2026-04-24) 사후 확인 — `/dev-android` 정적 점검 결과 **4/4 Pass**. `CouponItem.kt`에서 분기 A(AND)는 `isSkillVoucher = coupon.isUnlimited && coupon.fixedMenuSeq != null`(line 71)을 배지(line 202) + 부가설명(line 107-108)이 공유. 분기 B(단독)는 `hasBottomLeft = !coupon.isUnlimited`(line 114, 만료일 단독) + `hasBottomRight = coupon.fixedMenuSeq != null`(line 115, 링크 단독)로 각 필드 독립 조건 사용. **코드 수정 없음** — 재정의된 2종 분기 구조와 이미 완전 정합. 리포 status.md 결정 로그에 메모 1줄 기록 (2026-04-24 확인 완료)

### 웹 (/dev-web)
- [x] ISS-031 (웹): `CoopSkillVoucherItem`을 `CouponItem`과 동일 수직 리듬(`mb-[2px]` + 서브텍스트 `invisible` reserve + `my-[12px]` 점선 + `leading-[18px]` 하단 링크)으로 재구성. 외부 `<li>` min-height 없이 내부 reserve만으로 카드 높이 일치 — 2026-04-22 해결
- [x] ISS-032 (웹): `CoopSkillVoucherItem` 화살표를 인라인 SVG(`fill="#BE7AFE"`)로 교체 — 2026-04-22 해결
- [x] ISS-033 (웹): 일반 쿠폰 등록 성공 토스트 노출 — `couponCodeRegister.tsx` `case 'coupon':` 분기에 `dispatch(setToastMessage(t('coupon_register_success_toast')))` 추가. 번역 키 `coupon_register_success_toast` ko/ja/en 3종 신규 (iOS와 동일 키/문구). 2026-04-23 해결
- [x] ISS-034 (웹): 스킬 이용권 카드 쿠폰명 중복 제거 — QA 실기 재검증에서 "쿠폰명 + '이용권' 중복 노출"이 실제 원인으로 확인됨(사용 후 접미사 탈락 아님). `CoopSkillVoucherItem`의 `t('coop_skill_voucher_name', { value: productName })`(" 이용권" 접미사 부착) 제거 후 `{data.skillName}`만 렌더. dead key `coop_skill_voucher_name` 3개 언어 파일 함께 삭제. 우측 상단 `coop_skill_voucher_badge`("이용권") 유지로 이용권 구분은 여전히 명확. 2026-04-23 해결
- [x] ISS-030 (웹): 미로그인 상태에서 쿠폰 입력창 포커스/등록 시 안내 토스트 노출 — `couponCodeRegister.tsx` `handleInputFocus`/`handleRegister` 두 분기에 `dispatch(setToastMessage(t('common_toast_plz_login')))` 선행 디스패치 후 `goToLogin('?fallbackUrl=/coupon')` 호출. iOS(ISS-030 iOS)/Android(ISS-030 Android) 해결과 동일 UX. 번역 키 기존 보유 재사용. 2026-04-23 해결
- [x] ISS-035 (웹): `coopHeartCompletePopup.tsx`의 정적 PNG(`/images/coop/img_heart_complete.png`) + Next.js `<Image>`를 기존 프로젝트 자산 `/images/heart/heart_charge.gif`(`BonusHeartModal`에서 이미 사용 중, 1184×576) + plain `<img>`로 교체. `?t={mountTimestamp}` 캐시 버스터(`useMemo([])`)로 마운트 1회 재생. `-mx-[24px] w-[288px] h-[140px]`로 padding 밖 확장, 원본 비율 유지. 신규 자산 발급 없음 — 2026-04-22 해결
- [x] ISS-036 (웹): `app/coupon/page.tsx`에 `pageshow` 훅 추가, `persisted=true`일 때 `mutate('/api/coupon')`로 재검증. 서버가 used voucher를 응답에서 자동 제외하므로 재조회만으로 해소 — 2026-04-22 해결
- [x] ISS-037 (웹): `CoopSkillVoucherItem` "이용권" 라벨을 `CouponItem` 태그 스타일(`px-[6px]`/`rounded-full`/gray)과 통일. 첫 행 flex `justify-between` 구조로 변경 — 2026-04-22 해결
- [x] ISS-042 (웹): `couponCodeRegister.tsx` 버튼 내부에 `animate-spin` 인라인 스피너 추가, 풀스크린 `<Loading />` 제거, `aria-busy`/`aria-label` 보강 — 2026-04-22 해결
- [x] ISS-048 (웹 회귀 확인 + 코드 수정): design-spec §S4 재정의(2026-04-24) 점검 결과 3/4 Pass, (B-2) "스킬 보러가기 링크 `fixedMenuSeq` 단독 조건"이 Fail — 현재 링크는 `CoopSkillVoucherItem`(AND 분기 내부)에서만 렌더되어 `fixedMenuSeq != null && !isUnlimited`("스킬 지정 + 유한 만료") 쿠폰에 링크 미노출. **권장안 채택** — `CouponItem.tsx`에 optional prop `onSkillLinkClick?: (fixedMenuSeq) => void` 추가, 내부에서 `coupon.fixedMenuSeq != null && onSkillLinkClick`일 때 하단 우측 링크 렌더(`CoopSkillVoucherItem`과 동일 inline SVG chevron + `coop_skill_voucher_link` 키 재사용). `app/coupon/page.tsx`에서 `<CouponItem onSkillLinkClick={handleSkillVoucherClick} />` 주입. `types/coupon.ts:20` 주석을 "웹은 미사용" → ISS-048 조건 명시로 갱신. 하단 영역은 좌(만료정보 단독)+우(링크 단독) `space-between` flex, 둘 다 없으면 점선 구분선 포함 블록 전체 미렌더. 향후 "스킬 지정 + 유한 만료" 쿠폰 도입 시 선제 대응. 현 운영 환경 서버 응답에는 해당 쿠폰 타입 없어 QA 재현 불가, 스펙 정합성 선제 보강 — 2026-04-24 해결
- [x] ISS-051 (웹, ISS-035 후속): S3 충전 완료 모달 GIF 비율 회귀 수정 — `coopHeartCompletePopup.tsx`에서 `<img>`에 직접 부여하던 `-mx-[24px] w-[288px] h-[140px]`이 Tailwind preflight `img { max-width: 100% }`에 의해 부모 폭 240px(다이얼로그 `w-[288px] p-[24px]` 내부 `w-full`) 기준으로 클램프되어 너비 240·높이 140(비율 ≈1.71)으로 렌더, 원본 1184×576(≈2.06) 대비 세로 신장. 동일 자산을 정상 렌더하는 `BonusHeartModal`의 패턴(`<div className="w-[288px] -mx-6"><img /></div>`)과 동일하게 **breakout 래퍼 div** 도입 — 래퍼는 preflight 영향 없이 288px로 확장되고 그 안의 `<img>`는 부모 폭 288px 기준으로 `max-width: 100%`가 평가되어 정상 비율 유지. 단일 파일 수정(`app/coupon/components/coopHeartCompletePopup.tsx`), 외부 시그니처/번역/스펙 변경 없음 — 2026-04-28 해결

### 진행 방식
1. **분석 단계** (현재): 각 파트 에이전트(`/dev-server`, `/dev-ios`, `/dev-android`, `/dev-web`)가 담당 이슈를 하나씩 검토 → issues.md 해당 항목 하단에 `**분석 (yyyy-mm-dd 파트)**` 블록으로 근본 원인·해결 방안·영향 범위·예상 리스크 기록
2. **확인 단계**: 사용자가 분석 결과 검토 후 승인/조정
3. **구현 단계**: 승인된 방안을 각 파트 워크트리에서 구현 → tasks.md 체크, issues.md 상태 "해결 (날짜)"로 갱신

> 순서: iOS → Android → 웹 → 서버 (클라이언트 먼저 검토 → 서버 API/i18n 변경이 필요한지 역추적)

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
