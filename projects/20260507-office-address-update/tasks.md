# 과업 목록

> 새 주소 SSOT 는 [readme.md §새 주소](./readme.md#새-주소-확정--ssot) 참조.
> 모든 수정 파일에서 양화로 81 / Yanghwa-ro / ヤンファ路 81 / H 스퀘어 / Hスクエア 토큰을 새 주소로 교체.

## 기획 (planning/)
- [x] 영향 파일 전수 검색 (analyze 단계 완료)
- [x] 영문 호수 확정 (404 → 501)
- [x] 외부 채널 범위 제외 결정

## 서버 (/dev-server)
해당없음

## iOS (/dev-ios)
해당없음

## Android (/dev-android)
해당없음

## 웹 (/dev-web)

### 필수 — 사용자 노출

**hellobot-web** (`feat/office-address-update`) — [PR #997](https://github.com/thingsflow/hellobot-web/pull/997)
- [x] `public/translation/ko.json:501` `footer_address` → 한국어 새 주소
- [x] `public/translation/en.json:502` `footer_address` → 영어 새 주소
- [x] `public/translation/ja.json:501` `footer_address` → 일본어 새 주소

**hellobot-webview** (`feat/office-address-update`) — [PR #2912](https://github.com/thingsflow/hellobot-webview/pull/2912)
- [x] `src/assets/i18n/ko.json:499` `footer_address` → 한국어 새 주소
- [x] `src/assets/i18n/en.json:500` `footer_address` → 영어 새 주소
- [x] `src/assets/i18n/ja.json:499` `footer_address` → 일본어 새 주소 (`大韓民国` prefix 제거 — 결정 로그: hellobot-webview/docs/features/20260507-office-address-update/status.md)
- [x] `src/app/modules/terms/transactions-ja/transactions-ja.component.html:7` → 영문 새 주소 (일본 특정상거래법 공시 — 양화로 시기와 동일하게 영문 표기 유지)

**hellobot-report-webview** (`feat/office-address-update`) — [PR #422](https://github.com/thingsflow/hellobot-report-webview/pull/422)
- [x] `public/translation/ko.json:429` `footer_address` → 한국어 새 주소
- [x] `public/translation/en.json:428` `footer_address` → 영어 새 주소
- [x] `public/translation/ja.json:428` `footer_address` → 일본어 새 주소

### 권장 — 입력 placeholder
- [x] hellobot-webview `src/app/modules/random-box/input/input/input.component.ts:54` placeholder → `예) 서울시 마포구 잔다리로7길 3`

### 검증
- [x] 각 리포에서 `git grep -n "양화로\|Yanghwa-ro\|ヤンファ路\|H 스퀘어\|Hスクエア"` 잔존 없음 (마이그레이션 문서/약관 아카이브만 매치)
- [ ] 로컬 빌드/실행 후 footer 표시 확인 (ko/en/ja)
- [ ] 일본 결제 플로우 → 특정상거래법 페이지 라인 7 표시 확인

## 스튜디오 (/dev-studio)
해당없음

## 데이터 (/dev-data)
해당없음

## 인프라 (/dev-infra)
해당없음

## QA (/qa)
- [ ] 운영 배포 후 hellobot-web footer 주소 확인 (ko/en/ja 도메인별)
- [ ] 운영 배포 후 hellobot-webview footer 주소 확인 (앱 내 웹뷰)
- [ ] 운영 배포 후 hellobot-report-webview footer 주소 확인
- [ ] 일본 결제 플로우 → 특정상거래법 공시 페이지 주소 확인
- [ ] CDN 캐시 무효화 후 강제 새로고침 결과 확인

## 의존 관계

- 3개 웹 리포는 병렬 작업 가능 (서로 의존 없음)
- 운영 배포는 가급적 동일 시점에 진행 (리포별 주소 불일치 회피)
- QA 는 운영 배포 후 수행
