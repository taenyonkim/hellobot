# F-004 — Orphan / Dead / 외부 자산 분류 (Tier 4 인풋)

| 항목 | 값 |
|---|---|
| Phase | P1 |
| 중요도 | ★★ (Tier 4 인풋) |
| 상태 | 확정 (메타데이터 검증 완료 + 사용자 확인 완료 2026-04-30) |
| 작성일 | 2026-04-30 (Mystery 1건 dead 분류 갱신: 2026-04-30 사용자 확인) |
| 출처 | (1) F-001 §5·§6 의심 자산 41건 / (2) common-data-airflow 전체 코드 grep / (3) `bq show` 메타데이터 (lastModifiedTime, numRows, numBytes) — 비용 X (메타만) |
| affects-ssot | yes — `queries.py 가 destination 의 진실원천` 룰 + 정리 정책 후보 (v2 인계) |
| affects-tier | **Tier 4 (Airflow 잔존 / 정리 / historical) 의 1차 인풋** |

## 핵심 사실 (선결)

### 1. `queries.py` 가 destination 의 진실원천 — F-001 §6 의 절반은 false alarm

| | |
|---|---|
| 이전 추론 (F-001) | "SQL 파일 == destination" → 31건이 orphan 의심 |
| **검증 결과** | **`{layer}/queries.py` 안의 SQL string 이 `INSERT INTO` / `CREATE TABLE` 의 진짜 destination**. SQL 파일은 SELECT 본문만 담는 분리 패턴 |
| 함의 | F-001 §6 의 31건 중 일부는 SQL 파일이 없을 뿐 queries.py 에 있는 활성 자산 |

**검증한 실제 케이스**:
- `intermediate_ir_dashboard_metrics_fb` — `intermediate/queries.py` 에 destination — **활성**
- `intermediate_randombox_metrics_fb` — `intermediate/queries.py` 에 destination — **활성**
- `report_crm_optin_new` — `report/queries.py` 에 destination — **활성**
- 그 외 `hlb_report` 의 24개 테이블 — queries.py 가 destination

→ **F-001 §6 의 정확한 분류는 본 카드 §3·§4 표 참조**.

→ SSOT 갱신 가치 (v2 인계 후보): catalog/architecture.md §파이프라인 패턴 또는 §5 공통 규약에 **"SQL 파일 = SELECT 본문 / queries.py = destination + DDL"** 명문화 필요.

## 발견 / 사실

### 2. 검증 매트릭스 — 41건 자산의 정확한 분류

검증 차원:
- (a) 어디서 만들어지나? — `queries.py` / `*_func.py` / 외부 / 어디에도 없음
- (b) BQ 메타데이터 — lastModifiedTime, numRows, numBytes
- (c) 분류: **활성 / 외부 source / dead / historical 스냅샷 / mystery**

### 3. 활성 (queries.py 또는 *_func.py 에 destination 있음 — F-001 §6 의 false alarm)

| 자산 | last_modified | 비고 |
|---|---|---|
| `hlb_intermediate.intermediate_ir_dashboard_metrics_fb` | (활성) | queries.py |
| `hlb_intermediate.intermediate_randombox_metrics_fb` | (활성) | queries.py |
| `hlb_report.report_crm_optin_new` | (활성) | queries.py |

→ **Tier 1·2 후보** (사용 빈도에 따라). F-001 의 다운스트림 카운트 재계산 시 이 3건은 활성으로 처리.

### 4. 외부 source / 운영자 수동 (Tier 4: dbt 비대상, Airflow 잔존)

| 자산 | 근거 | 카테고리 |
|---|---|---|
| `hlb_staging.events_list` | 운영자 수동 INSERT (카탈로그 ISS-011 해결) | 이벤트 화이트리스트 1차 |
| `hlb_staging.staging_key_events_fb_events_list` | 동일 | Firebase 화이트리스트 2차 |
| `hlb_staging.staging_key_events_se_events_list` | 동일 | 서버 화이트리스트 |
| `hlb_staging.staging_currency_rate_sheet` | `pre_report_hlb_okr_metrics_revenue.sql` 에서 사용. GSheet sync 추정 | GSheet sync |
| `hlb_staging.staging_original_chatbot_list` | `staging_chatbot_server.sql` 에서 LEFT JOIN. 외부 source | 외부 source |
| `hlb_staging.staging_utm_sources_to_except` | 4개 SQL 에서 사용. 운영 룰 (마케팅 제외 도메인) — 운영자 수동 추정 | 운영 룰 데이터 |

→ **Tier 4 (Airflow 잔존)**. dbt 마이그 시 dbt source 로 등록만 하고 변환 안함.

→ SSOT 갱신 가치: `staging_currency_rate_sheet` 가 어떻게 sync 되는지 카탈로그 §데이터 소스 표에 미반영 (`google_sheet_sync.*` 와 다른 데이터셋 — `hlb_staging` 안에 있는데 원천이 GSheet). 외부 확인 필요.

### 5. ~~★★★ Mystery active~~ → **Dead 확정 (2026-04-30 사용자 확인)**

`hlb_mart_integrated.union_mart_user_key_actions2` 는 **유지하지 않아도 되는 테이블** 임이 사용자 발화로 확인됨 (2026-04-30). §6 dead 표에 합류.

| 항목 | 값 | 기존 가설 |
|---|---|---|
| 데이터셋 | `hlb_mart_integrated.union_mart_user_key_actions2` | |
| last_modified | 2026-04-07 | "활성" 으로 의심됨 |
| rows | 265,136,901 (2.65억) | 본진과 비교 가능한 규모 → 본진의 v2 후보 추정 |
| bytes | **199 GB** | dbt 마이그 핵심 자산 가능성 추정 |
| 코드 grep | 0 hits | 외부 노트북/Colab 추정 |
| **사용자 확인 결과** | **유지 불필요 (정리 대상)** | 가설 모두 기각 |

→ **§6 dead 표의 가장 큰 1건 (199 GB)** 으로 합류. 정리 대상에 추가.

→ "최근 갱신 ≠ 활성" 의 교훈: lastModifiedTime 만으로 활성 판단하지 말 것. 외부확인 가치가 항상 있음. 본 finding 카드의 1차 보고가 정리 후보로의 사용자 확인을 끌어낸 경로.

### 6. Dead / orphan (정리 후보, dbt 마이그 비대상)

기준: lastModifiedTime ≥ 6개월 전 (오늘 = 2026-04-30) + 코드 흔적 없음 + (또는) 사용자 확인.

| 자산 | last_modified | 미사용 일수 | rows | size | 추정 |
|---|---|---|---|---|---|
| **`hlb_mart_integrated.union_mart_user_key_actions2`** | **2026-04-07** | (활성 갱신중이나 사용자 확인 결과 정리 대상) | **265M** | **199.5 GB** ★ | 본진의 v2 실험 잔재 — 사용자 확인 (2026-04-30) |
| `hlb_intermediate.intermediate_v2_mart_funnel_fb` | 2023-10-23 | **919일** | 56.9M | **14.1 GB** | v1→v2 전환 잔재 (현재 사용중인 건 `intermediate_v2_skill_funnel_fb`) |
| `hlb_mart.mart_web_to_app_install` | 2024-11-28 | 518일 | 981K | 226 MB | 1회성 분석 잔재 추정 |
| ~~`hlb_mart.mart_user_server_types_list`~~ | ~~2023-05-09~~ | (정정 — F-104 분석 결과 활성 dimension) | 6 | 0 MB | ~~types 디멘전, mart_user_server.sql 에서 FROM 으로만 사용~~ → **활성 dimension** — `mart_user_server.sql` 의 cross join 의존 (사용자 type whitelist), type 이 거의 안 변해서 미수정. dead 아님. |
| `hlb_mart_integrated.mart_v2_skill_funnel_fb_with_tag_info` | 2024-09-05 | 602일 | 53.2M | **19.6 GB** | v2 skill funnel 의 tag info 결합 — 사용 흔적 없음 |
| `hlb_pre_report.pre_report_user_revenue_info` | (data error / empty) | - | - | - | 빈 테이블 또는 drop 됨 |
| `hlb_report.pre_report_cohort_retention_visit` | 2023-11-28 | 884일 | 38.8M | 5.2 GB | hlb_pre_report 의 동명과 별개. 잘못된 데이터셋 분류 또는 historical |
| `hlb_report.pre_report_user_revenue_info` | 2023-10-10 | 932일 | 817K | 54 MB | 동일 — 잘못된 데이터셋 분류 |
| `hlb_report.report_cohort_retention_active_weekly_app_saju` | 2024-11-21 | 525일 | 11K | 0.6 MB | 스킬별 historical (사주) |
| `hlb_report.report_cohort_retention_active_weekly_app_tarot` | 2024-11-21 | 525일 | 11K | 0.6 MB | 스킬별 historical (타로) |
| `hlb_report.report_cohort_retention_pay_daily_app` | 2023-11-02 | 910일 | **0** | 0 MB | empty (drop 후보) |
| `hlb_report.report_cohort_retention_pay_daily_web` | 2023-11-02 | 910일 | 1.7K | 0.1 MB | dead |
| `hlb_report.report_cohort_retention_visit_by_monthly` | 2024-11-08 | 538일 | 253 | 0 MB | dead |
| `hlb_report.report_cohort_retention_visit_by_platform_monthly` | 2024-11-08 | 538일 | 506 | 0 MB | dead |
| `hlb_report.report_dashboard_randombox` | 2023-08-31 | 973일 | 364 | 0 MB | dead |
| `hlb_report.report_kpi_onboarding_newuser_weekly` | 2024-03-25 | 766일 | 169 | 0 MB | dead — storyplay 쪽 동명만 사용 |

**합계 정리 후보**: ~~**16건**~~ → **15건** (F-104 정정으로 `mart_user_server_types_list` 활성 분류 이동). 누적 size = **약 239 GB**:
- `union_mart_user_key_actions2` 199 GB (★ 가장 큰 1건, 사용자 확인 정리 대상)
- `mart_v2_skill_funnel_fb_with_tag_info` 19.6 GB
- `intermediate_v2_mart_funnel_fb` 14.1 GB
- `pre_report_cohort_retention_visit` (hlb_report) 5.2 GB
- 그 외 합계 ~1 GB

→ **Tier 4 (정리 후보)** — dbt 마이그에서 옮기지 않음. 정리 시점은 후속 dbt 마이그 시작 직전 또는 본 프로젝트 종료 시점에 사용자 결정.

### 7. Historical 스냅샷 (보존, marker)

| 자산 | 비고 |
|---|---|
| `hlb_pre_report.pre_report_skill_with_manual_tagged_info_20231026` | 일자 스냅샷, 7,581 rows |
| `hlb_pre_report.pre_report_skill_with_manual_tagged_info_20231103` | 7,639 rows |
| `hlb_pre_report.pre_report_skill_with_manual_tagged_info_20240409` | 8,536 rows |

→ historical 보존. dbt 마이그 비대상. **현재 활성 자산은 `pre_report_skill_with_manual_tagged_info` (suffix 없음)**.

### 8. mart_adhoc 일별 스냅샷 누적 (854 + 848)

`adhoc_banner_order` (854 일분) / `adhoc_home_section_order` (848 일분) — `mart_adhoc/queries.py` 가 매일 새 스냅샷 테이블을 만든다.

| | |
|---|---|
| **누적 size** | 미측정 (별도 ls + sum 필요) — 추정 수 GB ~ 수십 GB |
| dbt 마이그 시 처리 | dbt 모델은 incremental 또는 partitioned table 패턴이 자연 — 일자 별 새 테이블 분기는 dbt 안티패턴 |
| 권장 | dbt 마이그 시 단일 partitioned table 로 통합 (MP-2 적용 — 더 나은 구조) |

→ **Tier 2 (보존하며 재구현)** — 단 구조 변경 (MP-2). 외부 컨슈머가 일자별 테이블을 직접 참조하지 않는다면 (Looker view 의 wildcard 일 가능성 큼) 안전하게 통합 가능.

→ 외부확인필요: 일자별 테이블을 직접 참조하는 외부 사용처 있는지 (Looker SQL / 분석가 ad-hoc).

## 근거

### 코드 grep 방법

```python
# common-data-airflow 전체 (568 files: .sql .py .yaml .json .md)
# 각 의심 테이블 이름을 word boundary 정규식으로 검색
# 결과:
#  - 0 hits (entire repo)        → orphan
#  - hits in queries.py (DML)    → 활성
#  - hits in *_func.py           → 함수 안에서 다른 테이블 만들 때 참조 — 검증 필요
#  - hits in scripts/storyplay/  → cross-service false positive 가능 (워드 매치)
```

### BQ 메타데이터 (메타만, 비용 X)

```bash
bq show --format=prettyjson hellobot-f445c:hlb_*.<table>
# lastModifiedTime, numRows, numBytes, creationTime 추출
```

세션 누적 BQ 스캔: **0 GB** (모든 조회는 메타데이터). 기록.

## dbt 마이그 영향

### Tier 4 (dbt 비대상) 1차 인풋

| 카테고리 | 건수 | 처리 방식 |
|---|---|---|
| 외부 source / 운영자 수동 | 6 | dbt source 등록만, 변환 없음 |
| **Dead / orphan / 정리 대상** | **16** | 정리 후보, 마이그 비대상 (`union_mart_user_key_actions2` 199 GB 포함) |
| Historical 스냅샷 | 3 | 보존, 마이그 비대상 |

### 3건 자산 정정 (F-001 다운스트림 카운트 표)

다음 3건은 F-001 §6 에서 "SQL 없이 BQ 만" 으로 분류되었으나 실제로는 활성 — 다운스트림 카운트 재계산 시 활성으로 처리 권장:
- `intermediate_ir_dashboard_metrics_fb`
- `intermediate_randombox_metrics_fb`
- `report_crm_optin_new`

### MP-1 / MP-2 적용 권장

| 자산군 | MP 적용 |
|---|---|
| mart_adhoc 일별 스냅샷 (854/848 일분) | **MP-2 적용** — partitioned table 로 통합. 더 나은 구조 |
| dead/orphan 15건 | 마이그 옵션 외 — 정리 |
| `union_mart_user_key_actions2` | MP-1 적용 — 정체 확인 후 보존 vs 새 마트 결정 |

## 후속 액션

- [x] **`union_mart_user_key_actions2` 정체 확인** — 사용자 확인 (2026-04-30): **유지 불필요, 정리 대상**. §5·§6 갱신 완료
- [ ] **F-001 §6 표 정정** — 3건 활성으로 정정 + 본 카드 cross-link
- [ ] **`queries.py` destination 룰 SSOT 반영** (v2 인계 후보)
  - 위치: `catalog/architecture.md §5 공통 규약` 또는 `§3 DAG 체인` 인근에 신설
  - 내용: "SQL 파일 = SELECT 본문 / `{layer}/queries.py` 의 SQL 문자열 = destination DDL/DML 의 진실원천"
- [ ] **mart_adhoc 일별 스냅푰 외부 컨슈머 확인** — Looker SQL 직접 참조 여부 (외부확인필요)
- [ ] **정리 후보 15건 삭제 정책 결정** — 본 프로젝트 종료 시점 또는 dbt 마이그 시작 시점에 사용자 결정
- [ ] **`hlb_staging.staging_currency_rate_sheet` 출처 명문화** (v2 인계 후보) — 카탈로그 §데이터 소스 표에 GSheet sync 명시

## 참조

- F-001 §5·§6 (의심 자산 출처): [F-001-mart-downstream-map.md](./F-001-mart-downstream-map.md)
- BQ 메타데이터 raw 출력은 본 카드 §6 표에 체화 (별도 TSV 미작성)
