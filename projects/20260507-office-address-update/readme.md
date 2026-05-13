# 사무실 주소 업데이트 (서교동 이전)

## 배경

뉴럴아케이드 사무실이 마포구 양화로 81 (H 스퀘어 4층 404호)에서 서교동(잔다리로7길 3, 5층 501호)으로 이전.
직전 [transfer-update](../../hellobot-webview/docs/20260331-transfer-update/development-plan.md) 작업으로 양화로 81 주소가 모든 사용자 노출 채널에 동기화되어 있어, 이를 신규 주소로 교체한다. 회사명·대표자·사업자번호·계좌·이메일 등은 변경 없음 — **주소만 단일 변경**.

## 목표

- 웹 3개 리포의 footer i18n + 일본 특정상거래법 공시 페이지 주소를 새 주소로 교체
- 코드 베이스 내 옛 주소(양화로 81) 잔존 0건 (마이그레이션 문서 제외)

## 새 주소 (확정 — SSOT)

| 언어 | 주소 |
|------|------|
| 한국어 | 서울특별시 마포구 잔다리로7길 3, 5층 501호(서교동) |
| 영어 | 501, 3 Jandari-ro 7-gil, Mapo-gu, Seoul, Republic of Korea |
| 일본어 | ソウル特別市 麻浦区 ジャンダリ路7ギル 3, 5階501号 (西橋洞) |

> **참고**: 직전 양화로 시기 webview 일본어 footer는 `大韓民国` prefix가, web/report-webview 일본어는 `4階` 표기가 들어가 있는 등 리포별 형식 차이가 존재. 위 표기를 SSOT로 삼되, 각 리포의 기존 형식(prefix/접미사)을 유지할지 통일할지는 `/dev-web` 단계에서 판단 후 status.md에 결정 기록.

## 범위

**포함**
- hellobot-web `public/translation/{ko,en,ja}.json` footer_address
- hellobot-webview `src/assets/i18n/{ko,en,ja}.json` footer_address
- hellobot-webview `src/app/modules/terms/transactions-ja/transactions-ja.component.html` (일본 특정상거래법 공시)
- hellobot-report-webview `public/translation/{ko,en,ja}.json` footer_address
- (권장) hellobot-webview `random-box/input/input.component.ts` placeholder 예시 텍스트

**제외**
- 외부 채널 — Notion 약관/개인정보처리방침 본문, PG 가맹점 정보, App Store/Play Store 사업자 정보, 메일(SES/Braze) 템플릿. 별도 운영 트랙으로 진행.
- 회사명·대표자·사업자등록번호·통신판매업신고번호·계좌·이메일 등 다른 회사 정보 (변경 없음)
- 약관 아카이브 — `terms-*230801`, `privacy-*230801`, `jp-ps-act-ja230801` 등 날짜 박힌 과거 버전 (법적 보존 목적, 수정 금지)
- 서버/스튜디오/모바일/데이터/인프라 리포 (코드 내 주소 임베드 없음 — 검색 완료)

## 영향 범위

| 파트 | 영향 | 설명 |
|------|------|------|
| 서버 | X | hellobot-server 코드에 주소 임베드 없음 (마이그레이션 문서만 존재) |
| iOS | X | 코드 내 주소 노출 없음 |
| Android | X | 코드 내 주소 노출 없음 |
| 웹 | O | hellobot-web, hellobot-webview, hellobot-report-webview 3개 리포 i18n + 1개 약관 페이지 |
| 스튜디오 | X | 회사 주소 노출 없음 |
| 데이터 | X | 해당없음 |
| 인프라 | X | 해당없음 |
| QA | O | 배포 후 footer/특정상거래법 페이지 화면 검증 (ko/en/ja) |

## 문서 목록

| 문서 | 설명 |
|------|------|
| [1pager.md](./1pager.md) | 프로젝트 1-pager (Problem/Solution/Metric) |
| [status.md](./status.md) | 전체 진행 상태 |
| [tasks.md](./tasks.md) | 파트별 과업 목록 |

## 참고

- 직전 이전 작업 (테헤란로 → 양화로): [hellobot-webview/docs/20260331-transfer-update/development-plan.md](../../hellobot-webview/docs/20260331-transfer-update/development-plan.md)
- 영향 파일 전수 검색 결과는 본 readme의 "범위" 섹션에 정리됨 — `/dev-web` 단계에서 별도 탐색 불필요
