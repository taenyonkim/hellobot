# F-204 — 운영성 Server 이벤트 시맨틱 baseline (대량 미등록)

| 항목 | 값 |
|---|---|
| Phase | P2 |
| 중요도 | ★ — 분석 비대상 (의도된 미등록 추정) + ★★ skill_feedback_complete (검토 가치) |
| 상태 | 확정 (대부분 의도된 미등록) — skill_feedback_complete 사용자 확인 필요 |
| 작성일 | 2026-05-01 |
| 출처 | F-002 §5 Server 7일 분석 + 카탈로그 §4-2 (이들은 카탈로그 미등록) |
| affects-ssot | yes — 카탈로그에 운영성 Server 이벤트 분류 정책 명시 가치 |
| affects-tier | **Tier 4 (정리/Airflow 잔존 — dbt 비대상)** + 1건 사용자 결정 대기 |

## 1. 그룹 — 4 운영성 Server 이벤트

| 이벤트 | 7일 발화 | 1st | se_2nd | 분류 |
|---|---|---|---|---|
| `use_attribute` | **1,577,315** | - | - | 운영성 (의도된 미등록) |
| `update_attribute` | **1,410,455** | - | - | 운영성 (의도된 미등록) |
| `receive_user_message` | **909,795** | - | - | 운영성 (의도된 미등록) |
| `skill_feedback_complete` | 24,501 | - | - | **★ 분석 가치 있음 — 사용자 확인 필요** |

본 4 이벤트는 Server 발화의 **92%** 차지 (총 510만/553만 = 92%) 인데 화이트리스트 미등록 → staging 안 들어감.

## 2. 의도된 미등록 (3건) — 운영 시스템 이벤트

### `use_attribute` / `update_attribute`
- 챗봇 봇 운영 중 사용자 속성 (attribute) 사용·갱신 이벤트
- 챗봇 logic 의 내부 동작 — 분석 가치 낮음
- F-002 §5 + ISS-015 case C 명시

### `receive_user_message`
- 사용자가 챗봇에 메시지 보낸 시점 (서버 수신)
- 챗봇 핵심 활동인데 분석 미사용 — historical 결정 (P6 후보)

→ 카탈로그 §4-2 에 운영성 이벤트 표기 가치 (현재 카탈로그에는 본 3건 미등록 = "분석에 안 쓰는 이벤트" 표기 부재)

## 3. ★ 사용자 확인 필요 — `skill_feedback_complete`

- 7일 24,501 발화 (일 평균 3,500)
- 스킬 사용 후 피드백 완료 이벤트 — **분석 가치 있어 보임** (NPS·만족도)
- 화이트리스트 미등록 → staging 안 들어감 (= 분석 불가)
- → **누락 vs 의도 미등록 구분 필요**

## 4. dbt 마이그 가이드

### 4-1. Tier 분류

| 이벤트 | Tier | 처리 |
|---|---|---|
| use_attribute / update_attribute / receive_user_message | Tier 4 (Airflow 잔존) | dbt source 등록만, 분석 변환 안함. raw 보존만 |
| **skill_feedback_complete** | **결정 대기** | 분석 가치 있으면 화이트리스트 등록 → Tier 1·2 |

### 4-2. dbt source 등록 (Tier 4)
```yaml
sources:
  - name: server_events
    tables:
      - name: server_events
        # 운영성 이벤트 4종은 별도 분석 변환 없음
        # 분석 활성 이벤트만 staging_key_events_se 로 흐름
```

### 4-3. 보존 필수
- 본 4 이벤트는 mart 단까지 안 흐르므로 보존 부담 없음
- 단, raw `server_events` 보존 (BQ 자동 export)

## 5. 후속 액션

- [x] 본 카드 작성 (2026-05-01)
- [ ] **(★ 사용자 결정)** `skill_feedback_complete` 화이트리스트 등록 여부 — F-002 §4 후속 액션과 통합
- [ ] (v2 인계) 카탈로그 §4-2 에 운영성 Server 이벤트 분류 표 신설 (use_attribute 등 3건)
- [ ] (P6) `receive_user_message` 가 분석 미사용인 historical 출처
