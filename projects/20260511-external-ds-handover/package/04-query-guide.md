# 04 — BigQuery 쿼리 안전 · 비용 가이드

> BigQuery 는 **스캔 바이트 기준 과금**입니다. 부주의한 쿼리 1회로 큰 비용이 발생할 수 있어 아래 규칙을 반드시 따르세요.

---

## 1. 필수 규칙 (체크리스트)

쿼리 실행 전 다음을 항상 확인:

- [ ] **Dry-run 으로 스캔 바이트 사전 확인** (비용 0)
- [ ] **파티션 키 WHERE 절 포함** (`event_date` 또는 `_TABLE_SUFFIX`)
- [ ] **`SELECT *` 금지** — 필요 컬럼만 명시
- [ ] **`--maximum_bytes_billed`** 옵션으로 byte cap 적용
- [ ] **`--max_rows`** 로 미리보기 행 수 제한

---

## 2. 표준 명령 형식 (bq CLI)

```bash
bq --project_id=hellobot-f445c query \
   --use_legacy_sql=false \
   --maximum_bytes_billed=10737418240 \
   --max_rows=20 \
   'SELECT event_date, COUNT(*) AS cnt
    FROM `hellobot-f445c.hlb_mart.mart_use_skill_se`
    WHERE event_date BETWEEN "2026-05-01" AND "2026-05-07"
    GROUP BY event_date'
```

| 옵션 | 권장값 | 이유 |
|------|-------|------|
| `--project_id=hellobot-f445c` | 고정 | 기본 GCP 프로젝트 명시 |
| `--use_legacy_sql=false` | 고정 | Standard SQL (마트 컨벤션) |
| `--maximum_bytes_billed=10737418240` | 10GB | 비용 가드 (cap 초과 시 오류로 차단) |
| `--max_rows=20` | 미리보기 시 | 큰 결과는 별도 export |

---

## 3. Dry-run (의무)

모든 쿼리 실행 **전에** dry-run 으로 스캔 바이트 확인:

```bash
bq --project_id=hellobot-f445c query \
   --use_legacy_sql=false \
   --dry_run \
   'SELECT ...'

# 출력 예: "this query will process 152 MB of data"
```

| 스캔 크기 | 처리 |
|----------|------|
| < 1 GB | 그대로 실행 |
| 1~10 GB | 결과 확인 후 실행 |
| > 10 GB | 쿼리 재검토 (파티션 필터 / 컬럼 최소화) 후 cap 상향 |

> **참고 가격** (2026-05 기준 BigQuery on-demand): TB 당 약 USD 5. 10GB 스캔 ≈ USD 0.05.

---

## 4. 파티션 필터 (테이블별)

| 테이블 패턴 | 파티션 필터 |
|---|---|
| `analytics_164027297.events_*` | `_TABLE_SUFFIX BETWEEN 'YYYYMMDD' AND 'YYYYMMDD'` |
| `analytics_164027297.events_intraday_*` | 동일 (실시간 데이터 — 오늘만) |
| `analytics_164027297.server_events` | `WHERE DATE(TIMESTAMP_TRUNC(event_timestamp, DAY), 'Asia/Seoul') BETWEEN ...` |
| `hlb_staging.staging_key_events_*` | `WHERE event_date BETWEEN ...` |
| `hlb_mart.*` (대부분 파티션 없음) | `WHERE event_date = ...` (효과 제한적) — Dry-run 결과로 풀스캔 여부 확인 |
| `hlb_intermediate.intermediate_user_daily_info` | `WHERE event_date BETWEEN ...` (DAY 파티션 있음) |

> ⚠️ `analytics_164027297.server_events` 의 파티션 컬럼은 **`event_timestamp` (TIMESTAMP, DAY)** — `event_date` 컬럼은 존재하지 않습니다. 단순 timestamp 범위 (`event_timestamp >= ... AND <`) 도 동작하나, 위 패턴이 가장 효율적입니다 (검증: 0.9MB vs 32GB).

---

## 5. 비용 최적화 패턴

### 5-1. 동일 테이블 다중 스캔 금지

BigQuery 의 CTE (WITH 절) 는 결과를 캐싱하지 않습니다. 동일 테이블을 N 번 참조하면 N 회 스캔.

**❌ 나쁜 예** (동일 테이블 3회 스캔):
```sql
WITH a AS (SELECT user_id FROM big_table WHERE condition_1),
     b AS (SELECT user_id FROM big_table WHERE condition_2),
     c AS (SELECT user_id FROM big_table WHERE condition_3)
SELECT ...
```

**✅ 좋은 예** (1회 스캔 + 조건부 집계):
```sql
WITH base AS (
  SELECT user_id, menu_seq, event_date
  FROM big_table
  WHERE common_filter
),
user_summary AS (
  SELECT user_id,
         COUNTIF(condition_1) > 0 AS flag_1,
         COUNTIF(condition_2) > 0 AS flag_2,
         COUNT(DISTINCT CASE WHEN condition_3 THEN key END) = N AS flag_3
  FROM base
  GROUP BY user_id
)
SELECT user_id FROM user_summary WHERE flag_1 AND NOT flag_2 AND NOT flag_3;
```

### 5-2. `NOT IN (SELECT ...)` → `LEFT JOIN + IS NULL`

```sql
-- ❌ 나쁜 예
WHERE user_id NOT IN (SELECT user_id FROM other_table)

-- ✅ 좋은 예
LEFT JOIN other_table b ON a.user_id = b.user_id
WHERE b.user_id IS NULL
```

### 5-3. 탐색적 분석은 근사 함수

```sql
-- 정확 (비용 ↑)
COUNT(DISTINCT user_id)

-- 근사 (비용 ↓, 오차 ~1%)
APPROX_COUNT_DISTINCT(user_id)
```

### 5-4. 필요 컬럼만 SELECT

BigQuery 는 컬럼 기반 스토리지 → 컬럼 수가 비용에 직접 영향. `SELECT *` 사용 금지.

---

## 6. 자주 쓰는 보조 명령

```bash
# 데이터셋 목록
bq --project_id=hellobot-f445c ls --max_results=50

# 테이블 목록 (특정 데이터셋)
bq --project_id=hellobot-f445c ls --max_results=100 hellobot-f445c:hlb_mart

# 테이블 스키마 (비용 0 — 메타데이터만)
bq --project_id=hellobot-f445c show --format=prettyjson \
   hellobot-f445c:hlb_mart.mart_use_skill_se

# 5행 미리보기 (비용 0 — 메타데이터만)
bq --project_id=hellobot-f445c head --max_rows=5 \
   hellobot-f445c:hlb_mart.mart_user_daily_info

# 쿼리 결과를 CSV 로 저장 (큰 결과셋용)
bq --project_id=hellobot-f445c query \
   --use_legacy_sql=false \
   --format=csv \
   --maximum_bytes_billed=10737418240 \
   'SELECT ...' > output.csv
```

---

## 7. Python SDK 사용 시

```python
from google.cloud import bigquery
client = bigquery.Client(project="hellobot-f445c")

# Dry-run
job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
query = """
SELECT event_date, COUNT(*) AS cnt
FROM `hellobot-f445c.hlb_mart.mart_use_skill_se`
WHERE event_date BETWEEN '2026-05-01' AND '2026-05-07'
GROUP BY event_date
"""
dry_run_job = client.query(query, job_config=job_config)
print(f"Will scan {dry_run_job.total_bytes_processed / 1e6:.1f} MB")

# 실제 실행 (byte cap 적용)
job_config = bigquery.QueryJobConfig(
    maximum_bytes_billed=10 * 1024 ** 3  # 10 GB
)
df = client.query(query, job_config=job_config).to_dataframe()
```

---

## 8. 금지 사항

- ❌ 파티션 필터 없는 파티션 테이블 조회
- ❌ `--maximum_bytes_billed` 없는 `bq query`
- ❌ Dry-run 생략 후 바로 실행
- ❌ `SELECT *` from large tables
- ❌ 쿼리 결과를 BigQuery 테이블로 저장 (`CREATE TABLE`, `INSERT`) — **부여된 권한은 read-only**
- ❌ 임의 데이터셋 생성 — 권한 없음

---

## 9. 비용 문제 발생 시

- 의뢰자에게 즉시 보고: 쿼리 내용 + 실행 시각 + 스캔 바이트
- BigQuery 콘솔 → 좌측 메뉴 → "Job history" 에서 본인 쿼리 history 확인 가능
- `--maximum_bytes_billed` 옵션이 fail-safe 로 동작 (10GB 초과 시 자동 차단)
