# 과업 목록

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
- [ ] Admin 정산 통계 custom page
- [x] ISS-001: useCoupon 처리 순서 변경 — usage UPSERT 우선 + chargeHeart/issueCoupon 후속
- [x] ISS-001: Admin 수동 취소 시 상품 회수 (하트 차감 + 회수 로그, 이용권 삭제)
- [x] ISS-001: design.md §5-2, §5-3, §5-4, §5-5 변경 반영
- [x] 명칭 변경: coupc-marketing → coop-marketing (파일명, 클래스명, 설정키 등. DB 테이블명은 유지)
- [x] ISS-003: check API 응답에서 expiryDate 필드 제거 (DTO + Service)
- [x] ISS-004: useCoupon L0 재검증 에러코드를 check와 동일하게 세분화 (8003→CM_002, 8005→CM_003, UseYN→CM_003)
- [x] ISS-005: admin locale 띄어쓰기 통일 — cancel "사용취소" → "사용 취소"
- [ ] ISS-006: 결제취소 쿠폰(8099) 별도 에러 메시지 추가 검토 (해결 방안 논의 필요)
- [x] api-spec.md 작성 (클라이언트용 API 명세)
- [x] client-guide.md 작성 (클라이언트 개발 가이드)

## iOS (/dev-ios)
- [ ] 쿠폰 등록 화면에 상품권 코드 판별 로직 연동
- [ ] 하트 충전권 확인 팝업 (S2-A) + 충전 완료 팝업 (S3)
- [ ] 스킬 교환권 확인 팝업 (S2-B) + 토스트 + 이용권 카드 (S4)
- [ ] 에러 팝업 (S5) — 만료/사용완료/미존재 등
- [ ] 카카오 딥링크 진입 처리
- [ ] 내 하트 페이지 이동 / 스킬 상세 페이지 이동

## Android (/dev-android)
- [ ] 쿠폰 등록 화면에 상품권 코드 판별 로직 연동
- [ ] 하트 충전권 확인 팝업 (S2-A) + 충전 완료 팝업 (S3)
- [ ] 스킬 교환권 확인 팝업 (S2-B) + 토스트 + 이용권 카드 (S4)
- [ ] 에러 팝업 (S5) — 만료/사용완료/미존재 등
- [ ] 카카오 딥링크 진입 처리
- [ ] 내 하트 페이지 이동 / 스킬 상세 페이지 이동

## 웹 (/dev-web)
- [x] 쿠폰 등록 UI에 상품권 코드 처리 연동
- [x] 하트 충전 / 스킬 교환 결과 화면
- [x] ISS-002: 미로그인 상태에서 쿠폰 입력/등록 시 로그인 안내 처리 (입력 포커스+등록 버튼에서 goToLogin)
- [x] ISS-003: 완료 모달/이용권 카드에서 유효기간 표시 제거

## 스튜디오 (/dev-studio)
해당없음

## 데이터 (/dev-data)
해당없음 (추후 정산 데이터 파이프라인 필요 시 추가)

## 의존 관계
- ~~서버 api-spec.md 작성 완료 → iOS, Android, Web 착수 가능~~ ✅ 완료
- 서버 Admin 정산 통계 완료 → 운영 배포 가능
- ~~쿠프마케팅 상용 인증키 수령 → 프로덕션 배포 가능~~ ✅ 개발/상용 동일
- ~~쿠폰번호 프리픽스 확정 → 코드 판별 로직 최종 확정~~ ✅ 90, 91 확정
