# 기술 아키텍처 — 일자별 보유 하트 잔액 마트

## 1. 원천 (검증 완료, 2026-05-13)

| 테이블 | row | logical bytes | 시간 컬럼 타입 | 파티션 |
|---|---:|---:|---|---|
| `server_rdb.heart_log` | 76,268,014 | 17.1 GB | STRING ⚠️ | 없음 |
| `server_rdb.heart_log_detail` | 87,383,360 | 5.49 GB | STRING ⚠️ | 없음 |

상세 컬럼·검증 결과: [server_rdb_heart_log.md](../../common-data-airflow/docs/hellobot-data/catalog/tables/staging/server_rdb_heart_log.md), [server_rdb_heart_log_detail.md](../../common-data-airflow/docs/hellobot-data/catalog/tables/staging/server_rdb_heart_log_detail.md)

### 핵심 가정 검증 (실측 2026-05-13, 1.4 GB 스캔)

`heart_log_detail.use_heart_log_detail_seq` 의 self-reference 분포:

| 분포 | 행수 | 비율 |
|---|---:|---:|
| NULL | 0 | 0% |
| `= seq` (자기참조 = 충전 detail) | 69,972,758 | 80.09% |
| `< seq` (과거 충전 참조 = 사용 detail) | 17,397,241 | 19.91% |
| `> seq` (이상치) | 0 | 0% |

→ 산식 그대로 사용 가능. NULL/이상치 보강 불필요.

## 2. 잔액 산식 (서버 getUsableHeart 와 동등, server_rdb.* 기준)

```sql
DECLARE target_d DATE DEFAULT DATE_SUB(CURRENT_DATE("Asia/Seoul"), INTERVAL 1 DAY);

WITH live_charges AS (
  SELECT chg.seq AS charge_detail_seq, h.user_seq,
         IF(h.expired_at IS NULL, "normal","bonus") AS heart_kind
  FROM `hellobot-f445c.server_rdb.heart_log` h
  JOIN `hellobot-f445c.server_rdb.heart_log_detail` chg
    ON chg.heart_log_seq = h.seq AND chg.seq = chg.use_heart_log_detail_seq
  WHERE h.quantity > 0
    AND DATE(TIMESTAMP(h.created_at), "Asia/Seoul") <= target_d
    AND (h.is_refunded = FALSE
         OR DATE(TIMESTAMP(h.refunded_at), "Asia/Seoul") > target_d)
    AND (h.expired_at IS NULL
         OR DATE(TIMESTAMP(h.expired_at), "Asia/Seoul") > target_d)
)
SELECT lc.user_seq, lc.heart_kind, SUM(det.quantity) AS balance
FROM `hellobot-f445c.server_rdb.heart_log_detail` det
JOIN live_charges lc ON det.use_heart_log_detail_seq = lc.charge_detail_seq
WHERE DATE(TIMESTAMP(det.created_at), "Asia/Seoul") <= target_d
GROUP BY 1, 2;
```

**주의**:
- alias 는 `det` / `chg` / `target_d` 사용 — 단일 문자 `d` 는 DECLARE 변수 `D` 와 case-insensitive 충돌
- 모든 시간 컬럼은 `TIMESTAMP(..)` 캐스트 (STRING 으로 적재됨)

## 3. 마트 설계

### 3-1. `hlb_mart.mart_user_heart_balance_daily` (주산출)

- **그레인**: `(event_date, user_seq, heart_kind)` — `heart_kind ∈ {'normal','bonus'}`
- **파티션**: `event_date` DAY
- **클러스터링**: `user_seq` (또는 `user_id_processed` 매핑 후)
- **머티리얼라이제이션**: 1안 풀 recompute (`MERGE` 또는 `CREATE OR REPLACE TABLE PARTITION (event_date=...)` per-day)

| 컬럼 | 타입 | 정의 |
|---|---|---|
| `event_date` | DATE | Asia/Seoul 기준 |
| `user_seq` | INT64 | `heart_log.user_seq` |
| `user_id_processed` | STRING | `mart_user_daily_info` 매핑 |
| `heart_kind` | STRING | `normal` / `bonus` |
| `balance` | INT64 | D 시점 보유 잔량 (위 산식) |
| `balance_expiring_in_7d` | INT64 | bonus 만 — D ~ D+7 사이 만료 예정 잔량 |
| `charged_today` | INT64 | D 일자 충전량 |
| `used_today` | INT64 | D 일자 사용량 (절댓값) |
| `expired_today` | INT64 | D 일자 `ExpiredHeart` 차감량 |
| `refunded_today` | INT64 | D 일자 환불 차감량 |
| `charged_today_krw` | INT64 | `charged_today × 150` (보조) |
| `is_test_user` | BOOL | 테스터 플래그 (필터용으로 보존) |

### 3-2. `hlb_mart.mart_user_heart_flow_daily` (보조)

- **그레인**: `(event_date, user_seq, heart_kind, log_type)`
- **컬럼**: `delta` (해당 log_type 의 일자 합계)
- **용도**: 충전 출처별(promotion/purchase/gift 등) 보유 기여도 분해, ROI 분석 입력

### 3-3. `hlb_report.report_avg_heart_balance_daily` (R2 산출)

- **목적**: Customer Job #2 "우리 서비스의 사용자별·전체 평균 하트 잔고를 알 수 있다" 충족
- **그레인**: `(event_date, heart_kind, population)`
  - `heart_kind ∈ {'normal', 'bonus', 'total'}` — 'total' 은 두 종류 합산 행
  - `population ∈ {'all_signup', 'active_d7', 'paying_d30'}` — 세 모집단을 동시에 적재 (분석 측에서 필요한 관점 선택)
- **소스**: `hlb_mart.mart_user_heart_balance_daily` (R1 마트) + `hlb_mart.mart_user_daily_info` (활성 / 신규 분기) + `hlb_mart_integrated.union_mart_user_key_actions` (결제자 분기)
- **컬럼**:

| 컬럼 | 타입 | 정의 |
|---|---|---|
| `event_date` | DATE | Asia/Seoul |
| `heart_kind` | STRING | `normal` / `bonus` / `total` |
| `population` | STRING | `all_signup` / `active_d7` / `paying_d30` |
| `num_users` | INT64 | 해당 모집단의 사용자 수 |
| `num_users_with_balance` | INT64 | balance > 0 인 사용자 수 |
| `avg_balance` | FLOAT64 | 평균 잔고 (분모 = num_users, 0 잔고 포함) |
| `avg_balance_holders_only` | FLOAT64 | 평균 잔고 (분모 = num_users_with_balance, 0 제외) |
| `p10_balance` | INT64 | 10 분위 |
| `p25_balance` | INT64 | 25 분위 (1사분위) |
| `p50_balance` | INT64 | 중앙값 |
| `p75_balance` | INT64 | 75 분위 (3사분위) |
| `p90_balance` | INT64 | 90 분위 |
| `total_balance` | INT64 | 전체 보유 합계 (전사 총량) |

- **파티션**: `event_date` DAY
- **머티리얼라이제이션**: R1 마트 산출 직후 일 1회 풀 갱신 (집계 크기 작음 — 일 ~9 행 = 3 heart_kind × 3 population)
- **모집단 정의**:
  - `all_signup` — 전체 가입자 (`mart_user_daily_info` 의 join 대상 전체)
  - `active_d7` — D-7 ~ D 사이 1회 이상 방문 (DAU 정의 활용)
  - `paying_d30` — D-30 ~ D 사이 결제자 (`union_mart_user_key_actions` 의 `pay_*` 이벤트 보유 user)

### 3-4. lineage

```
server_rdb.heart_log + server_rdb.heart_log_detail
    │
    ▼ (mart, 신규 — intermediate 미사용, 직접 mart 산출)
hlb_mart.mart_user_heart_balance_daily       ← R1 주산출
hlb_mart.mart_user_heart_flow_daily          ← R1 보조 (흐름)
    │
    ├─▶ hlb_report.report_avg_heart_balance_daily   ← R2 (+ mart_user_daily_info, union_mart_user_key_actions 로 모집단 분기)
    │
    ▼ (dim 으로 join, union 합류 X — transaction 마트가 아님)
Looker 대시보드
```

## 4. 백필/일배치 전략

| 전략 | 일배치 비용 | 백필 비용 | 정합성 | 운영 복잡도 |
|---|---|---|---|---|
| **1안: 풀 recompute (선택)** | 10.16 GB/회 ≈ $0.05 | 자연 (D 변경만) | ★★★ | 단순 |
| 2안: 델타 + 캐시 | 적음 | 별도 SQL | ★★ (환불·만료 소급 누락 위험) | 복잡 |
| 3안: rolling N일 | 10 GB/회 (파티션 없어 동일) | — | ★★★ | 중간 |

**선택**: 1안. 비용 미미 + 정합성 최상.

### 비용 추정 (1안)

- 매일: 10.16 GB × $5/TB ≈ **$0.05/회**
- 1년: **~$18**
- 첫 백필 (1년치 D 변경 = 365회): **~$18** (1회와 동일 — 매일 동일 풀스캔이므로)
  - 단 실제로는 각 D 별로 별도 쿼리 실행하면 365 × 10 GB = 3.6 TB ≈ $18.
  - 대안: 단일 쿼리로 모든 D 를 한 번에 산출 (CROSS JOIN UNNEST 가능) → 동일 데이터를 1회 스캔하고 D 별 GROUP BY → 10 GB 1회. **첫 백필은 단일 쿼리로**.

## 5. 환불·만료 처리 정책 (v1)

- **환불 (`is_refunded=true`)**: D 시점에 `refunded_at > D` 면 그 충전건은 아직 잔액에 포함, `refunded_at ≤ D` 면 제외. → 환불의 소급 효과가 자연히 반영됨.
- **만료**: 보너스 충전건의 `expired_at` 가 D 보다 미래면 잔액에 포함, 과거면 제외. 서버가 만료 시 `ExpiredHeart` 보정 로그를 따로 남기지만, 잔액 산식에는 직접 영향 없음 (`expired_at` 조건이 우선).
- 두 정책 모두 서버 `getUsableHeart` 와 동일 의미 — 단 서버는 "지금" 만 보고 본 마트는 "임의 D 시점" 까지 일반화.

## 6. 갭·제약

- 옛 위치 (`analytics_164027297.server_rdb_*`) 의 적재 출처가 미확인 ([ISS-017](../../common-data-airflow/docs/hellobot-data/catalog/issues.md), [external-tasks B-1](../../common-data-airflow/docs/hellobot-data/catalog/external-tasks.md))
- prior art (`hellobot_user_transformed_table_func.py`) 가 옛 위치 참조 — 별도 마이그레이션 과업
- 마트 자체에 `user_id_processed` 매핑은 dim join 으로 처리 — `mart_user_daily_info` 의 매핑 활용

## Changelog

| 날짜 | 변경 | 작성자 |
|---|---|---|
| 2026-05-13 | 초안 — server_rdb.* 기준 산식·마트 설계·1안 풀 recompute 채택 (dry-run 10.16 GB 검증) | /dev-data |
| 2026-05-15 | §3-3 R2 리포트 마트 `hlb_report.report_avg_heart_balance_daily` 스펙 추가 (3 heart_kind × 3 모집단 그레인, 평균·분위수·총량 컬럼). §3-4 lineage 갱신. 사용 취소 이벤트·Hackle·GA 는 본 프로젝트 제외 | /analyze |
