# F-202 — 결제 이벤트 그룹 (Server `pay_for_*`) 시맨틱 baseline

| 항목 | 값 |
|---|---|
| Phase | P2 |
| 중요도 | ★★★ — 매출 직결 (Server) |
| 상태 | 확정 — dead 변종 4건 분리 |
| 작성일 | 2026-05-01 |
| 출처 | 카탈로그 [event-catalog.md §4-2 결제](../../../../../common-data-airflow/docs/hellobot-data/catalog/event-catalog.md) + F-002 §3·§5 (dead whitelist 분석) + F-101 §3 결제 컬럼 시맨틱 |
| affects-ssot | yes — 4건 deprecated 표기 (v2 인계, F-002 §3 Dead whitelist 인계와 통합) |
| affects-tier | **Tier 1 (활성 1건) + Tier 4 정리 (dead 4건)** |

## 1. 6 이벤트의 활성 분류 (★ F-002 검증)

| 이벤트 | 1st | se_2nd | 7일 raw | 분류 | dbt Tier |
|---|---|---|---|---|---|
| `pay_for_contents` | - | ✓ | **16,020** | **활성** (★ 매출 본진) | Tier 1·2 |
| `pay_under_750` (파생) | (SQL 변환) | - | (mart 단 분기) | **활성** (`mart_use_skill_se` 파생) | Tier 2 (산식 보존) |
| `pay_for_package` | - | ✓ | **0** | dead | Tier 4 (정리) |
| `pay_for_coaching_program` | - | ✓ | **0** | dead | Tier 4 |
| `pay_for_collection` | - | ✓ | **0** | dead | Tier 4 |
| `pay_for_chatbot_subscription` | ✓ | ✓ | **0** | dead | Tier 4 (양쪽 등록인데도 발화 0 — 기능 deprecated 추정) |

→ **활성은 단 1건** (`pay_for_contents`) + **파생 1건** (`pay_under_750`). 나머지 4건은 dead whitelist (F-002 §3 카테고리 "결제 옵션 3건" + chatbot_subscription).

## 2. 활성 이벤트 — `pay_for_contents`

### 발화 시점
사용자가 스킬 콘텐츠 결제 완료 시 서버 발화 (env=production 만).

### 파라미터
| 파라미터 | 타입 | 의미 |
|---|---|---|
| `menu_seq` + `menu_name` | STRING + STRING | 결제 콘텐츠 ID/이름 (페어) |
| `chatbot_seq` + `chatbot_name` | 동일 | 소속 챗봇 |
| `spent_heart_coin` | INTEGER | 유료 하트 사용량 |
| `spent_bonus_heart_coin` | INTEGER | 보너스 하트 (revenue_krw 제외) |
| `spent_cash_amount` | FLOAT | 현금 결제액 |
| `spent_cash_currency` | STRING | 통화 (KRW/JPY/USD) |
| `current_heart_price` `heart_price` `current_price` `price` | INTEGER | 가격 정보 (할인 전·후) |

### 비즈 룰 (보존 필수 — F-101 §4-1 동일)
```
revenue_krw = IFNULL(spent_heart_coin, 0) * KRW_PER_HEART  -- KRW_PER_HEART = 150
            + IFNULL(spent_cash_amount * cr.rate, 0)
```
- 보너스 하트 제외
- 외화 환산은 `google_sheet_sync.currency_rate`

### 다운스트림
- `mart_use_skill_se` (F-101) → `union_mart_user_key_actions` (F-106) → KPI 알림 + Looker

## 3. 파생 이벤트 — `pay_under_750`

### 정의 (F-101 §4-2 동일)
```sql
event_name = CASE
  WHEN event_name = "pay_for_contents"
   AND (heart_value + bonus_heart_value + cash_value_krw) < 750
  THEN "pay_under_750"
  ELSE event_name
END
```
- mart 단 변환 (`mart_use_skill_se.sql`) 에서 분기
- 원본 raw 이벤트 아님 — 분석 분리 목적

### 보존 필수
- 임계값 750 KRW
- 변환 SQL 위치 (mart 단)

## 4. Dead 이벤트 4건 (정리 대상)

### 4-1. `pay_for_package`, `pay_for_collection`, `pay_for_coaching_program`
- se_2nd 등록되어 있으나 7일 raw 발화 0건
- 카탈로그 §4-2 에 명시되어 있지만 실 발화 없음 → **기능 자체 deprecated 추정**

### 4-2. `pay_for_chatbot_subscription`
- **events_list (1차) + se_2nd (2차) 모두 등록**된 유일한 양쪽 등록 결제 이벤트인데도 7일 발화 0
- 챗봇 구독 기능 deprecated (F-002 §3 chatbot_subscription 카테고리 8건 dead 와 일치)

### 처리
→ **MP-3 정리 대상**. v2 인계 9번 (Dead whitelist deprecation 표기) 에 통합. 카탈로그 §4-2 에 deprecated 표기 권장.

→ dbt 마이그에서: `mart_use_skill_se` 의 `event_name IN (...)` 필터 list 에서 4건 제거 권장 (단, historical 데이터에 레코드 있을 수 있으니 주의).

## 5. dbt 마이그 가이드

### 5-1. Tier 분류
| 자산 | Tier | 처리 |
|---|---|---|
| `pay_for_contents` | Tier 1·2 | 보존 (mart_use_skill_se Tier 와 함께) |
| `pay_under_750` | Tier 2 | 산식 보존 |
| 4건 dead | Tier 4 | 정리 (MP-3) |

### 5-2. dbt event 모델 (의사 코드)
```sql
-- staging_key_events_se 에서 결제 이벤트만 필터
{{ config(materialized='incremental', partition_by={'field': 'event_date'}) }}

WITH payment_events AS (
    SELECT *
    FROM {{ ref('staging_key_events_se') }}
    WHERE event_name IN (
        'pay_for_contents'  -- 활성만 (dead 4건 제거)
    )
)
-- 750 미만 분기
SELECT *,
       CASE WHEN total_amount_krw < {{ var('pay_under_750_threshold') }} THEN 'pay_under_750'
            ELSE event_name END AS event_name_classified
FROM payment_events
```

### 5-3. 보존 필수
- `pay_for_contents` 7개 결제 파라미터 + 페어 규칙
- `pay_under_750` 임계값 750 + 변환 위치 (mart 단)
- KRW_PER_HEART = 150 (F-101 §4-1 통합 권장)

### 5-4. 개선 후보 (MP-2)
- dead 4건 제거 (단순화)
- KRW_PER_HEART dbt var
- pay_under_750 임계값 dbt var

## 6. 후속 액션

- [x] 본 카드 작성 (2026-05-01)
- [ ] (P7) dead 4건 정리 결정 — MP-3 에 통합
- [ ] (v2 인계) 카탈로그 §4-2 의 dead 4건에 deprecated 표기
