# Findings — As-Is 분석 누적 노트

본 디렉토리는 **dbt 마이그레이션 As-Is 분석** 의 발견사항을 누적하는 곳이다. finding 카드는 모듈식 — 다음 세션이 어디서든 이어받을 수 있도록 자체 완결성을 유지한다.

## 폴더 구조

```
findings/
├── README.md              ← (본 파일) 인덱스 + 중요도/Tier 가이드
├── 00-overview.md         ← 전체 그림 (P7 완료 시점에 작성)
├── 10-usage-frequency/    ← P1: 마트·이벤트·지표의 다운스트림 카운트
├── 20-asset-semantics/    ← P2: 자산별 시맨틱 baseline (그레인·NULL·암묵 가정)
│   ├── marts/
│   ├── events/
│   └── metrics/
├── 30-lineage/            ← P3: DAG → SQL → 테이블 의존 그래프
├── 40-staging-transforms/ ← P4: 이벤트 → staging 변환 룰
├── 50-external-deps/      ← P5: 외부 의존 (Firebase/GSheet/Braze/Notion/Looker)
├── 60-historical/         ← P6: 코드만으로는 안 보이는 결정·암묵 룰
└── 70-migration-tiers/    ← P7: Tier 1~4 분류표 (후속 dbt 프로젝트 직접 인풋)
```

## finding 카드 ID 규칙

| 범위 | 시작 ID | 예 |
|---|---|---|
| 10-usage-frequency | F-001+ | F-001-mart-downstream-map.md |
| 20-asset-semantics/marts | F-101+ | F-101-union_mart_user_key_actions.md |
| 20-asset-semantics/events | F-201+ | F-201-enter_skill.md |
| 20-asset-semantics/metrics | F-301+ | F-301-revenue_krw.md |
| 30-lineage | F-401+ | F-401-sql-lineage.md |
| 40-staging-transforms | F-501+ | F-501-staging_key_events_fb.md |
| 50-external-deps | F-601+ | F-601-firebase-export.md |
| 60-historical | F-701+ | F-701-krw-per-heart-150.md |
| 70-migration-tiers | F-901+ | F-901-tier-table.md |

ID 는 **카드 작성 순서대로** 부여 (Phase 와 무관). 본 README 의 §finding 인덱스 표에 추가하며 갱신.

## finding 카드 표준 포맷

각 카드는 다음 frontmatter + 본문 구조를 따른다.

```markdown
# F-NNN — {한 줄 제목}

| 항목 | 값 |
|---|---|
| Phase | P? |
| 중요도 | ★★★ / ★★ / ★ |
| 상태 | 확정 / 잠정 / 외부확인필요 |
| 작성일 | YYYY-MM-DD |
| 출처 | {BQ 쿼리·실행일·스캔 / SQL 파일 / 사용자 발화 / Notion / Slack / PR} |
| affects-ssot | yes (→ v2 §신규 과업 ID) / no |
| affects-tier | Tier 1~4 (P7 시점 분류) |

## 발견 / 사실
- 핵심 사실을 bullet 또는 표

## 근거
- 출처별 검증 결과 (쿼리·스캔 바이트·SQL 라인 등)

## dbt 마이그 영향
- Tier 분류 시 고려할 점
- 보존 필수 항목 / 재정의 가능 항목

## 후속 액션
- [ ] {필요 시 — 카탈로그 갱신 / 다른 finding 카드 / 외부 확인}
```

## 중요도 가이드

| 등급 | 정의 | 운영 |
|---|---|---|
| **★★★** | dbt 마이그 직접 인풋 — 사용 빈도 상위 자산, 시맨틱 baseline, Tier 1·2 후보 | 후속 프로젝트가 그대로 받아 사용. SSOT 갱신 가치 높음 |
| **★★** | Tier 3 (재정의 + 합의) 후보 — 의미가 모호하거나 historical 결정에 의존 | 사용자 합의 필요. 합의 결과는 카탈로그·data-measurement-plan 으로 승격 |
| **★** | Tier 4 또는 참조 — historical / 외부 의존 / 마이그 무관 | 보존하되 마이그 우선순위 낮음 |

## Tier 분류 (P7 산출 — 정의 미리보기)

| Tier | 정의 | dbt 후속 프로젝트 처리 |
|---|---|---|
| **Tier 1** | 시맨틱 명확, 의존 단순 → **그대로 dbt 모델로 이식** | 사실상 1:1 SQL 이식 (스키마·이름 동일 권장) |
| **Tier 2** | 시맨틱 보존하며 재구현 — 단 보존 부담 크면 새 마트 + 대시보드 새로 구축 옵션 가능 (MP-1) | dbt naming + tests + dbt 표준 패턴. baseline 카드의 "현재 스키마" vs "개선 후보" 둘 중 trade-off 결정 |
| **Tier 3** | 재정의 + 합의 필요 (모호하거나 historical 결정 의존) | **합의 후 신규 정의로 마이그** — 본 프로젝트가 합의 항목 식별만, 합의는 후속 |
| **Tier 4** | dbt 비대상 (Airflow 잔존) | dbt 안 옮김. Airflow DAG 로 유지 (외부 export·sync·orphan 정리 등) |

> **마이그 정책 적용**: Tier 1·2 의 "보존" 은 절대 제약이 아닌 권장 ([MP-1](../readme.md#마이그-정책--2026-04-30-사용자-확정)). 보존 부담이 가치보다 크면 새로 짓는 옵션이 항상 열려있다. 마트 스키마도 더 나은 구조가 있으면 변경 가능 ([MP-2](../readme.md#마이그-정책--2026-04-30-사용자-확정)).

(Tier 정의·기준은 P7 진입 시점 사용자와 합의 후 확정. 위는 작업 가설.)

## finding 인덱스

작성된 카드는 아래 표에 추가한다 (카드 작성 시 즉시).

| ID | Phase | 제목 | 중요도 | 상태 | 작성일 | affects-ssot |
|---|---|---|---|---|---|---|
| [F-001](./10-usage-frequency/F-001-mart-downstream-map.md) | P1 | 마트 다운스트림 카운트 (내부 SQL 의존 인벤토리) | ★★★ | 확정 | 2026-04-30 | yes (3건 v2 인계 후보) |
| [F-002](./10-usage-frequency/F-002-event-usage-frequency.md) | P1 | 이벤트 사용 빈도 + 화이트리스트 정합성 실측 — ISS-014 실측 검증 / 1차만 등록 57건 / dead whitelist 50건 / 미등록 고볼륨 ~10건 | ★★★ | 확정 (3건 외부확인) | 2026-04-30 | yes (5건 v2 인계 후보) |
| [F-003](./10-usage-frequency/F-003-external-interfaces.md) | P1 | 외부 인터페이스 매트릭스 (dbt 비대상 영역) — Slack KPI 알림 채널·소스 마트 매핑 / GSheet input / Braze 단방향 / Looker 메타부재 | ★★★ | 확정 (Looker 외부확인) | 2026-04-30 | yes (KPI 채널·외부 인터페이스 표 SSOT 후보) |
| [F-004](./10-usage-frequency/F-004-orphan-and-dead-marts.md) | P1 | Orphan / Dead / 외부 자산 분류 (Tier 4 인풋) — `queries.py` 가 destination 진실원천 / `union_mart_user_key_actions2` dead 확정 (199GB) / dead 16건 | ★★ | 확정 | 2026-04-30 (갱신) | yes (3건 v2 인계 후보) |
| [P1-recap](./10-usage-frequency/P1-recap.md) | P1 | P1 회고 — 4 finding 종합 + P2 진입 가이드 + SSOT 인계 12건 + 외부확인필요 8건 + 산출 형태 (A. 마이그 인풋 / B. 정리 대상 MP-3) | ★★★ | 확정 | 2026-04-30 | (종합) |
| [F-101](./20-asset-semantics/marts/F-101-mart_use_skill_se.md) | P2 | `mart_use_skill_se` 시맨틱 baseline — 다운스트림 47 / KPI 알림 직접 의존 / revenue_krw 매출 표준 / 51 컬럼 / Tier 2 권장 | ★★★ | 확정 | 2026-05-01 | yes (1건 추가 stale: 파티션) |
| [F-102](./20-asset-semantics/marts/F-102-intermediate_user_daily_info.md) | P2 | `intermediate_user_daily_info` 시맨틱 baseline — 다운스트림 26 / DAU 본진 / UNION+ROW_NUMBER / 26 컬럼 / Tier 1 권장 / **카탈로그 missing 발견** | ★★★ | 확정 | 2026-05-01 | yes (1건 추가: tables/intermediate/ 전체 missing) |
| [F-103](./20-asset-semantics/marts/F-103-mart_skill_funnel_fb.md) | P2 | `mart_skill_funnel_fb` 시맨틱 baseline (★ **레거시**) — 다운스트림 23 / 47 컬럼 / **Tier 3 (레거시 폐기 vs 보존 결정)** / **alias 오타 `pricegit` 발견** / 카탈로그 카드 missing | ★★★ | 확정 (Tier 3 결정 대기) | 2026-05-01 | yes (3건 추가: 카드 missing / alias 오타 / 레거시 표기) |
| [F-104](./20-asset-semantics/marts/F-104-mart_user_server.md) | P2 | `mart_user_server` 시맨틱 baseline — 다운스트림 17 / CRM 본진 / 26 컬럼 / **partition 없음 (개선 후보)** / `test_group` A/B 가격실험 / Tier 2 권장 | ★★ | 확정 | 2026-05-01 | yes (2건: 카드 missing / F-004 정정) |
| [F-105](./20-asset-semantics/marts/F-105-staging_fixed_menu_copy.md) | P2 | `staging_fixed_menu_copy` 시맨틱 baseline — 다운스트림 14 / 메뉴 마스터 / 50 컬럼 / **서버 스키마 갭 (snapshot.create_at 누락)** / Tier 1 권장 | ★★ | 확정 | 2026-05-01 | yes (1건: tables/staging/ 디렉토리 missing 17건) |
| [F-106](./20-asset-semantics/marts/F-106-union_mart_user_key_actions.md) | P2 | `union_mart_user_key_actions` 시맨틱 baseline (★ **외부 진입점**) — 분석 본진 / 131 컬럼 / 195.8 GB / 자기참조 누적매출 / RFM 스냅샷 / **MP-1 trade-off 결정 핵심** | ★★★ | 확정 | 2026-05-01 | yes (2건: 카탈로그 stale 파티션·컬럼수) |
| [F-201](./20-asset-semantics/events/F-201-enter_skill.md) | P2 | `enter_skill` 이벤트 (★ 양쪽 발화) — Firebase + Server / 매출 직결 / 페어 규칙 준수 | ★★★ | 확정 | 2026-05-01 | no |
| [F-202](./20-asset-semantics/events/F-202-payment-events-group.md) | P2 | 결제 이벤트 그룹 (Server `pay_for_*`) — 활성 1 (`pay_for_contents`) + 파생 1 (`pay_under_750`) + dead 4 | ★★★ | 확정 | 2026-05-01 | yes (dead 4건 deprecation, F-002 §3 통합) |
| [F-203](./20-asset-semantics/events/F-203-firebase-skill-onboarding-group.md) | P2 | Firebase 신규 스킬 온보딩 9 이벤트 — 양쪽 등록 활성 / 페어 규칙 일부 미준수 / Tier 1·2 | ★★ | 확정 | 2026-05-01 | (간접 ISS-015) |
| [F-204](./20-asset-semantics/events/F-204-server-operational-events.md) | P2 | 운영성 Server 이벤트 4건 — `use_attribute`/`update_attribute`/`receive_user_message` (Tier 4) + `skill_feedback_complete` (★ 결정 대기) | ★ | 확정 (1건 사용자 결정) | 2026-05-01 | yes (운영성 분류 표) |
| [F-301](./20-asset-semantics/metrics/F-301-core-metrics-overview.md) | P2 | 핵심 지표 종합 (10 도메인 × 50+ 지표) — 보존 필수 6 / 합의 필요 3 / 외부 의존 3 / KPI 알림 매핑 | ★★★ | 확정 | 2026-05-01 | no |
| [F-901](./70-migration-tiers/F-901-tier-classification.md) | P7 | dbt 마이그 Tier 분류 매트릭스 — 마트·이벤트·지표·DAG·외부 종합 + 합의 항목 4건 | ★★★ | 확정 | 2026-05-01 | (종합) |
| [F-902](./70-migration-tiers/F-902-recommended-migration-order.md) | P7 | 마이그 권장 순서 (5 Wave, 약 4~6개월) + Strangler 패턴 + 검증 전략 | ★★★ | 확정 | 2026-05-01 | (종합) |
| [F-903](./70-migration-tiers/F-903-cleanup-targets.md) | P7 | 정리 대상 종합 (MP-3) — 마트 15건 ~239 GB + dead whitelist 50 + 1차만 57 + dead 결제 4 + DAG 5 | ★★ | 확정 | 2026-05-01 | (종합) |
| [00-overview](./00-overview.md) | P7 | **As-Is 종합 + dbt 마이그 권장 순서 (시니어 1일차 압축본)** ★ 후속 프로젝트 시작 시 첫 진입 문서 | ★★★ | 확정 | 2026-05-01 | (종합) |
| [90-next-actions](./90-next-actions.md) | (인계) | **다음 액션 인계 문서** ★ 다음 세션 시작 시 첫 진입. 사용자 의도 재정의 (운영 환경 = 본질 목표) + 트랙 A·B + 다음 세션 프롬프트 + v2 인계 24~31 | ★★★ | 확정 | 2026-05-06 | (8건 추가 인계 권장) |

## 다음 세션이 이어받기

새 세션 시작 시 다음 순서로 컨텍스트 회복:

1. 워크스페이스 `CLAUDE.md` (전체 규칙)
2. 본 프로젝트 [readme.md](../readme.md) (목적·범위)
3. 본 프로젝트 [status.md](../status.md) (Phase 진행)
4. 본 프로젝트 [tasks.md](../tasks.md) (현재·다음 과업)
5. 본 README §finding 인덱스 (지금까지 발견사항)
6. 진행 중인 Phase 폴더의 가장 최근 카드

→ catalog SSOT (`common-data-airflow/docs/hellobot-data/catalog/infra-map.md`) 는 그 이후 필요 시 참조.
