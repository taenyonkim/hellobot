# 과업 목록

본 프로젝트는 **계획 수립**이 deliverable이다. 실제 적용(hooks 작성, 디렉토리 시드, 도메인 문서 작성)은 후속 프로젝트로 분리한다.

## 의존 관계

```
Phase 1 (Discovery)  →  Phase 2 (Design)  →  Phase 3 (Pilot 계획)
  병렬 진행 가능          synthesize           stop here
```

---

## Phase 1 — Discovery (병렬 진행 가능)

### 1-A. Claude Code 기능 카탈로그 (`planning/claude-code-features.md`)

- [x] 1차 시드 작성 — 알려진 기능별 용도/적용 후보 정리 (커맨드/스킬/훅/서브에이전트/메모리/MCP/스케줄)
- [ ] 공식 문서 또는 변경 이력 기반 보강 — 최신 기능 누락 여부 점검 (필요시 `claude-code-guide` 에이전트 활용)
- [ ] 워크스페이스 적용 후보 점수화 — 도입 비용 vs 효과로 우선순위 분류 (P1/P2/P3)
- [ ] 기능별 "현재 미사용 → 도입 시 대체될 운영 행위" 매핑

### 1-B. 누적 프로젝트 회고 (`planning/retrospective.md`)

- [ ] 7개 프로젝트(coop-integration / billing-refund-regression / admin-performance / data-infra-documentation / data-infra-documentation-v2 / dbt-migration-prep / coop-integration의 Phase별) 진행 패턴 회고
- [ ] 잘 작동한 패턴 추출 (살릴 것)
- [ ] 반복 비용 패턴 추출 (제거할 것)
- [ ] 운영 규칙 ↔ 실제 사용의 간극 정리 (현실화할 것)
- [ ] "다음 프로젝트가 이전 프로젝트의 결정을 참조하지 못한 사례" 추출

### 1-C. 도메인 지식 누적 모델 (`planning/domain-knowledge-design.md`)

- [x] 1차 설계안 — 저장 위치/카테고리/작성 시점/참조 흐름 (4-layer: concepts / patterns / decisions / cases)
- [ ] 리포별 적용 형태 점검 — 9개 리포 각각 현실적 보유 가능 자산 점검
- [ ] 갱신 흐름 설계 — 누가 언제 어떤 형식으로 갱신하는가 (자동화 가능한 부분 식별)
- [ ] 컨텍스트 로딩 부담 점검 — 누적될수록 무거워지는 위험 차단 방안 (인덱스, lazy 로딩)

---

## Phase 2 — Design (Phase 1 완료 후 통합)

### 2-A. 통합 architecture 작성 (`architecture.md`)

- [ ] AS-IS 정리 — 현재 워크스페이스 운영 구조 + 누적 자산 위치
- [ ] TO-BE 정리 — Phase 1 산출물 종합 (어떤 기능을 어떻게 도입하고, 도메인 지식이 어디에 어떻게 쌓이는가)
- [ ] 기능 ↔ 운영 매핑 테이블 — Claude Code 기능 ↔ 워크스페이스 운영 행위
- [ ] 디렉토리 구조 변경안 — 워크스페이스 / 각 리포 / .claude/
- [ ] 에이전트 커맨드 변경 항목 — 추가/삭제 없이, 절차 변경 항목만 명세
- [ ] 트레이드오프 / 리스크 정리 — 누적 부담, 학습 곡선, 일관성 유지 비용

### 2-B. 검증 기준 정의

- [ ] "개선되었다"의 정량적 지표 (예: 신규 프로젝트 셋업 시간, 컨텍스트 로딩 비용, 반복 결정 발생률)
- [ ] "도메인 지식이 누적되고 있다"의 관찰 가능 지표

---

## Phase 3 — Pilot 적용 계획

### 3-A. 파일럿 대상 선정

- [ ] 우선 적용 리포 1개 선정 (후보: `hellobot-server` / `common-data-airflow` — 누적 사례 가장 많음)
- [ ] 우선 적용 카테고리 1개 선정 (후보: `domain/` 또는 `patterns/` 단독)
- [ ] 검증 시나리오 — 다음 프로젝트(예: 신규 결제 기능, 신규 BQ 마트)가 적용된 자산을 활용하는 흐름 시뮬레이션

### 3-B. 로드맵

- [ ] 파일럿 → 확장 단계 정의 (1개 리포 → 3개 리포 → 전체)
- [ ] 각 단계의 진입 조건 / 종료 조건
- [ ] 후속 프로젝트로 이관할 작업 명세 (이 프로젝트의 종료 정보에 기록)

---

## 후속 프로젝트로 이관 (참고)

본 프로젝트 종료 후 별도 프로젝트로 분리할 작업:

- [ ] hooks 실제 작성 (settings.json + 스크립트)
- [ ] 파일럿 리포 도메인 문서 시드 (예: `hellobot-server/docs/domain/heart-coupon.md`)
- [ ] CLAUDE.md / `.claude/commands/*.md` 도메인 지식 참조 절차 반영
- [ ] 메모리 시스템 활용 가이드 작성 + 시드
- [ ] 검증 (다음 신규 프로젝트에서 자산 활용도 측정)
