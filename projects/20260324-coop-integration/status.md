# 개발 상태

## 현재 상태: 개발중 (Phase 1 구현 완료, QA 검증 대기)

> 2026-04-19: ISS-011 + ISS-009 해결을 위한 **아키텍처 전면 개편**. 서버 단일 진입점 + 1단계 원샷 플로우로 전환.
> 2026-04-20: 서버/iOS/Android/웹 Phase 1 구현 완료. QA TC 재편성 완료 (145건, xlsx v5). 배포 및 QA 검증 단계 진입.
> 2026-04-21: ISS-021/022 (expiresAt 무제한 + sentinel + `isUnlimited` 재설계) 서버·iOS·Android·Web 해결 완료. ISS-023/024 (S4 링크 우측 정렬) iOS·Android 해결. ISS-016 Web 해결 (토스트 2.5초). ISS-017 Web 해결 (쿠폰 리스트 즉시 반영). "모바일 웹뷰 환경 검증" 항목은 아키텍처 확정(앱 네이티브 / 웹 브라우저 독립) 결과 해당 없음으로 종결.
> 2026-04-21: Notion 스프린트 태스크 5건을 ISS-025~029로 등록. ISS-025 웹 재진입 시 스킬 카드 하단 유실(P2), ISS-026 iOS 쿠폰 에러 메시지 표시 오류(P2), ISS-027 iOS 스킬 보러가기 화살표 이미지 리소스 교체(P3), ISS-028 Android S3 모달 여백·이미지 크기(P2), ISS-029 AdminJS 메뉴명 한글화(P3). 각 파트 tasks.md에 과업 추가.
> 2026-04-21: Android ISS-016/019/020/028 일괄 해결 재확인 및 반영. ISS-028(S3 모달) — design-spec "공통 컴포넌트 팝업"(288dp / shadow `0 8 24 rgba(0,0,0,0.24)`) 규칙에 맞춰 카드 폭 288dp 고정 + shadow(elevation 24dp) + 일러스트 240×117dp로 수정.
> 2026-04-21: iOS ISS-026/027 해결. ISS-026은 `CouponRegisterErrorMapper` 신설로 서버 ko 메시지 우선/폴백 + 오프라인 한글 메시지 치환. ISS-027은 "스킬 보러가기" 라벨 + SF Symbol `chevron.right` (violet400 틴트) horizontal stack으로 텍스트 `>` 제거.
> 2026-04-22: Android ISS-027 해결 — `coop_link_view_skill` 문자열 3종(ko/ja/en)에서 ` >` 제거 + `CouponItem.kt` 우측 링크를 `Row(Text + Icon)` 구조로 재구성. 기존 벡터 드로어블 `icon_arrow_right_16` 재사용 + `Icon(tint = violet400)`로 색 오버라이드.
> 2026-04-22: Web QA 이슈 4건 해결 — ISS-032(화살표 violet inline SVG), ISS-037(라벨 스타일 CouponItem 일치), ISS-042(버튼 인라인 스피너 + 풀스크린 Loading 제거), ISS-036(bfcache 복원 시 `pageshow` 훅 + `mutate('/api/coupon')` 재조회). ISS-031/034/035/033은 외부 의존(디자이너/서버/Android/아키텍트) 답변 대기.
> 2026-04-22: Web QA 이슈 2건 추가 해결 — ISS-031(사용자 결정 준용: `CoopSkillVoucherItem`을 `CouponItem` 수직 리듬 모방 + 서브텍스트 `invisible` reserve로 카드 높이 동일화), ISS-035(사용자 결정 준용: 신규 자산 발급 없이 기존 `public/images/heart/heart_charge.gif` 재사용, `BonusHeartModal`의 plain `<img>` + `?t=` 캐시 버스터 패턴 이식). 잔여: ISS-033(`/architect` 대기), ISS-034(QA 재검증 대기).
> 2026-04-22: iOS ISS-042 해결 — 사용자 결정(스피너 미구현, disable + 회색만) 반영. `CouponInputFieldView`에 `isInputFilledRelay` + `isRegisteringRelay` BehaviorRelay 2개 + `setupContext()` combineLatest(`filled && !registering`) → `sendButton.rx.isEnabled` 단일 진실 공급원. `CouponListViewController.registerCoupon(code:)` `.do(onSubscribe:/onDispose:)` 훅으로 API 라이프사이클 전체 리셋 보장. 회색은 기존 disabled 토큰(gray400/gray200) 재사용, 신규 색상 정의 없음.
> 2026-04-23: iOS ISS-039 해결 — 서버 i18n 배포(ISS-044 포함, 커밋 ba674b3b) 후 `CouponRegisterErrorMapper` 판정 완화. `resolve()` / `ReasonServerError` 경로에서 `containsHangul` 게이트 제거 → 서버 `message`/`reason` non-empty 시 그대로 표시(ja/en 번역 자연 반영), 빈 문자열·offline 등 서버 응답 없음 경로만 `codeMessages[code]` ko 상수 safety net 폴백. `nonEmpty(_:)` 헬퍼 도입으로 trim/empty 가드 통일. 기존 쿠폰 플로우(`/api/coupon`, `/api/coupon/send` 등) 비경유 — coop-integration 단일 진입점만 영향. 단위 테스트 작성은 후속 별건.
> 2026-04-23: Web dev 배포본 QA 3건 해결 — ISS-030(미로그인 입력창/등록 버튼 포커스 시 `common_toast_plz_login` 토스트 선행 후 `goToLogin` 호출로 iOS/Android와 UX 정합), ISS-033(일반 쿠폰 성공 토스트 `coupon_register_success_toast` ko/ja/en 번역 키 신규 + `case 'coupon':` 분기 dispatch 추가 — iOS와 동일 키/문구), ISS-034(스킬 이용권 카드 `{data.skillName}`만 렌더 + 접미사 덧붙이기 템플릿 키 `coop_skill_voucher_name` ko/ja/en 삭제 — "쿠폰명 이용권 이용권" 중복 해소).
> 2026-04-23: **ISS-047 등록** — iOS 스킬 이용권 카드 "스킬 보러가기" 링크 en/ja 번역 누락. `CouponItemModel.swift:324` 한글 리터럴 하드코딩 결함. 문구 확정: ko "스킬 보러가기" / en "View Skill" / ja "スキルを見る" (Android `coop_link_view_skill` 3종과 통일, ISS-027 해결 시 `>` 제거 정합). design-spec.md §S4 + client-guide.md §S4 **i18n 문구 3종 확정** 명시 추가. iOS `/dev-ios` 구현 과업 발주 — ResourceKit 키 1건 × 3언어 추가 + 리터럴 교체.
> 2026-04-23: iOS QA 피드백 3건 일괄 해결 — ISS-040(이용권 배지 클라이언트 derive: `CouponItemCell.bind()`의 tags 렌더 직전 `effectiveTags` 파생 — `isSkillVoucher && !coupon.tags.contains(voucherTag)` 조건에서 "이용권" prepend, ResourceKit `coop_label_voucher` 3종 추가), ISS-041 재조정(행 collapse → reserve: `descriptionLabel.flex.isIncludedInLayout = false` 라인 제거 → 일반 쿠폰과 동일 높이 유지 + 텍스트만 숨김, 웹 ISS-031 reserve 전략과 정합), ISS-047(`coop_link_view_skill` 3종 추가 + 한글 리터럴을 `.Coupon.View.skillLink`로 치환). 수정 파일: `Hellobot/Feature/Coupon/CouponList/Views/CouponItemModel.swift`, `Modules/Common/ResourceKit/ResourceKit/Sources/Strings/String+Coupon.swift`, `Modules/Common/ResourceKit/ResourceKit/Resources/Localizable/{ko,en,ja}.lproj/Localizable.strings`. Android `coop_label_voucher`/`coop_link_view_skill` 3언어와 키명·값 완전 통일.
> 2026-04-24: **ISS-048 등록 + design-spec §S4 렌더 분기 규칙 재정의 (/architect)**. `/dev-ios` 점검에서 design-spec.md §S4 line 103-104 "모든 분기 동일 기준(AND)" 선언이 같은 문서 하위 문장(line 114 만료일 `isUnlimited` 단독 / line 116 링크 조건 비명시)과 api-spec.md 두 필드 독립성 계약과 **자기모순**임을 포착. 원인은 ISS-040 배지 derive 문구가 네 분기 전체에 과잉 일반화된 것. 재정의 방향은 "분기 2종 구조" — (1) 상품 자체 식별 분기(배지·부가설명 = AND), (2) 개별 속성 반응 분기(만료일 = `isUnlimited` 단독, 링크 = `fixedMenuSeq` 단독). design-spec §S4 상단 블록 교체 + line 116 링크 조건 명시 추가 + 레이아웃 도식 안내 추가 + Changelog 1줄. iOS/Android 코드 수정 0건(현 구현이 api-spec.md 규약과 이미 정합), Web 회귀 확인 `/dev-web` 발주. 서버·QA 영향 없음.
> 2026-04-24: **Web ISS-048 회귀 점검 + 해결** — 4개 요소 중 3 Pass, (B-2) "스킬 보러가기 링크 `fixedMenuSeq` 단독 조건" Fail(링크가 AND 분기된 `CoopSkillVoucherItem`에서만 렌더, `fixedMenuSeq != null && !isUnlimited` 쿠폰 미지원). 권장안 적용 — `CouponItem.tsx`에 optional `onSkillLinkClick?` prop 추가 + 내부 `fixedMenuSeq != null && onSkillLinkClick` 단독 조건 분기(동일 inline SVG + `coop_skill_voucher_link` 재사용), `app/coupon/page.tsx`가 `handleSkillVoucherClick` 주입, 하단 영역 좌(만료정보)+우(링크) `space-between` 재구성, `types/coupon.ts:20` 주석 갱신. iOS/Android(4/4 Pass, 무수정)와 함께 3개 클라이언트 모두 재정의된 2종 분기 구조 정합. 현 운영 환경 해당 쿠폰 타입 없어 QA 재현 불가 — 스펙 정합성 선제 보강.

## 파트별 현황

| 파트 | 상태 | 브랜치 | 워크트리 | 비고 |
|------|------|--------|---------|------|
| 기획 | 진행중 | - | - | 스킬 이용권 라인업 선정, 최종 상품 구성 확정 잔여 |
| 디자인 | 완료 (Phase 1 반영 완료) | - | - | 2026-04-19: S2 확인 팝업 제거 반영 (1단계 전환) |
| 서버 | Phase 1 완료 (QA 대응 잔여) | feat/coupnc-integration | worktrees/hellobot-server/ | Phase 1 구현 완료 (04-19): `POST /api/coupon/register`, `CouponPrefixRule` 엔티티+시드, `CO_APP_UPDATE_REQUIRED`, 진입 가드, `registerOneShot`(Redlock), AdminJS, `/api/coop/*` @deprecated. ISS-021 무제한 유효기간 (04-21). ISS-022 해결 (04-21). 잔여: 메트릭 수집, API 테스트 추가, ja/en 번역 검수, **ISS-029 AdminJS 메뉴명 한글화** |
| iOS | Phase 1 완료 (QA 이슈 10건 해소, 1건 대기) | feat/coop-integration | worktrees/hellobot_iOS/ | Phase 1 전환 완료 (04-19). ISS-018 해결 (04-19). ISS-019/021/022/023/026/027 해결 (04-21). ISS-030/033/035/038/041 해결 (04-22). ISS-042 해결 (04-22). **ISS-039 해결 (04-23)** — `CouponRegisterErrorMapper` 판정 완화(containsHangul 제거, non-empty 서버값 우선). **ISS-040/041 재조정/047 해결 (04-23)** — 이용권 배지 클라이언트 derive + 박스 높이 reserve 전환 + 스킬 보러가기 en/ja 번역. 잔여: ISS-036(실기기 재현 확인), 카카오 딥링크 진입 처리 |
| Android | Phase 1 완료 (QA 대응 잔여) | feat/coop-integration | worktrees/hellobot_android/ | Phase 1 전환 완료 (04-19). ISS-016/019/020/022/024/028 해결 (04-21). ISS-027 해결 (04-22). 잔여: 카카오 딥링크 진입 처리 |
| 웹 | Phase 1 완료 (QA 대응 진행) | feat/coop-integration | worktrees/hellobot-web/ | Phase 1 전환 완료 (04-19~20). ISS-017 해결 (04-19). ISS-016/022/025 해결 (04-21). ISS-031/032/035/036/037/042 해결 (04-22). **ISS-030/033/034 해결 (04-23)**. **ISS-048 해결 (04-24)** — `CouponItem`에 `fixedMenuSeq` 단독 조건 스킬 링크 분기 추가로 재정의된 2종 분기 구조 정합. 잔여: 없음 |
| 스튜디오 | 해당없음 | - | - | |
| 데이터 | 설계 초안 완료 | - | - | 2026-04-22 [planning/performance-analysis-design.md](planning/performance-analysis-design.md) 작성 — 이벤트 3종 스펙, `mart_coop_coupon_usage` 신규, `union_mart_user_key_actions.funnel_from_coop_coupon` 태깅, report 마트 2종, SQL 템플릿 5종, 외부 확인 8건. 서버 Phase 1 프로덕션 배포 후 착수 가능 |
| QA | Step A 완료 (플랫폼별 재편성, 검증 대기) | - | - | 145건 (폐기 63건 제거 후). 플랫폼별 재편성 (Web 44, iOS 20, AOS 20, Admin·Server 47 + Skip 2). xlsx v5 생성 (5 시트: Web, iOS, Android, Admin·Server, 요약). TC ID 체계 변경 (TC-W-*, TC-I-*, TC-A-*, P1-*, TC-M*/N*/A*-DEP). 이전 버전 v4 감사 추적 보존. Step B 검증 대기 |

## 잔여 과업 요약

| # | 과업 | 파트 | 블로커 | 비고 |
|---|------|------|--------|------|
| 1 | ~~Phase 1 서버 구현 (register + 가드 + PrefixRule)~~ | 서버 | — | ✅ 완료 (04-19) |
| 2 | ~~Phase 1 클라이언트 구현 (분기 제거 + 단일 API + S2 삭제)~~ | iOS/Android/Web | — | ✅ 완료 (04-19~20) |
| 3 | Phase 1 QA 재검증 | QA | #2 완료 | 구버전 회귀 포함. TC v10 기준 플랫폼 매트릭스 검증 진행 |
| 4 | 카카오 딥링크 진입 처리 | iOS, Android | 딥링크 스킴 미확정 | 기존 COUPON 딥링크 재사용 검토 |
| 5 | Admin 정산 통계 custom page | 서버 | 없음 | 운영 배포 전 필요 |
| 6 | ~~웹뷰 환경 검증~~ | 웹 | — | ✅ 해당 없음 종결 (04-21). 앱은 네이티브 `CouponListViewController`/`CouponListActivity`, 웹 `/coupon`은 스킬스토어 브라우저 전용 (architecture.md §6) |
| 7 | ~~일본어 번역 검수~~ | 웹 | — | ✅ 완료 |
| 8 | ~~ISS-019 스킬 이용권 카드 "스킬 보러가기 >" 링크~~ | Android | — | ✅ 해결 (04-21) |
| 9 | ~~ISS-020 스킬 이용권 등록 후 스킬 팝업 즉시 노출 제거 → 토스트 + 리스트 업데이트~~ | Android | — | ✅ 해결 (04-21) |
| 10 | ~~ISS-016 에러 토스트 지속시간 2.5초~~ | Android | — | ✅ 해결 (04-21, SafeToast) |
| 11 | 서버 ISS-009 메트릭/로그 수집 + API 테스트 추가 | 서버 | 없음 | 가드 발동 빈도 관측 |
| 12 | 스킬 이용권 라인업 선정 | 기획 | 없음 | |
| 13 | 최종 상품 구성 확정 | 기획 | #12 완료 후 | |
| 14 | Phase 2 `/api/coop/*` 엔드포인트 제거 | 서버 | Phase 1 전파트 배포 완료 후 | 별도 릴리스 |
| 15 | ~~ISS-025 웹 스킬 카드 재진입 시 하단 유실 수정~~ | 웹 | — | ✅ 해결 (04-21). Notion DLT-HLB-1002 |
| 16 | ~~ISS-026 iOS 쿠폰 에러 메시지 표시 오류 (영문/빈 토스트)~~ | iOS | — | ✅ 해결 (04-21). Notion DLT-HLB-1016 |
| 17 | ~~ISS-027 스킬 보러가기 화살표 이미지 리소스 교체~~ | iOS/Android | — | ✅ iOS 해결 (04-21), Android 해결 (04-22). Notion DLT-HLB-1020 |
| 18 | ~~ISS-028 Android S3 모달 여백·이미지 크기 정합성~~ | Android | — | ✅ 해결 (04-21). Notion DLT-HLB-1022 |
| 19 | ISS-029 AdminJS 메뉴명 한글화 ("쿠폰 분류 규칙 설정") | 서버 | 없음 | Notion DLT-HLB-1026 |

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
