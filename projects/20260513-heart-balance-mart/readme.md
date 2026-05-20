# 일자별 사용자 보유 하트 잔액 추이 마트

> 사용자별 일자별 "보유 하트 수량" 시계열 BigQuery 마트 구축. Looker 등 대시보드에서 보유 하트 추이·분포·환불/만료 영향을 분석.

## Problem

하트 사용은 앱 전환·매출의 선행지표(충전 → 소진 → 재충전 = 앱 매출)임에도 불구하고, 현재 **사용자별 하트 잔고와 사용율을 인지하지 못하는 상태**임.

## Customer Job

1. 사용자별 하트 소진율을 알고, 관리할 수 있다
2. 우리 서비스의 사용자별·전체 평균 하트 잔고를 알 수 있다

## Requirement (확정 스코프, 2026-05-15)

- **R1. 사용자별 일자별 하트 잔고·증감 BQ 적재** — daily 단위로 사용자별 보유 하트 잔고와 증감(충전/사용/만료/환불)이 BQ 마트에 기록됨
- **R2. 전체 사용자 평균 하트 잔고 추이 BQ 적재** — 전체 모집단의 평균 하트 잔고가 일자별로 BQ 리포트 마트에 기록됨

### 명시적 제외 (본 프로젝트에서 추적하지 않음)

- ❌ **하트 사용 취소 이벤트 추적** — 사용 취소는 본 프로젝트의 측정 대상이 아님. 환불(`is_refunded`) 차감과 만료(`expired_at`) 차감은 R1 잔고 산식에 자연 반영되지만, 별도 "취소 이벤트" 발화/적재는 다루지 않음.
- ❌ **Hackle / GA 이벤트 발화·연동** — 본 프로젝트는 BQ 마트 산출만 다룸. 클라이언트/서버에서 Hackle·GA 로 이벤트를 보내는 부분은 별도 검토 대상이며 본 과업 범위 외.

## 배경

서버 `hellobot-server` 의 잔액 산출 함수 `services/heart.ts:935 getUsableHeart` 는 `heart_log` + `heart_log_detail` 원장에서 **요청 시점**의 보유 잔액을 동적으로 계산합니다. 분석/대시보드 측에서 **일자별 시계열** 로 추이를 보려면 별도 마트가 필요합니다.

기존 자산 점검 결과:
- `mart_purchase_fb` (Firebase 인앱 결제) 와 `mart_use_skill_se` (서버 스킬 사용) 는 **transaction 그레인** — 충전/사용 transaction 은 있어도 "잔액" 컬럼이 없음.
- 잔액 prior art 인 [`hellobot_user_transformed_table_func.py`](../../common-data-airflow/dags/scripts/hellobot/hellobot_user_transformed_table_func.py) 는 **현재 시점 단일 스냅샷** 만 산출 + **stale 위치** 참조 ([ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md)).

→ 신규 마트 필요.

## 목표 (Requirement → 분석 활용)

1. **R1 활용**: 사용자별 보유 하트 추이·세그먼트(결제자/비결제자, RFM 등) 별 보유 하트 추이·보유 분포(분위수)·만료 임박/환불 인한 잔액 감소 기여도
2. **R2 활용**: 전사 평균 하트 잔고 추이 (정의: §architecture.md 의 R2 마트 스펙)

## 산출물

| 산출물 | 충족 요구 | 비고 |
|---|---|---|
| `hlb_mart.mart_user_heart_balance_daily` (주) | **R1** | 사용자×일자×heart_kind 그레인, 잔량+증감 4종 |
| `hlb_mart.mart_user_heart_flow_daily` (보조) | R1 보조 | 충전 출처별 분해, ROI 분석 입력 |
| `hlb_report.report_avg_heart_balance_daily` (R2 산출) | **R2** | 일자별 전체 평균 잔고 (모집단·분포 정의 §architecture.md) |
| DAG 변경 — `hellobot_datamart_mart_pipeline` + `pre_report_pipeline` task 추가 | — | mart 2개 + report 1개 |
| Looker 대시보드 (별도 산출) | — | 본 프로젝트 외 |

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
