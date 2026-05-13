# 과업 — 일자별 보유 하트 잔액 마트

## 데이터 (/dev-data)

### 설계 단계 (현재 — 유형 A)

- [x] 원천 SSOT 식별 — `server_rdb.heart_log[_detail]` 확정, 옛 위치 stale 확인 ([ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md))
- [x] 잔액 산식 정의 (서버 `getUsableHeart` 와 동등, server_rdb.* 기준)
- [x] self-ref 가정 실측 검증 (NULL 0, self-ref 80.09%, 사용 19.91%)
- [x] 1일치 풀 recompute 비용 측정 (dry-run 10.16 GB / $0.05)
- [x] 마트 설계 초안 (`mart_user_heart_balance_daily` + 보조 `mart_user_heart_flow_daily`)
- [x] 카탈로그 SSOT 정정 + 신규 staging 테이블 문서 등록

### 구현 단계 (유형 B 전환 — 워크트리 필요)

- [ ] 워크트리 생성: `cd common-data-airflow && git checkout develop && git pull && git branch Feat/heart-balance-mart && git worktree add ../projects/20260513-heart-balance-mart/worktrees/common-data-airflow Feat/heart-balance-mart`
- [ ] SQL: `scripts/hellobot/mart/mart_user_heart_balance_daily.sql` (산식 + 일자 파라미터)
- [ ] SQL: `scripts/hellobot/mart/mart_user_heart_flow_daily.sql` (보조)
- [ ] queries.py 또는 mart_func.py 에 함수 추가
- [ ] DAG: `hellobot_datamart_mart_pipeline.py` 에 2개 task 추가 (PythonOperator)
- [ ] 백필 스크립트: 1년치 단일 쿼리로 적재 (CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(...))) — 약 10 GB / $0.05
- [ ] 일배치 운영 모드로 전환 후 1주 모니터링

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
