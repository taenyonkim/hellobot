# mart_user_daily_info

> 상세 포맷 기준 문서. 신규 마트 문서 작성 시 본 파일의 구조를 그대로 따름.
> 데이터 소스: `scripts/hellobot/mart/mart_user_daily_info.sql` (실측)

## 개요

- **Full name**: `hellobot-f445c.hlb_mart.mart_user_daily_info`
- **그레인 (1행의 의미)**: `user_id_processed × event_date` (중복 제거, Firebase 우선)
- **파티션**: *미지정* → `event_date` 파티션 적용 권장 (→ [ISS-002](../.././issues.md))
- **클러스터링**: 없음
- **머티리얼라이제이션**: `CREATE OR REPLACE TABLE` (전체 치환)
  - dbt 이식 시 `materialized='incremental'` + `unique_key=['event_date','user_id_processed']` 권장
- **스케줄**: 매일 1회
  - DAG: `hellobot_datamart_mart_pipeline` (수동 트리거 구조)
  - 실제로는 `staging_pipeline` (cron `0 2 * * *` UTC = KST 11:00)에서 `intermediate → mart` 체인으로 자동 실행

## 설명

사용자 × 일 단위로 **사용자 마스터 속성**을 펼친 dimension-like 테이블.
Firebase 이벤트와 서버 이벤트의 사용자 접속 정보를 합집합(UNION ALL)한 뒤, 동일 `(event_date, user_id_processed)`에서 **Firebase를 우선 선택**하여 중복 제거.
이후 `intermediate_user_first_info`와 조인하여 `user_created_at` 및 신규 월/주 여부를 덧붙임.

**핵심 용도**: 일자별 사용자 프로필 분포 분석, DAU 계산의 기반, 다른 마트(스킬·결제 등)와 조인할 때의 사용자 컨텍스트 제공.

## 업스트림 (소스 모델)

- `hlb_intermediate.intermediate_user_daily_info` (직접 참조)
  - ← `hlb_intermediate.intermediate_user_daily_info_temp_fb` (Firebase 경로)
  - ← `hlb_intermediate.intermediate_user_daily_info_temp_se` (Server 경로)
  - ← `hlb_intermediate.intermediate_user_first_info` (가입일 JOIN)

## 다운스트림 (알려진 소비자)

- `hlb_mart_integrated.union_mart_use_skill_and_user_daily` (스킬 사용 ↔ 사용자 일별 조인)
- Looker Studio 대시보드: **TBD** (외부 확인 과업)
- Braze Segment export: **TBD** (외부 확인 과업)
- `report_*` 직접 참조 여부: **TBD** (확인 필요)

## 컬럼 (실제 SQL 기준, 22개)

| 컬럼 | 타입 | 설명 | 비고 / 테스트 힌트 |
|---|---|---|---|
| `event_date` | DATE | 이벤트 발생일 (Asia/Seoul 기준) | **not_null**, 향후 파티션 키 후보 |
| `event_month` | STRING | 이벤트 월 (`YYYY-MM`) | |
| `event_week` | STRING | 이벤트 주차 (`YYYY-Www`, 월요일 시작) | |
| `start_of_week` | DATE | 해당 주 시작일(월요일) | |
| `end_of_week` | DATE | 해당 주 종료일(일요일) | |
| `user_id` | STRING | 서버 발급 사용자 ID | 서버 로그인 시점 이후에만 존재 |
| `user_pseudo_id` | STRING | Firebase 디바이스 식별자 | |
| `user_id_processed` | STRING | 표준화된 사용자 식별자 | **not_null**, `(event_date, user_id_processed)` 복합 PK 후보 |
| `language` | STRING | 사용자 기기 언어 | |
| `country` | STRING | 국가 코드 | |
| `platform` | STRING | 플랫폼 (예: ANDROID / IOS / WEB) | **accepted_values** — 실제 도메인 값 확인 필요 |
| `operating_system` | STRING | OS | |
| `operating_system_version` | STRING | OS 버전 | |
| `version` | STRING | 앱 버전 | |
| `user_gender` | STRING | 성별 (원본 컬럼: `gender`) | |
| `user_birth_year` | INT64 | 생년 | |
| `user_birth_month` | INT64 | 생월 | |
| `user_birth_day` | INT64 | 생일 | |
| `user_age` | INT64 | 나이 | 계산 시점 기준, 만 나이 여부 확인 필요 |
| `user_type` | STRING | 사용자 유형 | 실제 도메인 값 확인 필요 |
| `user_created_at` | DATE | 최초 가입일 | `intermediate_user_first_info` JOIN |
| `user_is_new_month` | BOOLEAN | 이번 이벤트 월이 가입 월과 같은지 | |
| `user_is_new_week` | BOOLEAN | 이번 이벤트 주가 가입 주와 같은지 | |
| `in_app_language` | STRING | 앱 내 언어 설정 | |

## 답할 수 있는 질문 (이 테이블만으로)

- 일/주/월별 DAU (COUNT DISTINCT `user_id_processed`)
- 플랫폼 · 국가 · 언어 · OS 버전 · 앱 버전 분포
- 연령대 · 성별 분포 및 시계열 변화
- 신규 월/주 유저 수 (`user_is_new_month` / `user_is_new_week`)
- 특정 일자 활성 유저의 가입 코호트 분포 (`user_created_at`)

## 답할 수 없는 질문 (다른 마트 필요)

| 필요 분석 | 가야 할 테이블 |
|---|---|
| 스킬 사용 수·완료율 | `mart_use_skill_se` / `mart_skill_funnel_fb` |
| 결제·매출·구매 횟수 | `mart_purchase_fb` |
| 세션 수·체류 시간 | `mart_session_start_fb` |
| 화면 체류/페이지뷰 | `intermediate_home_action_fb` / `mart_home_action_fb` |
| 리텐션 / 코호트 | `report_cohort_retention_*` |
| 이탈 위험 / 개인화 점수 | **현재 파이프라인에 없음** (기존 문서의 `churn_risk_score` 등 주장은 허위 — [ISS-001](../.././issues.md)) |

## 주의사항

- 파티션 키 없음 → 전체 스캔 비용 주의. 조회 시 `WHERE event_date BETWEEN …` 필수 ([ISS-002](../.././issues.md))
- Firebase + Server UNION 이후 Firebase 우선 선택 → **서버 전용 사용자** (Firebase 미수집 경로)는 서버 행으로 기록됨
- `user_id`는 비로그인 사용자에서 NULL 가능 — 분석 기본 키는 `user_id_processed`
- 시간대: `event_date` 는 Asia/Seoul 기준 (원본 Firebase는 UTC → staging에서 변환됨)

## 기존 문서 대비 변경 사유

- 기존 `common-data-airflow/docs/hellobot-data/tables/mart/mart_user_daily_info.md` (295줄)는 실제 SQL과 컬럼·설명이 심각하게 불일치 → **deprecated** 처리 ([ISS-001](../.././issues.md))
- 본 문서는 `scripts/hellobot/mart/mart_user_daily_info.sql`의 실제 내용만 반영

## dbt 이식 매핑

```
현재 경로        scripts/hellobot/mart/mart_user_daily_info.sql
dbt 경로        models/marts/hellobot/core/mart_user_daily_info.sql
모델 이름       mart_user_daily_info (또는 fct_user_daily_activity)
materialized    incremental (unique_key=['event_date','user_id_processed'], partition_by=event_date)
```

### schema.yml 초안 (이식 시 복사용)

```yaml
version: 2

models:
  - name: mart_user_daily_info
    description: |
      사용자 × 일 단위 사용자 마스터 속성 테이블. Firebase/Server 이벤트를
      UNION 후 Firebase 우선으로 중복 제거. DAU 및 유저 프로필 분석의 기반.
    config:
      materialized: incremental
      partition_by:
        field: event_date
        data_type: date
      unique_key: ['event_date', 'user_id_processed']
    columns:
      - name: event_date
        description: 이벤트 발생일 (Asia/Seoul)
        tests:
          - not_null
      - name: user_id_processed
        description: 표준화된 사용자 식별자
        tests:
          - not_null
      - name: platform
        description: 사용자 플랫폼
        tests:
          - accepted_values:
              values: ['ANDROID', 'IOS', 'WEB']  # 실제 값 확인 후 확정
      # ... (나머지 19개 컬럼은 위와 동일 포맷으로 확장)
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns: [event_date, user_id_processed]
```
