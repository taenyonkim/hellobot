# 개발 상태

## 현재 상태: 개발중

## 워크트리/브랜치 현황

| 파트 | 리포 | 브랜치 | 워크트리 | PR |
|------|------|--------|---------|-----|
| 서버 | hellobot-server | feat/coupnc-integration | worktrees/hellobot-server/ | - |
| iOS | hellobot_iOS | - | - | - |
| Android | hellobot_android | - | - | - |
| 웹 | hellobot-web | - | - | - |

## 파트별 진행 상태

| 파트 | 상태 | 담당 | 비고 |
|------|------|------|------|
| 서버 | 개발중 | /dev-server | Entity, Service, Controller, Admin 구현 완료. 정산 통계 미완. |
| iOS | 대기 | /dev-ios | 서버 API 완료 및 api-spec.md 작성 후 착수 |
| Android | 대기 | /dev-android | 서버 API 완료 및 api-spec.md 작성 후 착수 |
| 웹 | 대기 | /dev-web | 서버 API 완료 후 착수 |
| 스튜디오 | 해당없음 | - | |
| 데이터 | 해당없음 | - | |

## 서버 개발 상세 진행

- [x] 요구사항 정의 (requirements.md)
- [x] 기존 시스템 검토 (기프티엘, 하트, 쿠폰 시스템)
- [x] 교환 방식 확정 (하트=즉시충전, 스킬=100%할인쿠폰)
- [x] 백엔드 설계 (backend-design.md)
- [x] 사용자 스토리 정의 (user-stories.md)
- [x] 화면 기획서 + 와이어프레임 v3 확정
- [x] 백엔드 개발 가이드 (backend-guide.md)
- [x] Entity 3개 + Migration + HeartLogType + Config + ErrorCode
- [x] DTO + Service + Controller
- [x] Admin 페이지 (상품 관리, 사용 이력, API 로그)
- [x] API 테스트 — 필수 동작 (Phase 1~6 통과)
- [x] API 테스트 — 전체 (40건 중 28건 통과, 11건 보류)
- [ ] Admin 정산 통계 custom page
- [ ] api-spec.md (클라이언트용 API 명세) — 미작성
- [ ] client-guide.md (클라이언트 개발 가이드) — 미작성
- [ ] 클라이언트 연동
- [ ] 배포

## 대기 중 외부 확인

| 항목 | 상태 | 비고 |
|------|------|------|
| 상용 인증키 (Auth_Key) | 대기 | 테스트키와 동일 여부 확인 필요 |
| 쿠폰번호 프리픽스 | 대기 | 코드 판별 로직에 필요 |

## 작업 로그

### 2026-04-12 — 워크스페이스 프로젝트 세팅

기존 hellobot-server의 feat/coupnc-integration 브랜치에서 진행 중이던 프로젝트를 워크스페이스 프로젝트로 등록.
- 완료: projects/20260324-coupc-marketing-kakao-gift/ 생성
- 완료: 기존 문서 검토 후 워크스페이스 레벨 readme.md, status.md, tasks.md 작성
- 다음: 서버 워크트리 세팅, 잔여 서버 개발(정산 통계), api-spec.md 작성, 클라이언트 착수

### 2026-03-24 ~ 2026-04-09 — 서버 개발 (기존 작업)

hellobot-server/docs/features/20260324-coupc-marketing-kakao-gift/status.md에 상세 로그 기록.
주요 이력:
- 03-24: 프로젝트 시작, 요구사항 정의, 기존 시스템 검토
- 03-31: Admin 설계, 교환 방식 검토
- 04-01: 사용자 스토리 정의
- 04-06: 스킬 교환 방식 확정 (100%할인쿠폰), 쿠프마케팅 답변 반영
- 04-07: 백엔드 코드 구현 완료 (Entity, Service, Controller, Admin)
- 04-08: 개발환경 정보 반영 (CompCode, 테스트쿠폰)
- 04-09: API 테스트 완료 (28/40 통과)
