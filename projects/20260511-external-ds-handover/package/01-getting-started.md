# 01 — Getting Started: BigQuery 접근 셋업

> 외부 분석가가 HelloBot BigQuery 에 접근하여 첫 쿼리를 실행하기까지의 단계.

---

## 1. 사전 준비 (의뢰자가 제공)

의뢰자로부터 다음을 전달받으세요:

| 항목 | 내용 |
|---|---|
| **외부 분석가 계정** | Google 계정 1개 (의뢰자에게 알려주신 메일) — IAM 권한이 부여됨 |
| **GCP 프로젝트 ID** | `hellobot-f445c` |
| **읽기 권한 범위** | `hlb_mart`, `hlb_mart_integrated`, `hlb_mart_adhoc`, `hlb_staging`, `hlb_intermediate`, `hellobot_braze`, `google_sheet_sync`, `server_rdb`, `analytics_164027297` (의뢰자 부여 후 확인) |
| **권한 레벨** | **BigQuery Data Viewer** + **BigQuery Job User** (조회·쿼리 실행만, 쓰기/스키마 변경 불가) |

> 권한 부여는 의뢰자가 IAM 콘솔에서 직접 수행합니다. 본인 계정으로 BigQuery 콘솔(`https://console.cloud.google.com/bigquery?project=hellobot-f445c`) 접근이 되는지 먼저 확인하세요.

---

## 2. 도구 셋업

### 2-1. Google Cloud SDK 설치 (1회)

```bash
# Mac
brew install --cask google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### 2-2. OAuth 로그인 (1회)

```bash
gcloud auth login
# → 브라우저 OAuth 진행

# 활성 계정 확인 (전달받은 메일과 일치해야 함)
gcloud config get-value account

# 기본 프로젝트 설정 (선택)
gcloud config set project hellobot-f445c
```

### 2-3. Python SDK 사용 시 (선택)

`google.cloud.bigquery` 라이브러리로 분석할 경우:

```bash
# Application Default Credentials 셋업 (1회)
gcloud auth application-default login
# → ~/.config/gcloud/application_default_credentials.json 생성

pip install google-cloud-bigquery pandas
```

이후 Python:
```python
from google.cloud import bigquery
client = bigquery.Client(project="hellobot-f445c")
```

---

## 3. 첫 쿼리 (검증)

### 3-1. BigQuery 콘솔에서

1. https://console.cloud.google.com/bigquery?project=hellobot-f445c 접속
2. 좌측 탐색기 → `hellobot-f445c` 프로젝트 펼침
3. `hlb_mart` 데이터셋 → 테이블 목록 확인 가능하면 정상

### 3-2. bq CLI 에서

```bash
# 데이터셋 목록
bq --project_id=hellobot-f445c ls --max_results=20

# hlb_mart 테이블 목록
bq --project_id=hellobot-f445c ls --max_results=50 hellobot-f445c:hlb_mart

# 핵심 마트 스키마 확인 (메타데이터만 — 비용 0)
bq --project_id=hellobot-f445c show --format=prettyjson \
   hellobot-f445c:hlb_mart_integrated.union_mart_user_key_actions

# 미리보기 5행 (비용 0 — 메타데이터)
bq --project_id=hellobot-f445c head --max_rows=5 \
   hellobot-f445c:hlb_mart.mart_user_daily_info
```

### 3-3. 실제 쿼리 (DAU 1주 — 첫 비용 발생)

⚠️ **반드시 [04-query-guide.md](./04-query-guide.md) 의 안전 규칙(파티션 필터 · dry-run · byte cap)을 먼저 읽으세요.**

```bash
# Step 1: dry-run 으로 스캔 바이트 확인 (비용 0)
bq --project_id=hellobot-f445c query \
   --use_legacy_sql=false \
   --dry_run \
   "SELECT event_date, COUNT(DISTINCT user_id_processed) AS dau
    FROM \`hellobot-f445c.hlb_mart.mart_user_daily_info\`
    WHERE event_date BETWEEN '2026-05-01' AND '2026-05-07'
    GROUP BY event_date
    ORDER BY event_date"
# 출력: "this query will process X bytes of data"

# Step 2: 스캔 바이트가 적정하면 실제 실행 (10GB cap)
bq --project_id=hellobot-f445c query \
   --use_legacy_sql=false \
   --maximum_bytes_billed=10737418240 \
   --max_rows=20 \
   "<같은 쿼리>"
```

---

## 4. 권한 문제 해결

| 증상 | 원인 | 조치 |
|---|---|---|
| `Access Denied: Project ...` | 프로젝트 권한 누락 | 의뢰자에게 GCP 프로젝트 IAM 확인 요청 |
| `Access Denied: Dataset ...` | 데이터셋별 권한 누락 | 의뢰자에게 해당 데이터셋 BQ Data Viewer 요청 |
| `User does not have permission to query table` | 테이블별 권한 제한 | 의뢰자에게 해당 테이블 권한 요청 |
| `Quota exceeded: maximum bytes billed` | 쿼리가 cap 초과 | 쿼리를 좁히거나 (파티션 필터 강화) `--maximum_bytes_billed` 상향 |
| `gcloud auth ... PERMISSION_DENIED` | 계정 OAuth scope 부족 | `gcloud auth login --update-adc` |

---

## 5. 다음 단계

1. **[10-infra-map.md](./10-infra-map.md)** — 데이터 인프라 1페이지 지도 (3분)
2. **[02-conventions-quick-ref.md](./02-conventions-quick-ref.md)** — 결정적 컨벤션 (5분)
3. **[04-query-guide.md](./04-query-guide.md)** — 안전 쿼리 패턴

---

## 6. 환경 정보 요약

| 항목 | 값 |
|---|---|
| GCP 프로젝트 | `hellobot-f445c` |
| 주요 데이터셋 | `hlb_staging`, `hlb_intermediate`, `hlb_mart`, `hlb_mart_integrated`, `hlb_mart_adhoc`, `hlb_pre_report`, `hlb_report` |
| 외부 소스 데이터셋 | `analytics_164027297` (Firebase GA4), `server_rdb` (RDS 스냅샷), `google_sheet_sync` (마케팅·환율 수기), `hellobot_braze` (CRM) |
| 시간대 | Asia/Seoul (KST) — 모든 `event_date` 컬럼 |
| 표준 사용자 ID | `user_id_processed` (자세한 정의는 컨벤션 문서 참조) |
| 표준 매출 컬럼 | `revenue_krw` (유료 하트 + 현금, 보너스 제외) |
| 하트 환산 상수 | `KRW_PER_HEART = 150` |
