# 개발 상태

## 현재 상태: 완료

## 파트별 현황

| 파트 | 상태 | 비고 |
|------|------|------|
| 분석/설계 | 완료 | architecture.md 작성 완료 |
| 적용 (coop-integration) | 완료 | status/issues/서버status/웹status/architecture §3 경량화 완료 |
| 명칭 변경 | 완료 | design.md → architecture.md (CLAUDE.md, commands, how-to-work, projects/readme, coop-integration) |
| 가이드 갱신 | 완료 | projects/readme.md, CLAUDE.md, commands/*.md, how-to-work.md |

## 블로커

없음

## 확정 사항

| 항목 | 내용 |
|------|------|
| issues.md 역할 | 레지스트리만 (현상+원인+상태). 해결 상세는 기록하지 않음 |
| 해결된 이슈 작업 추적 | tasks.md에 과업으로 등록하여 추적 |
| status.md 역할 | 경량 대시보드만 (~30줄). 작업 로그 제거 |
| 과업 체크리스트 단일 소스 | tasks.md가 유일한 소스. 리포 status.md에서 체크박스 중복 제거 |
| 리포 status.md 로그 | 개발 로그 → 결정 로그로 전환 (의사결정만 기록, 구현 내역은 git log) |
| architecture.md API 섹션 | api-spec.md 참조로 대체 (에러코드/응답 상세 중복 제거) |
| 기술 설계 문서 명칭 | design.md → architecture.md (GUI/UI 디자인과 혼동 방지) |
| 계약 문서 Changelog | architecture.md, api-spec.md에 Changelog 필수 (확인 컬럼 포함) |
