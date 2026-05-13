# mart_home_action_fb

> 홈 화면 액션 이벤트 (탭 조회, 배너 터치, 섹션 아이템 터치 등) 분석 마트. Firebase 이벤트 기반.

## 개요

- **Full name**: `hellobot-f445c.hlb_mart.mart_home_action_fb`
- **그레인**: 이벤트 단위 (user × event_timestamp × menu_seq)
- **파티션**: *미지정*
- **머티리얼라이제이션**: `CREATE OR REPLACE TABLE`
- **스케줄**: 매일 1회

## 설명

홈 화면의 탐색·클릭 행동을 Firebase로 수집한 뒤 스킬 메타·챗봇 메타를 덧붙인 마트. `union_mart_user_key_actions`의 **홈 배너 유입 퍼널 태깅**에 사용됨.

**포함 이벤트 (SQL 주석 기준)**
- `view_tab_at_home` — 홈 탭 조회
- `touch_featured_banner` — 홈 메인 배너 터치
- `touch_home_section_item` — 홈 섹션 내 아이템 터치
- `touch_home_section_more_item` — 홈 섹션 더보기 터치

**2025.10.13 추가 (오늘의 운세 탭)**
- `view_daily_fortune` / `view_daily_fortune_subject` / `touch_daily_fortune_subject`
- `start_ad_on_daily_fortune` / `finish_ad_on_daily_fortune`

**필터**: `chatbot_seq != "0"` 또는 NULL (0은 invalid 값)

## 업스트림

- `hlb_intermediate.intermediate_home_action_fb` (base)
  - ← `intermediate_v2_metrics_lv1_fb` / `lv2` / `lv3`
- `hlb_staging.staging_fixed_menu_copy` (menu 조인)
- `hlb_staging.staging_chatbot_server` (chatbot 조인)

## 다운스트림

- `hlb_mart_integrated.union_mart_user_key_actions` — `touch_featured_banner` 만 필터해서 `funnel_from_home_banner` 태깅
- `hlb_mart_integrated.union_mart_use_skill_from_home_banner` (추정)

## 컬럼 (그룹별)

### 시간
`event_date` (**not_null**, 파티션 후보) / `event_timestamp` / `event_month` / `event_week` / `start_of_week` / `end_of_week`

### 이벤트 · 사용자
- `event_name` — 위 4+5종
- `user_id` / `user_pseudo_id` / `user_id_processed` (**not_null**)

### 챗봇 · 메뉴 (조인)
- `chatbot_seq` / `chatbot_name` / `chatbot_created_at_date` / `chatbot_type` / `chatbot_category` / `chatbot_channel` / `chatbot_content_type`
- `menu_seq` / `menu_name` (staging_fixed_menu_copy JOIN) / `menu_price` / `current_price`

### 홈 액션 컨텍스트
- `banner_title` — 배너 이벤트일 때 표기된 제목
- `section_name` — 섹션 이벤트일 때 섹션명 (예: "추천스킬", "인기 TOP 10")
- `tab_name` — 탭 컨텍스트
- `item_index` — 섹션 내 아이템 순서 (0-indexed 추정)
- `ga_session_id` — GA 세션 ID

### 기기 · 플랫폼
- `platform` / `country` / `language` / `operating_system` / `operating_system_version` / `version`

### 사용자 속성
- `user_gender` / `user_birth_year/month/day` / `user_age` / `user_type` / `user_created_at`
- `user_is_new_month` / `user_is_new_week` / `user_in_app_language`

## 답할 수 있는 질문

- 홈 배너 CTR (`touch_featured_banner` / `view_tab_at_home`)
- 배너별 클릭 수 (`banner_title` 집계)
- 섹션별 퍼포먼스 (`section_name` × 결제 전환율)
- 섹션 내 아이템 순서(`item_index`)의 영향
- 오늘의 운세 탭 진입률 및 광고 시청 완료율 (2025.10.13~ 이벤트)

## 답할 수 없는 질문

| 필요 분석 | 가야 할 테이블 |
|---|---|
| 카테고리 탐색 · 검색 유입 | `mart_v2_skill_funnel_fb` |
| 결제 연결 분석 | `union_mart_user_key_actions` (funnel_from_home_banner) |
| 스킬 상세 진입 이후 행동 | `mart_skill_funnel_fb` / `mart_v2_skill_funnel_fb` |

## 주의사항

- `chatbot_seq = "0"` 은 invalid 이벤트라 필터링됨 — 클라이언트 버그/특수 케이스 추적 시에는 raw staging 필요
- `menu_price` / `current_price` 는 이벤트 시점 로그 값 (서버 현재 가격과 다를 수 있음)
- `banner_title`, `section_name` 은 한글 혼재 — 문자열 매칭 시 `LIKE '%...%'` 패턴 주의 (섹션 이름 변경 이력 있음)

## dbt 이식 매핑

```
현재 경로        scripts/hellobot/mart/mart_home_action_fb.sql
dbt 경로        models/marts/hellobot/home/mart_home_action_fb.sql
materialized    incremental (partition_by=event_date)
```
