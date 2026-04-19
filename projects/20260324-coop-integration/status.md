# 개발 상태

## 현재 상태: 개발중 (Phase 1 구현 완료, QA 검증 대기)

> 2026-04-19: ISS-011 + ISS-009 해결을 위한 **아키텍처 전면 개편**. 서버 단일 진입점 + 1단계 원샷 플로우로 전환.
> 2026-04-20: 서버/iOS/Android/웹 Phase 1 구현 완료. QA TC 재편성 완료 (145건, xlsx v5). 배포 및 QA 검증 단계 진입.

## 파트별 현황

| 파트 | 상태 | 브랜치 | 워크트리 | 비고 |
|------|------|--------|---------|------|
| 기획 | 진행중 | - | - | 스킬 이용권 라인업 선정, 최종 상품 구성 확정 잔여 |
| 디자인 | 완료 (Phase 1 반영 완료) | - | - | 2026-04-19: S2 확인 팝업 제거 반영 (1단계 전환) |
| 서버 | Phase 1 구현 완료 | feat/coupnc-integration | worktrees/hellobot-server/ | Phase 1 구현 완료 (2026-04-19): `POST /api/coupon/register`, `CouponPrefixRule` 엔티티+시드, `CO_APP_UPDATE_REQUIRED`, 진입 가드, `registerOneShot`(Redlock), AdminJS, `/api/coop/*` @deprecated. 잔여: 메트릭 수집, API 테스트 추가, ja/en 번역 검수 |
| iOS | Phase 1 구현 완료 | feat/coop-integration | worktrees/hellobot_iOS/ | Phase 1 전환 완료 (04-19): 프리픽스 분기 제거 + 단일 API + S2 삭제 + ISS-018 해결. QA 대응 잔여 |
| Android | Phase 1 구현 완료 | feat/coop-integration | worktrees/hellobot_android/ | Phase 1 전환 완료 (04-19): 프리픽스 분기 제거 + 단일 API + S2 삭제. QA 대응 잔여 |
| 웹 | Phase 1 구현 완료 | feat/coop-integration | worktrees/hellobot-web/ | Phase 1 전환 완료 (04-19~20): 프리픽스 분기 제거 + 단일 API + S2 삭제 + ISS-017 해결. 웹뷰 검증 잔여 |
| 스튜디오 | 해당없음 | - | - | |
| 데이터 | 해당없음 | - | - | |
| QA | Step A 완료 (플랫폼별 재편성, 검증 대기) | - | - | 145건 (폐기 63건 제거 후). 플랫폼별 재편성 (Web 44, iOS 20, AOS 20, Admin·Server 47 + Skip 2). xlsx v5 생성 (5 시트: Web, iOS, Android, Admin·Server, 요약). TC ID 체계 변경 (TC-W-*, TC-I-*, TC-A-*, P1-*, TC-M*/N*/A*-DEP). 이전 버전 v4 감사 추적 보존. Step B 검증 대기 |

## 잔여 과업 요약

| # | 과업 | 파트 | 블로커 | 비고 |
|---|------|------|--------|------|
| 1 | Phase 1 서버 구현 (register + 가드 + PrefixRule) | 서버 | 없음 | ISS-011, ISS-009, ISS-015 통합 해소 |
| 2 | Phase 1 클라이언트 구현 (분기 제거 + 단일 API + S2 삭제) | iOS/Android/Web | #1 완료 | |
| 3 | Phase 1 QA 재검증 | QA | #2 완료 | 구버전 회귀 포함 |
| 4 | 카카오 딥링크 진입 처리 | iOS, Android | 딥링크 스킴 미확정 | 기존 COUPON 딥링크 재사용 검토 |
| 5 | Admin 정산 통계 custom page | 서버 | 없음 | 운영 배포 전 필요 |
| 6 | 웹뷰 환경 검증 | 웹 | 없음 | 모바일 앱 내 WebView 동작 확인 |
| 7 | 일본어 번역 검수 | 웹 | 없음 | |
| 8 | 스킬 이용권 라인업 선정 | 기획 | 없음 | |
| 9 | 최종 상품 구성 확정 | 기획 | #8 완료 후 | |
| 10 | Phase 2 `/api/coop/*` 엔드포인트 제거 | 서버 | Phase 1 전파트 배포 완료 후 | 별도 릴리스 |

## 블로커

없음. Phase 1 서버 구현 완료 후 클라이언트 작업 착수 가능.

## Phase 1 배포 순서 (엄수)

상세: [architecture.md §9](./architecture.md), [tasks.md 의존 관계](./tasks.md)

```
서버 프로덕션 배포
    ↓ (헬스체크 + 스모크 테스트 통과)
웹 배포 + iOS/Android 앱스토어 제출
    ↓ (신버전 릴리스 순차 진행)
구버전 잔존율 모니터링
    ↓ (4주 경과 + 호출률 < 0.1%)
Phase 2: /api/coop/* 엔드포인트 제거
```

**위험**: 클라이언트 선행 배포 시 신버전 클라이언트가 존재하지 않는 엔드포인트 호출 → 장애. 서버 선행 필수.
**롤백**: 서버 롤백 전 신버전 클라이언트를 먼저 되돌려야 안전.

## 확정 사항

| 항목 | 내용 |
|------|------|
| 상용 인증키 (Auth_Key) | 개발/상용 동일 |
| 쿠폰번호 프리픽스 | 90, 91 (DB `coupon_prefix_rule` 시드 데이터) |
| 쿠폰 형식 판별 | 서버 단일 진입점 (`POST /api/coupon/register`) — 확정 2026-04-19 |
| 쿠폰 등록 단계 | 1단계 원샷 — 확정 2026-04-19 |
| 구버전 앱 대응 | 서버 `/api/coupon` 가드 → `CO_APP_UPDATE_REQUIRED` 토스트 — 확정 2026-04-19 |
| 앱 업데이트 메시지 | "앱 업데이트가 필요한 쿠폰이에요." — 확정 2026-04-19 |
| 기획-디자인 정합성 | 검토 완료 (04-18). S2 팝업 제거 반영 (04-19) |
