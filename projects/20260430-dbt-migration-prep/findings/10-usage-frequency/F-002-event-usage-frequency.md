# F-002 — 이벤트 사용 빈도 + 화이트리스트 정합성 실측

| 항목 | 값 |
|---|---|
| Phase | P1 |
| 중요도 | ★★★ (이벤트 마이그 우선순위 + ISS-014 실측 검증) |
| 상태 | 확정 (BQ 직접 검증, 7일 + 어제 1일) |
| 작성일 | 2026-04-30 |
| 출처 | BQ 직접 조회 4건 — 누적 스캔 ~370 MB (`events_*` 7일 208 MB / `server_events` 7일 107 MB / Firebase 어제 38 MB / Server 어제 14 MB) — 비용 ~$0.002 |
| affects-ssot | yes — ISS-014 실측 검증 / dead whitelist 50건 / 미등록 고볼륨 이벤트 / 화이트리스트 운영 패턴 (v2 인계) |
| affects-tier | 이벤트 마이그 우선순위 + 정리 대상 (dead whitelist 정리, MP-3) |

## 발견 / 사실

### 1. 화이트리스트 3중 구조의 실측 동작

| 리스트 | 사이즈 | 역할 | 실제 효과 |
|---|---|---|---|
| `hlb_staging.events_list` | 68 | "1차 게이트" (운영자 의도) | **57건이 1차에만 등록 → staging 못 도달** |
| `hlb_staging.staging_key_events_fb_events_list` | 44 | Firebase 2차 게이트 | **이게 실질적 Firebase 게이트** |
| `hlb_staging.staging_key_events_se_events_list` | 7 | Server 2차 게이트 | **이게 실질적 Server 게이트** |

#### 교집합 분석

| 관계 | 건수 | 의미 |
|---|---|---|
| `events_list ∩ fb_2nd` | 10 | 양쪽 등록 (정상 통과) |
| `events_list ∩ se_2nd` | 2 | 양쪽 등록 |
| `fb_2nd \ events_list` | **34** | 1차 미등록인데 staging 통과 (의도/구현 차이) |
| `se_2nd \ events_list` | **5** | 동일 |
| `events_list \ (fb_2nd ∪ se_2nd)` | **57** | 1차에만 — staging 도달 못함 |
| 3개 모두 등록 | 1 | (`enter_skill` 만 추정) |

→ **카탈로그 ISS-014 의 실측 검증**: 운영자 의도(1차+2차 OR union) 와 실제(2차 only effective) 의 갭이 명확.

→ **1차 게이트(events_list)는 실질적으로 비활성** — 1차에만 등록된 57건은 staging 에 못 들어감 (raw 발화량 있어도). 운영자가 "분석에 쓰자" 의도해서 등록했지만 fb_2nd / se_2nd 에 추가 등록 안하면 효과 없음.

### 2. 1차에만 등록 + raw 발화 있는 이벤트 (의도 vs 실제 갭의 직접 증거)

다음 이벤트들은 **1차 게이트(events_list) 에 등록되어 있고 실제 발화도 있는데 staging 에 못 들어감** (2차 미등록):

| 이벤트 | 7일 raw 발화 (Firebase) | 갭 |
|---|---|---|
| `view_tab_at_home` | 205,634 | **★ 분석 핵심 이벤트인데 staging 도달 X** |
| `view_home_main` | 168,097 | ★ |
| `view_chatroom` | 150,676 | |
| `page_view` | 329,207 | (auto GA4? — 의도된 미등록 가능) |
| `view_skills_in_category` | 36,635 | ★ |
| `touch_home_section_item` | 39,328 | ★ |
| `enter_sub_category_tab` | 12,767 | |
| `view_chatbot_main` | 18,362 | |
| `view_search_main` | 7,224 | |
| `touch_search_result` | 6,313 | |
| `view_search_result` | 5,649 | |
| ... 더 많음 | | |

→ **분석에 쓰일 의도가 있던 이벤트 다수가 staging 에 못 도달**. 운영자(taenyon) 가 1차 게이트에만 추가했지만 2차 게이트에 추가 누락 → 마트로 안 흐름.

→ 이 시그널은 **카탈로그 issues.md ISS-014** 와 일치하며, **실제 이벤트가 누락되고 있음** 의 증거. v2 인계 후보.

### 3. Dead whitelist 50건 (정리 후보, MP-3)

화이트리스트에 등록되어 있지만 7일 raw 발화 0건. 정리 후보 카테고리:

| 카테고리 | 건수 | 예시 |
|---|---|---|
| 챗봇 구독 (subscription) | 8 | `complete_chatbot_subscription`, `view_chatbot_subscription`, `pay_for_chatbot_subscription` |
| 관계 (relation) | 7 | `created_relation_new`, `touch_relation_share`, `view_relation_create_new` |
| 일일 운세 (daily_fortune) | 4 | `view_daily_fortune`, `start_ad_on_daily_fortune` |
| 컬렉션 / 랜덤박스 | 6 | `touch_collection_random_box`, `view_collection_ranking` |
| 스킬 리워드 (skill_reward) | 4 | `touch_skill_reward_popup`, `view_skill_reward_result` |
| 결제 옵션 | 3 | `pay_for_collection`, `pay_for_package`, `pay_for_coaching_program` |
| 미션 / 코칭 | 3 | `touch_missions_list`, `view_missions_detail`, `open_coaching_program_description` |
| 기타 | 15 | `click_recommend_skill`, `touch_chatbot_recommend_question` 등 |

→ **이 50건은 화이트리스트에서 정리 후보** (운영자 검토 필요). 일부는 **기능 자체가 deprecated** (chatbot_subscription, relation, collection 등 카테고리 전체).

→ MP-3 정리 대상에 합류.

→ 카탈로그 SSOT 갱신 가치: `event-catalog.md` 의 deprecated 이벤트 표기 (현재 이벤트 카탈로그는 활성 가정).

### 4. Firebase Top 이벤트 (7일) — 마이그 우선순위

200개 이벤트 중 Top 25:

| 순위 | event_name | 7d count | 1st | fb_2nd | 비고 |
|---|---|---|---|---|---|
| 1 | `show_item_in_home_section` | 1,601,985 | - | - | **미등록 — 분석 누락 의심** |
| 2 | `screen_view` | 1,380,471 | - | Y | GA4 자동 |
| 3 | `send_msg_by_user` | 926,919 | - | - | **미등록** (서버에서 처리?) |
| 4 | `user_engagement` | 887,210 | - | Y | GA4 자동 |
| 5 | `initial_tab` | 594,705 | - | - | **미등록** |
| 6 | `start_block` | 527,093 | - | - | **미등록** |
| 7 | `show_home_section` | 512,732 | - | - | **미등록** |
| 8 | `start_chatroom` | 458,713 | - | - | **미등록** |
| 9 | `page_view` | 329,207 | Y | - | 1차만 (효과 없음) |
| 10 | `scroll` | 286,915 | - | - | GA4 자동 (의도된 미등록) |
| 11 | `enter_reward_ad_on_block` | 226,608 | - | - | **미등록** |
| 12 | `show_home_section_complete` | 217,464 | - | - | **미등록** |
| 13 | `view_tab_at_home` | 205,634 | Y | - | 1차만 |
| 14 | `view_home_main` | 168,097 | Y | - | 1차만 |
| 15 | `enter_skill` | 158,251 | Y | Y | ★ **핵심 마이그 자산** (양쪽 등록) |
| 16 | `view_chatroom` | 150,676 | Y | - | 1차만 |
| 17 | `session_start` | 137,037 | - | Y | GA4 자동 |
| 18 | `view_chatlist_main` | 105,020 | - | - | **미등록** |
| 19 | `enter_tab_at_home` | 100,194 | - | - | **미등록** |
| 20 | `open_skill_description` | 88,596 | Y | Y | ★ |
| 21 | `consume_skill` | 88,522 | - | Y | ★ (서버 발송 추정) |
| 22 | `show_chatbot_at_friends` | 87,254 | - | - | **미등록** |
| 23 | `start_persistant_menu` | 63,712 | - | - | **미등록** |
| 24 | `ad_reward` | 62,248 | - | - | **미등록** |
| 25 | `click_start_button` | 56,929 | Y | - | 1차만 |

→ **고볼륨 이벤트 다수 미등록 — 사용자 확인 필요**:
   - `show_item_in_home_section` (1.6M) — 홈 섹션 노출 이벤트, 분석 가치 있어 보임
   - `send_msg_by_user` (927K) — 사용자 메시지 발송, 챗봇 핵심 활동
   - `start_block` (527K) — 블록 시작
   - `enter_reward_ad_on_block` (227K) — 광고 진입

   → 의도된 미등록 (예: GA4 자동 또는 시스템 이벤트) 인지 vs 등록 누락인지 확인 필요.

→ **Tier 1·2 이벤트 자산 (양쪽 등록)**: `enter_skill`, `open_skill_description`, `consume_skill`, `enter_skill` (서버), `view_skill_feedback`, `pay_for_contents` (서버) 등

### 5. Server 이벤트 7일 — 7건 전체

| 순위 | event_name | 7d count | 1st | se_2nd | 비고 |
|---|---|---|---|---|---|
| 1 | `use_attribute` | 1,577,315 | - | - | **미등록 — 운영성, 의도된** ([ISS-015 케이스 C](../../../../common-data-airflow/docs/hellobot-data/catalog/issues.md)) |
| 2 | `update_attribute` | 1,410,455 | - | - | 동일 |
| 3 | `receive_user_message` | 909,795 | - | - | 동일 |
| 4 | `enter_skill` | 167,440 | Y | Y | ★ |
| 5 | `consume_skill` | 99,881 | - | Y | ★ |
| 6 | `skill_feedback_complete` | 24,501 | - | - | **미등록 — 분석 가치 있어 보임** |
| 7 | `pay_for_contents` | 16,020 | - | Y | ★ 매출 직결 |

→ Server 이벤트 종류 자체가 매우 적음 (7건). 모두 dbt 마이그 시 보존 필수 (특히 `pay_for_contents`).

### 6. Staging 살아남는 비율 (어제 1일)

| 소스 | raw | staging | 살아남는 비율 |
|---|---|---|---|
| Firebase | 1,415,531 | 519,399 | **36.7%** |
| Server | 496,213 | 39,311 | **7.9%** |

**Firebase 36.7%** — 화이트리스트가 정상 작동. 자동 GA4 이벤트 다수 (screen_view, user_engagement, scroll 등) 거름.

**Server 7.9%** — `use_attribute`/`update_attribute`/`receive_user_message` 가 92% 차지하는데 모두 미등록 (의도된). 분석 대상 7%만 staging.

#### 화이트리스트 통과 이벤트의 raw → staging 정합성

상위 20건 모두 **96.9%~100% 통과율** — 테스터 제외 등 정제 외 거의 1:1. 정상 동작.

| event | 통과율 |
|---|---|
| `screen_view` | 99.6% |
| `enter_skill` | 99.9% |
| `view_home_main` | 99.6% |
| `pay_for_contents` (서버) | (별도 확인 필요) |

→ 100% 미만의 차이는 **테스터 제외** + **null user 등 정제 룰** 의 결과. 의심스러운 drop 없음.

## 근거

### BQ 조회 4건

| Q | 대상 | 스캔 | 비용 |
|---|---|---|---|
| Q1 | 화이트리스트 3개 row count | < 1 MB | $0 |
| Q2 | `events_*` 7일 (2026-04-23~29) event_name COUNT | **208 MB** | ~$0.001 |
| Q3 | `server_events` 7일 event_name COUNT | **107 MB** | ~$0.0005 |
| Q4a | Firebase 어제 raw vs staging | 38 MB | $0 |
| Q4b | Server 어제 raw vs staging | 14 MB | $0 |

**세션 누적 스캔**: ~370 MB (워크스페이스 한도 100 GB 의 0.4%)

### 데이터 산출물 (cross-session 재사용)

```
findings/10-usage-frequency/
├── whitelist_contents.csv               (127 rows: 3 lists × 평균 42)
├── fb_7d_events.csv                     (200 rows: 이벤트별 7일 발화량)
├── se_7d_events.csv                     (7 rows: 서버 이벤트 7일)
├── fb_yesterday_raw_vs_stg.csv          (300 rows: 어제 raw vs staging)
└── se_yesterday_raw_vs_stg.csv          (7 rows)
```

## dbt 마이그 영향

### 이벤트 자산의 마이그 분류

| 분류 | 건수 | 처리 |
|---|---|---|
| **양쪽 등록 + 활성** (Firebase: 10건 + Server: 2건) | 12 | **Tier 1·2 핵심 자산** — `enter_skill`, `consume_skill`, `pay_for_contents` 등 |
| **2차만 등록 + 활성** (Firebase fb_2nd: 34건 + Server se_2nd: 5건) | 39 | **Tier 1·2** — staging 정상 통과 |
| **1차만 등록 (효과 없음)** | 57 | **Tier 4 정리 후보** — events_list 에서 제거 또는 fb_2nd 추가 결정 |
| **미등록 + 고볼륨** (확인 필요) | ~10건 | 사용자 확인 — 의도된 미등록 vs 누락 |
| **Dead whitelist** (등록 but 0 발화) | 50 | **MP-3 정리 대상** |

### MP-1 / MP-3 적용

- **MP-3 정리 대상 (이벤트 영역)**:
  - Dead whitelist 50건 (화이트리스트 정리)
  - 1차만 등록된 이벤트 57건 (events_list 정리 또는 2차 추가)
- **MP-1 권장**: 활성 이벤트(46건) 의 이름·파라미터 보존이 권장 — Looker·KPI 알림 의존. 단 **시맨틱 명확화** 가 필요한 이벤트들이 있어 P2 baseline 카드에서 case-by-case 결정.

### dbt source 등록 (Tier 4 잔존)

dbt 가 직접 owning 못하는 영역:
- `analytics_164027297.events_*` (Firebase) → dbt source 등록만
- `analytics_164027297.server_events` (Server) → dbt source 등록만
- `hlb_staging.events_list`, `staging_key_events_*_events_list` → dbt seed 또는 dbt source (운영자 수동 INSERT 가 활성인 한)

→ dbt staging layer 가 1차 변환 (raw → staging) 을 담당. 화이트리스트 게이트는 dbt 안에서 ref + filter 로 구현 가능.

## 후속 액션

- [ ] **★ 1차만 등록 57건 처리 결정 (사용자 확인)** — Phase: P5 / 출처: F-002 §1·§2
  - Option A: events_list 에서 정리 (의미 없으니 제거)
  - Option B: fb_2nd / se_2nd 에 추가 등록 (분석 의도대로 staging 도달)
  - 결정 후 v2 §신규 과업 (또는 본 프로젝트 직접 정리) 등록
- [ ] **★ Dead whitelist 50건 정리 결정** — Phase: P7 / 출처: F-002 §3
  - 카테고리별 검토: chatbot_subscription, relation, collection 카테고리 전체 deprecated 여부
- [ ] **★ 미등록 고볼륨 이벤트 ~10건 분류** — Phase: P5 / 출처: F-002 §4
  - 의도된 미등록 (시스템·자동 GA4) vs 누락 (분석 가치 있는데 빠짐) 구분
  - 누락이면 fb_2nd 등록 후속
- [ ] **★ ISS-014 실측 검증 결과 카탈로그 SSOT 반영 (v2 인계)** — Phase: P5 / 출처: F-002 §1·§2
  - 카탈로그 issues.md ISS-014 에 본 finding 의 정량적 검증 추가 (1차에만 57건, 2차만 39건, raw 발화 있는데 staging 도달 못함 시그널)
  - 운영자 의도와 실제 동작 차이 명확화
- [ ] **★ 화이트리스트 3중 구조 명문화 (v2 인계)** — Phase: P5
  - 카탈로그 architecture.md §5 또는 event-catalog.md §2 에 "1차 events_list 는 의도 표시용 (실효 없음), 2차 fb/se_events_list 가 실제 게이트" 명시
  - 또는 1차 게이트를 살리는 SQL 변경 제안 (architecture 변경)

## 참조

- ISS-014 (의도/구현 차이): [catalog/issues.md](../../../../common-data-airflow/docs/hellobot-data/catalog/issues.md)
- F-001 (마트 다운스트림): [F-001-mart-downstream-map.md](./F-001-mart-downstream-map.md)
- F-003 (외부 인터페이스): [F-003-external-interfaces.md](./F-003-external-interfaces.md)
- F-004 (정리 대상 마트): [F-004-orphan-and-dead-marts.md](./F-004-orphan-and-dead-marts.md)
