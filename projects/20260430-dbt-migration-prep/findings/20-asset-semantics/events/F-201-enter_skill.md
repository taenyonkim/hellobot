# F-201 — `enter_skill` 이벤트 시맨틱 baseline (★ 매출 직결)

| 항목 | 값 |
|---|---|
| Phase | P2 |
| 중요도 | ★★★ — 양쪽(Firebase + Server) 발화, 매출 분석 본진 |
| 상태 | 확정 |
| 작성일 | 2026-05-01 |
| 출처 | 카탈로그 [event-catalog.md §4-1·§4-2·§7](../../../../../common-data-airflow/docs/hellobot-data/catalog/event-catalog.md) + F-002 §4·§5 + F-101/F-106 |
| affects-ssot | no (카탈로그 적절히 명시) |
| affects-tier | **Tier 2 (보존하며 재구현) — 양쪽 의미 분리 보존 필수** |

## 1. 핵심 사실

`enter_skill` 은 **Firebase 와 Server 양쪽에서 발화하는 유일한 이벤트** (F-002 §1 — 1차 events_list + 2차 fb_2nd + 2차 se_2nd 모두 등록된 1건).

| 소스 | 7일 발화량 | 의미 | 소비 마트 |
|---|---|---|---|
| **Firebase** | 158,251 | 클라이언트 화면 진입 (UI 관점) | `mart_v2_skill_funnel_fb` (퍼널 분석) |
| **Server** | 167,440 | 서버 비즈니스 로직 진입 (실제 진입) | **`mart_use_skill_se` (매출 정합 기준)** |

→ **결제·매출 분석은 반드시 Server 버전 사용** (카탈로그 §7 Q&A 명시). Firebase 버전은 사용자 화면 행동 추적용.

## 2. 발화 시점·트리거

### Firebase (UI 관점)
- 사용자가 스킬 카드 클릭 또는 자동 진입한 시점에 클라이언트 SDK 가 발화
- 화면 전환 직전 — 실제 비즈니스 로직 실행 여부와 무관

### Server (비즈니스 관점)
- 서버에서 스킬 진입 처리 완료 시점에 발화
- 권한 검증·하트 차감 등 실제 진입 로직 수행 후

→ **양쪽 카운트 차이 = 실패·취소·재시도 등의 갭** (Firebase 158K vs Server 167K, 어제 1일 기준 카운트 차이는 사용자 동작이 다른 timezone 으로 분류된 영향 가능).

## 3. 파라미터 (양쪽 공통)

| 파라미터 | 타입 | 필수 | 의미 |
|---|---|---|---|
| `menu_seq` | STRING/INT 혼재 (COALESCE) | NULL 가능 (collection_seq 만 있을 때) | 메뉴(스킬) ID — `staging_fixed_menu_copy` 와 조인 |
| `menu_name` | STRING | NULL 가능 | 메뉴 이름 (페어 규칙 — ID 동시 발송) |
| `chatbot_seq` | STRING/INT | | 챗봇 ID |
| `chatbot_name` | STRING | | 챗봇 이름 |
| `block_seq` | STRING/INT | NULL 가능 | 블록 ID (block 진입 시) |

### ID/이름 페어 규칙
[event-catalog §5 ID/이름 페어 규칙](../../../../../common-data-airflow/docs/hellobot-data/catalog/event-catalog.md#id이름-페어-발송-규칙-) 준수 — `menu_seq` + `menu_name`, `chatbot_seq` + `chatbot_name` 동시 발송. 페어 미준수 시 historical accuracy 손실.

→ `enter_skill` 은 ID/이름 페어 규칙 준수 (양쪽 발화 모두) — ISS-015 미준수 이벤트 list 에 없음.

## 4. 비즈 룰 (보존 필수)

### 4-1. 양쪽 의미 분리 (★)
- 코드·분석에서 "어느 쪽 enter_skill" 인지 명시 필요
- mart 단에서 자동 분리: Firebase → `mart_v2_skill_funnel_fb`, Server → `mart_use_skill_se`
- → dbt 마이그 시 **이 분리 보존 필수**. 같은 이름이지만 의미가 다름.

### 4-2. Server 버전이 매출 표준
- `mart_use_skill_se.event_name = 'enter_skill'` 행은 결제 직전·진입 후 모든 케이스 포함
- `revenue_krw` 분석은 `pay_for_*` 와 enter_skill 차이로 결제 전환율 계산
- KPI 알림 (`hlb_fs_new_skill_pay_amounts`) 가 본 이벤트 활용

### 4-3. 파라미터 페어 (`menu_seq` + `menu_name`)
- 메뉴 rename 시 historical 정확성 보존 (ID 만 보내면 과거 분석 시 현재 이름으로 해석)
- → dbt 마이그 시 mart 단에서 페어 보존 (다단 COALESCE 룰, F-101 §4-3 동일)

## 5. 다운스트림

- **Firebase enter_skill** → `mart_v2_skill_funnel_fb` (스킬 퍼널 분석)
- **Server enter_skill** → `mart_use_skill_se` (F-101 — 매출 직결) → `union_mart_user_key_actions` (F-106) → KPI 알림 + Looker

## 6. dbt 마이그 가이드

### 6-1. Tier 분류: **Tier 2 (보존하며 재구현)**

본 이벤트는 화이트리스트 양쪽 등록되어 있어 변경 시 **양쪽 staging + 양쪽 mart + KPI 알림 모두 영향**. 보존 필수.

### 6-2. 보존 필수
- 이벤트 이름 `enter_skill` (양쪽 동일)
- Firebase + Server 양쪽 발화 분리
- 파라미터: `menu_seq`/`menu_name`, `chatbot_seq`/`chatbot_name`, `block_seq` (페어 규칙 준수)
- 화이트리스트 3개 모두 등록 유지 (events_list, fb_2nd, se_2nd)

### 6-3. 개선 후보 (MP-2)
| # | 개선안 | 가치 vs 부담 |
|---|---|---|
| 1 | dbt event spec 문서화 (이름 충돌 해결을 위한 alias `enter_skill_fb` / `enter_skill_se` mart 단에서) | 가치 中 / 부담 中 (다운스트림 grep 후 영향 평가) |
| 2 | `event_params.menu_seq` STRING/INT 통일 (서버 측에서 STRING 으로) | 가치 中 / 부담 中 (서버팀 협의) |

### 6-4. 위험 요소
- **양쪽 동일 이름**: 분석가가 Firebase 와 Server 헷갈림 — 카탈로그 §7 Q&A 가 핵심
- **페어 규칙 미준수**: 본 이벤트는 준수하지만 다른 이벤트는 미준수 (ISS-015)

## 7. 후속 액션

- [x] 본 카드 작성 (2026-05-01)
- [ ] (P5 외부 확인) Firebase + Server 양쪽 발화량 차이의 원인 (158K vs 167K, 어제) — historical 추적 가치
