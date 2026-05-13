# 워크스페이스 진화 — Claude Code 활용 + 도메인 지식 누적

## 배경

워크스페이스 운영을 두 차례 정리한 결과(20260411 setup, 20260415 ops-improvement) 문서 구조와 워크플로우는 안정화되었으나, 운영을 누적하면서 다음 한계가 드러났다.

1. **Claude Code의 풍부한 기능을 충분히 활용하지 못함**
   - 슬래시 커맨드 11개 외에 hooks / skills / subagents / MCP / scheduled tasks / 메모리 시스템 등은 사실상 미사용
   - `.claude/settings.json` 의 권한 허용이 누적될 뿐, hooks 자동화는 없음
   - 메모리 파일은 5건만 유지 — 프로젝트가 누적되어도 늘어나지 않음

2. **프로젝트마다 에이전트가 도메인 지식을 매번 재발견**
   - `/dev-server` 가 `coop-integration` 에서 학습한 쿠폰/하트 도메인 지식이 다음 프로젝트로 이어지지 않음
   - 같은 함정(예: `chargeHeart` 트랜잭션 분리, `usableDays` 정책)에 다음 프로젝트에서 다시 빠질 위험
   - 리포 `docs/features/{프로젝트}/status.md` 의 결정 로그는 살아 있으나 다음 프로젝트가 역참조하지 않음
   - 반복 작업(API 추가, 마이그레이션, BQ 마트 추가)을 매번 처음부터 분석

3. **누적 컨텍스트 자산이 흩어져 있음**
   - 도메인 개념 / 반복 패턴 / 의사결정 / 지난 사례가 한 곳에 정리된 위치가 없음
   - 새 세션의 에이전트는 매번 광범위 탐색으로 컨텍스트를 재구성

## 목표

다음 세 가지를 동시에 달성하는 워크스페이스 운영 체계의 **개선 계획**을 수립한다. 본 프로젝트의 산출물은 계획 문서이며, 적용은 후속 단계에서 단계적으로 진행한다.

1. **Claude Code 기능 카탈로그 + 적용 매핑**
   현재 워크스페이스 운영의 어느 부분이 어떤 Claude Code 기능에 의해 자동화·고도화될 수 있는지 매핑한다.
   - 자동화로 대체될 운영 행위 (예: 과업 완료 → status 동기화)
   - 누적 지식 저장소로 활용될 메커니즘 (메모리, 스킬)
   - 컨텍스트 효율을 높일 메커니즘 (subagent, MCP)

2. **현재 워크스페이스 운영 회고 + 개선점 도출**
   누적된 7개 프로젝트의 진행 패턴을 회고하여 구조적 개선점을 도출한다.
   - 무엇이 잘 작동했는가 (살릴 것)
   - 무엇이 반복적으로 비용이었는가 (제거할 것)
   - 운영 규칙과 실제 사용의 간극 (현실화할 것)

3. **파트별 도메인 지식 누적 구조 설계**
   `/dev-*` 에이전트가 프로젝트를 진행할수록 해당 리포의 도메인 지식이 자산으로 쌓이는 구조를 설계한다.
   - 도메인 개념(엔티티·라이프사이클·정책) 영속 저장소
   - 반복 작업 패턴(레시피) 영속 저장소
   - 의사결정 기록(ADR) 영속 저장소
   - 지식이 새 프로젝트에서 자동/반자동으로 활용되는 흐름

## 범위

### 포함

- 누적 7개 프로젝트의 운영 회고 (성공/실패 패턴, 간극)
- Claude Code 기능 조사 (공식 문서 + 워크스페이스 적용 가능성)
- 기능 ↔ 운영 매핑 (어느 기능이 어느 운영 행위를 대체/보강하는가)
- 도메인 지식 누적 구조 설계 (저장 위치, 작성 시점, 참조 흐름)
- 통합 architecture 문서 (TO-BE 구조 + 적용 로드맵)
- 파일럿 적용 계획 (1개 리포 / 1개 카테고리부터 검증)

### 제외

- 본 프로젝트에서는 **계획 수립까지** 수행. 실제 적용(hooks 작성, 디렉토리 생성, 도메인 문서 시드)은 후속 프로젝트.
- 에이전트 커맨드(`.claude/commands/*.md`)의 대규모 재작성은 본 프로젝트 범위 외 (변경 항목만 명시)
- 신규 프로젝트 진행 (개발 작업 없음)

## 영향 범위

| 파트 | 영향 | 설명 |
|------|------|------|
| 워크스페이스 | O | CLAUDE.md, projects/readme.md, .claude/ 구성 (계획만) |
| 에이전트 커맨드 | O (계획만) | 도메인 지식 참조 절차 추가, hooks 통합 |
| 각 리포 docs/ | O (계획만) | `domain/`, `patterns/`, `decisions/` 신설 제안 |
| 코드 | X | 코드 변경 없음 |

## 산출물

- `readme.md` — 본 문서
- `status.md` — 진행 상태
- `tasks.md` — 단계별 과업
- `planning/claude-code-features.md` — Claude Code 기능 카탈로그 + 워크스페이스 매핑
- `planning/retrospective.md` — 누적 7개 프로젝트 운영 회고
- `planning/domain-knowledge-design.md` — 도메인 지식 누적 구조 설계
- `architecture.md` — 통합 개선 계획 (TO-BE + 로드맵)

## 문서 목록

| 문서 | 설명 |
|------|------|
| [status.md](./status.md) | 진행 상태 |
| [tasks.md](./tasks.md) | 단계별 과업 |
| [planning/claude-code-features.md](./planning/claude-code-features.md) | Claude Code 기능 조사 |
| [planning/retrospective.md](./planning/retrospective.md) | 누적 프로젝트 회고 |
| [planning/domain-knowledge-design.md](./planning/domain-knowledge-design.md) | 도메인 지식 누적 구조 |
| [architecture.md](./architecture.md) | 통합 개선 계획 |

## 선행 프로젝트

- [20260411-workspace-setup](../20260411-workspace-setup/) — 워크스페이스 초기 구축 (디렉토리 / 커맨드 / 워크트리 운영 규칙)
- [20260415-workspace-ops-improvement](../20260415-workspace-ops-improvement/) — 문서 구조 정리 (단일 소스, 중복 제거, 명칭 정리)

본 프로젝트는 위 두 프로젝트 위에 **운영 체계 + 지식 누적 레이어** 를 추가하는 3차 진화다.
