# 이슈 목록

## 이슈 분류
- **bug**: 구현이 설계와 다름
- **edge-case**: 설계에서 고려하지 못한 예외 상황
- **enhancement**: 기존 요구사항 범위 밖의 개선

---

## 미해결 이슈

### ISS-002: 미로그인 상태에서 쿠폰 입력창 클릭/등록 시 로그인 안내 팝업 미표시

| 항목 | 내용 |
|------|------|
| 분류 | bug |
| 발견일 | 2026-04-14 |
| 발견 단계 | QA |
| 심각도 | P2 |
| 영향 파트 | 웹 |
| 상태 | 구현완료 |

**현상**: 쿠폰 등록 화면(`/coupon`)에서 미로그인(anonymous) 상태의 사용자가 쿠폰 입력창을 클릭하거나 등록 버튼을 눌러도 로그인 안내 팝업이 뜨지 않는다. 대신 API 호출이 진행되어 401 에러가 토스트로 표시된다.

**원인**: `couponCodeRegister.tsx`의 `handleRegister` 및 입력 인터랙션에 `user?.type === 'anonymous'` 체크가 없다. 설계 문서(screen-plan.md, client-guide.md)에서 "기존 쿠폰 화면이 로그인 상태에서만 접근 가능하므로 추가 처리 불필요"로 전제했으나, 실제로는 미로그인 상태에서도 쿠폰 페이지 접근이 가능하다. `LoginGuideBadge` 컴포넌트가 로그인 유도 배너를 보여주지만, 입력/등록 동작 자체를 차단하지 않는다.

**해결**: `couponCodeRegister.tsx`에 anonymous 체크 추가.
- 입력창 포커스 시(`onFocus`): blur 후 `goToLogin('?fallbackUrl=/coupon')` 호출
- 기존 `LoginGuideBadge`의 `goToLogin` 패턴과 동일한 방식 사용

**비고**: 설계 문서(screen-plan.md, client-guide.md)의 "로그인 상태에서만 접근 가능" 전제는 별도 수정 필요.

---

### ISS-003: 사용 완료 모달에서 쿠폰 유효기간(expiryDate)이 불필요하게 표시됨

| 항목 | 내용 |
|------|------|
| 분류 | bug |
| 발견일 | 2026-04-14 |
| 발견 단계 | QA |
| 심각도 | P2 |
| 영향 파트 | 서버, 웹, 디자인 |
| 상태 | 구현완료 |

**현상**: 쿠프마케팅 쿠폰 사용 완료 모달에서 "유효기간: 202x.xx.xx"가 표시되고 있다.

**원인**: check API 응답의 `expiryDate`는 쿠프마케팅 L0 API의 `EndDay` 필드로, **쿠폰 자체의 사용 기한**(카카오 선물하기 쿠폰의 만료일)이다. 유효한 쿠폰을 사용하여 교환된 상품(하트, 스킬 이용권)에는 별도의 유효기간이 없으므로, 사용 완료 후 이 날짜를 표시하는 것은 잘못된 정보 전달이다. `expiryDate`는 서버에서 사용 가능 여부 판단(L0 검증)에만 사용하면 된다.

**웹 해결**: expiryDate 표시/전달 전면 제거.
- `coopHeartCompletePopup.tsx`: expiryDate prop 및 유효기간 표시 제거
- `coopSkillVoucherItem.tsx`: expiryDate 관련 표시(만료일, 남은 일수) 제거
- `couponCodeRegister.tsx`: expiryDate 전달 제거
- `types/coop.ts`: CoopSkillVoucher에서 expiryDate 필드 제거
- 번역 키 `coop_heart_complete_expiry` 제거 (ko/en/ja)

**서버 해결**: check API 응답(CheckCoopMarketingCouponResponseDto)에서 `expiryDate` 필드 제거. Service의 heart/skill 응답 모두에서 `expiryDate: apiResponse.EndDay` 삭제.

**잔여 범위**:
- **iOS/Android**: 완료 모달 구현 시 유효기간 미표시

---

### ISS-004: useCoupon L0 재검증의 에러코드가 check와 불일치

| 항목 | 내용 |
|------|------|
| 분류 | bug |
| 발견일 | 2026-04-14 |
| 발견 단계 | 리뷰 |
| 심각도 | P2 |
| 영향 파트 | 서버 |
| 상태 | 구현완료 |

**현상**: check API에서는 쿠프마케팅 응답코드(8003→CM_002, 8005→CM_003)를 세분화하여 매핑하도록 수정했으나, useCoupon의 L0 재검증(coupc-marketing.ts:270-271)에서는 모든 실패를 `CM_INVALID_COUPON`(CM_001)으로 뭉뚱그리고 있다. 이미 사용된 쿠폰을 재시도하면 check에서는 "이미 사용된 쿠폰입니다"가 뜨지만 use에서는 "유효하지 않은 쿠폰입니다"가 표시되어 사용자 메시지가 일관되지 않다.

**원인**: check의 에러코드 매핑 수정 시 useCoupon의 L0 재검증 분기를 함께 수정하지 않음.

**해결**: useCoupon L0 재검증에 check와 동일한 에러코드 분기 적용. UseYN="Y" → CM_003, ResultCode 8003 → CM_002, 8005 → CM_003, 기타 → CM_001.

---

### ISS-005: admin locale 띄어쓰기 불일치 (unuse vs cancel)

| 항목 | 내용 |
|------|------|
| 분류 | bug |
| 발견일 | 2026-04-14 |
| 발견 단계 | 리뷰 |
| 심각도 | P3 |
| 영향 파트 | 서버 |
| 상태 | 구현완료 |

**현상**: admin/locale.ts에서 `unuse: "사용 취소"`(띄어쓰기 있음)와 `cancel: "사용취소"`(띄어쓰기 없음)로 같은 성격의 액션 라벨 표기가 불일치.

**원인**: 기존 `unuse` 라벨과 신규 `cancel` 라벨 추가 시 표기 통일 누락.

**해결**: `cancel: "사용취소"` → `cancel: "사용 취소"`로 수정.

---

### ISS-006: 쿠프마케팅 응답코드 8099(결제취소 쿠폰)에 대한 별도 에러 메시지 없음

| 항목 | 내용 |
|------|------|
| 분류 | enhancement |
| 발견일 | 2026-04-14 |
| 발견 단계 | 리뷰 |
| 심각도 | P3 |
| 영향 파트 | 서버 |
| 상태 | 구현완료 |

**현상**: 쿠프마케팅 응답코드 `8099`(결제취소 쿠폰 — 카카오 선물하기에서 결제 자체가 취소된 쿠폰)가 현재 `CM_001`(유효하지 않은 쿠폰)으로 폴백되어 "유효하지 않은 쿠폰입니다"가 표시된다. 사용자 입장에서는 왜 유효하지 않은지 알 수 없다.

**원인**: check API의 에러코드 매핑(coupc-marketing.ts:186-190)에서 `8003`, `8005`만 세분화하고 `8099`는 기본값(`CM_001`)으로 처리. requirements.md에 `8099`가 정의되어 있으나 별도 내부 에러코드가 없음.

**해결**: `CM_PAYMENT_CANCELED_COUPON`(CM_010) 에러코드 추가. 8099 → CM_010 매핑을 check API와 useCoupon L0 재검증 모두에 적용. 한국어 메시지: "결제가 취소된 쿠폰입니다".

---

## 해결된 이슈

### ISS-001: 쿠폰 취소 후 재사용 시 CM_007 에러 (유니크 제약 위반 + 하트 누수)

| 항목 | 내용 |
|------|------|
| 분류 | edge-case |
| 발견일 | 2026-04-13 |
| 해결일 | 2026-04-14 |
| 심각도 | P1 — 하트 누수 발생 |
| 영향 파트 | 서버 |

**해결 방안**:
- usage INSERT → UPSERT (ON CONFLICT → UPDATE)로 재사용 시 유니크 제약 위반 방지
- 처리 순서 변경: usage UPSERT 우선 → chargeHeart/issueCoupon 후속 (하트 누수 원천 차단)
- Admin 수동 취소 시 상품 회수 추가 (하트 차감 + 회수 로그, 스킬 이용권 삭제)

**관련 문서 변경**:
- requirements.md F4 (F4-1 자동 취소, F4-2 Admin 수동 취소 분리)
- design.md §5-2~§5-5 (처리 순서, 자동 복구, Admin 취소)
- HeartLog.ts: UseByGiftCouponRecovery 타입 추가
- coupc-marketing.ts: upsertUsage, adminCancelCoupon, getAdminCancelInfo
- Admin options: cancel handler → adminCancelCoupon 호출
