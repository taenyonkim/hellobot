# 마트 카탈로그 (인덱스)

> 본 파일은 **인덱스**입니다. 테이블별 상세는 [tables/](./tables/) 하위 md 파일 참조.
> 포맷 규약: [readme.md](./readme.md)
> 우선 범위: [scope-union-user-key-actions.md](./scope-union-user-key-actions.md) — `union_mart_user_key_actions` 계보 집중

## 작성 상태 (2026-04-22)

| 레이어 | 대상 수 | 카탈로그화 | 비고 |
|---|---:|---:|---|
| staging | TBD | 0 | 이벤트 카탈로그에서 처리 예정 |
| intermediate | TBD | 0 | 요약 수준으로 추후 작성 |
| mart | 22 | 7 | **P0 완료** |
| mart_integrated | 5 | 1 | P0 타겟 완료 |
| mart_adhoc | 7 | 1 | RFM 완료 |
| pre_report | 5 | 0 | |
| report | 48 | 0 | |

## hlb_mart_integrated

| 테이블 | 그레인 | 용도 한줄 | 상세 |
|---|---|---|---|
| `union_mart_user_key_actions` | event | **사용자 분석의 본진** — 방문·스킬·결제 UNION + 메타/퍼널/RFM/누적매출 | [📄](./tables/mart_integrated/union_mart_user_key_actions.md) |
| `union_mart_use_skill_and_user_daily` | — | 스킬 사용 ↔ 사용자 일별 조인 | 미작성 |
| `union_mart_use_skill_from_home_banner` | — | 홈 배너 유입 스킬 사용 | 미작성 |
| `union_mart_use_skill_from_exhibition_page` | — | 기획전 유입 | 미작성 |
| `union_mart_use_skill_from_search_result` | — | 검색 결과 유입 | 미작성 |

## hlb_mart

### P0 (union_mart_user_key_actions 직접 소스)

| 테이블 | 그레인 | 용도 한줄 | 상세 |
|---|---|---|---|
| `mart_user_daily_info` | user × event_date | 일별 사용자 마스터 (DAU 기반) | [📄](./tables/mart/mart_user_daily_info.md) |
| `mart_use_skill_se` | event | 서버 스킬 사용·결제 이벤트 | [📄](./tables/mart/mart_use_skill_se.md) |
| `mart_purchase_fb` | event (transaction) | Firebase 인앱 스토어 결제 | [📄](./tables/mart/mart_purchase_fb.md) |
| `mart_fixed_menu_server` | menu | 스킬(메뉴) 메타 마스터 — 디멘션 | [📄](./tables/mart/mart_fixed_menu_server.md) |
| `mart_skill_open_date_se` | menu | 스킬 로그 기준 첫 등장일 | [📄](./tables/mart/mart_skill_open_date_se.md) |
| `mart_home_action_fb` | event | 홈 배너/섹션/탭 액션 (+ 오늘의 운세) | [📄](./tables/mart/mart_home_action_fb.md) |
| `mart_v2_skill_funnel_fb` | event | 스킬 퍼널 전체 (홈/카테고리/검색/추천/상세) | [📄](./tables/mart/mart_v2_skill_funnel_fb.md) |

### P1 (추후 우선순위 마킹 후 확장)

| 테이블 | 용도 | 상세 |
|---|---|---|
| `mart_first_open_fb` | 최초 오픈 | 미작성 |
| `mart_session_start_fb` | 세션 시작 | 미작성 |
| `mart_sign_up_fb` | 가입 | 미작성 |
| `mart_login_success_fb` | 로그인 성공 | 미작성 |
| `mart_leave_fb` | 이탈 | 미작성 |
| `mart_marketing_utm_first_fb` | UTM 최초 접촉 | 미작성 |
| `mart_skill_funnel_fb` | 스킬 퍼널 (구 버전) | 미작성 |
| `mart_exhibition_fb` | 기획전 | 미작성 |
| `mart_ai_chatbot_fb` | AI 챗봇 | 미작성 |
| `mart_relation_fb` | 관계도 | 미작성 |
| `mart_randombox_metrics_fb` | 랜덤박스 | 미작성 |
| `mart_v2_metrics_lv1_fb` / `lv2` | V2 지표 | 미작성 |
| `mart_fixed_menu_evaluation_server` | 스킬 평가 | 미작성 |
| `mart_user_server` | 서버 사용자 풀 | 미작성 |

## hlb_mart_adhoc

| 테이블 | 그레인 | 용도 한줄 | 상세 |
|---|---|---|---|
| `adhoc_mart_user_rfm_info_daily` | user | RFM 스코어 (결제 · 참여 분리, 12세그먼트) | [📄](./tables/mart_adhoc/adhoc_mart_user_rfm_info_daily.md) |
| 나머지 6건 | — | — | 미작성 |

## hlb_pre_report

*(작성 예정)*

## hlb_report

*(작성 예정 — 카테고리로 묶음)*

---

## 범례

- 📄 — 상세 문서 작성 완료
- 🔜 — 진행 중 / 다음 차례
- 미작성 — P1~ 우선순위 마킹 이후 범위 확정
