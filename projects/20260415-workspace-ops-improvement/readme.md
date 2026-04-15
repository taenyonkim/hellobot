# 프로젝트 문서 구조 개선

## 배경

워크스페이스 프로젝트 관리 체계를 coop-integration 프로젝트에서 실제 운영하면서, 문서 간 정보 중복과 업데이트 부담이 확인됨.
- 하나의 과업 완료 시 3~4개 파일을 업데이트해야 함
- 같은 정보(이슈 상세, 작업 로그, 과업 체크박스)가 여러 문서에 반복 기록
- 세션 시작 시 현황 파악을 위해 178줄짜리 status.md를 매번 읽어야 함
- 전체 프로젝트 문서 1,510줄 중 약 12-15%가 의미 있는 중복

## 목표

1. 각 정보의 단일 소스(Single Source of Truth) 확립
2. 과업 완료/이슈 해결 시 업데이트 대상 파일 수 최소화
3. 세션 시작 시 컨텍스트 로딩 효율화 (현황 파악에 필요한 읽기량 감소)
4. 문서 간 역할 경계 명확화

## 범위

- 포함:
  - 프로젝트 문서 구조 재설계 (status.md, tasks.md, issues.md 역할 재정의)
  - 리포 레벨 status.md 역할 재정의
  - architecture.md ↔ api-spec.md 중복 제거
  - 프로젝트 기술 설계 문서 명칭 변경 (design.md → architecture.md)
  - 에이전트 운영 규칙 갱신 (CLAUDE.md, commands/*.md)
  - 프로젝트 가이드/템플릿 갱신 (projects/readme.md)
  - coop-integration 프로젝트에 개선된 구조 적용 (검증)

- 제외:
  - 리포별 CLAUDE.md 변경 (각 리포의 개발 규칙은 그대로)
  - 에이전트 커맨드 추가/삭제 (기존 11개 유지)
  - 코드 변경

## 영향 범위

| 파트 | 영향 | 설명 |
|------|------|------|
| 워크스페이스 | O | CLAUDE.md 에이전트 규칙, projects/readme.md 템플릿 |
| 에이전트 커맨드 | O | .claude/commands/*.md 문서 업데이트 절차 변경 |
| coop-integration | O | 기존 문서를 개선된 구조로 마이그레이션 (검증용) |
| 서버/웹/iOS/Android | X | 코드 변경 없음 |

## 문서 목록

| 문서 | 설명 |
|------|------|
| [status.md](./status.md) | 진행 상태 |
| [tasks.md](./tasks.md) | 과업 목록 |
| [architecture.md](./architecture.md) | 문서 구조 개선 설계 (AS-IS → TO-BE, 템플릿, 에이전트 규칙) |
