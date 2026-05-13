# F-104 — `hlb_mart.mart_user_server` 시맨틱 baseline

> **외부 전달용 안내** — 본 문서는 내부 dbt 마이그 분석 과정에서 작성된 자산 baseline 카드입니다. 본문 중 "Tier 1~4", "dbt 마이그 가이드", "F-NNN" 등 내부 의사결정 마커는 무시하셔도 됩니다. 자산의 **그레인 · 컬럼 · 비즈 룰 · 외부 의존** 정보만 분석 참고용으로 활용하세요.

| 항목 | 값 |
|---|---|
| Phase | P2 |
| 중요도 | ★★ (다운스트림 17, F-001 4위) — 사용자 마스터 + CRM 분석 본진 |
| 상태 | 확정 |
| 작성일 | 2026-05-01 |
| 출처 | SQL 본문 + queries.py + `bq show` 실측 + F-001 raw |

## 1. 자산 메타 (실측)

| 항목 | 값 |
|---|---|
| Full name | `hellobot-f445c.hlb_mart.mart_user_server` |
| 행 수 | 63,529,633 (6,353만) |
| 크기 | 5.13 GB |
| **파티션** | **없음** ★ — 본 마트는 partition 안되어 있음 (개선 후보) |
| 클러스터링 | 없음 |
| 컬럼 수 | 26 |
| Materialization | `CREATE OR REPLACE TABLE` (전체 재생성, 매일) — 추정 |
| 마지막 갱신 | 2026-05-01 (활성) |

## 2. 그레인 (1 row 의 의미)

```
1 row = 1 user (user_id 단일 키)
```

- `staging_user_server` (RDS 스냅샷) 1:1 변환 — RDS user 테이블의 매일 스냅샷
- `deleted_at_date` 가 NULL 이 아니면 탈퇴 사용자 (그러나 본 마트에는 보존)
- → 모든 분석에서 사용자 마스터로 사용 (활성·CRM·코호트 등의 디멘전)

## 3. 핵심 컬럼 시맨틱 (26개)

### 시간 (6) — 가입일 정규화
| 컬럼 | 의미 |
|---|---|
| `created_at` | 가입일 (KST DATE) |
| `created_at_month` `created_at_week` `start_of_week` `end_of_week` | 사전 계산 시간 디멘전 |
| `created_at_timestamp` | 가입 시점 (TIMESTAMP, UTC) |
| `deleted_at_date` | 탈퇴일 (NULL = 활성 사용자) |

### 사용자 정보 (5)
| 컬럼 | 의미 |
|---|---|
| `user_id` | INTEGER (RDS `seq` 컬럼) |
| `type` | 사용자 타입 (`mart_user_server_types_list` 와 cross join 으로 필터됨) |
| `name` | 사용자 이름 |
| `gender` `birth_year` `birth_month` `birth_day` | 인적 정보 |

### A/B 테스트 그룹 (1, 비즈 룰)
| 컬럼 | 의미 |
|---|---|
| `test_group` | A (홀수 user_id) / B (짝수 user_id) — **가격조정 실험 그룹** |

### 푸시 플래그 (12, CRM 본진)
| 컬럼 | 의미 |
|---|---|
| `push_in_app_on` | **파생** — 7개 플래그 OR (in-app 푸시 활성 여부) |
| `push_app_on` | 앱 푸시 마스터 스위치 |
| `push_os_on` | OS 레벨 권한 |
| `push_day_on` `push_night_on` | 시간대 |
| `push_fortune_of_today_on` `push_bonus_heart_on` `push_chatroom_on` `push_heartco_on` `push_follow_on` `push_attendance_check_on` | 카테고리별 |

→ **CRM 분석의 진실 원천** — `report_crm_optin_*` 7 SQL 가 본 마트 직접 사용.

## 4. 비즈 룰 (보존 필수)

### 4-1. `test_group` A/B 분류 (★ historical)
```sql
CASE
    WHEN MOD(CAST(seq AS INT64), 2) = 1 THEN "A"
    WHEN MOD(CAST(seq AS INT64), 2) = 0 THEN "B"
END AS test_group  -- 가격조정 실험 그룹
```

- user_id 의 홀짝으로 A/B 분기
- **출처 미명문화** — 언제 도입된 가격조정 실험인지, 현재도 활성인지 불명 (P6 historical 수집 후보)
- → 다운스트림에서 가격·매출 분석 시 사용 가능
- dbt 마이그 시: 보존하되 historical 명문화 필요

### 4-2. `push_in_app_on` 파생 룰
```sql
push_in_app_on = (push_day_on OR push_night_on OR push_fortune_of_today_on
                  OR push_bonus_heart_on OR push_chatroom_on OR push_heartco_on
                  OR push_follow_on)
```
- 7개 플래그 중 하나라도 ON 이면 TRUE
- **`push_app_on`, `push_os_on`, `push_attendance_check_on` 는 제외** — 의도된 분류
- → CRM optin 분석의 1차 정의

### 4-3. `type` 필터 (cross join 패턴)
```sql
WITH user_types AS (
    SELECT ARRAY_AGG(DISTINCT type) AS types
    FROM `hellobot-f445c.hlb_mart.mart_user_server_types_list`
)
... CROSS JOIN user_types AS ut WHERE sus.type IN UNNEST(ut.types)
```

- `mart_user_server_types_list` 는 **6 rows 의 type whitelist dimension** — F-004 §6 에서 dead 로 잘못 분류됨 (정정 필요)
- 운영자 수동 갱신 dimension (2023-05 이후 미수정 = type 이 거의 안 변함)
- → dbt 마이그 시 **dbt seed** 로 등록 권장

→ **F-004 정정**: `mart_user_server_types_list` 는 dead 가 아닌 **활성 stable dimension** (사용자 확인 시점에 dead 표 에서 제거).

### 4-4. UTC→KST 시간대 변환
```sql
DATE(TIMESTAMP(create_at), "Asia/Seoul") AS created_at
```
- RDS 의 `create_at` (UTC TIMESTAMP) 을 KST DATE 로 변환
- 카탈로그 §결정적 컨벤션 일치

## 5. 외부·내부 의존

### 업스트림
- `hlb_staging.staging_user_server` (RDS 스냅샷, 매일 갱신)
- `hlb_mart.mart_user_server_types_list` (6 rows dimension)

### 다운스트림 (17 SQL — F-001 raw 정확한 list)

| 카테고리 | 파일 |
|---|---|
| **mart** | `queries.py` (자체) |
| **report (16)** | `report_activation_monthly{,_app,_web}` (3) / `report_crm_optin_new_{daily,weekly,monthly}` (3) / `report_crm_optin_total{,_daily,_weekly,_monthly}` (4) / `report_kpi_total_skill_{monthly,weekly}{,_platform_app,_platform_web}` (6) |

→ **CRM optin (7) + activation (3) + KPI total skill (6) 모두 본 마트 의존**.

### KPI 알림 직접 의존
없음 (간접만 — report_kpi_total_skill_* 가 KPI 알림 source).

