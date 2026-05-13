# mart_skill_open_date_se

> 스킬별 **로그 상 첫 등장 날짜**. 서버 DB의 "오픈 날짜"와 다를 수 있음 (실제 사용자에게 노출된 첫 날).

## 개요

- **Full name**: `hellobot-f445c.hlb_mart.mart_skill_open_date_se`
- **그레인**: 스킬(menu_seq) 단위 — 1행 = 1 menu_seq
- **파티션**: *없음* (디멘션 성격)
- **머티리얼라이제이션**: `CREATE OR REPLACE TABLE`
- **스케줄**: 매일 1회

## 설명

`mart_use_skill_se` 전체 이력에서 `menu_seq` 별로 가장 오래된 이벤트 1건을 선택. 서버 DB의 `fixed_menu.create_at_date` 컬럼과 값이 다를 수 있는 이유는 "서버에 등록만 되고 사용자 노출은 뒤늦게 열린" 스킬이 존재하기 때문.

## 업스트림

- `hlb_mart.mart_use_skill_se` (유일한 소스) — **같은 mart 레이어 참조** ([ISS-003](../.././issues.md))

## 다운스트림

- `hlb_mart_integrated.union_mart_user_key_actions` (`open_date` 컬럼 조인)

## 컬럼

`mart_use_skill_se` 의 컬럼 서브셋 (가장 오래된 1행):

- `event_date` — **로그 상 첫 등장일** (= `open_date` 역할)
- `event_month` / `event_week` / `start_of_week` / `end_of_week`
- `chatbot_seq` / `chatbot_name` / `chatbot_category`
- `menu_seq` (**PK, not_null**) / `menu_name`
- `block_seq` / `block_name`
- `locale`

## 답할 수 있는 질문

- 스킬이 실제로 처음 사용된 날짜 (로그 기준)
- 월별/주별 신규 오픈 스킬 수
- 카테고리별 스킬 오픈 빈도 추이

## 답할 수 없는 질문

| 필요 분석 | 가야 할 테이블 |
|---|---|
| 스킬 서버 생성일 (운영 관점) | `mart_fixed_menu_server.menu_create_at_date` |
| 스킬의 전체 사용 이력 | `mart_use_skill_se` |

## 주의사항

### 레이어 위반 (ISS-003)
- mart 레이어인데 **같은 mart 레이어**의 `mart_use_skill_se` 를 참조
- dbt 이식 시 `intermediate` 또는 `marts/base/` 로 재배치 제안

### 테스트 기간 이벤트 주의
- 테스트 환경에서 발생한 이벤트도 포함되어 `event_date` 가 실제 공개일보다 빠를 수 있음
- `mart_use_skill_se` 는 테스터 제외 필터가 staging 단에서 이미 적용되어 있으므로 영향은 제한적

## dbt 이식 매핑

```
현재 경로        scripts/hellobot/mart/mart_skill_open_date_se.sql
dbt 경로        models/intermediate/hellobot/int_skill_open_date.sql (레이어 재배치 권장)
materialized    table (디멘션, 일별 전체 치환)
```
