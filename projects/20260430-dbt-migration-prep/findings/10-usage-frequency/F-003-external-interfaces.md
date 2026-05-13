# F-003 — 외부 인터페이스 매트릭스 (dbt 비대상 영역)

| 항목 | 값 |
|---|---|
| Phase | P1 |
| 중요도 | ★★★ (MP-1 trade-off 결정의 직접 인풋) |
| 상태 | 확정 (코드 grep 범위 내) — Looker 메타는 외부확인필요 |
| 작성일 | 2026-04-30 |
| 출처 | `dags/hlb_dags/**/*.py` + `dags/scripts/hellobot/**/*.{py,sql}` 정규식 grep (slack/notion/looker/braze/google_sheet/email_ses/s3/bq_extract) |
| affects-ssot | yes — KPI 알림 채널 매핑 + 외부 인터페이스 표가 카탈로그 미반영 (v2 인계 후보) |
| affects-tier | **Tier 4 (Airflow 잔존) 의 1차 인풋** — dbt 가 못 가져가는 출력 알림 / 입력 ETL |

## 발견 / 사실

### 1. 외부 인터페이스 4종 (출력) + 5종 (입력)

#### 출력 (BQ → 외부)

| 인터페이스 | 코드 위치 | 어떻게 연결 | 본 분석 발견 건수 |
|---|---|---|---|
| **Slack 실패 알림** (#데이터-장애알림) | 모든 hlb_dags 의 `on_failure_callback` (`scripts/etc/slack_alert.py`) | DAG 단위 자동 (CLAUDE.md 명시) | 51 hlb files |
| **Slack KPI 알림** (4개 팀 채널) | `dags/scripts/hellobot/kpi_noti/hlb_kpi_noti_func.py` + `dags/hlb_dags/hlb_kpi_noti.py` | `send_success_message_to_slack(channel_id, text)` | KPI 5종, 채널 3개 |
| **Notion KPI** | (hellobot 영역 외) `dags/tf_dags/thingsflow_krafton_kpi_to_notion.py` | `notion_client.NotionClient` | hellobot 자산 직접 grep 0건 — tf_report 경유 추정 |
| **Hackle 대시보드** | `dags/scripts/hellobot/hackle_dashboard_2023_func.py` (1건) | BQ extract → Hackle? — 별도 확인 필요 | 1 file |
| **Looker Studio 대시보드** | (코드 외 — 외부 메타) | BQ 직접 쿼리 (Looker SA 권한) | 코드 grep 0건 ([infra-map §갭](../../../../common-data-airflow/docs/hellobot-data/catalog/infra-map.md)) |

#### 입력 (외부 → BQ)

| 인터페이스 | 데이터셋 / 테이블 | 메커니즘 | 코드 위치 |
|---|---|---|---|
| **Firebase GA4** | `analytics_164027297.events_*` (일별), `events_intraday_*` | Firebase 자동 BQ export | (인프라 설정, 코드 외) |
| **서버 이벤트** | `analytics_164027297.server_events` | 서버가 BQ 에 직접 INSERT | (서버 코드, 본 리포 외) |
| **RDS Snapshot (AWS Glue)** | `server_rdb.snapshot_*` | `hellobot_glue_job_scripts.py` + `hellobot_snapshot_to_bigquery.py` DAG | 2 hellobot files |
| **GSheet sync** | `google_sheet_sync.*`, `hlb_staging.staging_currency_rate_sheet` | `hellobot_sync_google_sheet.py` DAG (`hellobot_datamart_staging_pipeline` 의 한 단계) | 1 DAG + 11 SQL 사용처 |
| **Braze Export** | `hellobot_braze.*` | Braze 자동 BQ export (Braze → BQ) | 7 hellobot files (input 측) |
| **Manual** | `manual_server_rdb.product` | 운영자 수동 업로드 | (수동, 코드 외) |

### 2. Slack KPI 알림 — 채널·소스 마트 매핑 (보존 필수)

`hlb_kpi_noti.py` DAG 가 매일 5개 함수를 트리거하여 3개 Slack 채널로 KPI 알림을 보낸다. 각 함수는 BQ 마트를 읽어 텍스트를 만든다.

#### 채널 매핑

| 채널 ID | 채널명 (코드 코멘트) | KPI 함수 | 수신팀 |
|---|---|---|---|
| `C06QV5555A7` | `#div_chatbot_biz` | `send_kpi_noti_fs_chatbot_team`, `send_kpi_noti_chatbot_imc_team`, `send_kpi_noti_chatbot_product_team`, `send_kpi_noti_ns_chatbot_team` | FS 챗봇팀 / IMC실 / Product팀 / NS 챗봇팀 (4팀 모두 동일 채널) |
| `C06A9JZRNH1` | `#team_ops-maximize` | `send_kpi_noti_maxmize_operating_team` | 운영 Maximize팀 |
| `C02HMRP42QM` | (코멘트 없음) | (별도 함수 1건 — 분류 미상) | 분류 미상 |

→ **채널 ID 가 코드 하드코드** — 채널 변경 시 코드 수정 필요. dbt 마이그 시 채널 매핑을 그대로 보존하거나 dbt-alerts 패턴으로 옮겨야 함.

#### 소스 마트 (KPI 알림이 깨지면 안되는 자산)

| 소스 마트 | KPI 함수 | 보존 강도 |
|---|---|---|
| `hlb_mart_integrated.union_mart_user_key_actions` | LTV (`get_hlb_monthly_ltv`) | ★★★ 직접 외부 출력 의존 |
| `hlb_report.report_kpi_total_skill_monthly` / `_weekly` | opt-in (`new_purchase_user_opt_in`) | ★★★ |
| `hlb_mart.mart_fixed_menu_server` | 신규 스킬 (`hlb_fs_new_skill_counts`, `hlb_fs_new_skill_pay_amounts`) | ★★★ |
| `hlb_mart.mart_use_skill_se` | 결제액 (`hlb_fs_new_skill_pay_amounts`, `hlb_fs_new_skill_total_pay_amounts`, `hlb_marketing_contribution_margins`) | ★★★ (이미 F-001 1위) |
| `hlb_mart_integrated.union_mart_user_key_actions` | LTV 계산 + 다수 KPI | ★★★ |
| (그 외 다수 — `kpi_noti/queries.py` 직접 확인 필요) | | |

→ **MP-1 trade-off 의 직접 인풋**: KPI Slack 알림은 외부(팀 직접 수신) 인터페이스라 마트 컬럼 변경 시 알림 SQL 도 같이 수정해야 함. dbt 마이그 시:
- 옵션 A (보존): 마트 스키마·컬럼 그대로 유지하고 알림 SQL 그대로 → 보존 부담 적음
- 옵션 B (재구축): 마트 스키마 개선 + 알림 SQL 도 재작성 → 한꺼번에 처리 시 가능

### 3. GSheet 사용 마트 (입력 측, 11 SQL 위치)

GSheet 데이터 (`google_sheet_sync.*`) 를 직접 사용하는 SQL:

| SQL | GSheet 사용 용도 |
|---|---|
| `mart/mart_use_skill_se.sql` | (코멘트 확인 필요) — 매출 정합 |
| `mart_adhoc/adhoc_mart_user_key_actions_for_targeting.sql` | 타겟팅 기준 |
| `mart_integrated/union_mart_use_skill_from_exhibition_page.sql` | 전시 페이지 매핑 |
| `mart_integrated/union_mart_user_key_actions.sql` | 본진 마트 — GSheet 의존 |
| `pre_report/pre_report_skill_with_manual_tagged_info.sql` | 수동 태깅 정보 |
| `staging/staging_chatbot_server.sql` | 챗봇 메타 보강 |
| `tf_report/report_kpi_daily.sql`, `_quarterly.sql` | tf_report 영역 (회사 KPI) |
| `mart/mart_use_skill_se.sql` | 광고매출·환율 |
| `kpi_noti/queries.py` | KPI 알림 (마케팅 ROAS 광고매출) |
| `staging_pipeline DAG` | 동기화 트리거 |

→ **dbt source 등록 후 ref 를 통해 사용**. GSheet → BQ 동기화는 Tier 4 (Airflow 잔존). 마트 안에서의 사용은 Tier 1·2.

### 4. Braze 단방향 (input only)

`hellobot_braze.*` 에서 BQ 로 자동 export. **Braze 로 데이터 보내는 코드는 hellobot 영역에 없음** — `report_braze_crm_*` 마트는 reporting 용 (CRM 캠페인 통계) 이고 캠페인 발사는 Braze 자체 또는 별도 시스템.

| 자산 | 처리 |
|---|---|
| `hellobot_braze.*` (input) | dbt source 로 등록만 |
| `hlb_report.report_braze_crm_daily/weekly/monthly` (output) | 일반 dbt 모델로 마이그 가능 |

### 5. 외부 인터페이스 우선순위 (보존 강도)

| 인터페이스 | 보존 강도 | 이유 | dbt 마이그 처리 |
|---|---|---|---|
| Firebase GA4 input | ★★★ | dbt 가 owning 못함, 자동 export | dbt source 등록 |
| Server events input | ★★★ | 동일 | dbt source 등록 |
| RDS snapshot input | ★★★ | 매일 스냅샷, AWS Glue 의존 | dbt source 등록, sync DAG 잔존 |
| GSheet input | ★★ | 마케팅 ROAS·환율 — 운영자 수동 갱신 | dbt source, sync DAG 잔존 |
| Braze input | ★★ | CRM 분석에 핵심 | dbt source 등록 |
| **Slack KPI 알림** | **★★★** | 직접 사람 수신 — 깨지면 KPI 보고 중단 | **dbt-alerts 또는 Airflow 잔존 (옵션)** |
| **Slack 실패 알림** | ★★★ | 운영 안정성 | DAG 단위 보존 (Airflow 잔존) |
| Notion KPI | (hellobot 영역 외) | tf_report 경유 | 본 프로젝트 범위 외 |
| Looker Studio | ★★ ~ ★★★ | 메타 부재로 영향 추정 어려움 | **MP-1 trade-off 핵심** — 메타 export 후 결정 |
| Hackle 대시보드 | ★ | 1건 BQ extract — 사용 빈도·중요도 미상 | 별도 확인 |

## dbt 마이그 영향

### Tier 4 후보 (Airflow 잔존)

다음은 dbt 가 가져갈 수 없거나 가져갈 가치 적은 영역:

1. **모든 입력 ETL** — Firebase/Server events/RDS/GSheet/Braze sync. dbt 는 source 만 등록.
2. **Slack 알림 DAG** — `hlb_kpi_noti.py` + `on_failure_callback` 패턴. dbt 안에 dbt-alerts/dbt-checks 로 옮기면 일부 가능하지만 **Airflow 잔존이 안전**.
3. **Hackle dashboard extract** — 1건, 본 분석 범위 외.

### MP-1 trade-off 결정 트리거

본 finding 이 baseline 카드 작성 시 직접 활용되는 자산 매핑:

| 마트 | 외부 직접 의존 | MP-1 결정 권장 |
|---|---|---|
| `mart_use_skill_se` | KPI 알림 + (Looker 추정) | **보존 권장** — 변경 시 알림 SQL + Looker 재작성 부담 큼 |
| `union_mart_user_key_actions` | LTV 알림 + KPI + (Looker 추정) | **보존 권장** — 본진 자산, 외부 분석 진입점 |
| `report_kpi_total_skill_*` | KPI opt-in 알림 | **보존 권장** — KPI 알림 직결 |
| `mart_fixed_menu_server` | KPI 알림 + 다수 마트 의존 (F-001 9위) | **보존 권장** |
| `report_braze_crm_*` | (외부 출력 없음, 단순 reporting) | **재구축 가능** — 보존 부담 낮음 |
| sparse / dead 자산 | (없음) | **정리 대상 (MP-3)** |

### 외부 인터페이스가 없는 자산은 자유

다운스트림 카운트가 높지만 외부 인터페이스 없는 자산 (예: `intermediate_user_daily_info`) 은 내부 SQL 만 영향 받음 → dbt 마이그 시 시맨틱 보존 + naming 개선 자유도 높음 (MP-2 적용 용이).

## 후속 액션

- [ ] **`kpi_noti/queries.py` 전체 SQL 파싱 — 모든 KPI 함수의 소스 마트 매핑** — Phase: P2 (시맨틱 baseline 카드 작성 시)
- [ ] **`C02HMRP42QM` 채널 정체 확인 (사용자)** — KPI 알림 1건이 코멘트 없이 사용. 어떤 KPI 가 어디로 가는지 확정 필요
- [ ] **Looker Studio 메타 export 권한 확인 (외부확인필요)** — Looker SA 의 BQ 쿼리 이력 또는 Looker 자체 메타 export 가능한지. 가능하면 별도 finding 으로 자산-대시보드 매핑
- [ ] **Hackle 대시보드 정체 확인** — `hackle_dashboard_2023_func.py` 가 어디에 데이터 보내는지 (외부확인필요)
- [ ] **GSheet sync 시트 매핑** — `hellobot_sync_google_sheet.py` 가 어떤 GSheet 와 sync 하는지 (시트 ID·범위 코드 확인)
- [ ] **★ KPI 알림 채널 매핑 + 외부 인터페이스 표 SSOT 반영 (v2 인계 후보)** — 카탈로그 `architecture.md §4 데이터 소스` 다음에 `§4-2 외부 출력` 신설. KPI 알림 매핑 + Looker (확인 시) + Notion (tf_report 경유) 명시.

## 참조

- F-001 핵심 자산 (KPI 알림 의존): [F-001-mart-downstream-map.md](./F-001-mart-downstream-map.md)
- F-004 정리 대상 (외부 인터페이스 없는 자산): [F-004-orphan-and-dead-marts.md](./F-004-orphan-and-dead-marts.md)
