# F-902 — dbt 마이그레이션 권장 순서 (leaf → root)

| 항목 | 값 |
|---|---|
| Phase | P7 |
| 중요도 | ★★★ — 후속 dbt 프로젝트 실행 순서 |
| 작성일 | 2026-05-01 |
| 출처 | F-001 다운스트림 카운트 + F-901 Tier 분류 + 카탈로그 §3 DAG 체인 |

## 0. 마이그 전략 — Strangler Pattern (점진적)

**Big-bang (한번에 모두) 비권장**. 이유:
- 마트 130+ + 외부 인터페이스 9종 동시 변경 = 위험 매우 큼
- KPI 알림 / Looker 영향 검증 부담

**Strangler 권장**:
- Tier 1·2 자산을 leaf 부터 dbt 로 점진 이식
- 한 자산이 dbt 로 옮겨지면 그 자산을 source 로 쓰던 다운스트림도 dbt 로 이동 가능
- 이중 운영 (Airflow 마트 + dbt 마트) 기간 동안 결과 비교 검증

## 1. 의존 위계 (5 계층)

```
[Layer 5] report (외부 출력 — KPI 알림, Looker)
            ↑
[Layer 4] mart_integrated (union_mart_user_key_actions = 외부 진입점)
[Layer 4] pre_report (코호트 리텐션 등)
[Layer 4] mart_adhoc (RFM, 광고 매핑)
            ↑
[Layer 3] mart (mart_use_skill_se, mart_purchase_fb, mart_user_daily_info, ...)
            ↑
[Layer 2] intermediate (intermediate_user_daily_info, intermediate_use_skill_se, ...)
            ↑
[Layer 1] staging (staging_key_events_fb/se, staging_fixed_menu_copy, ...)
            ↑
[Layer 0] sources (Firebase events_*, server_events, RDS snapshot_*, GSheet)  ← dbt source
```

**leaf = Layer 1 (staging)**, **root = Layer 5 (report 외부 출력)**.

## 2. 권장 마이그 순서 (5 Wave)

### Wave 1: 인프라 기초 + sources (1~2주)
**목표**: dbt 프로젝트 셋업 + source 정의

| 작업 | 산출 |
|---|---|
| dbt 프로젝트 초기화 (도구 결정 후) | `dbt_project.yml`, profiles |
| Layer 0 — `sources.yml` 정의 | 5 외부 input 등록 (Firebase / Server events / RDS / GSheet / Braze) |
| `KRW_PER_HEART = 150` dbt var | `dbt_project.yml` |
| 페어 규칙 + 화이트리스트 정책 dbt macro | `macros/` |

→ 이 단계까지는 데이터 변환 없음. 인프라만.

### Wave 2: Layer 1·2 — staging + intermediate (3~4주)
**목표**: 가장 안정적인 leaf 부터. 외부 영향 거의 없음.

| 우선순위 | 자산 | Tier | 비고 |
|---|---|---|---|
| 1 | `staging_fixed_menu_copy` (F-105) | Tier 1 | 메뉴 마스터, 의존 14 마트 모두 사용 → 첫 자산으로 옮기면 광범위 효과 |
| 2 | `staging_key_events_fb`, `staging_key_events_se` | Tier 1·2 | 화이트리스트 게이트키핑 + 정제 룰 보존 |
| 3 | `staging_chatbot_server`, `staging_block_copy_server` | Tier 1 | 챗봇·블록 메타 |
| 4 | 그 외 staging 11종 | Tier 1 | RDS 스냅샷 1:1 변환 |
| 5 | `intermediate_user_daily_info` (F-102) | Tier 1 | UNION + ROW_NUMBER, DAU 본진 |
| 6 | `intermediate_use_skill_se` | Tier 2 | mart_use_skill_se 직접 source |
| 7 | `intermediate_user_first_info` | Tier 1 | 가입 정보 lookup |
| 8 | 그 외 intermediate | Tier 1·2 | |

**검증 방식**: dbt 모델 결과 vs 기존 BQ 마트 결과를 같은 날짜에 비교 (`MINUS` / `EXCEPT DISTINCT`).

### Wave 3: Layer 3 — mart (3~5주)
**목표**: 분석가가 직접 쓰는 마트. KPI 알림 영향 시작.

| 우선순위 | 자산 | Tier | 위험·검증 |
|---|---|---|---|
| 1 | `mart_user_server` (F-104) | Tier 2 + 파티션 추가 | CRM optin 7 SQL 검증 |
| 2 | `mart_use_skill_se` (F-101) | Tier 2 | **★ KPI 알림 4 + 47 다운스트림 — 이중 운영 + 결과 비교 필수** |
| 3 | `mart_purchase_fb` | Tier 2 | Firebase 인앱 결제 |
| 4 | `mart_user_daily_info` | Tier 2 | DAU mart 레이어 |
| 5 | `mart_fixed_menu_server` | Tier 2 | mart_use_skill_se source |
| 6 | `mart_skill_open_date_se` | Tier 2 | 스킬 첫 등장일 |
| 7 | `mart_v2_skill_funnel_fb` | Tier 2 | v2 우선 (Tier 3 결정 후 v1 처리) |
| 8 | `mart_skill_funnel_fb` (F-103, **레거시**) | **Tier 3 결정 후** | 합의 결과 따름 |
| 9 | 그 외 mart 약 14종 | Tier 1·2 | |

**중요**: Wave 3 에서 KPI 알림이 dbt 마트를 처음 사용. **이중 운영 (기존 + dbt) 1~2주 + 일자별 결과 비교 PASS 후 컷오버**.

### Wave 4: Layer 4 — mart_integrated + pre_report + mart_adhoc (4~6주)
**목표**: 분석 진입점·코호트·RFM. **MP-1 trade-off 결정 시점**.

| 우선순위 | 자산 | Tier | 위험·결정 |
|---|---|---|---|
| 1 | `mart_integrated.union_mart_user_key_actions` (F-106) | **Tier 2 (★ MP-1 trade-off 결정 후)** | 자기참조 → `{{ this }}` + incremental, GSheet 의존 stale 검증 |
| 2 | `pre_report_cohort_retention_visit/pay/active` | Tier 2 | 코호트 산식 보존 |
| 3 | `pre_report_skill_with_manual_tagged_info` | Tier 2 | |
| 4 | `pre_report_hlb_okr_metrics_revenue` | Tier 2 | 매출 OKR (GSheet 의존) |
| 5 | `mart_adhoc.adhoc_mart_user_rfm_info_daily` | Tier 2 (보존) | RFM 12 세그먼트 enum 보존 |
| 6 | `mart_adhoc` 일별 스냅샷 (`adhoc_banner_order` 854일분 등) | **Tier 2 + MP-2** | partitioned table 통합 검토 (외부 컨슈머 확인 후) |

**중요**: Wave 4 에서 외부 분석 진입점 (`union_mart_user_key_actions`) 가 dbt 로 이동. Looker·분석가 ad-hoc 쿼리 영향 큼 → **외부 안내 + 1주 이상 이중 운영 권장**.

### Wave 5: Layer 5 — report (3~4주)
**목표**: 외부 출력 마트. KPI 알림·Looker 직접 의존.

| 그룹 | Tier | 처리 |
|---|---|---|
| `report_kpi_total_skill_*` (6) | Tier 2 | KPI 알림 (`new_purchase_user_opt_in`) 의존 |
| `report_activation_monthly_*` (3) | Tier 2 | 활성 보고 |
| `report_key_metrics_*` (7) | Tier 2 | 핵심 지표 |
| `report_revenue_*` (3) | Tier 2 | 매출 보고 |
| `report_cohort_retention_*` (10+) | Tier 2 | 코호트 리텐션 |
| `report_crm_optin_*` (7) | Tier 2 | CRM optin (Braze 의존) |
| `report_braze_crm_*` (3) | Tier 2 | Braze CRM |
| `report_skill_info_*`, `report_skill_referral_*` | Tier 1·2 | 스킬 보고 |
| `report_dashboard_ir_*` | Tier 2 | IR 대시보드 |
| `report_total_metrics_ip_*` | Tier 2 | IP 지표 |
| `tf_report.report_kpi_*` | Tier 2 | 회사 KPI (Notion 의존) |

**중요**: Wave 5 가 끝나면 dbt 가 데이터 변환 100% 담당. Airflow 는 sync (input) + 알림 (output) 만 잔존.

### Post-migration: 정리 (1~2주)
**목표**: MP-3 정리 대상 처리

[F-903 정리 대상 종합](./F-903-cleanup-targets.md) 참조:
- 마트 16건 (~239 GB)
- Dead whitelist 50건
- 1차만 등록 이벤트 57건

## 3. 검증 전략 (각 Wave 마다)

### dbt tests
```yaml
models:
  - name: mart_use_skill_se
    columns:
      - name: event_date
        tests: [not_null]
      - name: user_id
        tests: [not_null]
      - name: event_name
        tests:
          - accepted_values:
              values: [enter_skill, consume_skill, pay_for_contents,
                       pay_for_package, pay_for_coaching_program,
                       pay_for_collection, pay_for_chatbot_subscription,
                       pay_under_750]
      - name: revenue_krw
        tests: [not_null]
```

### 결과 비교 (이중 운영 동안)
```sql
-- 기존 마트 vs dbt 마트 일자별 매출 비교
SELECT event_date,
       legacy_revenue,
       dbt_revenue,
       SAFE_DIVIDE(dbt_revenue - legacy_revenue, legacy_revenue) AS diff_pct
FROM (...)
WHERE event_date BETWEEN ... AND ...
ORDER BY event_date DESC
```

→ diff < 0.1% 이면 컷오버 가능.

### 외부 의존 회귀 (Wave 3 이후)
- KPI 알림 SQL: dbt 마트로 source 변경 후 1주 이상 이중 운영
- Looker 대시보드: dbt 마트 alias 만 변경 (스키마 동일 시 자동 호환)

## 4. 추정 일정

| Wave | 기간 | 누적 |
|---|---|---|
| Wave 1 (인프라) | 1~2주 | 1~2주 |
| Wave 2 (staging + intermediate) | 3~4주 | 4~6주 |
| Wave 3 (mart) | 3~5주 | 7~11주 |
| Wave 4 (mart_integrated + pre_report) | 4~6주 | 11~17주 |
| Wave 5 (report) | 3~4주 | 14~21주 |
| Post (정리) | 1~2주 | 15~23주 |

→ **총 약 4~6개월** (단, 도구 결정·환경 셋업·외부 합의 포함).

## 5. 위험 요소·완화

| 위험 | 완화 |
|---|---|
| **자기참조 백필 위험** (`union_mart_user_key_actions` F-106) | dbt incremental + 백필 절차 명확화 + historical 보존 |
| **외부 분석 영향** (Wave 4·5) | 1주+ 이중 운영, 분석가 사전 안내, 결과 비교 |
| **KPI 알림 끊김** | 컷오버 시점 직전 1일 결과 PASS 검증 |
| **GSheet stale** | dbt source freshness test, 알림 |
| **Wave 3 의 mart_use_skill_se 변경** | KPI 알림 4 + 47 다운스트림 → 매우 신중 (Wave 3 의 핵심 자산) |
| **MP-1 trade-off 미결정** | Wave 4 진입 전 사용자 합의 필수 |

## 6. 참조

- F-901 Tier 분류표: [F-901-tier-classification.md](./F-901-tier-classification.md)
- F-903 정리 대상: [F-903-cleanup-targets.md](./F-903-cleanup-targets.md)
- F-001 다운스트림: [../10-usage-frequency/F-001-mart-downstream-map.md](../10-usage-frequency/F-001-mart-downstream-map.md)
- F-003 외부 인터페이스: [../10-usage-frequency/F-003-external-interfaces.md](../10-usage-frequency/F-003-external-interfaces.md)
