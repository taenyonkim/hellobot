# 개발 상태

## 현재 상태: 설계완료 · 개발대기

## 파트별 현황

| 파트 | 상태 | 브랜치 | 워크트리 | 비고 |
|------|------|--------|---------|------|
| 데이터 | 설계완료 · 개발대기 | Feat/age-group-5yr (예정) | worktrees/common-data-airflow (예정) | 사용자 워크트리 생성 승인 후 진행 |
| 기타 파트 | 해당없음 | - | - | |

## 블로커

없음

## 확정 사항

| 항목 | 내용 |
|------|------|
| 버킷 구간 | 13-15, 16-20, 21-25, 26-30, 31-35, 36-40, 41-45, 46-50, 51-55, 56-60, 61-65, 66+, 정보없음 |
| 컬럼명 | `age_group_5yr` |
| 분류 시점 | event_date 시점 (user_age 와 동일 컨벤션) |
| 적용 범위 | union_mart_user_key_actions + 동일 패턴 5개 SQL 전체 (총 6개) |
| 월간 추이/drift | 마트 컬럼 신설 X — 신규 recipe `age-cohort-trend-analysis.md` 로 표준화 |
| 6개 SQL 중복 제거 | 별도 과업 분리 (UDF/macro 검토) |

## 마일스톤

| # | 작업 | 상태 |
|---|------|------|
| 1 | 프로젝트 문서 작성 | ✅ |
| 2 | 워크트리 생성 (사용자 승인 후) | ⏳ |
| 3 | BQ 사전 검증 (user_birth_year NULL 비중, user_age 계산 기준) | ⏳ |
| 4 | 6개 SQL 수정 | ⏳ |
| 5 | 카탈로그 SSOT 갱신 (테이블 컬럼표 + Changelog) | ⏳ |
| 6 | 신규 recipe 작성 (`age-cohort-trend-analysis.md`) | ⏳ |
| 7 | infra-map 진입 색인 / catalog readme 인벤토리 갱신 | ⏳ |
| 8 | PR 생성 | ⏳ |
