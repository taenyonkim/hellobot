# 과업 — 일자별 보유 하트 잔액 마트

## 스코프 (2026-05-15 확정)

- **포함**: R1 (사용자별 일자별 잔고·증감), R2 (전체 평균 잔고 추이)
- **제외**: 하트 사용 취소 이벤트 추적 / Hackle·GA 이벤트 발화·연동 (readme.md §Requirement 참조)

## 데이터 (/dev-data)

### 설계 단계 (완료 — 유형 A)

- [x] 원천 SSOT 식별 — `server_rdb.heart_log[_detail]` 확정, 옛 위치 stale 확인 ([ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md))
- [x] 잔액 산식 정의 (서버 `getUsableHeart` 와 동등, server_rdb.* 기준)
- [x] self-ref 가정 실측 검증 (NULL 0, self-ref 80.09%, 사용 19.91%)
- [x] 1일치 풀 recompute 비용 측정 (dry-run 10.16 GB / $0.05)
- [x] 마트 설계 초안 (`mart_user_heart_balance_daily` + 보조 `mart_user_heart_flow_daily`)
- [x] 카탈로그 SSOT 정정 + 신규 staging 테이블 문서 등록
- [x] 요구사항 스코프 확정 (R1+R2, 사용취소·Hackle·GA 제외)
- [ ] R2 리포트 마트 설계 (`report_avg_heart_balance_daily`) — 모집단·분포 컬럼 정의 → architecture.md 반영

### 구현 단계 — R1 (유형 B 전환)

- [x] 워크트리 생성 — `Feat/heart-balance-mart` 브랜치 + `projects/20260513-heart-balance-mart/worktrees/common-data-airflow/` (2026-05-15)
- [x] SQL: `dags/scripts/hellobot/mart/mart_user_heart_balance_daily.sql` (산식 + GENERATE_DATE_ARRAY 다일자 일괄 산출)
- [x] SQL: `dags/scripts/hellobot/mart/mart_user_heart_flow_daily.sql` (보조)
- [x] queries.py — 2개 쿼리 추가 (CREATE TABLE IF NOT EXISTS + DELETE + INSERT 패턴)
- [x] mart_func.py — `update_mart_user_heart_balance_daily_table`, `update_mart_user_heart_flow_daily_table` 추가 (`run_query_with_previous_date(days_before=2)`)
- [x] DAG: `hellobot_datamart_mart_pipeline.py` — task 2개 + dummy_task → tasks → success 체인 등록
- [x] 카탈로그 갱신 — `tables/mart/mart_user_heart_balance_daily.md`, `mart_user_heart_flow_daily.md` 신규, `mart-catalog.md` 인벤토리 추가
- [x] dry-run 비용 검증 — balance 11.3 GB / $0.057, flow 5.1 GB / $0.026 (1일·1년 동일, BQ 컬럼 스캔 1회)
- [x] Python syntax 검증 (ast.parse)
- [x] PR 생성 — [#185](https://github.com/thingsflow/common-data-airflow/pull/185) (Feat/heart-balance-mart → develop, 2026-05-15)
- [ ] PR 리뷰·머지
- [ ] 백필 실행 — 1년치 (2025-05-15 ~ 2026-05-14). **머지 후 사용자 승인 받아 실행**
- [ ] 일배치 운영 모드 전환 (수동 → mart_pipeline 스케줄에 흡수) + 1주 모니터링

### 구현 단계 — R2

- [ ] SQL: `scripts/hellobot/report/report_avg_heart_balance_daily.sql` (R1 마트 → 일자별 평균·분위수 집계)
- [ ] queries.py 또는 pre_report_func.py 에 함수 추가
- [ ] DAG: `hellobot_datamart_pre_report_pipeline.py` 또는 `report_pipeline.py` 에 task 추가
- [ ] 백필: R1 백필 완료 후 R1 → R2 일괄 계산
- [ ] 1주 모니터링 (R1 모니터링과 병행)

### 후속 (별도 과업)

- [ ] `hellobot_user_transformed_table_func.py` 의 `analytics_164027297.server_rdb_*` → `server_rdb.*` 마이그레이션 ([ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md))
- [ ] 옛 위치 (`analytics_164027297.server_rdb_*`) 의 적재 출처 식별 + 사용 중단 ([external-tasks B-1](../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md))
- [ ] Looker 대시보드 작성 (별도 작업, 본 마트 완성 후)

## 출처 (검증 일자·쿼리·스캔)

| 항목 | 출처 |
|---|---|
| `server_rdb.heart_log` 14 컬럼 / 76.3M / 17.1 GB | `bq show --schema` 2026-05-13 |
| `server_rdb.heart_log_detail` 5 컬럼 / 87.4M / 5.49 GB | 동일 |
| self-ref 분포 80/20 | `bq query` 2026-05-13, 1.4 GB 스캔 |
| 1일치 풀 recompute 10.16 GB | `bq dry-run` 2026-05-13 |
| 옛 위치 stale 확인 | `bq show` 비교 2026-05-13 |
