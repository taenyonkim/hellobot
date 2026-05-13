# 워크스페이스 진화 — 통합 개선 계획 (1차안)

> 본 문서는 [planning/](./planning/) 의 세 시드 문서를 기반으로 한 통합 계획의 1차안.
> Phase 1 후속 보강이 끝나면 본 문서가 확정안이 됨.
>
> 관련 문서:
> - [planning/claude-code-features.md](./planning/claude-code-features.md)
> - [planning/retrospective.md](./planning/retrospective.md)
> - [planning/domain-knowledge-design.md](./planning/domain-knowledge-design.md)

---

## 1. 핵심 명제

> **"문서 구조는 정리되었다. 다음은 운영의 자동화와 지식의 영속화다."**

지난 두 메타-프로젝트(setup, ops-improvement)는 **무엇을 어디에 쓸지**를 정리했다. 본 프로젝트는 **에이전트가 어떻게 잊지 않고 누적해 가는가**를 정리한다.

---

## 2. AS-IS 정리

### 2-1. 구조

```
워크스페이스 (현재)
  ├── CLAUDE.md                        ← 풍부 (운영 규칙 적극 사용)
  ├── docs/                            ← 상시 문서 (architecture, deployment, how-to-work)
  ├── projects/                        ← 프로젝트별 문서 + 워크트리 (단일 소스 정착)
  ├── .claude/
  │   ├── commands/                    ← 11개 슬래시 커맨드 (적극 사용)
  │   ├── settings.{json,local.json}   ← 권한 누적 (hooks 미사용)
  │   └── (skills/agents 미사용)
  └── 9개 리포
       ├── CLAUDE.md / README.md       ← 편차 큼 (보강 필요)
       └── docs/features/              ← 프로젝트별 구현 기록 (Cases)
            (domain/, patterns/, decisions/ 미존재)

메모리 (현재)
  └── ~/.claude/projects/.../memory/
      └── 5건 (정체) — 인덱스 활용 미진
```

### 2-2. 운영 흐름

- 슬래시 커맨드로 역할 격리 (장점) → 호출 사이 학습 누적 안 됨 (한계)
- 단일 소스 + Changelog (장점) → 누락 시 발견은 사후 점검 (한계)
- 워크트리 + 원본 메인 (장점) → 도메인 지식은 워크트리/리포 status 에 묻힘 (한계)
- `/workspace 종료` 가 SSOT 승격 / 영속화의 채널 (장점) → 도메인 자산 갱신 단계 부재 (한계)

### 2-3. 핵심 격차

| 격차 | 증상 |
|------|------|
| 도메인 지식 비영속 | 다음 프로젝트가 이전 결정을 자동 참조하지 못함 |
| 반복 절차 비형식화 | 매번 처음부터 재추론 |
| 운영 강제력 부재 | 계약 문서 Changelog 누락 종종 발생 |
| 컨텍스트 부풀림 | 메인 컨텍스트가 광범위 grep/glob 으로 무거워짐 |
| 메모리 미활용 | 누적 자산을 가리키는 인덱스 부재 |

---

## 3. TO-BE 정리

### 3-1. 구조 변경

```
워크스페이스 (TO-BE)
  ├── CLAUDE.md                        ← 비대화 차단: 카테고리별 분리 (선택)
  ├── docs/                            ← 그대로
  ├── projects/                        ← 그대로
  ├── .claude/
  │   ├── commands/                    ← 본문 다이어트 + "도메인 진입점 로드" 절차 추가
  │   ├── settings.json                ← 카테고리별 정리
  │   ├── settings.local.json          ← 권한 정리 (별 변경 없음)
  │   └── hooks/ (NEW)                 ← 결정론적 강제 (계약 문서 Changelog 경고 등)
  └── 9개 리포 (점진 신설)
       ├── CLAUDE.md                   ← 도메인 진입점 가이드 추가
       └── docs/
            ├── domain/    (NEW)       ← Concepts (개념·정책)
            ├── patterns/  (NEW)       ← 반복 절차
            ├── decisions/ (NEW)       ← ADR
            └── features/              ← 그대로 (Cases)

메모리 (TO-BE)
  └── ~/.claude/projects/.../memory/
       ├── (기존 5건)
       ├── reference_dev_*_domain.md   (NEW) — 리포별 도메인 진입점 인덱스
       └── feedback_recurring_*.md     (NEW) — 반복 결정 단축 메모
```

### 3-2. 운영 흐름 변경

| 단계 | 변경 |
|------|------|
| `/analyze` | 영향 리포의 `docs/domain/index.md` + 최근 ADR 로드 → readme.md §관련 자산 |
| `/dev-*` 작업 시작 | 리포 CLAUDE.md → docs/domain/index.md → 관련 도메인 문서 + ADR 로드 |
| `/dev-*` 작업 종료 | 결정 로그 작성 (현행) — 단, 영구 영향이면 ADR 승격 후보 표시 |
| `/workspace 종료` | "도메인 자산 갱신 후보 점검" 단계 추가 (사용자 확인 필수) |
| `Edit` (계약 문서) | hook: Changelog 미수정 시 경고 (P1) |
| `Stop` (에이전트 작업) | hook: 도메인 결정 발생 표시가 있는데 ADR 없음 → 알림 (P2) |

---

## 4. 기능 ↔ 운영 매핑

| Claude Code 기능 | 도입 항목 | 대체될 운영 행위 | 우선순위 |
|------------------|----------|-----------------|---------|
| **메모리 시스템** | `reference_*` / `feedback_*` 항목 추가 | "도메인 진입점을 매번 탐색" / "반복 결정을 매번 재발견" | P1 |
| **CLAUDE.md (리포)** | 리포별 진입점 보강 | "리포 코드 베이스 광범위 탐색" | P1 |
| **Hooks** | `PostToolUse` 계약 문서 / `Stop` 결정 알림 / `SessionStart` 점검 | "Changelog 누락 사후 catch-up" / "ADR 갱신 누락" / "오래된 status 발견" | P1 |
| **Subagents (Explore)** | `/dev-*` 의 광범위 탐색 위임 | "메인 컨텍스트 부풀림" | P2 |
| **Skills** | 반복 절차 (마이그레이션, 마트 추가, 이벤트 검증 5단계 등) | "매번 절차 재추론" | P2 |
| **MCP** | (이미 적극사용 — Figma, Notion 일부) | — | (유지) |
| **Scheduled Tasks** | 매일 워크스페이스 점검 (선택) | "수동 `/workspace` 점검" | P3 |
| **Slash Commands** | 본문 다이어트 + 도메인 참조 절차 | "본문 비대화" | P1 |

---

## 5. 디렉토리 구조 변경안

### 5-1. 워크스페이스

| 위치 | 현재 | 변경 |
|------|------|------|
| `.claude/hooks/` | 없음 | **신설** (스크립트 + settings.json hooks 섹션) |
| `.claude/commands/*.md` | 그대로 | **본문 다이어트** — 도메인 진입점 로드 절차 추가, 중복 규칙은 CLAUDE.md 로 위임 |
| `docs/` | 그대로 | (선택) `agent-knowledge-conventions.md` 신설 — domain/patterns/decisions 작성 가이드 |
| `CLAUDE.md` | 풍부 | 비대화 차단 — 운영 규칙 일부를 `docs/agent-conventions.md` 등으로 외출 (선택) |

### 5-2. 각 리포 (점진 도입)

| 위치 | 현재 | 변경 |
|------|------|------|
| `docs/domain/` | 없음 | **신설** (첫 도메인 자산이 만들어질 때) |
| `docs/patterns/` | 없음 | **신설** (첫 패턴이 만들어질 때) |
| `docs/decisions/` | 없음 | **신설** (첫 ADR 작성 시) |
| `docs/features/` | 있음 | 그대로 |
| `CLAUDE.md` | 편차 큼 | 진입점 가이드 추가 (`docs/domain/index.md` 우선 로드 안내) |

### 5-3. 메모리

| 항목 | 현재 | 변경 |
|------|------|------|
| MEMORY.md | 5건 | **인덱스 격상** — 도메인 진입점 추가, 반복 결정 단축 메모 추가 |
| 갱신 흐름 | 비명시적 | 프로젝트 종료 절차 / 패턴 형성 시점에 명시적 갱신 |

---

## 6. 에이전트 커맨드 변경 항목

본 프로젝트는 **신규 커맨드 추가/삭제 없음**. 기존 11개 커맨드 본문에 다음 항목 반영.

### 6-1. 모든 `/dev-*` 공통

```markdown
## 컨텍스트 로딩 (변경)
1. 워크스페이스 CLAUDE.md (자동)
2. 리포 CLAUDE.md (자동)
3. **리포 docs/domain/index.md (있으면)** ← NEW
4. 프로젝트 readme.md / status.md / tasks.md / architecture.md / api-spec.md
5. **관련 도메인 문서 / 최근 ADR (필요 시)** ← NEW
```

### 6-2. `/analyze`

```markdown
## 영향 분석 시 (변경)
- 영향 리포의 docs/domain/index.md 확인 → readme.md §관련 자산 섹션 작성
```

### 6-3. `/architect`

```markdown
## 설계 시 (변경)
- 영향 리포의 docs/decisions/ 최근 ADR 확인 — 충돌하는 결정이 있는지
- 본 설계가 영구 결정을 만들 가능성이 있으면 architecture.md 에 명시
```

### 6-4. `/workspace 종료`

```markdown
## 6.5 도메인 자산 갱신 점검 (NEW)
- 본 프로젝트의 결정 중 ADR 승격 후보 식별
- 본 프로젝트에서 학습한 도메인 개념 → docs/domain/ 갱신 후보 식별
- 새로운 반복 절차 → docs/patterns/ 후보 식별
- 사용자와 협의 후 작성/갱신
- 갱신 결과를 status.md §종료 정보 §승격 산출물 표에 기록
```

---

## 7. Hooks 1차 후보 (P1)

### 7-1. 계약 문서 Changelog 미수정 경고

| 항목 | 값 |
|------|----|
| 트리거 | `PostToolUse` (Edit/Write) |
| 매처 | 변경 파일이 `architecture.md` / `api-spec.md` / `design-spec.md` / `data-measurement-plan.md` / `event-spec.md` |
| 동작 | 변경된 헝크에 Changelog 갱신이 없으면 stderr 경고 |
| 효과 | Changelog 누락 사후 catch-up 비용 제거 |

### 7-2. 도메인 결정 ADR 알림

| 항목 | 값 |
|------|----|
| 트리거 | `Stop` |
| 매처 | 리포 status.md 결정 로그가 갱신됨 (git diff 확인) |
| 동작 | 결정이 영구 영향 가능성이 있으면 사용자에게 ADR 승격 여부 묻기 (정보 출력) |
| 효과 | ADR 작성 누락 알림 |

### 7-3. 세션 시작 점검

| 항목 | 값 |
|------|----|
| 트리거 | `SessionStart` |
| 매처 | (없음) |
| 동작 | 진행중 프로젝트 status 표 + 미해결 이슈 카운트 출력 |
| 효과 | 세션 시작 시 컨텍스트 즉시 확보 |

> 모든 hook 은 **경고/알림 only**. 작업 차단 금지.

---

## 8. 적용 로드맵

```
[본 프로젝트] 계획 수립 (현재)
    │
    ├─→ Phase 1 후속 보강 (planning/* 정밀화)
    │
    └─→ 본 architecture 확정
        │
        ▼
[후속 프로젝트 1] 파일럿 — hellobot-server domain/ 시드
    │  대상: 1개 리포, 1개 카테고리
    │  검증: 다음 결제 관련 프로젝트가 자산을 활용하는가
    │
    └─→ 회고
        │
        ▼
[후속 프로젝트 2] 확장 — hooks 도입 + common-data-airflow 모델 정렬
    │
    └─→ 회고
        │
        ▼
[후속 프로젝트 3] 전면 적용 — 9개 리포 전체 + 메모리 인덱스 갱신 흐름
```

각 후속 프로젝트는 명확한 진입/종료 조건을 가진다.

| 단계 | 진입 조건 | 종료 조건 |
|------|----------|----------|
| 본 프로젝트 | (현재) | architecture.md 확정 + tasks Phase 3 완료 |
| 파일럿 (P-1) | 본 프로젝트 종료 | 파일럿 리포의 domain/ 시드 + 다음 신규 프로젝트 1건에서 활용 검증 |
| 확장 (P-2) | 파일럿 회고에서 가치 확인 | hooks 안정 + 2번째 리포 적용 |
| 전면 (P-3) | 확장 회고에서 일관성 확인 | 전 리포 적용 + 메모리 인덱스 정착 |

---

## 9. 트레이드오프 / 리스크

| 리스크 | 완화 |
|--------|------|
| 도메인 자산이 stale | 마지막 검증일 + 분기 점검 + 미참조 자산 archive |
| 작성 부담으로 갱신 안 됨 | 짧게 유지 (50~200줄) + `/workspace 종료` 절차에 명시 |
| 인덱스 비대화 | 카테고리별 인덱스 분리 + 메모리에는 진입점만 |
| Hooks false positive 로 작업 차단 | 모든 hook 은 경고/알림 only |
| 학습 곡선 | 파일럿에서 충분 검증 후 확장 |
| 리포 간 모델 불일치 | common-data-airflow 카탈로그 모델과 사전 정합성 검토 |
| 본 계획의 자체 stale | 본 프로젝트 종료 후 6개월 시점에 재검토 (메모리에 reminder) |

---

## 10. 검증 기준

본 개선이 **효과 있다고 판단할 수 있는 신호**.

| 신호 | 측정 |
|------|------|
| 신규 프로젝트의 컨텍스트 진입 비용 감소 | `/dev-*` 첫 호출 시 grep/glob 수, 첫 산출물까지의 turn 수 |
| 이전 결정의 자동 참조 | 새 프로젝트 readme.md §관련 자산 에 ADR 인용 빈도 |
| 반복 결정 발생률 감소 | 비슷한 ISS 가 반복 발생하는가 |
| 계약 문서 Changelog 누락 | hooks 도입 후 사후 발견 건수 변화 |
| 메모리 항목 누적 | MEMORY.md 항목 변동 빈도 |

---

## Changelog

| 날짜 | 변경자 | 변경 내용 | 확인 |
|------|--------|----------|------|
| 2026-05-03 | /workspace | 1차안 작성 (planning/* 시드 종합) | — |
