# 진행 상태

## 파트별 현황

| 파트 | 상태 | 비고 |
|---|---|---|
| 데이터 | R1 PR 오픈 ([#185](https://github.com/thingsflow/common-data-airflow/pull/185), 리뷰·머지 대기) / R2 구현 대기 | 워크트리·SQL·DAG·카탈로그 완료. dry-run 검증 통과 |
| 서버 | 해당 없음 | 잔액 산출은 BQ 측 (server-side 변경 불필요) |
| 클라이언트 | 해당 없음 | 대시보드 소비만 |

## 결정 로그

| 날짜 | 결정 | 이유 |
|---|---|---|
| 2026-05-13 | 원천 SSOT = `server_rdb.heart_log[_detail]` 확정. `analytics_164027297.server_rdb_heart_log[_detail]` 사용 금지 | BQ 실측 결과 옛 위치는 컬럼 6종 누락 + 1일 stale ([ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md)) |
| 2026-05-13 | 백필 전략 = 1안 풀 recompute | dry-run 10.16 GB / $0.05 — 매우 저렴, 정합성 ★★★ |
| 2026-05-13 | 환불·만료 처리 = D 시점 기준 자연 반영 (정책 별도 컬럼 없음) | 서버 `getUsableHeart` 와 의미 동등 |
| 2026-05-13 | SQL alias 컨벤션: `det` / `chg` / `target_d` | DECLARE 변수와 case-insensitive 충돌 회피 |
| 2026-05-15 | 스코프 확정 = R1(사용자별 일자별 잔고·증감) + R2(전체 평균 잔고 추이) | Customer Job 두 가지(소진율·평균 잔고)에 직접 대응 |
| 2026-05-15 | **제외**: 하트 사용 취소 이벤트 추적 | 측정 대상 아님. 환불·만료는 R1 잔고 산식에 자연 반영되므로 별도 이벤트 불요 |
| 2026-05-15 | **제외**: Hackle·GA 이벤트 발화·연동 | 본 프로젝트는 BQ 마트 산출만 다룸. 클라/서버 SDK 발화는 별도 검토 대상 |
| 2026-05-15 | R2 구현체 = `hlb_report.report_avg_heart_balance_daily` (별도 마트) | R1 마트를 dim 으로 집계. report 레이어 적합 — DAG 체인상 pre_report_pipeline 후속 |
| 2026-05-15 | R1 구현 완료 — worktree + SQL + queries.py + mart_func.py + DAG + 카탈로그 | dry-run: balance 11.3 GB, flow 5.1 GB. 모두 BQ 컬럼 스캔 1회로 1일·1년 동일 비용 |
| 2026-05-15 | sparse row 정책 = balance > 0 또는 활동 있는 (D, user, kind) 만 row | 76M charges × 365d 인플레이션 회피. 분석 시 모집단 LEFT JOIN 으로 0 보강 |
| 2026-05-15 | CREATE TABLE IF NOT EXISTS 를 queries.py 에 포함 (idempotent) | 별도 DDL 스크립트 불필요. DAG 첫 실행 시 테이블 자동 생성, 이후엔 no-op |

## 갭·이슈

- [ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md) — 옛 위치 stale + prior art 마이그레이션 (본 프로젝트 산출 후 별도 과업)
- [external-tasks B-1](../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md) — 옛 위치 적재 출처 식별
- R2 모집단·분포 컬럼 정의 미확정 → architecture.md 에 다음 액션으로 추가

## 다음 액션

1. **PR #185 리뷰·머지** (Feat/heart-balance-mart → develop)
2. **머지 후 R1 백필 실행** — 사용자 승인, 2025-05-15 ~ 2026-05-14 (~16.5 GB / $0.08, 첫 실행 시 테이블 자동 생성)
3. R2 구현 (`report_avg_heart_balance_daily` SQL/queries/DAG, 별도 PR)
4. 일배치 통합 → 1주 모니터링 → Looker 대시보드
