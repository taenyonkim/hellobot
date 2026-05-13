# 03 — 알려진 함정 · 데이터 품질 갭

> 분석 시 결과를 왜곡하거나 잘못된 해석으로 이어질 수 있는 알려진 항목 모음. 본 패키지 작성 시점(2026-05) 기준이며, 의뢰자가 인지하고 있는 항목만 정리했습니다.

---

## 1. 컨벤션 · 정의 함정

### 1-1. `revenue_krw` 와 `spent_total_amount_krw` 구분

| 컬럼 | 의미 |
|---|---|
| `revenue_krw` | **표준 매출** — 유료 하트 + 현금. **보너스 하트 사용은 제외**. KPI / 대시보드 / ROAS 등 매출 지표는 이것 |
| `spent_total_amount_krw` | 총 소비 — 유료 + 보너스 하트 모두 KRW 환산 |

→ "매출"이라는 단어를 들으면 거의 항상 `revenue_krw` 입니다. `spent_total_amount_krw` 는 "사용자가 가치 단위로 얼마나 썼는지" (보너스 포함) 측정.

### 1-2. Firebase `value` 마이크로단위

Firebase `in_app_purchase` 이벤트의 `value` 파라미터는 통화가 KRW 일 때 1,000,000 배(마이크로단위)로 옵니다. 파이프라인의 staging 단계에서 `/1e6` 처리되어 마트에 들어가므로 **마트 컬럼 (`revenue_krw` 등) 은 이미 정상 KRW 단위**입니다. 단, raw `analytics_164027297.events_*` 를 직접 분석할 경우 직접 처리 필요.

### 1-3. `user_id_processed` 시작 시점

| 플랫폼 | `user_id` 사용 시작일 | 그 전 |
|---|---|---|
| APP | 2019-04-01 | `user_pseudo_id` (Firebase 자동 생성) |
| WEB | 2022-12-01 | `user_pseudo_id` |

→ 2022-12-01 이전 WEB 데이터에서 `user_id_processed` 는 anonymous ID. 사용자 매핑 시 유의.

### 1-4. 시간대 일관성

- 모든 `event_date` 는 KST 기준 (staging 에서 변환됨)
- `event_timestamp` 는 UTC TIMESTAMP 그대로 보존 (변환 필요 시 `TIMESTAMP_TRUNC(event_timestamp, DAY, 'Asia/Seoul')` 등)
- raw `analytics_164027297.events_*` 의 `_TABLE_SUFFIX` 는 UTC 날짜 — 마트의 `event_date` 와 1일 차이 발생 가능

---

## 2. 이벤트 수집 함정

### 2-1. 화이트리스트 게이트키핑

Firebase / 서버 모두 raw 단계에 이벤트가 존재해도 **`*_events_list` 화이트리스트에 등록되지 않은 이벤트는 staging 이후 마트에 도달하지 않습니다**.

- Firebase: `hlb_staging.staging_key_events_fb_events_list`
- 서버: `hlb_staging.staging_key_events_se_events_list`
- 보조: `hlb_staging.events_list`

→ raw 와 마트 간 이벤트 수가 다른 정상적인 이유. raw 직접 분석 시 화이트리스트 필터 기준이 다를 수 있음을 인지.

### 2-2. 서버 이벤트 환경 필터

서버 이벤트는 staging 단계에서 `env IN ('production','prod')` 만 통과시킵니다. dev/staging 데이터는 자동 제외.

### 2-3. 테스터 자동 제외

`server_rdb.user_test_group` 에 등록된 사용자는 모든 마트에서 자동 제외됩니다. 분석 시 추가 필터 불필요. 단, raw 직접 분석 시에는 수동 제외 필요.

### 2-4. ID/이름 페어 룰 미준수 케이스

대부분 이벤트는 `*_seq` + `*_name` 페어로 발송되지만, 일부 이벤트에서 미준수 사례가 있습니다. 이 경우 마스터 dimension (예: `mart_fixed_menu_server`) 과 조인 필요. 분석 중 `*_seq` 만 있고 `*_name` 이 NULL/누락이면 페어 미준수 의심.

---

## 3. 마트 품질 함정

### 3-1. 파티션 미적용 마트 다수

대부분의 `hlb_mart.*` 가 `PARTITION BY` 없이 `CREATE OR REPLACE TABLE` 로 매일 전체 재생성됩니다. `WHERE event_date = '...'` 조건을 걸어도 **테이블 풀스캔이 발생**할 수 있습니다.

→ **반드시** [04-query-guide.md](./04-query-guide.md) 의 dry-run 으로 스캔 바이트를 사전 확인하세요. 10GB 이상이면 query 구조 재검토.

### 3-2. `mart_user_daily_info` 파티션 없음

DAU 본진 마트인데 파티션이 없습니다. 큰 기간 조회는 풀스캔. 가능하면 `mart_use_skill_se` 등 파티션 있는 마트로 우회하거나, 작은 기간씩 분할 조회.

### 3-3. `mart_skill_funnel_fb` 는 **레거시**

스킬 퍼널 분석에서 `mart_skill_funnel_fb` 와 `mart_v2_skill_funnel_fb` 둘 다 존재. **v2 가 신규 버전**이며 일부 SQL 에 `pricegit` 같은 alias 오타도 있는 등 가독성 이슈. 새 분석은 가능하면 `mart_v2_skill_funnel_fb` 사용 권장.

### 3-4. `mart_skill_open_date_se` 레이어 위반

`mart_skill_open_date_se` 는 같은 `hlb_mart.mart_use_skill_se` 를 참조합니다 (mart→mart). 일반적인 staging→intermediate→mart 의존 흐름과 다른 예외. 의존 체인 추적 시 유의.

---

## 4. 외부 의존 함정

### 4-1. `google_sheet_sync.*` — 수동 갱신

마케팅 ROAS, 광고매출, 환율, 스킬 태그 등이 Google Sheet 수동 입력에 의존합니다. freshness 모니터링이 부재하여 시트 갱신 누락 시 알 수 없습니다. 분석 중 광고매출이 갑자기 0 으로 나오면 시트 미갱신 의심.

- `google_sheet_sync.marketing_roas_daily`
- `google_sheet_sync.ad_revenue_network_daily`
- `google_sheet_sync.ad_revenue_direct_daily`
- `google_sheet_sync.taenyon_temp_skill_tag_info_v2` (스킬 태그 — 운영자 수동 관리)
- `google_sheet_sync_all.hellobot_kpi_goal_monthly` (KPI 목표)

### 4-2. `manual_server_rdb.product` — 수동 업로드

상품 마스터가 수동 업로드 테이블입니다. 신규 상품 추가 시 업로드 누락이면 매출 분석에서 해당 상품 카테고리가 누락될 수 있음.

### 4-3. Braze export freshness

`hellobot_braze.*` 의 푸시 발송·오픈 데이터는 Braze export 일별 동기화에 의존. 동기화 지연 가능.

### 4-4. AWS Glue RDS 스냅샷 (`server_rdb.snapshot_*`)

RDS 스냅샷은 일별. 따라서 `server_rdb.*` 의 사용자 정보·상품 정보는 **D+1 기준** (오늘 변경된 RDS 값은 내일에야 BQ 에 반영).

---

## 5. 모니터링 갭 (인지만)

다음은 인프라 측 모니터링이 부재한 영역으로, **분석 결과 검증 시** 인지하면 도움 됩니다:

| 영역 | 갭 | 분석 시 영향 |
|---|---|---|
| Freshness 자동 알림 | 없음 | Firebase export 지연, GSheet 갱신 누락 자동 감지 불가 |
| 스키마 변경 감지 | 없음 | 서버 RDS 스키마 변경 시 snapshot 실패 후 인지 |
| Row count 이상치 감지 | 없음 | 이벤트 드랍/급증 자동 감지 불가 |
| Null 비율 · 중복 모니터링 | 없음 | 데이터 품질 자동 검증 부재 |
| Looker Studio 대시보드 ↔ 마트 매핑 | 없음 | 마트 변경의 영향 범위 수동 추적 |

→ 분석 결과가 이상하게 보이면 **숫자가 갑자기 변한 시점 직전의 raw 이벤트 수**를 직접 확인하는 것이 가장 빠릅니다.

---

## 6. 이중 정의 (참고)

분석 중 다음 컬럼/지표는 여러 마트에 비슷한 이름으로 등장합니다. 의도가 다를 수 있으므로 마트별 정의 확인 필요:

| 컬럼 | 정의 차이 |
|---|---|
| `revenue_krw` vs `spent_total_amount_krw` | §1-1 참조 |
| `user_id` vs `user_id_processed` | `user_id` 는 raw 그대로 (anonymous 가능), `user_id_processed` 는 표준화 (§1-3) |
| `created_at` (사용자 가입일) vs `user_created_at` | 같은 의미지만 마트별 표기 다름 |
| `event_date` (KST) vs `_TABLE_SUFFIX` (UTC) | §1-4 참조 |
