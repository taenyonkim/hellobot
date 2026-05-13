# 사무실 주소 업데이트 (서교동 이전)

## Problem

뉴럴아케이드 사무실이 양화로 81 (H 스퀘어 4층 404호)에서 서교동(잔다리로7길 3, 5층 501호)으로 이전했다.
직전 [hellobot-webview/docs/20260331-transfer-update](../../hellobot-webview/docs/20260331-transfer-update/development-plan.md) 작업으로 모든 사용자 노출 채널의 주소가 "양화로 81"로 동기화되어 있어, 신규 주소를 미반영 시 footer/약관/특정상거래법 공시에서 폐쇄된 주소가 노출된다.

## Customer Job

- 사용자/이용자: footer·약관·결제 공시에서 정확한 사업장 주소를 확인할 수 있어야 한다 (전자상거래법·특정상거래법 의무).
- 회사: 외부 감사·고객문의·법적 분쟁 시 코드 베이스가 등기상 주소와 일치해야 한다.

## Solution / Feature

웹 3개 리포 (hellobot-web, hellobot-webview, hellobot-report-webview) 의 i18n 리소스와 일본 특정상거래법 공시 페이지의 주소 문자열을 새 주소로 교체한다. 회사명·대표자·사업자번호·계좌·이메일 등 다른 회사 정보는 변경 없음 — **주소만** 단일 변경.

**새 주소 (확정)**

| 언어 | 주소 |
|------|------|
| 한국어 | 서울특별시 마포구 잔다리로7길 3, 5층 501호(서교동) |
| 영어 | 501, 3 Jandari-ro 7-gil, Mapo-gu, Seoul, Republic of Korea |
| 일본어 | ソウル特別市 麻浦区 ジャンダリ路7ギル 3, 5階501号 (西橋洞) |

## Success Metric

**input metric**
- 수정 PR 3건(웹 리포별) 머지 + 운영 배포 완료
- 11개 파일(필수 10 + 권장 1) 의 주소 문자열이 새 주소로 갱신

**output metric**
- 운영 환경 footer·일본 특정상거래법 페이지 화면 검증에서 잘못된 주소 0건
- 코드 베이스 grep("양화로 81" / "Yanghwa-ro" / "ヤンファ路") = 0건 (마이그레이션 문서 제외)

## Benchmark

직전 양화로 이전 작업 ([hellobot-webview/docs/20260331-transfer-update](../../hellobot-webview/docs/20260331-transfer-update/development-plan.md))을 그대로 차용. 동일 파일 군 + 동일 키. 영향 범위는 더 작다 (회사명·계좌·사업자번호 등 부속 변경 없음).

## Trade off

- 외부 채널(Notion 약관 본문, PG 가맹점 정보, App Store/Play Store 사업자 정보, 메일 SMTP/Braze 템플릿)은 본 프로젝트 범위에서 제외 → 별도 운영 트랙으로 진행. 이 부분이 누락되면 코드만 갱신되고 외부 노출은 양화로 주소가 잔존한다.
- 약관 아카이브 (`terms-ja230801` 등 날짜 박힌 과거 버전)는 법적 보존 목적으로 유지 — 변경하지 않는다.

## Unhappy Path

- **부분 배포**: 3개 리포 중 일부만 배포되면 footer 주소가 리포별로 불일치 (예: 메인 웹은 서교동, 웹뷰는 양화로). 동일 시점 배포 권장.
- **일본 특정상거래법 페이지 누락**: i18n footer는 갱신했는데 `transactions-ja.component.html` 라인 7 누락 시 일본 결제 페이지에서 옛 주소 노출 — 법적 리스크.
- **배포 캐시**: CloudFront/CDN 캐시로 옛 주소가 일정 시간 노출. 배포 후 캐시 무효화 확인 필요.

## Feedback loop

- 배포 후 ko/en/ja 각 환경 footer 직접 확인
- 일본 결제 플로우에서 특정상거래법 페이지 주소 확인
- 코드 베이스 잔존 grep 검증 (마이그레이션 문서 제외)
