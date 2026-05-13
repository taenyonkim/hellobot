# mart_v2_skill_funnel_fb

> **V2 스킬 퍼널 전체 이벤트** (노출·탐색·진입·검색). 홈, 카테고리, 검색, 관련 스킬 등 **모든 스킬 유입 경로**의 이벤트를 담음.

## 개요

- **Full name**: `hellobot-f445c.hlb_mart.mart_v2_skill_funnel_fb`
- **그레인**: 이벤트 단위 (user × event_timestamp × menu_seq)
- **파티션**: *미지정*
- **머티리얼라이제이션**: `CREATE OR REPLACE TABLE`
- **스케줄**: 매일 1회

## 설명

홈 메인 · 섹션 · 카테고리 · 검색 · 추천 · 상세 설명 등 **스킬에 도달하는 모든 경로의 Firebase 이벤트**를 집계. `union_mart_user_key_actions`의 유입 경로 태깅 3종(home_section / home_category / search_result) 모두 본 테이블에서 추출.

**포함 이벤트 (SQL 주석 기준 20+종)**

| 카테고리 | 이벤트 |
|---|---|
| 홈 메인 | `view_home_main`, `page_view`, `touch_featured_banner`, `view_tab_at_home` |
| 추천/관련 | `view_recommend_skill`, `click_recommend_skill`, `touch_related_skill`, `click_start_button` |
| 섹션 | `touch_home_section_item`, `touch_home_section_more_item` |
| 카테고리 | `touch_category_item`, `enter_sub_category_tab`, `view_skills_in_category`, `touch_skill_item_in_category` |
| 검색 | `view_search_main`, `view_search_result`, `view_search_no_result`, `touch_search_result` |
| 상세 | `open_skill_description`, `enter_skill` |
| 신규 스킬 온보딩 | `view_new_skill_description`, `view_new_birth_info`, `view_new_question`, `view_new_preview`, `touch_new_preview_unlock`, `touch_new_preview_cta`, `view_new_login_bottomsheet` |
| 오늘의 운세 (2025.10.13~) | `view_daily_fortune`, `view_daily_fortune_subject`, `touch_daily_fortune_subject`, `start_ad_on_daily_fortune`, `finish_ad_on_daily_fortune` |

**필터**: `chatbot_seq != "0"` 또는 NULL

## 업스트림

- `hlb_intermediate.intermediate_v2_skill_funnel_fb` (base)
  - ← `intermediate_v2_metrics_lv1_fb` / `lv2` / `lv3`
- `hlb_staging.staging_fixed_menu_copy` (menu 조인)
- `hlb_staging.staging_chatbot_server` (chatbot 조인)

## 다운스트림

- `hlb_mart_integrated.union_mart_user_key_actions` — 3종 유입 이벤트 태깅
  - `funnel_from_home_section` ← `touch_home_section_item` / `touch_home_section_more_item` (특정 섹션 필터)
  - `funnel_from_home_category` ← `touch_skill_item_in_category`
  - `funnel_from_search_result` ← `touch_search_result`

## 컬럼 (그룹별)

### 시간
`event_date` (**not_null**, 파티션 후보) / `event_timestamp` (UTC) / `event_month` / `event_week` / `start_of_week` / `end_of_week`

### 이벤트 · 사용자
- `event_name` — 20+종, **accepted_values** 목록 관리 필요 (신규 이벤트 추가 시 갱신)
- `user_id` / `user_pseudo_id` / `user_id_processed` (**not_null**)
- `page_location`

### 챗봇 · 메뉴
- `chatbot_seq` / `chatbot_name` / `chatbot_created_at_date` / `chatbot_type` / `chatbot_category` / `chatbot_channel` / `chatbot_original_type` / `chatbot_content_type`
- `menu_seq` / `menu_name` (JOIN staging_fixed_menu_copy) / `menu_price` / `current_price`

### 스킬 관련 참조
- `related_skill_seq` / `related_skill_name` — 관련 스킬 (`touch_related_skill` 이벤트)
- `recommend_seq` / `recommend_name` — 추천 스킬
- `referral` — 유입 referer

### 카테고리
- `category_seq` / `category_name` / `sub_category_seq` / `sub_category_name` / `sub_category_tab_index`

### 홈 섹션 / 탭 / 배너
- `banner_title` / `section_name` / `tab_name`

### 세션
- `ga_session_id`

### 기기 · 플랫폼 · 사용자 속성
- `platform` / `country` / `language` / `operating_system` / `operating_system_version` / `version`
- `user_gender` / `user_birth_year/month/day` / `user_age` / `user_type` / `user_created_at`
- `user_is_new_month` / `user_is_new_week`

## 답할 수 있는 질문

- 스킬 진입 경로별 비중 (홈 섹션 / 카테고리 / 검색 / 추천)
- 검색 퍼널 (view_search_main → view_search_result → touch_search_result)
- 카테고리 퍼널 (touch_category_item → view_skills_in_category → touch_skill_item_in_category)
- 섹션별 CTR (section_name × touch_home_section_item / 해당 섹션 노출 수)
- 신규 스킬 온보딩 이탈률 (view_new_* / touch_new_*)
- 오늘의 운세 탭 탐색 퍼널

## 답할 수 없는 질문

| 필요 분석 | 가야 할 테이블 |
|---|---|
| 결제 연결 | `union_mart_user_key_actions` (funnel_from_* 태깅됨) |
| 이벤트 파라미터 원본 | `intermediate_v2_skill_funnel_fb` 또는 `staging_key_events_fb` |
| 구버전 퍼널 | `mart_skill_funnel_fb` (v1, 레거시) |

## 주의사항

### `section_name` 필터 하드코딩 (union_mart_user_key_actions)
`union_mart_user_key_actions`의 `distinct_touch_home_section_item` CTE는 **특정 섹션 이름 리스트**만 `funnel_from_home_section` 으로 태깅:
- "추천스킬", "인기 TOP 10"(제외), "인기 관계도", "⚡ 실시간 인기", "새로 나온 스킬"
- 주제별 섹션 다수 (`LIKE '%퇴사를 꿈꾸며%'`, `'%썸일까? 착각일까?%'` 등)
- → 새 섹션 추가 시 `union_mart_user_key_actions.sql` 의 CTE도 갱신 필요. 신규 섹션 누락 리스크.

### 이벤트 목록 관리
- 2025.10.13 오늘의 운세 탭 이벤트 추가 사례처럼 **이벤트가 계속 늘어남**
- 새 이벤트 추가 시 본 SQL + intermediate + staging_key_events_fb 3곳 업데이트 필요
- 신규 이벤트 배포 시 수집 누락 가능성 → 플레이북에 반영 필요

### `chatbot_seq = "0"` 제외
- 0은 invalid 값이라 필터링됨 — 클라이언트 이슈 추적 시에는 raw staging 필요

## dbt 이식 매핑

```
현재 경로        scripts/hellobot/mart/mart_v2_skill_funnel_fb.sql
dbt 경로        models/marts/hellobot/funnel/mart_v2_skill_funnel_fb.sql
materialized    incremental (partition_by=event_date)
note            'v2'는 내부 버전 구분. dbt에서는 모델명을 유지하거나 skill_funnel로 통일 고려
```
