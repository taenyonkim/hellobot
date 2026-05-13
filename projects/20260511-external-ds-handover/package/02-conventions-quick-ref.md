# 02 — 결정적 컨벤션 Quick Reference

> 분석 시 반드시 알아야 할 데이터 컨벤션 요약. 상세는 [11-architecture.md §5 공통 규약](./11-architecture.md) 참조.

---

## 1. 한눈에

| # | 룰 | 내용 |
|---|---|---|
| 1 | **시간대** | 모든 `event_date` 는 **Asia/Seoul (KST)** (staging 에서 UTC→KST 변환) |
| 2 | **표준 사용자 ID** | `user_id_processed` — APP 2019-04-01+ / WEB 2022-12-01+ 부터 `user_id`, 그 전은 `user_pseudo_id` |
| 3 | **표준 매출** | `revenue_krw` (유료 하트 + 현금, 보너스 하트 **제외**) |
| 4 | **하트 환산** | `KRW_PER_HEART = 150` (1하트 = 150 KRW) |
| 5 | **KRW 마이크로단위** | Firebase `in_app_purchase` + `currency='KRW'` 의 `value` 는 1,000,000 배 — 파이프라인에서 `/1e6` 처리 후 마트에 들어감 |
| 6 | **주차 기준** | `WEEK(MONDAY)` (월요일 시작) |
| 7 | **서버 이벤트 env 필터** | `env IN ('production','prod')` 만 분석 대상 (dev/staging 배제) |
| 8 | **테스터 자동 제외** | `server_rdb.user_test_group` 등록 사용자는 **모든 마트에서 자동 제외됨** (분석 시 추가 필터 불필요) |
| 9 | **이벤트 화이트리스트** | Firebase / 서버 양쪽 모두 `*_events_list` 화이트리스트 등록된 이벤트만 staging 도달 (등록 안된 이벤트는 raw 에 있어도 마트에 없음) |
| 10 | **파티션** | 마트 대부분 파티션 **없음** → 조회 시 `WHERE event_date BETWEEN …` 필수 (비용 가드) |

---

## 2. 자주 쓰는 패턴

### 2-1. DAU/WAU/MAU

```sql
-- DAU
SELECT event_date, COUNT(DISTINCT user_id_processed) AS dau
FROM `hellobot-f445c.hlb_mart.mart_user_daily_info`
WHERE event_date BETWEEN '2026-05-01' AND '2026-05-31'
GROUP BY event_date;

-- WAU (월요일 시작)
SELECT DATE_TRUNC(event_date, WEEK(MONDAY)) AS week_start,
       COUNT(DISTINCT user_id_processed) AS wau
FROM `hellobot-f445c.hlb_mart.mart_user_daily_info`
WHERE event_date BETWEEN '2026-04-01' AND '2026-05-31'
GROUP BY week_start;

-- MAU
SELECT FORMAT_DATE("%Y-%m", event_date) AS event_month,
       COUNT(DISTINCT user_id_processed) AS mau
FROM `hellobot-f445c.hlb_mart.mart_user_daily_info`
WHERE event_date BETWEEN '2026-01-01' AND '2026-05-31'
GROUP BY event_month;
```

### 2-2. 매출 (revenue_krw)

```sql
-- 일별 매출
SELECT event_date,
       SUM(revenue_krw) AS revenue_krw,
       COUNT(DISTINCT user_id_processed) AS paying_users
FROM `hellobot-f445c.hlb_mart.mart_use_skill_se`
WHERE event_date BETWEEN '2026-05-01' AND '2026-05-31'
  AND revenue_krw > 0
GROUP BY event_date;
```

> **권장**: 매출 분석은 **`mart_use_skill_se`** (서버 이벤트, 매출 정합 기준) 우선 사용. Firebase 의 `mart_purchase_fb` 는 스토어 인앱 결제 분석에만 사용.

### 2-3. 신규 vs 기존 사용자 분기

```sql
SELECT event_date,
       SUM(CASE WHEN is_new_month THEN 1 ELSE 0 END) AS new_users,
       SUM(CASE WHEN NOT is_new_month THEN 1 ELSE 0 END) AS existing_users
FROM `hellobot-f445c.hlb_mart.mart_user_daily_info`
WHERE event_date BETWEEN '2026-05-01' AND '2026-05-31'
GROUP BY event_date;
```

### 2-4. 사용자 단위 통합 분석 (방문·스킬·결제)

```sql
-- union_mart_user_key_actions: 한 사용자의 모든 액션을 시계열로
SELECT event_date, user_id_processed, action_type, menu_seq, revenue_krw
FROM `hellobot-f445c.hlb_mart_integrated.union_mart_user_key_actions`
WHERE event_date BETWEEN '2026-05-01' AND '2026-05-07'
  AND user_id_processed = '12345';
```

→ **사용자 분석의 본진**. 1행 = 1개 액션 이벤트. 자세한 컬럼은 [📄 카드](./23-tables/mart_integrated/union_mart_user_key_actions.md) 참조.

---

## 3. ID/이름 페어 (이벤트 설계 룰)

ID 컬럼(`*_seq`)을 사용하는 이벤트는 대응 이름 컬럼(`*_name`)도 함께 들어 있습니다. **분석 시 굳이 마스터 dimension 과 조인할 필요 없이 이벤트 자체의 이름 컬럼을 활용** 가능 (시점별 명칭 변화도 보존).

| ID | 페어 이름 |
|---|---|
| `menu_seq` | `menu_name` |
| `chatbot_seq` | `chatbot_name` (+ `chatbot_bundle_seq`, `chatbot_language`) |
| `block_seq` | `block_name` |
| `collection_seq` | `collection_name` |
| `package_seq` | `package_title` |

> 일부 이벤트에서 이 룰이 미준수된 경우가 있어 마스터 조인이 필요할 수 있습니다 ([03-known-caveats.md](./03-known-caveats.md) 참조).

---

## 4. 데이터 freshness

| 데이터셋 | 갱신 시점 |
|---|---|
| Firebase events (`analytics_164027297.events_*`) | D+1 KST 10:00 경 (Google 자동) |
| 서버 이벤트 (`analytics_164027297.server_events`) | 거의 실시간 (수 분 지연) |
| RDS 스냅샷 (`server_rdb.snapshot_*`) | D+1 일별 |
| `hlb_staging.*` | D+1 KST 11:00 경 |
| `hlb_mart.*` | D+1 KST 11:30 ~ 12:00 경 |
| `hlb_mart_integrated.*`, `hlb_mart_adhoc.*` | 위 mart 직후 |
| `hlb_report.*` | 위 mart_integrated 직후 |

**전체 파이프라인**: KST 11:00 (= UTC 02:00) staging 트리거 → 약 1~2시간 내 모든 report 완료.

---

## 5. 파이프라인 계층

```
sources                     (Firebase · server_events · RDS · GSheet · Braze)
  ↓
hlb_staging                 (테스터 제외 · 이벤트 화이트리스트 · KST 변환)
  ↓
hlb_intermediate            (조인 · 비즈 로직 · 사용자 정보 병합)
  ↓
hlb_mart                    (도메인별 분석 마트 — ★ 분석가 진입점)
  ↓
hlb_mart_integrated         (사용자×이벤트 통합 — ★★ 분석의 본진)
hlb_mart_adhoc              (RFM · UTM · 스냅샷)
  ↓
hlb_pre_report → hlb_report (KPI · Slack 알림 · 대시보드)
```

상세: [11-architecture.md](./11-architecture.md)

---

## 6. 빠른 참조 — 어디서 답을 찾나

| 질문 | 1차 데이터셋 / 마트 |
|---|---|
| 일별 활성 사용자 | `hlb_mart.mart_user_daily_info` |
| 결제·매출 (서버 정합) | `hlb_mart.mart_use_skill_se` |
| Firebase 스토어 인앱 결제 | `hlb_mart.mart_purchase_fb` |
| 사용자 마스터 / CRM 디멘전 | `hlb_mart.mart_user_server` |
| 스킬(메뉴) 마스터 | `hlb_mart.mart_fixed_menu_server` |
| 사용자별 전 액션 시계열 | `hlb_mart_integrated.union_mart_user_key_actions` ★ |
| 홈 배너·섹션·탭 | `hlb_mart.mart_home_action_fb` |
| 스킬 퍼널 (탐색→상세→사용) | `hlb_mart.mart_v2_skill_funnel_fb` |
| 사용자 RFM 세그먼트 | `hlb_mart_adhoc.adhoc_mart_user_rfm_info_daily` |
| 푸시·CRM 발송/오픈 | `hellobot_braze.*` + `hlb_report.report_crm_*` |
| 코호트 리텐션 | `hlb_pre_report.pre_report_cohort_retention_*` |
| 마케팅 ROAS / 광고매출 | `google_sheet_sync.*` (수기) |

전체 인벤토리: [20-mart-catalog.md](./20-mart-catalog.md)
