# 과업 목록

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
- [ ] 쿠폰 등록 UI에 상품권 코드 처리 연동
- [ ] 하트 충전 / 스킬 교환 결과 화면

## 스튜디오 (/dev-studio)
해당없음

## 데이터 (/dev-data)
해당없음 (추후 정산 데이터 파이프라인 필요 시 추가)

## 의존 관계
- ~~서버 api-spec.md 작성 완료 → iOS, Android, Web 착수 가능~~ ✅ 완료
- 서버 Admin 정산 통계 완료 → 운영 배포 가능
- ~~쿠프마케팅 상용 인증키 수령 → 프로덕션 배포 가능~~ ✅ 개발/상용 동일
- ~~쿠폰번호 프리픽스 확정 → 코드 판별 로직 최종 확정~~ ✅ 90, 91 확정
