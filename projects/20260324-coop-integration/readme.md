# 쿠프마케팅 카카오 선물하기 상품권 연동

## 배경

쿠프마케팅(상품권 전문 제휴업체)과 연동하여 카카오 선물하기 상품권 기능을 헬로우봇에 추가한다. 카카오 선물하기에서 구매한 상품권(하트 충전권, 스킬 교환권)을 헬로우봇 앱에서 쿠폰번호로 등록하여 사용할 수 있도록 한다.

## 목표

- 쿠프마케팅 API를 통한 카카오 선물하기 상품권 발급/관리 연동
- 하트 충전권: 상품권 등록 → 즉시 하트 충전
- 스킬 교환권: 상품권 등록 → 100% 할인 쿠폰 발급 → 기존 스킬 구매 플로우로 0하트 구매
- 상품 관리 Admin 페이지 (상품 CRUD, 사용 이력 조회, API 로그 조회, 정산 통계)

## 범위

- 포함:
  - 쿠프마케팅 API 연동 (L0 조회, L1 사용, L2 사용취소, L3 망취소)
  - 하트 충전권 (즉시 충전, HeartService 재사용)
  - 스킬 교환권 (100% 할인 쿠폰 발급 → 기존 구매 플로우)
  - 상품 관리 Admin 페이지 + 정산 통계
  - API 호출 전문 로그
  - 클라이언트 UI (네이티브: iOS, Android, Web)
- 제외:
  - 부분 사용 (전액 1회 소진만 지원)
  - 활성화(A1)/충전(C1) 프로세스 (쿠프마케팅 측 처리)

## 영향 범위

| 파트 | 영향 | 설명 |
|------|------|------|
| 서버 | O | 쿠프마케팅 API 연동, Entity/Service/Controller, Admin 페이지 |
| iOS | O | 쿠폰 등록 UI, 하트 충전/스킬 교환 확인 팝업, 딥링크 |
| Android | O | 쿠폰 등록 UI, 하트 충전/스킬 교환 확인 팝업, 딥링크 |
| 웹 | O | 쿠폰 등록 UI (웹 버전) |
| 스튜디오 | X | 해당없음 |
| 데이터 | X | 해당없음 (추후 필요시 추가) |

## 문서 목록

### 프로젝트 문서 (공통 참조)

| 문서 | 설명 |
|------|------|
| [1pager.md](./1pager.md) | 프로젝트 1-pager |
| [requirements.md](./requirements.md) | 요구사항 정의서 |
| [user-stories.md](./user-stories.md) | 사용자 스토리 (US-1~US-6) |
| [screen-plan.md](./screen-plan.md) | 화면 기획서 |
| [designs/wireframe-v3.html](./designs/wireframe-v3.html) | 와이어프레임 확정본 |
| [references/](./references/) | 쿠프마케팅 API 레퍼런스, 연동 가이드 PDF |
| [planning/](./planning/) | 기획 과업 산출물 (기존 시스템 검토, 교환 방식 비교, 프라이싱 전략) |
| [status.md](./status.md) | 전체 진행 상태 및 워크트리/브랜치 현황 |
| [tasks.md](./tasks.md) | 파트별 과업 목록 |
| [issues.md](./issues.md) | 이슈 추적 |
| [architecture.md](./architecture.md) | 기술 설계 (데이터 흐름, 데이터 모델, 파트별 구현 포인트) |
| [api-spec.md](./api-spec.md) | 클라이언트용 API 명세 |
| [client-guide.md](./client-guide.md) | 클라이언트 개발 가이드 |
| [qa-test-cases.md](./qa-test-cases.md) | QA 테스트 케이스 (74건) |

### 리포 레벨 상세 문서 (hellobot-server)

워크트리 `worktrees/hellobot-server/docs/features/20260324-coupc-marketing-kakao-gift/` 내:

| 문서 | 설명 |
|------|------|
| `backend-architecture.md` | 백엔드 설계 (Entity, Service, 테이블 상세) |
| `backend-guide.md` | 백엔드 개발 가이드 (구현 순서, 코드 골격) |
| `testing/` | 테스트 플랜 및 결과 |
| `deployment/` | 배포 가이드 |
