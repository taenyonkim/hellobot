# F-203 — Firebase 신규 스킬 온보딩 이벤트 그룹 시맨틱 baseline

| 항목 | 값 |
|---|---|
| Phase | P2 |
| 중요도 | ★★ — 신규 스킬 사용자 온보딩 퍼널 분석 본진 |
| 상태 | 확정 |
| 작성일 | 2026-05-01 |
| 출처 | 카탈로그 [event-catalog.md §4-1 스킬 상세·미리보기](../../../../../common-data-airflow/docs/hellobot-data/catalog/event-catalog.md) + F-002 양쪽 등록 list |
| affects-ssot | no (카탈로그 적절) |
| affects-tier | **Tier 1·2** — 보존 (퍼널 시맨틱 명확) |

## 1. 그룹 — 9 Firebase 이벤트 (양쪽 등록)

본 그룹은 **events_list (1차) + staging_key_events_fb_events_list (2차) 양쪽 등록** + **`mart_v2_skill_funnel_fb` 직접 소비**.

### 진입·소개 단계
| 이벤트 | 트리거 | 7일 발화 |
|---|---|---|
| `open_skill_description` | 스킬 상세 화면 열기 | 88,596 |
| `view_new_skill_description` | 신규 포맷 스킬 설명 | 7,212 |
| `view_new_birth_info` | 신규 사용자 생년월일 입력 | 3,733 |
| `view_new_question` | 신규 사용자 질문 화면 | (확인 필요) |
| `view_new_login_bottomsheet` | 로그인 바텀시트 | 2,349 |

### 미리보기 단계
| 이벤트 | 트리거 | 7일 발화 |
|---|---|---|
| `view_new_preview` | 신규 미리보기 화면 | 3,888 |
| `touch_new_preview_cta` | 미리보기 CTA 터치 | (확인 필요) |
| `touch_new_preview_unlock` | 미리보기 잠금해제 터치 | (확인 필요) |

### 하트 충전
| 이벤트 | 트리거 | 7일 발화 |
|---|---|---|
| `view_coin_screen` | 하트 충전 화면 | 3,595 |

→ **신규 스킬 온보딩 퍼널의 9 단계 이벤트** — 사용자가 스킬을 발견·소개·미리보기·결제까지 가는 흐름.

## 2. 발화 시점·트리거

| 카테고리 | 트리거 |
|---|---|
| `view_*` | 화면 노출 직후 (impression) |
| `touch_*` | 사용자 클릭 (intent) |
| `open_*` | 화면 진입 (해당 화면 자체 노출) |

→ **퍼널 분석 패턴**: `view_*` (노출) → `touch_*` (클릭) → `open_*`/`enter_*` (진입) → `pay_for_*` (결제)

## 3. 파라미터 (공통)

| 파라미터 | 사용 이벤트 | 타입 | 의미 |
|---|---|---|---|
| `menu_seq` | `open_skill_description`, `view_new_skill_description` | STRING/INT | 스킬 ID |
| `menu_name` | (페어 규칙) | STRING | (일부 미준수 — ISS-015 case A/B) |
| `chatbot_seq` | 일부 | STRING/INT | 챗봇 ID |

→ `view_new_*`, `touch_new_*` 다수가 **파라미터 부재** (단순 화면 노출 카운트). 카탈로그 §4-1 표 의 "주요 파라미터" 컬럼이 "—" 표기.

## 4. 비즈 룰 (보존 필수)

### 4-1. ID/이름 페어 규칙 ([ISS-015](../../../../../common-data-airflow/docs/hellobot-data/catalog/issues.md))
- `menu_seq` 발송 이벤트는 `menu_name` 도 함께 발송 권장
- 본 그룹 일부 이벤트가 페어 미준수 (case B — 설계 준수, 구현 누락)
- → dbt 마이그 시 mart 단에서 `staging_fixed_menu_copy` 와 조인 시 NULL fallback 처리

### 4-2. 화이트리스트 양쪽 등록 = 활성
- F-002 §1 양쪽 등록 fb 10건에 본 9건 모두 포함 (+ enter_skill)
- staging 정상 통과 → mart_v2_skill_funnel_fb 도달

## 5. 다운스트림

`mart_v2_skill_funnel_fb` (Firebase 스킬 퍼널) → 그 외 report 다수 (F-001 raw 참조)

본 그룹은 매출 직결은 아님 — **스킬 노출·진입 퍼널 분석** 용도. 결제 전환율 계산 시 분모로 사용.

## 6. dbt 마이그 가이드

### 6-1. Tier 분류: **Tier 1·2 (보존)** — 퍼널 시맨틱 단순

| 평가 축 | 결과 |
|---|---|
| 시맨틱 명확도 | 명확 (화면 노출·터치 1:1) |
| 의존 단순도 | 단순 (Firebase 단일 소스) |
| 외부 인터페이스 | 간접 (mart_v2_skill_funnel_fb → report) |

### 6-2. 보존 필수
- 9개 이벤트 이름 (변경 시 클라이언트 SDK + 화이트리스트 + mart 모두 동시 수정)
- 화이트리스트 양쪽 등록 유지

### 6-3. 개선 후보 (MP-2)
- 페어 규칙 미준수 정리 (ISS-015 통합) — 클라이언트 발송 코드 수정 (dbt 외 영역)
- `view_new_*` vs `view_*` naming 일관성 (예: `view_new_birth_info` vs `view_skill_description`) — 부담 高 (다운스트림 동시 수정)

### 6-4. 위험 요소
- **`view_new_question` 발화량 미확인** (F-002 §1 의 1차만 등록 표 에서도 누락) — 7일 raw 데이터에서 추가 검증 필요
- 일부 이벤트가 dead whitelist 의심 (양쪽 등록되어 있어도 실제 발화량 작음)

## 7. 후속 액션

- [x] 본 카드 작성 (2026-05-01)
- [ ] (P5) `view_new_question` 7일 발화량 확인 (활성 vs dead 분류)
- [ ] (P7) Tier 1·2 — 후속 dbt 프로젝트
