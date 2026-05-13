# 외부 데이터 사이언티스트 핸드오버 패키지

> 외부 데이터 사이언티스트에게 HelloBot 데이터 분석 의뢰 시 BigQuery 조회 권한과 함께 전달할 자료 패키지.
>
> **시작일**: 2026-05-11
> **상태**: 초안 완료
> **유형**: 산출물 패키지 (외부 전달용)

## 배경 / 목적

외부 데이터 사이언티스트에게 헬로우봇의 데이터 분석을 의뢰. BigQuery 프로젝트 조회권한 부여와 함께 빠르게 데이터 구성을 파악하고 분석을 시작할 수 있도록 외부 전달용 문서 패키지를 준비.

**핵심 원칙**: 외부에 노출되어서는 안되는 내부 운영 정보(개인 계정, SA 키 경로, 내부 SSH, 운영자 식별자, 내부 PR/이슈 URL 등)를 제외.

## 패키지 위치

```
package/   ← 이 폴더만 외부 전달
```

## 외부 전달 시 체크리스트

전달 전 의뢰자가 직접 확인:

- [ ] 외부 분석가의 Google 계정에 IAM 권한 부여 완료
  - **권한 레벨**: `BigQuery Data Viewer` + `BigQuery Job User`
  - **대상 데이터셋**: `hlb_mart`, `hlb_mart_integrated`, `hlb_mart_adhoc`, `hlb_staging`, `hlb_intermediate`, `hellobot_braze`, `google_sheet_sync`, `server_rdb`, `analytics_164027297`
  - **GCP 프로젝트**: `hellobot-f445c`
  - 분석 범위에 따라 일부 데이터셋만 부여 가능
- [ ] 외부 분석가에게 본 `package/` 디렉토리 전체 전달 (zip / 공유 폴더 / Notion 등)
- [ ] NDA / 데이터 사용 범위·기간 합의 (별도 절차)
- [ ] 의뢰자가 분석가의 첫 쿼리·접근 정상 동작 확인 (`bq ls` 등)

## 패키지 구성

| 파일 / 디렉토리 | 종류 | 출처 |
|---|---|---|
| `package/README.md` | 신규 작성 | 외부 분석가용 진입점 |
| `package/01-getting-started.md` | 신규 작성 | BQ 접근 셋업 (내부 SA 키 경로 등 제외) |
| `package/02-conventions-quick-ref.md` | 신규 작성 | 결정적 컨벤션 요약 |
| `package/03-known-caveats.md` | 신규 작성 | 데이터 품질 함정 (분석가에 유효한 것만) |
| `package/04-query-guide.md` | 신규 작성 | BQ 쿼리 안전·비용 규칙 |
| `package/10-infra-map.md` | 복사 | `common-data-airflow/docs/hellobot-data/catalog/infra-map.md` |
| `package/11-architecture.md` | 복사 + 1줄 sanitize | 동일 catalog/architecture.md (운영자 식별자 일반화) |
| `package/20-mart-catalog.md` | 복사 | catalog/mart-catalog.md |
| `package/21-event-catalog.md` | 복사 + sanitize | 운영자 식별자 일반화 |
| `package/22-metric-dictionary.md` | 복사 | catalog/metric-dictionary.md |
| `package/23-tables/` | 복사 | catalog/tables/{mart,mart_integrated,mart_adhoc}/ |
| `package/30-top-asset-deep-dives/` | prep findings 발췌 (sanitize) | 카탈로그 갭 보강 (intermediate_user_daily_info / mart_user_server / mart_skill_funnel_fb_legacy / staging_fixed_menu_copy / core-metrics-overview) |

## 제외한 문서

| 제외 문서 | 사유 |
|---|---|
| `catalog/bq-access.md` | 내부 SA 키 경로·개인 OAuth 계정·내부 IAM 절차 |
| `catalog/issues.md` | 내부 약점 전수. 분석가에 유효한 함정만 추려 `03-known-caveats.md` 로 |
| `catalog/external-tasks.md` | 내부 TBD·운영자 인터뷰 항목 |
| `catalog/playbook.md` | 내부 개발 워크플로 (신규 마트 추가 등) |
| `catalog/recipes/*` | 내부 개발 레시피 (이벤트 등록 절차 등) |
| `catalog/_templates/*` | 내부 사용자 입력 템플릿 |
| `catalog/scope-union-*.md` | 과거 프로젝트 scope 정의 |
| `docs/hellobot-data/tables/` | deprecated (실제 SQL 불일치) |
| `projects/20260430-dbt-migration-prep/findings/` 의 F-001 ~ F-004 | 내부 사용 통계·정리 전략 |
| 동 prep findings F-901 ~ F-903, 90-next-actions | 내부 dbt 마이그 전략·후속 액션 |
| 동 prep findings raw CSV/TSV | 내부 분석 산출물 |
| `common-data-airflow/CLAUDE.md`, 워크스페이스 `CLAUDE.md` | 내부 에이전트 운영 룰 |
| 워크스페이스 `projects/*/` 전반 | 내부 프로젝트 진행 정보 |

## Sanitization 내역

복사한 카탈로그 파일에 다음 항목을 일반화:

1. `21-event-catalog.md` — 운영자 이름 → "운영자" 일반화 (3건)
2. `11-architecture.md` §4-2 — `taenyon (본인)` → "데이터팀 운영자" (1건)
3. `23-tables/mart_integrated/union_mart_user_key_actions.md` — "사용자(taenyon) 관리" → "운영자 직접 관리" (1건)
4. `30-top-asset-deep-dives/intermediate_user_daily_info.md` — Slack 채널 ID `C06QV5555A7` 제거, "챗봇 프로덕트팀 Slack 채널"로 일반화
5. `30-top-asset-deep-dives/*.md` 5건 — 상단에 외부 전달용 안내 추가 + 내부 metadata row(`affects-tier`, `affects-ssot`) 제거 + "dbt 마이그 가이드" 섹션 절단 + `intermediate_user_daily_info.md` 의 "## 0. 카탈로그 갭" 섹션 제거

> 참고: `taenyon_*` 으로 시작하는 BQ 테이블명 자체 (예: `google_sheet_sync.taenyon_temp_skill_tag_info_v2`) 는 실제 BQ 자원이므로 보존. 분석가가 쿼리 중 마주칠 명칭이라 사실대로 알려야 함.

`ISS-NNN` 형식 내부 이슈 ID 는 다수 잔존하지만 `issues.md` 가 패키지에 포함되지 않아 의미 없는 마커가 됩니다. 각 prep 카드 상단의 disclaimer 에서 이를 무시하라고 안내. 카탈로그 파일들의 ISS 링크는 클릭 시 404 — 분석가에게 의미 있는 정보는 본문 텍스트로 이미 충분히 설명됨.

## 후속 액션 (필요 시)

- [ ] 패키지를 zip 으로 묶거나 Notion/공유 폴더에 업로드 후 외부 분석가에게 전달
- [ ] 분석가에게 의뢰 범위 / 기간 / 분석 산출물 형식 공유 (별도 합의)
- [ ] 의뢰 진행 중 분석가의 추가 자료 요청이 있으면 본 패키지에 보강 (예: 특정 도메인 깊이 자료)
- [ ] 분석 종료 시 권한 회수
