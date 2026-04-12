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
| 서버 | 개발중 | /dev-server | [worktrees/hellobot-server/docs/features/.../status.md](./worktrees/hellobot-server/docs/features/20260324-coupc-marketing-kakao-gift/status.md) |
| iOS | 대기 | /dev-ios | - |
| Android | 대기 | /dev-android | - |
| 웹 | 착수전 | /dev-web | [worktrees/hellobot-web/docs/features/.../status.md](./worktrees/hellobot-web/docs/features/20260324-coupc-marketing-kakao-gift/status.md) |
| 스튜디오 | 해당없음 | - | - |
| 데이터 | 해당없음 | - | - |

> 각 파트의 구현 상세 및 작업 로그는 리포 레벨 status.md에 기록합니다.
> 이 문서에는 프로젝트 전체 요약과 파트 간 조율 사항만 기록합니다.

## 파트별 요약

| 파트 | 진행 요약 |
|------|----------|
| 서버 | Entity/Service/Controller/Admin 구현 완료. 잔여: 정산 통계. api-spec.md, client-guide.md 작성 완료. |
| 웹 | 워크트리 세팅 완료. 구현 착수 전. |

## 확정 사항

| 항목 | 상태 | 내용 |
|------|------|------|
| 상용 인증키 (Auth_Key) | 확정 | 개발/상용 동일 |
| 쿠폰번호 프리픽스 | 확정 | 90, 91 |

## 블로커

현재 없음.

## 작업 로그

### 2026-04-12 — 프로젝트 구조 정비

- 2레벨 문서 추적 도입 (프로젝트 요약 + 리포별 상세)
- hellobot-web 피쳐 문서 생성 (web-guide.md, status.md)
- 쿠폰번호 프리픽스 확정 (90, 91), 인증키 확정 (개발/상용 동일)
- api-spec.md, client-guide.md 작성 완료 → 클라이언트 착수 가능

### 2026-04-12 — 워크스페이스 프로젝트 세팅

기존 hellobot-server의 feat/coupnc-integration 브랜치에서 진행 중이던 프로젝트를 워크스페이스 프로젝트로 등록.

### 2026-03-24 ~ 2026-04-09 — 서버 개발

서버 상세 로그: worktrees/hellobot-server/docs/features/20260324-coupc-marketing-kakao-gift/status.md
