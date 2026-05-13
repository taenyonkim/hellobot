# 일자별 사용자 보유 하트 잔액 추이 마트

> 사용자별 일자별 "보유 하트 수량" 시계열 BigQuery 마트 구축. Looker 등 대시보드에서 보유 하트 추이·분포·환불/만료 영향을 분석.

## 배경

서버 `hellobot-server` 의 잔액 산출 함수 `services/heart.ts:935 getUsableHeart` 는 `heart_log` + `heart_log_detail` 원장에서 **요청 시점**의 보유 잔액을 동적으로 계산합니다. 분석/대시보드 측에서 **일자별 시계열** 로 추이를 보려면 별도 마트가 필요합니다.

기존 자산 점검 결과:
- `mart_purchase_fb` (Firebase 인앱 결제) 와 `mart_use_skill_se` (서버 스킬 사용) 는 **transaction 그레인** — 충전/사용 transaction 은 있어도 "잔액" 컬럼이 없음.
- 잔액 prior art 인 [`hellobot_user_transformed_table_func.py`](../../common-data-airflow/dags/scripts/hellobot/hellobot_user_transformed_table_func.py) 는 **현재 시점 단일 스냅샷** 만 산출 + **stale 위치** 참조 ([ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md)).

→ 신규 마트 필요.

## 목표

1. 전사 보유 하트 총량 추이 (일반/보너스 분리)
2. 세그먼트(결제자/비결제자, RFM 등) 별 보유 하트 추이
3. 보유 하트 분포(분위수) 추이
4. 만료 임박/만료/환불 인한 잔액 감소 기여도

## 산출물

- 신규 staging 인터미디에이트 — `hlb_intermediate.int_heart_log_resolved` (옵션, 그레인 보강용)
- 신규 마트 — `hlb_mart.mart_user_heart_balance_daily` (잔액 추이, 주산출)
- 신규 마트 — `hlb_mart.mart_user_heart_flow_daily` (충전/사용/만료/환불 흐름, 보조)
- DAG — `hellobot_datamart_mart_pipeline` 에 task 2개 추가
- Looker 대시보드 (별도 산출)

## 원천 (SSOT)

- `hellobot-f445c.server_rdb.heart_log` (14 컬럼, 76.3M row, 17.1 GB) — [📄](../../common-data-airflow/docs/hellobot-data/catalog/tables/staging/server_rdb_heart_log.md)
- `hellobot-f445c.server_rdb.heart_log_detail` (5 컬럼, 87.4M row, 5.49 GB) — [📄](../../common-data-airflow/docs/hellobot-data/catalog/tables/staging/server_rdb_heart_log_detail.md)
- **사용 금지**: `analytics_164027297.server_rdb_heart_log[_detail]` — stale, 누락 컬럼 ([ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md))

## 컨벤션 정합

- 시간대: Asia/Seoul (시간 컬럼은 STRING → `TIMESTAMP(..)` 캐스트 후 추출)
- 사용자 표준 ID: `user_id_processed` 매핑 (`mart_user_daily_info` 의 매핑 활용)
- 매출 환산 (보조 지표): `KRW_PER_HEART = 150`
- 테스터 제외: `server_rdb.user_test_group`

## 관련 문서

- [architecture.md](architecture.md) — 그레인·컬럼·lineage·산식
- [tasks.md](tasks.md) — 파트별 과업 (현재 데이터팀 단독)
- [status.md](status.md) — 진행 상태

## 일정

- 2026-05-13: 설계 시작, 카탈로그 정합 확인 (ISS-017 부분 해결)
- 향후: 워크트리 → SQL 구현 → 백필 → Looker 대시보드
