# 과업 목록

## 데이터 (/dev-data)

### Phase 1 — 사전 검증
- [ ] `user_birth_year IS NULL` 비중 측정 (최근 30일 union_mart_user_key_actions)
- [ ] `user_age` 계산 기준 (만 나이 / 한국 나이) 확인 — upstream 코드 추적 (mart_user_daily_info 또는 더 상위)
- [ ] 결과를 architecture.md 의 "검증 결과" 섹션에 기록

### Phase 2 — 워크트리 생성
- [ ] 사용자 승인 후 `Feat/age-group-5yr` 브랜치 + worktree 생성

### Phase 3 — SQL 수정 (워크트리 내)
- [ ] `scripts/hellobot/mart_integrated/union_mart_user_key_actions.sql`
  - [ ] `age_group_5yr` CASE 블록 추가 (`age_generation` 바로 아래)
  - [ ] `ALTER COLUMN age_group_5yr SET OPTIONS(description=...)` 추가
- [ ] `scripts/hellobot/mart_integrated/union_mart_use_skill_and_user_daily.sql` — CASE 블록 추가
- [ ] `scripts/hellobot/mart_integrated/union_mart_use_skill_from_home_banner.sql` — CASE 블록 추가
- [ ] `scripts/hellobot/mart_integrated/union_mart_use_skill_from_search_result.sql` — CASE 블록 추가
- [ ] `scripts/hellobot/mart_integrated/union_mart_use_skill_from_exhibition_page.sql` — CASE 블록 추가
- [ ] `scripts/hellobot/mart_adhoc/adhoc_mart_user_key_actions_for_targeting.sql` — CASE 블록 추가

### Phase 4 — 카탈로그 SSOT 갱신
- [ ] `docs/hellobot-data/catalog/tables/mart_integrated/union_mart_user_key_actions.md` §사용자 기본 컬럼 표에 `age_group_5yr` 추가 + dbt schema.yml 초안 반영 + 개정 이력
- [ ] `docs/hellobot-data/catalog/recipes/age-cohort-trend-analysis.md` 신규 작성 (월 기준 재계산 + drift 추적 패턴)
- [ ] `docs/hellobot-data/catalog/infra-map.md` §과업 유형 → 진입 문서 표에 신규 recipe 진입 행 추가
- [ ] `docs/hellobot-data/catalog/readme.md` 인벤토리에 신규 recipe 등록 (있는 경우)

### Phase 5 — PR
- [ ] 변경 사항 커밋 (Feat/age-group-5yr)
- [ ] PR 생성 (common-data-airflow develop 대상)
- [ ] Slack 데이터팀 채널에 PR 공유 (선택)

## 의존 관계

- Phase 1 (BQ 검증) → Phase 2 (워크트리) — 검증 결과로 컬럼 정의 미세 조정 가능 (NULL 비중이 매우 높으면 처리 방식 재논의)
- Phase 2 → Phase 3, 4 병렬 가능 (SQL 수정과 카탈로그 갱신은 독립)
- Phase 3, 4 완료 → Phase 5
