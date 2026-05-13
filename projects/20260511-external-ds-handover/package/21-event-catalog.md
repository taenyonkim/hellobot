# 이벤트 카탈로그

> 현재 파이프라인이 수집·처리하는 **Firebase + 서버 이벤트** 전체 목록과 수집 규칙.

## SSOT 정책 (★ 운영 원칙)

- **본 `event-catalog.md` = 단일 진실 원천(SSOT)** — 활성 이벤트의 정의·파라미터·발생 상황은 본 문서가 결정한다
- **검증된 활성 이벤트 = BigQuery `hlb_staging.events_list` / `staging_key_events_*_events_list` 에 등록된 이벤트** ([§2-1](#2-1-이벤트-화이트리스트-테이블) 참조). 그 외는 발송되어도 카탈로그 등록 대상 아님
- **Notion 설계 DB** ([📓 이벤트](https://www.notion.so/ab9172f059b3474e836dcfdc0f6fd9b9)) 는 **historical 참고 자료** — 대다수 이벤트가 미활용·미검증 상태이며, **본 카탈로그와 어긋나면 카탈로그를 우선**한다
- **신규 기능 설계 시 활용 흐름**:
  1. 새 이벤트가 필요하다 판단 → 본 카탈로그(§유스케이스 색인) 에서 재사용 가능 이벤트 우선 검색
  2. 매칭 없으면 Notion 설계 DB 에서 historical 매칭 검색 (이름·발생 상황 유사한 이벤트)
  3. Notion 매칭 발견 → BQ 로 실 발송 검증 → events_list 등록 → 본 카탈로그에 활성으로 등록
  4. Notion 매칭도 없으면 신규 설계 ([recipes/event-design-guide.md](./recipes/event-design-guide.md))
- **본 문서가 비어 있는 부분(파라미터 스키마 등)은 BQ 직접 조회 + Notion 참고로 채워가며 보강한다**

---

## 유스케이스 색인

"내가 측정하려는 행동에 쓸만한 이벤트가 이미 있나?" 를 빠르게 확인하세요.

| 측정하려는 행동 | 시작할 이벤트 | 소스 | 상세 |
|---|---|---|---|
| 홈 화면 방문 / 탭 전환 | `view_home_main`, `view_tab_at_home`, `page_view` | Firebase | [§4-1 홈·네비게이션](#홈--네비게이션) |
| 홈 배너·섹션 터치 (유입 태깅) | `touch_featured_banner`, `touch_home_section_item` | Firebase | [§4-1 홈 배너·섹션](#홈-배너--섹션) |
| 카테고리 · 검색 · 추천 탐색 | `touch_category_item`, `touch_search_result`, `click_recommend_skill` | Firebase | [§4-1 카테고리/검색/추천](#카테고리) |
| 스킬 상세 보기 · 미리보기 | `open_skill_description`, `view_new_skill_description`, `view_new_preview` | Firebase | [§4-1 스킬 상세](#스킬-상세--미리보기-신규-스킬-온보딩) |
| 스킬 실제 진입 (비즈니스 기준) | `enter_skill` | **Server** | [§4-2 스킬 사용·결제](#스킬-사용--결제) |
| 스킬 완료·소비 | `consume_skill` | Server | [§4-2](#스킬-사용--결제) |
| 하트·현금 결제 (정합 기준) | `pay_for_contents`, `pay_for_package`, `pay_for_coaching_program`, `pay_for_collection`, `pay_for_chatbot_subscription` | **Server** | [§4-2](#스킬-사용--결제) |
| 스토어 인앱 결제 | `in_app_purchase` (자동), `purchase` (수동) | Firebase | [§4-1 인앱 결제](#인앱-결제) |
| 관계도 노출·사용 | `view_relationship_map` 등 | Firebase | [§4-1 관계도](#관계도-기존-events_listmd-에서만-확인-mart-소비처-미확인) |
| 오늘의 운세 · 광고 | `view_daily_fortune`, `start_ad_on_daily_fortune`, `finish_ad_on_daily_fortune` | Firebase | [§4-1 오늘의 운세](#오늘의-운세-탭-2025-10-13-추가) |

**이 표에 없다 = 신규 이벤트가 필요할 가능성 높음**. 판단 트리: [playbook §Step 2](./playbook.md#step-2--이벤트-설계).

---

## 1. 이벤트가 흘러오는 경로 (한눈에)

```
클라이언트 (앱/웹)
  ├─ Firebase Analytics SDK → analytics_164027297.events_* (일별)
  │                         → analytics_164027297.events_intraday_* (당일 실시간)
  └─ 서버 이벤트 로거        → analytics_164027297.server_events

                ↓ (테스터 제외 + events_list 필터 + 중복 제거 + user_id_processed 계산)

hlb_staging.staging_key_events_fb    (Firebase)
hlb_staging.staging_key_events_se    (서버)

                ↓ (intermediate 가공)

hlb_intermediate.*

                ↓ (mart 변환)

hlb_mart.*, hlb_mart_adhoc.*

                ↓ (UNION + 메타 조인)

hlb_mart_integrated.union_mart_user_key_actions  ← 대부분의 분석은 여기서
```

## 2. 수집 게이트키핑 (중요)

### 2-1. 이벤트 화이트리스트 테이블

Firebase + 서버 이벤트 모두 **아래 BigQuery 테이블에 등록된 이벤트만** `staging_key_events_*` 로 흘러옴.

#### 의도된 역할 (운영자 답변 기준, 2026-04-27 운영자 답변)

| 화이트리스트 테이블 | 역할 |
|---|---|
| `hlb_staging.events_list` | **1차 게이트** — 소스(`analytics_164027297.events_*`) → `staging_key_events_fb` 로 가져올 이벤트 |
| `hlb_staging.staging_key_events_fb_events_list` | **2차 게이트** — `staging_key_events_fb` → 다음 단계(intermediate/mart) 로 넘어갈 이벤트 |
| `hlb_staging.staging_key_events_se_events_list` | 서버 staging 단일 게이트 (서버는 1차/2차 분리 없음) |

**등록 방식**: 모두 **BigQuery 에 수동 INSERT** (운영자 직접 운영). PR / Airflow Variable / GSheet sync 아님.

#### 실제 SQL 사용 패턴 (코드 스캔, 2026-04-27)

위 의도와 구현이 부분적으로 다름 ([ISS-014](./issues.md)) — 카탈로그에는 양쪽 모두 기재:

| 테이블 | 사용 위치 | 사용 형태 |
|---|---|---|
| `events_list` | `staging_key_events_fb.sql` | `staging_key_events_fb_events_list` 와 **UNION** → OR 게이트 |
|  | `intermediate_v2_metrics_*_fb.sql` (lv1/lv2/lv3/메인) | 직접 필터 |
| `staging_key_events_fb_events_list` | `staging_key_events_fb.sql` | 위 OR 게이트 |
|  | `staging_marketing_utm_fb.sql` | 직접 필터 |
|  | `mart_adhoc/adhoc_mart_acquisition_with_utm*.sql` | 직접 필터 |
| `staging_key_events_se_events_list` | `staging_key_events_se.sql` | 단일 게이트 |

> ⚠️ `staging_key_events_fb` 가 1차·2차 게이트를 OR 로 합쳐 처리하므로, **둘 중 한 곳에만 등록해도** 통과함. 의도된 분리 효과는 **다음 단계 SQL** (`intermediate_v2_metrics_*` / `staging_marketing_utm_fb` / `adhoc_mart_acquisition_with_utm*`) 에서 발생.

#### Raw → 분석 가능 시점 (2026-04-27 운영자 답변)

| 데이터 위치 | 도달 시점 |
|---|---|
| Raw Firebase (`analytics_164027297.events_*`) | 배치 다음날 KST 10시경 |
| Raw 서버 (`analytics_164027297.server_events`) | **즉시 BQ 조회 가능** — DebugView 와 별개로 실시간 검증 가능 |
| 데이터 마트 (화이트리스트 통과한 이벤트) | 배치 다음날 KST 11시경 |

#### 누락 발견 패턴

- 자동 모니터링·알림 **없음**
- **사후 발견** — 첫 배치 이후 분석 시 데이터 미관측되면 화이트리스트 누락 의심 → 파이프라인 점검
- 신규 기능 출시 직후 첫 분석 사이클(D+1)에 발견 가능 → 출시 + 1일 차에 의도적 검증 권장

#### 신규 이벤트 등록 워크스루

→ [`recipes/add-new-event.md`](./recipes/add-new-event.md)

### 2-2. 테스터 제외

- 소스: `hellobot-f445c.server_rdb.user_test_group` (서버 RDS 스냅샷)
- Firebase · 서버 이벤트 양쪽에서 동일하게 `user_id` 매칭으로 제외

### 2-3. 환경 필터 (서버 이벤트 전용)

- 서버 이벤트는 `env IN ("production", "prod")` 로 수집 (HelloBot staging 컨벤션)
- dev/staging 이벤트는 배제됨

**실측 (2026-04-27, 최근 7일)**:

| env | 행수 | 비고 |
|---|---:|---|
| `production` | 4,456,674 | 정상 운영 데이터 |
| `development` | 2,853 | staging 단에서 제외 |

> ⚠️ `prod` 값은 최근 7일 데이터에 존재하지 않음 (historical 가능성). HelloBot staging SQL (`scripts/hellobot/staging/staging_key_events_se.sql`) 은 `("production", "prod")` 로 안전하게 필터하지만, 일부 ad-hoc 함수(`hellobot_ltv_func.py`, `hackle_dashboard_2023_func.py`)는 `env = 'production'` 단일 필터 — `prod` 값이 다시 나타날 경우 누락 위험. [ISS-013](./issues.md) 으로 추적.

### 2-4. 중복 제거

- Firebase: `ROW_NUMBER() OVER(PARTITION BY event_timestamp, event_name, user_id)` 로 중복 행 중 1건만 사용
- 서버: `(event_timestamp, user_id, event_name, platform)` 조합으로 동일하게 처리
- `events_*` + `events_intraday_*` 합치는 과정에서의 중복은 각각 먼저 dedupe 후 UNION

## 3. user_id_processed 규칙

Firebase 이벤트의 `user_id` 는 로그인 이후에만 존재하므로, HelloBot 분석 전용 표준 식별자 `user_id_processed` 를 계산:

| 플랫폼 | 시점 | 사용 ID |
|---|---|---|
| 모든 플랫폼 | 2019-04-01 이전 | `user_pseudo_id` (Firebase 디바이스 ID) |
| APP (IOS/ANDROID) | 2019-04-01 이후 | `user_id` (서버 발급) |
| WEB | 2022-12-01 이전 | `user_pseudo_id` |
| WEB | 2022-12-01 이후 | `user_id` |

> ⚠️ `staging_key_events_fb.sql` 주석의 WEB 전환 시점(2019-12-01)이 실제 SQL의 2022-12-01과 불일치 ([ISS-010](./issues.md)). 실제 동작은 **2022-12-01** 기준.

## 4. 이벤트 목록 (코드 스캔 기반)

> 현재 mart 레이어까지 문서화된 테이블들이 실제로 사용하는 이벤트만 추출. 화이트리스트 테이블 전수는 외부 과업.

### 4-1. Firebase 이벤트 (소스: `analytics_164027297.events_*`)

#### 홈 · 네비게이션
| 이벤트 | 트리거 | 주요 파라미터 (확인 가능 범위) | 소비 마트 |
|---|---|---|---|
| `view_home_main` | 홈 메인 화면 조회 | — | `mart_v2_skill_funnel_fb` |
| `view_tab_at_home` | 홈 탭 조회 | `tab_name` | `mart_home_action_fb`, `mart_v2_skill_funnel_fb` |
| `page_view` | 일반 페이지 뷰 | `page_location` | `mart_v2_skill_funnel_fb` |

#### 홈 배너 · 섹션
| 이벤트 | 트리거 | 주요 파라미터 | 소비 마트 |
|---|---|---|---|
| `touch_featured_banner` | 홈 메인 배너 터치 | `banner_title`, `menu_seq`, `chatbot_seq` | `mart_home_action_fb`, `mart_v2_skill_funnel_fb`, `union_mart_user_key_actions` (`funnel_from_home_banner`) |
| `touch_home_section_item` | 홈 섹션 아이템 터치 | `section_name`, `menu_seq`, `item_index` | `mart_home_action_fb`, `mart_v2_skill_funnel_fb`, `union_mart_user_key_actions` (`funnel_from_home_section`) |
| `touch_home_section_more_item` | 홈 섹션 더보기 터치 | `section_name` | 동일 |

#### 카테고리
| 이벤트 | 트리거 | 주요 파라미터 | 소비 마트 |
|---|---|---|---|
| `touch_category_item` | 카테고리 아이템 터치 | `category_seq`, `category_name` | `mart_v2_skill_funnel_fb` |
| `enter_sub_category_tab` | 서브 카테고리 탭 진입 | `sub_category_seq`, `sub_category_tab_index` | 동일 |
| `view_skills_in_category` | 카테고리 내 스킬 목록 조회 | `category_seq` | 동일 |
| `touch_skill_item_in_category` | 카테고리 내 스킬 터치 | `category_seq`, `menu_seq` | `mart_v2_skill_funnel_fb`, `union_mart_user_key_actions` (`funnel_from_home_category`) |

#### 검색
| 이벤트 | 트리거 | 주요 파라미터 | 소비 마트 |
|---|---|---|---|
| `view_search_main` | 검색 메인 조회 | — | `mart_v2_skill_funnel_fb` |
| `view_search_result` | 검색 결과 조회 | `referral`(검색어 추정) | 동일 |
| `view_search_no_result` | 검색 결과 없음 조회 | — | 동일 |
| `touch_search_result` | 검색 결과 터치 | `menu_seq` | `mart_v2_skill_funnel_fb`, `union_mart_user_key_actions` (`funnel_from_search_result`) |

#### 추천 · 관련
| 이벤트 | 트리거 | 주요 파라미터 | 소비 마트 |
|---|---|---|---|
| `view_recommend_skill` | 추천 스킬 노출 | `recommend_seq`, `recommend_name` | `mart_v2_skill_funnel_fb` |
| `click_recommend_skill` | 추천 스킬 클릭 | 동일 | 동일 |
| `touch_related_skill` | 관련 스킬 터치 | `related_skill_seq`, `related_skill_name` | 동일 |
| `click_start_button` | 시작 버튼 클릭 | `menu_seq` | 동일 |

#### 스킬 상세 · 미리보기 (신규 스킬 온보딩)
| 이벤트 | 트리거 | 주요 파라미터 | 소비 마트 |
|---|---|---|---|
| `open_skill_description` | 스킬 상세 열기 | `menu_seq` | `mart_v2_skill_funnel_fb` |
| `enter_skill` | 스킬 진입 (Firebase 버전) | `menu_seq` | `mart_v2_skill_funnel_fb` (서버 enter_skill 과 구분) |
| `view_new_skill_description` | 신규 포맷 스킬 설명 조회 | `menu_seq` | `mart_v2_skill_funnel_fb` |
| `view_new_birth_info` | 신규 생년월일 입력 화면 | — | 동일 |
| `view_new_question` | 신규 질문 화면 | — | 동일 |
| `view_new_preview` | 신규 미리보기 화면 | — | 동일 |
| `touch_new_preview_unlock` | 미리보기 잠금해제 터치 | — | 동일 |
| `touch_new_preview_cta` | 미리보기 CTA 터치 | — | 동일 |
| `view_new_login_bottomsheet` | 로그인 바텀시트 조회 | — | 동일 |

#### 인앱 결제
| 이벤트 | 트리거 | 주요 파라미터 | 소비 마트 |
|---|---|---|---|
| `in_app_purchase` | 스토어 결제 (Firebase 자동 수집) | `currency`, `value` (KRW는 1,000,000 배 특이), `product_id`, `transaction_id` | `mart_purchase_fb` |
| `purchase` | 서버측에서 FB로 보낸 결제 | 동일 + `product_name`, `menu_seq` | `mart_purchase_fb` |

#### 관계도 (기존 `events_list.md` 에서만 확인, mart 소비처 미확인)
- `view_relationship_map`, `view_relation_create_new`, `view_list_relationship_map_this_skill`, `view_list_relation_starting_member`, `touch_relation_share`, `touch_relationship_map_in_list`
- 추정 소비처: `mart_relation_fb` (미문서화)

#### 오늘의 운세 탭 (2025-10-13 추가)
| 이벤트 | 트리거 | 소비 마트 |
|---|---|---|
| `view_daily_fortune` | 오늘의 운세 탭 조회 | `mart_home_action_fb`, `mart_v2_skill_funnel_fb` |
| `view_daily_fortune_subject` | 오늘의 운세 주제 탭 조회 | 동일 |
| `touch_daily_fortune_subject` | 오늘의 운세 주제 탭 클릭 | 동일 |
| `start_ad_on_daily_fortune` | 광고 시작 | 동일 |
| `finish_ad_on_daily_fortune` | 광고 종료 | 동일 |

#### 기타 (events_list.md 에서만)
- `view_coin_screen` — 코인 화면 조회

### 4-2. 서버 이벤트 (소스: `analytics_164027297.server_events`, `env IN ('production','prod')`)

#### 스킬 사용 · 결제
| 이벤트 | 트리거 | 주요 파라미터 | 소비 마트 |
|---|---|---|---|
| `enter_skill` | 스킬 진입 (서버 기록) | `menu_seq`, `chatbot_seq`, `block_seq` | `mart_use_skill_se` |
| `consume_skill` | 스킬 소비(완료) | 동일 | 동일 |
| `pay_for_contents` | 콘텐츠 결제 | + `spent_heart_coin`, `spent_cash_amount`, `spent_cash_currency` | 동일 |
| `pay_for_package` | 패키지 결제 | + `package_seq`, `package_title` | 동일 |
| `pay_for_coaching_program` | 코칭 프로그램 결제 | 결제 파라미터 | 동일 |
| `pay_for_collection` | 콜렉션 결제 | + `collection_seq`, `collection_name` | 동일 |
| `pay_for_chatbot_subscription` | 챗봇 구독 결제 | 결제 파라미터 | 동일 |

#### 파생 이벤트 (SQL 변환에서 생성, 원본 로그 아님)
| 이벤트 | 생성 위치 | 정의 |
|---|---|---|
| `pay_under_750` | `mart_use_skill_se` | `pay_for_contents` 중 총 결제 금액 750원 미만 |
| `visit_on_day` | `union_mart_user_key_actions` | `mart_user_daily_info` 의 각 사용자/일 조합 — 실제 로그 없음, 방문 집계 파생 |

## 5. 파라미터 스키마 확인 범위

현재 코드 스캔으로 확인된 `event_params` 키 (Firebase 기준 — `(SELECT value.* FROM UNNEST(event_params) WHERE key = "...")` 패턴):

| 파라미터 | 사용 이벤트 | 타입 힌트 |
|---|---|---|
| `currency` | `in_app_purchase`, `purchase` | STRING |
| `value` | `in_app_purchase`, `purchase` | INT64 (KRW는 마이크로단위) |
| `menu_seq` | 다수 (상세/결제/검색 등) | STRING 또는 INT64 (`COALESCE` 처리) |
| `product_id` | `in_app_purchase`, `purchase` | STRING |
| `product_name` | `purchase` | STRING |
| `transaction_id` | `in_app_purchase`, `purchase` | STRING |

> 전체 이벤트의 전체 파라미터 스키마는 `analytics_164027297.events_*` (Firebase) / `analytics_164027297.server_events` (서버) 직접 조회 필요. 진행은 [external-tasks.md A-2](./external-tasks.md) 참조.

### ID/이름 페어 발송 규칙 (★)

이벤트가 엔티티 ID(`*_seq`)를 보내면 대응 이름(`*_name`)도 **반드시** 함께 발송. 디멘션 조인 회피 + rename 시점 historical accuracy 보존이 목적. 상세: [`recipes/event-design-guide.md §3-4`](./recipes/event-design-guide.md#3-4-id-와-이름의-페어-발송--강제-규칙). 현행 미준수 이벤트 추적: [ISS-015](./issues.md).

## 6. 서버 이벤트 스키마

### 6-1. `analytics_164027297.server_events` 원천 스키마 (BQ 실측, 2026-04-27)

서버 이벤트는 **Firebase 와 동일하게 `event_params` REPEATED RECORD 구조**로 BQ 에 저장됨. 컬럼으로 플래튼된 형태는 **staging/intermediate 변환 후** 의 모습.

- 파티셔닝: `event_timestamp` (TIMESTAMP, DAY 파티션) — `event_date` 컬럼 **없음** ([ISS-012](./issues.md))
- 클러스터링: 없음
- 행수: ~17.7억 / 데이터 크기: ~705 GB

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `event_timestamp` | TIMESTAMP | 이벤트 발생 시각 (UTC). 파티션 키 |
| `event_name` | STRING | 이벤트 이름 (예: `pay_for_contents`, `enter_skill`) |
| `event_params` | RECORD REPEATED | 이벤트별 파라미터 (key + value: string/int/float/bool 4종 중 1) |
| `user_id` | STRING | 사용자 식별자 (서버 발급) — 서버 이벤트는 NULL 시 수집 대상 아님 |
| `user_properties` | RECORD REPEATED | 사용자 속성 (key + value 4종) |
| `channel` | STRING | 채널 — 실측: `app`, `skillstore` |
| `platform` | STRING | 플랫폼 — 실측: `ios`, `android`, `web` |
| `app_version` | STRING | 앱 버전 |
| `env` | STRING | 환경 — 실측: `production`, `development` (`prod` 는 historical 가능성, [§2-3](#2-3-환경-필터-서버-이벤트-전용)) |
| `locale` | STRING | 사용자 로케일 (예: `ko_KR`) |

`event_params` / `user_properties` 의 value 추출 패턴:

```sql
(SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'menu_seq') AS menu_seq_str,
(SELECT value.int_value    FROM UNNEST(event_params) WHERE key = 'menu_seq') AS menu_seq_int
```

### 6-2. staging/intermediate 변환 후 컬럼 (`hlb_staging.staging_key_events_se`)

`scripts/hellobot/staging/staging_key_events_se.sql` 이 위의 `event_params` 를 펼쳐 다음과 같은 컬럼으로 변환 (mart 에서 보이는 형태):

- `chatbot_seq`, `menu_seq`, `block_seq`, `collection_seq`
- `chatbot_name`, `menu_name`, `block_name`, `collection_name`
- `package_seq`, `package_title`
- `spent_heart_coin`, `spent_bonus_heart_coin`, `spent_cash_amount`, `spent_cash_currency`
- `current_heart_price`, `heart_price`, `current_price`, `price`
- `unlock_price`, `current_unlock_price`, `current_procedure`
- `product_category`

> 위 컬럼은 **staging 결과** 이며 `server_events` 원천에는 존재하지 않음. 신규 이벤트 설계 시 새 파라미터를 추가하면 `staging_key_events_se.sql` 의 UNNEST·SELECT 절도 함께 수정해야 mart 까지 흘러옴.

## 7. 자주 받는 질문

### Q. 새 이벤트가 왜 `staging_key_events_fb` 에 안 보이나요?
A. `staging_key_events_fb_events_list` 또는 `events_list` 테이블에 이벤트명이 수동 INSERT 되지 않은 상태. 등록 절차는 [§2-1](#2-1-이벤트-화이트리스트-테이블) + [recipes/add-new-event.md](./recipes/add-new-event.md) 참조.

### Q. `enter_skill` 이벤트가 Firebase(`mart_v2_skill_funnel_fb`) 와 서버(`mart_use_skill_se`) 양쪽에 있는데 뭐가 달라요?
A. Firebase 버전은 클라이언트 기록 (화면 관점), 서버 버전은 서버 기록 (실제 비즈니스 로직 진입). **결제·매출 분석은 서버 버전** 을 사용해야 정확함.

### Q. `user_id` 가 비어있는 이벤트는 어떻게 처리되나요?
A. `user_id_processed` 계산 규칙에 따라 `user_pseudo_id` 로 대체. 단, 서버 이벤트는 `user_id` 가 필수이므로 NULL이면 수집 대상이 아님.

### Q. 테스터 내부 사용은 분석에서 빠지나요?
A. `server_rdb.user_test_group` 테이블에 등록된 `user_seq` 는 staging 단에서 전부 제외됨. 이 테이블의 관리 주체 확인 필요.

## 8. 외부 확인 필요 (TBD)

- [ ] `staging_key_events_fb_events_list`, `staging_key_events_se_events_list`, `events_list` 전수 조회 → 코드에서 미발견 이벤트가 있는지
- [ ] 이벤트 화이트리스트 업데이트 절차·담당자 ([ISS-011](./issues.md))
- [ ] 각 Firebase 이벤트의 `event_params` 전체 스키마 (파라미터명·타입·필수여부)
- [x] `server_events` 의 전체 컬럼 스키마 및 환경 구분 (prod 외 존재하는지) — 2026-04-27 BQ 직접 조회 완료, §6-1 + §2-3 반영
- [ ] `server_rdb.user_test_group` 관리 주체·업데이트 주기
- [ ] Airbridge / Braze 등 Firebase 외부 수집 경로의 이벤트 대응

## 9. dbt 이식 매핑

```yaml
# sources.yml
version: 2

sources:
  - name: firebase
    database: hellobot-f445c
    schema: analytics_164027297
    tables:
      - name: events_*
        description: Firebase GA4 완료 일별 이벤트 (UTC 파티션)
        freshness:
          warn_after: {count: 12, period: hour}
          error_after: {count: 24, period: hour}
        loaded_at_field: _PARTITIONTIME
      - name: events_intraday_*
        description: Firebase GA4 당일 실시간 이벤트
      - name: server_events
        description: HelloBot 서버 이벤트 로거 (env=prod 필터 필수)

  - name: rds_hellobot
    database: hellobot-f445c
    schema: server_rdb
    tables:
      - name: user_test_group
        description: 분석 제외 테스터 유저 목록

# events.yml (custom convention, dbt 표준 아님)
events:
  - name: touch_featured_banner
    source: firebase
    description: 홈 메인 배너 터치
    params:
      - name: banner_title
        type: STRING
      - name: menu_seq
        type: STRING
    consumers:
      - mart_home_action_fb
      - mart_v2_skill_funnel_fb
      - union_mart_user_key_actions  # funnel_from_home_banner 태깅
```

---

## 개정 이력 (Changelog)

> **운영 규칙**:
> - 본 카탈로그가 SSOT 이므로, **이벤트의 신규 추가·변경·복구·폐기 시 본 표에 1행 누적**합니다.
> - 코드 PR 과 동일 PR 안에서 갱신 (`common-data-airflow/CLAUDE.md` §데이터 카탈로그 동기화 참조).
> - "변경 내용" 은 무엇이 어떻게 바뀌었는지 1~2줄. 영향 범위(소비 마트·다운스트림)도 함께 기록.
> - "이슈" 컬럼은 관련 ISS-NNN (`issues.md`) 또는 프로젝트 식별자. 없으면 비워둠.

| 날짜 | 이슈 | 변경 내용 | 변경자 |
|---|---|---|---|
| 2026-04-22 | — | 카탈로그 초안 — 코드 스캔 기반, mart-catalog P0 범위 이벤트 40+종 추출 | /dev-data |
