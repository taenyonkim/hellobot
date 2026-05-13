# F-105 — `hlb_staging.staging_fixed_menu_copy` 시맨틱 baseline

| 항목 | 값 |
|---|---|
| Phase | P2 |
| 중요도 | ★★ (다운스트림 14, F-001 5위) — 메뉴(스킬) 마스터 dimension |
| 상태 | 확정 |
| 작성일 | 2026-05-01 |
| 출처 | SQL 본문 + queries.py + `bq show` 실측 + F-001 raw |
| affects-ssot | yes — 카탈로그 카드 missing (tables/staging/ 디렉토리 자체 부재) + 서버 스키마 갭 (snapshot_fixed_menu.create_at 누락) |
| affects-tier | **Tier 1 후보** (그대로 이식, RDS 스냅샷 dimension) |

## 1. 자산 메타 (실측)

| 항목 | 값 |
|---|---|
| Full name | `hellobot-f445c.hlb_staging.staging_fixed_menu_copy` |
| 행 수 | **8,196** (메뉴 마스터, 작음) |
| 크기 | 13.5 MB |
| 파티션 | 없음 (dimension, partition 불필요) |
| 컬럼 수 | 50 |
| Materialization | `CREATE OR REPLACE TABLE` (전체 재생성 매일) — 추정 |
| 마지막 갱신 | 2026-05-01 (활성) |

## 2. 그레인 (1 row 의 의미)

```
1 row = 1 menu (스킬, seq 단일 키)
```

- `seq` = 메뉴 ID (RDS 는 INT, BQ 는 STRING 변환)
- `chatbot_seq` = 소속 챗봇 ID (FK)
- 8,196 rows = 현재 운영 중 + historical 메뉴 합산

## 3. 핵심 컬럼 시맨틱 (50개 — 상세)

### 식별자 (3)
| 컬럼 | 의미 |
|---|---|
| `seq` | 메뉴 ID (STRING — RDS INT 에서 cast) |
| `chatbot_seq` | 소속 챗봇 ID (STRING — RDS INT 에서 cast) |
| `name` | 메뉴 이름 |

### 기본 정보 (8)
- `image_url`, `description`, `extra_message`, `reference`, `text_count`, `data`, `new_until`, `type`

### 노출 / 판매 상태 (8)
| 컬럼 | 의미 |
|---|---|
| `is_open` | 앱 노출 여부 |
| `is_open_web` | 웹 노출 여부 |
| `visible_status` `visible_status_web` | 노출 상태 enum |
| `open_date` `open_date_web` | 오픈 예정일 |
| `is_stop_selling` | 판매 중지 |
| `show_ad` | 광고 노출 |

### 가격 (12)
| 컬럼 | 의미 |
|---|---|
| `price` `price_amount` | 정가 (하트 + KRW) |
| `discount_price` `discount_price_amount` `discount_start_date` `discount_end_date` `discount_block_seq` | 할인가 / 할인 기간 |
| `time_attack_price` `time_attack_price_amount` `time_attack_start_date` `time_attack_end_date` | 타임어택 가격 / 기간 |
| `price_currency` | 통화 (대부분 KRW) |
| `additional_discount_prices` | 추가 할인 (JSON 추정) |

### 무료 정책 (3)
- `is_free_today`, `is_free_in_app`, `is_free_in_web` (조건부 무료)

### 카드 이미지 (6)
- `card_image_url` `card_image_width` `card_image_height`
- `premium_skill_card_image_*` (3)

### 콘텐츠·검색·기타 (10)
- `html_content`, `search_score`, `targets`, `subjects`, `content_types`
- `is_recommend_outro_skill`, `policy_seq`
- `order` (정렬)
- `create_at` (가입일 — fixed_menu LEFT JOIN 으로 보강)

## 4. 비즈 룰 (보존 필수)

### 4-1. RDS Snapshot 변환 패턴
```sql
SELECT sfm.* EXCEPT(seq, chatbot_seq),
    CAST(sfm.seq AS STRING) AS seq,
    CAST(sfm.chatbot_seq AS STRING) AS chatbot_seq,
    fm.create_at AS create_at  -- snapshot 에 없어서 fixed_menu 에서 보강
FROM `hellobot-f445c.server_rdb.snapshot_fixed_menu` sfm
LEFT JOIN `hellobot-f445c.server_rdb.fixed_menu` fm ON sfm.seq = fm.seq
```

- **`seq`, `chatbot_seq` 를 INT → STRING 변환** — 다운스트림 14 마트가 STRING 으로 받음 (보존 필수)
- **`server_rdb.snapshot_fixed_menu` 와 `server_rdb.fixed_menu` 양쪽 사용** — 다음 §4-2 참조

### 4-2. ★ 서버 스키마 갭 — `snapshot_fixed_menu.create_at` 누락
SQL 본문 코멘트:
```
-- snapshot_fixed_menu 테이블엔 create_at 컬럼이 없음. fixed_menu 테이블에서 가져옴.
-- snapshot_fixed_menu 테이블에 create_at 컬럼이 누락된 것으로 보이고,
-- 서버 DB의 snapshot_fixed_menu 테이블에 create_at을 추가하는 방법이 가장 좋은 솔루션
-- 이 정보때문에 fixed_menu 테이블도 가져오게 됨
-- (snapshot_fixed_menu 테이블에 create_at 컬럼이 추가되면 fixed_menu 테이블은 필요없음)
```

- **현재 동작**: `snapshot_fixed_menu` (Glue 스냅샷) + `fixed_menu` (실시간 RDS?) 양쪽 사용
- **이상적 동작**: `snapshot_fixed_menu` 단독으로 충분 (서버팀이 `create_at` 컬럼 추가하면)
- → **외부 의존 / 서버팀 협의 필요** (P5 후보)

→ dbt 마이그 영향: 본 SQL 의 LEFT JOIN 은 보존하되, 서버 스키마 정리되면 단순화 가능.

### 4-3. 무료 정책 3종의 분리
- `is_free_today` / `is_free_in_app` / `is_free_in_web` 가 별개 컬럼
- 운영자가 각각 독립적으로 토글 가능 (앱/웹 정책 분리 + 일자별 무료 이벤트)

### 4-4. 가격 컬럼의 다중 단위
| 컬럼 | 단위 |
|---|---|
| `price`, `discount_price`, `time_attack_price` | **하트 코인 단위** |
| `price_amount`, `discount_price_amount`, `time_attack_price_amount` | **KRW 단위** |

→ 분석 시 `*_amount` 컬럼 사용 권장 (KRW 표준).

## 5. 외부·내부 의존

### 업스트림 (RDS — 외부 source)
- `hellobot-f445c.server_rdb.snapshot_fixed_menu` (AWS Glue 스냅샷, 매일)
- `hellobot-f445c.server_rdb.fixed_menu` (실시간 RDS sync 추정)

→ **둘 다 dbt 비대상** — Tier 4 (외부 input)

### 다운스트림 (14 SQL — F-001 raw 정확한 list)

| 카테고리 | 파일 | 비고 |
|---|---|---|
| **mart (9)** | `mart_ai_chatbot_fb` / `mart_exhibition_fb` / **`mart_fixed_menu_server`** / `mart_home_action_fb` / `mart_purchase_fb` / `mart_relation_fb` / `mart_skill_funnel_fb` / `mart_use_skill_se` / `mart_v2_skill_funnel_fb` | 거의 모든 mart 가 메뉴 정보 보강 의존 |
| **pre_report** | `pre_report_skill_with_manual_tagged_info` | |
| **report (3)** | `report_skill_info_{daily,mybot,origin}` | 스킬 보고 본진 |
| **staging** | `queries.py` (자체) | |

→ **메뉴(스킬) 마스터 dimension 의 진실 원천**. 변경 시 거의 모든 mart 영향.

### KPI 알림 직접 의존
없음 (간접만 — 본 마트가 mart 경유 후 KPI 알림으로 흐름).

## 6. dbt 마이그 가이드

### 6-1. Tier 분류 권장: **Tier 1 (그대로 이식)**

| 평가 축 | 결과 |
|---|---|
| 시맨틱 명확도 | 명확 (RDS 스냅샷 1:1 + cast) |
| 의존 단순도 | 매우 단순 (RDS 2 테이블) |
| 외부 인터페이스 | 간접 (mart 9 → KPI) |
| 시맨틱 변경 가치 (MP-2) | 낮음 (서버 스키마 정리되면 SQL 단순화) |

### 6-2. dbt 모델 설정 권장

```yaml
{{ config(
    materialized='table',  # 작은 dimension, 매일 전체 재생성
) }}

-- dbt source 등록
sources:
  - name: server_rdb
    tables:
      - name: snapshot_fixed_menu
      - name: fixed_menu  # 서버 스키마 정리 후 제거 가능
```

### 6-3. 보존 필수 항목

- 50 컬럼 이름·타입 (특히 `seq`/`chatbot_seq` STRING 표준)
- INT → STRING 변환 (다운스트림 14 의존)
- `create_at` 보강 위한 LEFT JOIN (서버 스키마 갭 해결 전까지)

### 6-4. 개선 후보 (MP-2)

| # | 개선안 | 영향 | 가치 vs 부담 |
|---|---|---|---|
| 1 | **서버 `snapshot_fixed_menu.create_at` 추가 요청** (서버팀 협의) | LEFT JOIN 제거, SQL 단순화 | 가치 高 / 부담 中 (서버팀 작업) |
| 2 | `additional_discount_prices` JSON STRING → STRUCT 변환 | 분석 편의 | 가치 中 / 부담 中 (다운스트림 grep) |
| 3 | dbt source freshness test (스냅샷이 2일+ 옛날이면 알림) | 데이터 품질 | 가치 中 / 부담 低 |
| 4 | `*_date` STRING 컬럼들 → DATE 변환 (`new_until`, `open_date`, `discount_*_date`, `time_attack_*_date`) | 타입 정확성 | 가치 中 / 부담 中 (다운스트림 사용 패턴 확인) |

### 6-5. 위험 요소

- **서버 스키마 갭** (`snapshot_fixed_menu.create_at`): 본 SQL 의 LEFT JOIN 의존성 — 서버팀과 미협의 시 영구 잔존
- **STRING ↔ INT 캐스팅**: 본 마트가 STRING 으로 변환했는데 다운스트림 일부 SQL 이 INT 가정으로 비교하면 implicit cast 비용 ↑
- **`additional_discount_prices` 가 JSON STRING**: 파싱 부담 (mart 안에서 JSON 추출 보류 추정)

## 7. 답할 수 있는·없는 질문

### 답할 수 있는
- 메뉴 마스터 정보 (이름·가격·이미지·정책)
- 노출 상태 (`is_open` / `is_open_web`)
- 무료 정책 분포
- 메뉴별 가격 분포·할인 패턴

### 답할 수 없는 (다른 마트 필요)
| 필요 | 가야 할 곳 |
|---|---|
| 메뉴 사용량·매출 | `mart_use_skill_se` (본 마트와 조인) |
| 메뉴 평가 | `mart_fixed_menu_evaluation_server` |
| 메뉴 첫 등장일 | `mart_skill_open_date_se` |

## 8. 후속 액션

- [x] 본 카드 작성 (2026-05-01)
- [ ] **(★ v2 인계 추가)** `tables/staging/` 디렉토리 + `staging_fixed_menu_copy.md` 카드 신설 (현재 missing — staging 17개 테이블 카드 모두 부재)
- [ ] **(P5 외부)** 서버 `snapshot_fixed_menu.create_at` 추가 요청 (서버팀 협의)
- [ ] (P7) Tier 1 — 후속 dbt 프로젝트에서 적용

## 참조

- SQL: [scripts/hellobot/staging/staging_fixed_menu_copy.sql](../../../../../common-data-airflow/dags/scripts/hellobot/staging/staging_fixed_menu_copy.sql)
- 다운스트림 14 list: [F-001-data-mart-downstream.tsv](../../10-usage-frequency/F-001-data-mart-downstream.tsv)
