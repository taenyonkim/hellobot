# F-001 — 마트 다운스트림 카운트 (내부 SQL 의존 인벤토리)

| 항목 | 값 |
|---|---|
| Phase | P1 |
| 중요도 | ★★★ |
| 상태 | 확정 (내부 SQL 범위) |
| 작성일 | 2026-04-30 |
| 출처 | `common-data-airflow/dags/scripts/hellobot/**/*.{sql,py}` 정적 분석 (regex grep, 자기 참조 제외, 파일 단위 dedup) |
| affects-ssot | yes — 카탈로그 핵심 테이블 10선 우선순위 재정렬 가치 (v2 §신규 과업 후보) |
| affects-tier | Tier 1·2 후보 식별의 1차 입력 |

## 발견 / 사실

### 1. DAG 파일은 테이블을 직접 참조하지 않는다 — 0건

`dags/hlb_dags/**/*.py` 전수 grep 결과 `hlb_*.<table>` 패턴 매치 0건. DAG 는 순수 오케스트레이션 (`TriggerDagRunOperator` + `PythonOperator`). 모든 테이블 참조는 `dags/scripts/hellobot/{layer}/*.sql` (또는 `queries.py` 안의 SQL 문자열) 안에 있다.

→ **dbt 마이그 시 의존 분석의 진실 원천 = SQL 파일 grep**. DAG 는 마이그 후에도 dbt 모델을 트리거하는 얇은 레이어로 잔존 가능 (Tier 4 잔존).

### 2. 의존 핫스팟 — Top 5

| 순위 | 테이블 | 다운스트림 파일 수 | 총 등장 횟수 | 본진 |
|---|---|---|---|---|
| 1 | `hlb_mart.mart_use_skill_se` | **47** | **148** | 매출/스킬 사용 |
| 2 | `hlb_intermediate.intermediate_user_daily_info` | 26 | 52 | DAU/리텐션 |
| 3 | `hlb_mart.mart_skill_funnel_fb` | 23 | 66 | 스킬 퍼널 |
| 4 | `hlb_mart.mart_user_server` | 17 | 17 | 사용자 마스터 |
| 5 | `hlb_staging.staging_fixed_menu_copy` | 14 | 14 | 메뉴 메타 디멘전 |

`mart_use_skill_se` 가 압도적 1위. 매출·결제·스킬 분석의 본진. 하나의 변경이 47개 다운스트림에 파급된다 — dbt 마이그 시 **시맨틱 보존 1순위**.

### 3. `union_mart_user_key_actions` 위치 재정의 필요 ★★

| | |
|---|---|
| 카탈로그 표현 | "**사용자 분석 본진**, 분석의 진입점" (infra-map §핵심 테이블 10선) |
| 실측 다운스트림 | **2개 파일** — `mart_integrated/queries.py` + `mart_integrated/union_mart_use_skill_and_user_daily.sql` |
| 함의 | **외부(Looker / ad-hoc 분석가) 가 주 사용자**. 내부 파이프라인에서는 hub 가 아니라 leaf |

→ dbt 마이그 시 **외부 인터페이스 호환성(컬럼·이름·그레인) 보존이 권장**. 단 [MP-1](../../readme.md#마이그-정책--2026-04-30-사용자-확정) 정책상 보존 부담이 가치보다 크면 새 마트 + 대시보드 새로 구축 옵션도 가능. 내부 의존성 보존 부담은 거의 없으므로 **Tier 1 (그대로 이식) vs Tier 2 (보존하며 재구현) 후보** — 후속 P2 baseline 카드에서 trade-off 평가.

→ 카탈로그 SSOT 갱신 가치: "분석 진입점" 의미를 명시 (현재는 단순 "분석 본진" 표현 — 외부/내부 혼재로 오해 가능). v2 §신규 과업 후보.

### 4. 계층별 인벤토리 정합성

| 레이어 | BQ 테이블 | SQL 파일 (destination) | 참조됨 | SQL 있는데 0 ref | SQL 없는 BQ |
|---|---|---|---|---|---|
| `hlb_staging` | 17 | 11 | 11 | 0 | **6** |
| `hlb_intermediate` | 25 | 21 | 21 | 0 | **4** |
| `hlb_mart` | 24 | 22 | 22 | 0 | **2** |
| `hlb_mart_integrated` | 7 | 5 | 5 | 0 | **2** |
| `hlb_mart_adhoc` | 200 | 7 | 5 | **2** | 200 (대부분 일별 스냅샷 누적) |
| `hlb_pre_report` | 8 | 5 | 5 | 0 | **3** |
| `hlb_report` | 64 | 54 | 43 | 0 | **11** |
| `tf_report` | 2 | 2 | 0 | **2** | 0 |

해석:
- **"SQL 있는데 0 ref" 컬럼**: 파이프라인이 만들지만 다른 SQL 이 안 쓰는 마트 = **외부(Looker/ad-hoc) 전용 자산** 또는 **dead artifact**. 별도 검증 필요.
- **"SQL 없는 BQ" 컬럼**: SQL 파일 없이 BQ 에 존재 = **외부 source / 운영자 수동 / deprecated / orphan**. F-004 (sparse) 와 P3 (lineage) 에서 추적.

### 5. 다운스트림 0인 destination 마트

| 마트 | 추정 사용처 |
|---|---|
| `hlb_mart_adhoc.adhoc_banner_order` | Looker / 광고 운영팀 ad-hoc — 일별 스냅샷 (854 일분) |
| `hlb_mart_adhoc.adhoc_home_section_order` | Looker / 홈 운영 — 일별 스냅샷 (848 일분) |
| `hlb_report.*` 11개 | 일부는 코호트·KPI 알림 SQL 의 destination — 외부 컨슈머(Slack 알림·Notion·Looker) 직결 후보 |
| `tf_report.report_kpi_daily/quarterly` | 회사 전체 KPI — Notion·Slack 직결 |

→ dbt 마이그에서 이 자산들은 **외부 인터페이스 보존이 곧 호환성** — Tier 1·2 의 1차 후보. 단 [MP-1](../../readme.md#마이그-정책--2026-04-30-사용자-확정) 에 따라 보존 부담 평가 후 새로 짓는 옵션도 가능 (특히 일별 스냅샷 누적 854 일분이 정말 모두 살아있어야 하는지 검토 가치).

### 6. SQL 없이 BQ 에만 존재하는 자산 (요주의)

다음은 파이프라인 SQL 으로 만들어지지 않는 BQ 테이블 — 외부 sync, 운영자 수동, historical, 또는 SQL 위치가 다른 곳일 가능성.

| 데이터셋 | 테이블 | 추정 |
|---|---|---|
| `hlb_staging` | `events_list`, `staging_key_events_fb_events_list`, `staging_key_events_se_events_list` | **이벤트 화이트리스트 — 운영자 수동 INSERT** (카탈로그 §2 + ISS-011 해결과 일치) |
| `hlb_staging` | `staging_currency_rate_sheet` | GSheet sync |
| `hlb_staging` | `staging_original_chatbot_list` | historical / 외부 |
| `hlb_staging` | `staging_utm_sources_to_except` | 운영 룰 데이터 |
| `hlb_intermediate` | `intermediate_ir_dashboard_metrics_fb`, `intermediate_randombox_metrics_fb`, `intermediate_user_recent_info`, `intermediate_v2_mart_funnel_fb` | **orphan 의심 — P3 lineage 에서 추적** |
| `hlb_mart` | `mart_user_server_types_list`, `mart_web_to_app_install` | orphan 의심 |
| `hlb_mart_integrated` | `mart_v2_skill_funnel_fb_with_tag_info`, `union_mart_user_key_actions2` | **`union_mart_user_key_actions2` 는 v2 후보? — historical 확인 필요** |
| `hlb_pre_report` | `pre_report_skill_with_manual_tagged_info_{20231026,20231103,20240409}` | 일자 스냅샷 — historical |
| `hlb_report` | `pre_report_cohort_retention_visit` (←hlb_pre_report 와 중복?), `pre_report_user_revenue_info` (←분류 오류?), `report_cohort_retention_active_weekly_app_{saju,tarot}`, `report_cohort_retention_pay_daily_{app,web}`, `report_cohort_retention_visit_by_monthly`, `report_cohort_retention_visit_by_platform_monthly`, `report_crm_optin_new`, `report_dashboard_randombox`, `report_kpi_onboarding_newuser_weekly` | **데이터셋 분류 모호 + historical 변종 다수 — P3 에서 추적** |

→ 본 cluster 는 **F-004 (sparse mart) + P3 (lineage)** 의 인풋.

## 근거

### 정적 분석 방법

```python
# scripts/hellobot/{staging,intermediate,mart,mart_integrated,mart_adhoc,pre_report,report,tf_report,kpi_noti}/*.{sql,py}
# regex: hlb_(staging|intermediate|mart|mart_integrated|mart_adhoc|pre_report|report)\.[a-zA-Z_][a-zA-Z0-9_]*
# 자기 참조 제외 — file_basename == 매치된 table 이면 skip
# 파일 단위 dedup — 한 파일이 같은 테이블을 N번 참조해도 file count = 1
# 별도 mentions 컬럼으로 raw count 도 보관
```

- `dags/hlb_dags/**/*.py` 동일 정규식 적용 — **0건** (Python DAG 가 SQL 텍스트를 직접 갖고있지 않다는 사실 검증)
- 결과 TSV: 임시 `/tmp/mart_downstream.tsv` (135 unique tables — staging~report 전 계층)

### 자기 참조 제외의 영향

자기 참조 (예: `mart_use_skill_se.sql` 안에서 incremental insert 위해 자기 자신을 SELECT) 를 제외해서, 결과는 "**다른 자산의 의존**" 만 카운트한다. 이게 dbt 마이그 우선순위 신호로 더 정확.

### 한계 (외부 의존)

본 카운트는 **`common-data-airflow` 리포 내부** 만 본다. 다음은 보지 못함:
- Looker Studio 대시보드 의존 (별도 메타 export 필요)
- 다른 사용자의 BQ ad-hoc 쿼리 빈도 (`INFORMATION_SCHEMA.JOBS_BY_PROJECT` 권한 확인 + 비용 검토 후 별도)
- `tf_dags/`, `btw_dags/`, `stp_dags/` (다른 서비스) 의 hellobot 마트 참조 — 본 분석 범위 외

→ 외부 사용도는 **F-003 (report·외부 인터페이스 인벤토리)** 와 후속 ad-hoc 으로 보강 필요.

## dbt 마이그 영향

### 마이그 우선순위 신호

| 시그널 | 해석 | Tier 후보 |
|---|---|---|
| Top 5 (47~14 다운스트림) | **변경 시 파급 최대** — 시맨틱 보존 필수 | Tier 2 (보존하며 재구현) — dbt naming/tests/incremental 적용 |
| 6~30위 (10~4) | 도메인 핵심 자산 | Tier 1 (그대로 이식) 또는 Tier 2 |
| 다운스트림 1~3 | 의존성 단순, leaf 후보 | Tier 1 |
| 다운스트림 0 (외부 전용) | 외부 인터페이스 보존이 곧 호환성 | Tier 1 (스키마 동일 유지) |
| SQL 없이 BQ 에만 | 외부 source / orphan | Tier 4 (Airflow/외부 잔존) 또는 정리 후보 |

### 마이그 순서 가이드

dbt 모델 의존 그래프는 leaf → root 가 안전. 다운스트림 카운트가 높은 = root 쪽이고, 낮은 = leaf 쪽이다. 따라서 **다운스트림 카운트 낮은 마트부터 dbt 모델로 옮기고** root (mart_use_skill_se 등) 를 마지막에 옮기는 것이 안전. 단 root 가 너무 늦어지면 dbt 가치를 못 누리므로, **root 를 가장 먼저 보존 카드(P2 시맨틱 baseline) 로 작성** 한 뒤 의존 그래프 leaf 부터 옮기되 root 까지의 시점을 미리 잡는 전략.

## 후속 액션

- [ ] **F-002 — 이벤트 사용 빈도** (P1) 작성 — 이벤트 발화량 + staging 살아남는 비율
- [ ] **F-003 — 외부 인터페이스 (Slack·Looker·Notion) 인벤토리** (P1) — 본 카드의 "다운스트림 0" 자산이 어디로 가는지 매핑
- [ ] **F-004 — sparse mart / orphan** (P1) — 본 카드의 §6 (SQL 없이 BQ 에만) 자산을 카탈로그 검증
- [ ] **카탈로그 갱신 가치 (v2 인계 후보)**:
  - `union_mart_user_key_actions` 의 "분석 진입점 vs 내부 hub" 표현 명료화 (infra-map §핵심 테이블 10선)
  - `hlb_report` 데이터셋 안의 `pre_report_*` 항목 = 분류 오류? (정합성 검증 필요)
  - `union_mart_user_key_actions2` 의 정체 — historical / v2 후보 / deprecated?
- [ ] **P3 lineage 에서 추적**: §6 의 "SQL 없이 BQ 에만" 자산 11+개

## 참조 데이터

전체 다운스트림 표 (135 tables): `/tmp/mart_downstream.tsv` (세션 종료 시 휘발 — 영구 저장 필요 시 본 폴더로 카피).

다음 분석에 또 쓸 가능성이 있어 본 finding 카드 작성 후 영구 저장 권장 — 후속 액션에서 결정.
