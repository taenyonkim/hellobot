# 이슈 목록

## 이슈 분류
- **bug**: 구현이 설계와 다름
- **edge-case**: 설계에서 고려하지 못한 예외 상황
- **enhancement**: 기존 요구사항 범위 밖의 개선

---

## 미해결 이슈

(없음)

---

## 해결된 이슈

### ISS-006: 쿠프마케팅 응답코드 8099(결제취소 쿠폰)에 대한 별도 에러 메시지 없음

| 항목 | 내용 |
|------|------|
| 분류 | enhancement |
| 발견일 | 2026-04-14 |
| 해결일 | 2026-04-14 |
| 심각도 | P3 |
| 영향 파트 | 서버 |

**해결**: `CM_PAYMENT_CANCELED_COUPON`(CM_010) 에러코드 추가. 8099 → CM_010 매핑을 check API와 useCoupon L0 재검증 모두에 적용. 한국어 메시지: "결제가 취소된 쿠폰입니다".

---

### ISS-005: admin locale 띄어쓰기 불일치 (unuse vs cancel)

| 항목 | 내용 |
|------|------|
| 분류 | bug |
| 발견일 | 2026-04-14 |
| 해결일 | 2026-04-14 |
| 심각도 | P3 |
| 영향 파트 | 서버 |

**해결**: `cancel: "사용취소"` → `cancel: "사용 취소"`로 수정.

---

### ISS-004: useCoupon L0 재검증의 에러코드가 check와 불일치

| 항목 | 내용 |
|------|------|
| 분류 | bug |
| 발견일 | 2026-04-14 |
| 해결일 | 2026-04-14 |
| 심각도 | P2 |
| 영향 파트 | 서버 |

**해결**: useCoupon L0 재검증에 check와 동일한 에러코드 분기 적용. UseYN="Y" → CM_003, ResultCode 8003 → CM_002, 8005 → CM_003, 8099 → CM_010, 기타 → CM_001.

---

### ISS-003: 사용 완료 모달에서 쿠폰 유효기간(expiryDate)이 불필요하게 표시됨

| 항목 | 내용 |
|------|------|
| 분류 | bug |
| 발견일 | 2026-04-14 |
| 해결일 | 2026-04-14 |
| 심각도 | P2 |
| 영향 파트 | 서버, 웹 |

**해결**:
- 서버: check API 응답에서 `expiryDate` 필드 제거 (DTO + Service)
- 웹: 완료 팝업/이용권 카드에서 유효기간 표시 제거, 번역 키 삭제, 타입 정리
- 설계 문서: api-spec.md, client-guide.md, design.md에서 expiryDate 필드 제거
- iOS/Android: 미구현 상태이므로 client-guide.md 반영으로 대응 완료

---

### ISS-002: 미로그인 상태에서 쿠폰 입력창 클릭/등록 시 로그인 안내 팝업 미표시

| 항목 | 내용 |
|------|------|
| 분류 | bug |
| 발견일 | 2026-04-14 |
| 해결일 | 2026-04-14 |
| 심각도 | P2 |
| 영향 파트 | 웹 |

**해결**: `couponCodeRegister.tsx`에 anonymous 체크 추가. 입력창 포커스 시 `goToLogin('?fallbackUrl=/coupon')` 호출.

---

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
