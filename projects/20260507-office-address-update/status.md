# 개발 상태

## 현재 상태: 배포중 (web · report-webview 운영 / webview 코드리뷰)

## 파트별 현황

| 파트 | 상태 | 브랜치 | 워크트리 | 비고 |
|------|------|--------|---------|------|
| 기획 | 완료 | - | - | 영향 파일 전수 검색 + 새 주소 SSOT 확정 |
| 서버 | 해당없음 | - | - | 코드 내 주소 임베드 없음 |
| iOS | 해당없음 | - | - | |
| Android | 해당없음 | - | - | |
| 웹 | 배포중 | feat/office-address-update | worktrees/{hellobot-web,hellobot-webview,hellobot-report-webview} | hellobot-web: PR [#997](https://github.com/thingsflow/hellobot-web/pull/997) main 머지 + deploy-prod 푸시 완료 (운영 배포 진행). hellobot-webview: PR [#2912](https://github.com/thingsflow/hellobot-webview/pull/2912) 코드리뷰 대기 (main 머지 시 자동 운영). hellobot-report-webview: PR [#422](https://github.com/thingsflow/hellobot-report-webview/pull/422) main 머지 완료 + prod-report-web-deploy 푸시 완료 → AWS Amplify 자동 배포. dev 환경: 3 리포 모두 deploy-dev / dev-report-web-deploy 푸시 완료. |
| 스튜디오 | 해당없음 | - | - | |
| 데이터 | 해당없음 | - | - | |
| 인프라 | 해당없음 | - | - | |
| QA | 대기 | - | - | 운영 배포 후 화면 검증 |

## 블로커

없음

## 확정 사항

| 항목 | 내용 |
|------|------|
| 새 주소 (한) | 서울특별시 마포구 잔다리로7길 3, 5층 501호(서교동) |
| 새 주소 (영) | 501, 3 Jandari-ro 7-gil, Mapo-gu, Seoul, Republic of Korea |
| 새 주소 (일) | ソウル特別市 麻浦区 ジャンダリ路7ギル 3, 5階501号 (西橋洞) |
| 영문 호수 | 501 (한·일과 일치 — 직전 양화로 시기의 404 표기 오류 정정) |
| 변경 범위 | 주소만. 회사명/대표자/사업자번호/계좌/이메일은 변경 없음 |
| 제외 채널 | Notion 약관, PG 가맹점, App Store/Play Store 사업자정보, 메일 템플릿 등 외부 채널 — 별도 운영 트랙 |
| 영향 리포 | hellobot-web, hellobot-webview, hellobot-report-webview (서버/모바일/스튜디오/데이터/인프라 영향 없음) |
| 다음 단계 | 코드 리뷰 → 운영 배포 (3 PR 동시) → `/qa` |
| 일본어 footer 표기 통일 | webview ja `大韓民国` prefix 제거. 3 리포 모두 SSOT 그대로 `ソウル特別市 麻浦区 ジャンダリ路7ギル 3, 5階501号 (西橋洞)` 사용 (각 리포 `docs/features/20260507-office-address-update/status.md` 결정 로그) |
