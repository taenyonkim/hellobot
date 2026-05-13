# mart_fixed_menu_server

> **스킬(메뉴) 메타 마스터**. 서버 RDS 스냅샷과 chatbot 정보를 결합하여 스킬별 분류·가격·타겟을 제공.

## 개요

- **Full name**: `hellobot-f445c.hlb_mart.mart_fixed_menu_server`
- **그레인**: 스킬(메뉴) 단위 — `(chatbot_id, menu_seq)` 조합
- **파티션**: *없음* (dimension-like 테이블이라 적합)
- **머티리얼라이제이션**: `CREATE OR REPLACE TABLE`
- **스케줄**: 매일 1회
- **성격**: 시간 축이 없는 **디멘션** 테이블

## 설명

서버 `fixed_menu` (스킬) 테이블의 스냅샷과 `chatbot` 메타를 조인하여 각 스킬의 **메타 마스터**를 구성. 카테고리 정보는 배열(`parent_category`, `sub_category`)로 집계하고, targets/subjects/content_types 는 Postgres array-literal 문자열(`{a,b,c}`)을 파싱해 BigQuery ARRAY로 변환.

**필터 조건**: `scs.status = "friend"` (친구 상태 챗봇만) + `sfmc.seq IS NOT NULL` (스킬이 있는 행만)

## 업스트림

- `hlb_staging.staging_chatbot_server` — 챗봇 마스터
- `hlb_staging.staging_fixed_menu_copy` — 스킬(메뉴) 마스터 (서버 복사본)
- `server_rdb.snapshot_fixed_menu_category` — 카테고리 계층 (self-join으로 parent/sub 구분)
- `server_rdb.snapshot_fixed_menu_categories_fixed_menu_category` — 스킬 ↔ 카테고리 매핑 (N:N)

> `server_rdb.*` 는 Glue job 기반 RDS 스냅샷 추정. 스케줄·freshness 확인 필요.

## 다운스트림

- `hlb_mart_integrated.union_mart_user_key_actions` (스킬 메타 조인)
- 기타 스킬 분석용 직접 참조 다수 (추정)

## 컬럼

### 챗봇 정보 (10)
- `chatbot_id` / `chatbot_database_id` / `chatbot_name`
- `chatbot_created_at_date` — `scs.created_at` 을 Asia/Seoul 로 변환한 DATE
- `chatbot_type` / `chatbot_category` / `chatbot_visible_status` / `chatbot_visible_status_web`
- `chatbot_language_code` / `chatbot_original_type` / `chatbot_content_type` — 사주/타로/관상 등

### 스킬(메뉴) 정보
- `menu_seq` (**not_null**) / `menu_name`
- `menu_parent_category` ARRAY\<STRING\> — 상위 카테고리 (복수 가능)
- `menu_sub_category` ARRAY\<STRING\> — 하위 카테고리
- `menu_create_at_date` — DATE (Asia/Seoul)
- `menu_price` — 원본 서버 가격
- `menu_visible_status` / `menu_visible_status_web`

### 태그 배열 (파싱됨)
- `targets` ARRAY\<STRING\> — 타겟 세그먼트 (예: 10대, 20대 여성)
- `subjects` ARRAY\<STRING\> — 주제 (예: 연애, 결혼)
- `content_types` ARRAY\<STRING\> — 콘텐츠 유형 (예: 사주, 타로)

> 원본은 Postgres array literal `{연애,결혼}` 문자열. `REGEXP_REPLACE`로 `{}`와 공백 제거 후 `SPLIT(',')` 하여 ARRAY 생성.

## 답할 수 있는 질문

- 전체 스킬 목록 및 카테고리 분포
- 콘텐츠 타입(사주/타로/…)별 스킬 수
- 특정 카테고리(연애/결혼) 스킬 마스터
- 신규 오픈 스킬 (`menu_create_at_date` 필터)
- 플랫폼별 노출 상태 스킬 (`menu_visible_status*`)
- 가격대별 스킬 분포 (`menu_price`)

## 답할 수 없는 질문

| 필요 분석 | 가야 할 테이블 |
|---|---|
| 스킬별 실제 사용량 | `mart_use_skill_se` |
| 스킬별 매출 | `union_mart_user_key_actions` |
| 스킬 오픈일 (로그 기준) | `mart_skill_open_date_se` (원본 DB `menu_create_at_date`와 다를 수 있음) |
| 스킬 태그 (topic/intents/temporal) | `google_sheet_sync.taenyon_temp_skill_tag_info_v2` (GSheet, [ISS-006](../.././issues.md)) |

## 주의사항

### 배열 필드 사용법
- `targets`, `subjects`, `content_types` 는 ARRAY 타입
- `union_mart_user_key_actions` 에서는 `tags[SAFE_OFFSET(0)]` 로 첫 요소만 사용
- 복수 값이 있는 스킬은 **첫 요소만** 사용 시 손실 가능

### 원본 스냅샷 freshness
- `server_rdb.snapshot_*` 의 업데이트 주기 확인 필요 (일별 추정)
- 신규 스킬이 서버에 등록된 당일엔 본 마트에 반영되지 않을 수 있음

### `chatbot_created_at_date` vs `menu_create_at_date`
- 챗봇 생성일과 스킬 생성일은 다름
- 스킬 "첫 로그 날짜"는 `mart_skill_open_date_se` 에서 따로 계산

## dbt 이식 매핑

```
현재 경로        scripts/hellobot/mart/mart_fixed_menu_server.sql
dbt 경로        models/marts/hellobot/dim/dim_skill.sql (디멘션이므로 dim_ prefix 권장)
materialized    table (디멘션, 일별 전체 치환)
sources         server_rdb.snapshot_fixed_menu_category,
                server_rdb.snapshot_fixed_menu_categories_fixed_menu_category
```
