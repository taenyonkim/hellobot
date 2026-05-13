# P1 회고 — 사용 빈도 인벤토리 (4 finding 종합)

| 항목 | 값 |
|---|---|
| Phase | P1 (완료) |
| 작성일 | 2026-04-30 |
| 산출 finding | F-001, F-002, F-003, F-004 (+ raw CSV 6개) |
| BQ 누적 스캔 | ~370 MB (~$0.002) |
| 다음 단계 | P2 (자산 시맨틱 baseline) — F-001/F-002 의 핵심 자산을 baseline 카드로 |

본 카드는 P1 4 finding 의 **종합 시각** + **P2 진입 시 즉시 활용 가능한 핵심 추출**.

## 1. 인프라 As-Is 1줄 요약

```
HelloBot 데이터 인프라 = Airflow + BigQuery 5계층 (staging → intermediate → mart → mart_integrated → report)
                       + queries.py 가 destination 진실원천 (SQL 파일은 SELECT 만)
                       + 화이트리스트 3중 게이트 (1차 events_list = 의도 / 2차 fb·se_events_list = 실효)
                       + Slack 알림이 가장 큰 외부 출력 (Looker는 메타 부재)
```

## 2. dbt 마이그 1순위 자산 (Top 5 — 시맨틱 baseline 카드 작성 대상)

| 마트 | 다운스트림 | KPI 알림 | 보존 강도 | P2 baseline 우선순위 |
|---|---|---|---|---|
| `hlb_mart.mart_use_skill_se` | **47** | ★ 직접 의존 | ★★★ | 1순위 (스킬 + 매출 본진) |
| `hlb_intermediate.intermediate_user_daily_info` | 26 | ★ (DAU) | ★★★ | 2순위 (DAU 본진) |
| `hlb_mart.mart_skill_funnel_fb` | 23 | (Looker 추정) | ★★★ | 3순위 |
| `hlb_mart.mart_user_server` | 17 | - | ★★ | 4순위 |
| `hlb_staging.staging_fixed_menu_copy` | 14 | (메뉴 디멘전) | ★★ | 5순위 (디멘전) |
| `hlb_mart_integrated.union_mart_user_key_actions` | 2 (내부) | ★ LTV | ★★★ | **외부 진입점** — 별도 시각으로 baseline |

## 3. 정리 대상 (MP-3) — Tier 4 비대상

### 마트 자산 16건 (~239 GB)

본 프로젝트 종료 시점에 사용자 일괄 검토:
- `union_mart_user_key_actions2` 199 GB (사용자 확인 정리)
- `mart_v2_skill_funnel_fb_with_tag_info` 19.6 GB
- `intermediate_v2_mart_funnel_fb` 14.1 GB
- `pre_report_cohort_retention_visit` (hlb_report 분류 오류) 5.2 GB
- 그 외 12건 (~1 GB)

상세: [F-004 §6](./F-004-orphan-and-dead-marts.md#6-dead--orphan-정리-후보-dbt-마이그-비대상)

### 이벤트 화이트리스트 50건

Dead whitelist (등록 but 7일 raw 0건). 카테고리:
- 챗봇 구독 8건 / 관계 7건 / 일일 운세 4건 / 컬렉션·랜덤박스 6건 / 스킬 리워드 4건 / 결제 옵션 3건 등

상세: [F-002 §3](./F-002-event-usage-frequency.md#3-dead-whitelist-50건-정리-후보-mp-3)

### 1차만 등록 이벤트 57건

events_list 1차 게이트만 등록 → staging 도달 못함 (실효 없음). Option A (정리) vs Option B (2차 추가) 결정 필요.

## 4. 외부확인필요 항목 8건

| 항목 | 출처 | 영향 |
|---|---|---|
| `union_mart_user_key_actions2` 정체 | F-004 §5 | **해결 (2026-04-30 정리 대상 확정)** |
| `C02HMRP42QM` Slack 채널 정체 | F-003 §2 | KPI 알림 매핑 완성 |
| Looker Studio 메타 export 가능 여부 | F-003 §1 | MP-1 trade-off 정확도 |
| Hackle 대시보드 출력 정체 | F-003 §1 | dbt 영향 평가 |
| GSheet sync 시트 매핑 | F-003 §3 | dbt source 등록 청사진 |
| mart_adhoc 일별 스냅샷 외부 컨슈머 | F-004 §8 | partitioned table 통합 가능 여부 (MP-2) |
| 1차만 등록 이벤트 57건 처리 | F-002 §2 | 정리 vs 2차 추가 |
| 미등록 고볼륨 이벤트 ~10건 분류 | F-002 §4 | 누락 vs 의도된 미등록 |
| Dead whitelist 50건 카테고리별 검토 | F-002 §3 | MP-3 정리 |

## 5. 발견된 카탈로그 SSOT 갱신 후보 (v2 인계 대기) 12건

### 시스템 패턴

1. **`queries.py` 가 destination 진실원천** — `architecture.md §5` 박스 신설 (F-004 §1 발견)
2. **화이트리스트 3중 구조 실효 — 1차 events_list 비활성** — `architecture.md §5` 또는 `event-catalog.md §2` (F-002 §1)
3. **외부 출력 (Slack KPI 알림) 표 신설** — `architecture.md §4-2` (F-003 §2)

### 자산 정정

4. **`union_mart_user_key_actions` 위치 명료화** ("분석 본진" → "외부 분석 진입점") — `infra-map §핵심 테이블 10선` (F-001 §3)
5. **계층별 인벤토리 정합성 표 신설** — `infra-map` 또는 `architecture.md` (F-001 §4)
6. **`hlb_staging.staging_currency_rate_sheet` GSheet sync 명문화** — `architecture.md §4 데이터 소스` (F-004 §4)
7. **`hlb_report` 데이터셋 분류 정합성 (`pre_report_*` 11건 잘못 분류 의심)** — `mart-catalog.md` (F-001 §6)

### 이슈

8. **ISS-014 실측 검증 정량 추가** (1차만 57 / 2차만 39) — `issues.md ISS-014` (F-002 §1)
9. **dead whitelist 50건 deprecation 표기** — `event-catalog.md` (F-002 §3)

### 정책

10. **dbt 마이그 정책 MP-1·MP-2·MP-3 명문화** — `recipes/dbt-migration-policy.md` 또는 `architecture.md` (사용자 발화)
11. **핵심 테이블 10선 우선순위 갱신** (다운스트림 카운트 기준) — `infra-map §핵심 테이블 10선` (F-001 §2)

### 신규 갭

12. **mart_adhoc 일별 스냅샷 안티패턴 표기** — `mart-catalog.md` (F-004 §8)

## 6. P2 진입 권장 — 자산 시맨틱 baseline

P1 결과로 baseline 카드 작성 우선순위가 명확해졌다.

### P2 작업 순서 권장

1. **본진 5건 baseline** (F-001 Top 5 + `union_mart_user_key_actions`)
   - 그레인·NULL 의미·암묵 가정 + KPI 알림 의존 컬럼 명시
   - 카탈로그 `tables/{레이어}/{table}.md` 가 있는 자산은 정보 압축 + dbt 마이그 시 보존 항목 명시
2. **이벤트 baseline** (활성 12건)
   - `enter_skill`, `consume_skill`, `pay_for_contents`, `view_skill_feedback` 등
   - 페어 규칙 (ISS-015), 발송 시점, 파라미터
3. **지표 baseline** (도메인 10종 중 사용 빈도 상위)
   - `revenue_krw`, DAU, ARPPU, 코호트 리텐션 등 산식
4. **MP-2 적용 후보 식별** — 시맨틱 변경이 가치 있는 자산 (예: mart_adhoc 일별 스냅샷)

### P3~P6 보강 시점

P2 baseline 작성 도중 정보 부족이 명확해지는 시점에 P3 (lineage)·P4 (staging 변환)·P5 (외부 의존)·P6 (historical) 진입.

→ **P2 → P3 → P7 흐름 권장** (사용자와 협의).

### P7 마이그 Tier 분류 — P2 직후 가능

P1 + P2 산출 시점에 다음 4 Tier 로 자산 분류 가능:
- Tier 1 (그대로 이식): 시맨틱 명확 + 의존 단순
- Tier 2 (보존하며 재구현): 보존 부담 vs 가치 평가
- Tier 3 (재정의 + 합의): 모호한 자산 (P2 baseline 카드의 "개선 후보" 영역)
- Tier 4 (Airflow 잔존 또는 정리): F-004 + F-002 dead whitelist + 1차만 등록 이벤트

## 7. 본 프로젝트 의 산출 형태 확정 (사용자 발화 반영)

본 프로젝트의 최종 산출은 다음 2 축:

```
A. dbt 마이그 인풋
   ├ Tier 1·2 자산 (보존 또는 재구현) — P2 baseline 카드
   ├ Tier 3 자산 (재정의 + 합의 필요) — P2 의 "개선 후보" 영역
   └ Tier 4 비대상 (Airflow 잔존 + 외부 source)

B. 정리 대상 (MP-3)
   ├ 마트 16건 (~239 GB)
   ├ 이벤트 dead whitelist 50건
   ├ 1차만 등록 이벤트 57건
   └ orphan SQL·Python 등 추후 발견
```

후속 dbt 프로젝트는 **A. 마이그 인풋** 만 받아 진행. **B. 정리 대상** 은 본 프로젝트 종료 시점 또는 후속 dbt 프로젝트 직전에 일괄 처리.

## 다음 액션

P2 진입 가능 — 사용자 결정:

1. P2 (자산 시맨틱 baseline) 즉시 진입?
2. 그 전에 §4 외부확인필요 8건 중 일부 사용자 확인 후 진입? (특히 미등록 고볼륨 이벤트 → P2 의 이벤트 baseline 정확도에 영향)
3. SSOT 인계 12건 중 일부 v2 즉시 인계? (주로 P2 baseline 작성 후가 자연스러우나 정책 박스 1·2·3 은 즉시 가능)
