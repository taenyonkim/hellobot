# HelloBot 데이터 인프라 — 외부 분석가용 핸드오버 패키지

> 본 패키지는 외부 데이터 사이언티스트가 HelloBot 서비스의 데이터 분석을 시작할 때 필요한 정보를 한 곳에 모은 자료입니다.
>
> **작성일**: 2026-05-11
> **대상**: 외부 협력 데이터 사이언티스트
> **포함 범위**: BigQuery 접근 → 데이터 구조 파악 → 핵심 마트·이벤트·지표 정의

---

## 0. 가장 먼저 읽을 것 (15분)

1. **[01-getting-started.md](./01-getting-started.md)** — BigQuery 접근 셋업 + 첫 쿼리 (5분)
2. **[10-infra-map.md](./10-infra-map.md)** — 데이터 인프라 1페이지 지도 (3분)
3. **[02-conventions-quick-ref.md](./02-conventions-quick-ref.md)** — 결정적 컨벤션 (시간대, user_id, 매출 정의 등) (5분)
4. **[03-known-caveats.md](./03-known-caveats.md)** — 분석 시 주의할 함정 (2분)

이 4개만 읽으면 **기본 쿼리 작성 가능** 상태가 됩니다. 깊이는 필요할 때 아래 참조 문서로 진입.

---

## 1. 문서 인벤토리

### 📍 시작 · 접근

| 문서 | 역할 | 우선도 |
|---|---|---|
| [README.md](./README.md) (본 파일) | 진입점 · 인벤토리 | ★ |
| [01-getting-started.md](./01-getting-started.md) | BigQuery 접근 셋업, IAM, 첫 쿼리 | ★★★ |
| [04-query-guide.md](./04-query-guide.md) | BigQuery 쿼리 안전 규칙 (파티션 · 비용) | ★★★ |

### 🗺 전체 그림

| 문서 | 역할 | 우선도 |
|---|---|---|
| [10-infra-map.md](./10-infra-map.md) | 1페이지 지도 — 레이어 · 핵심 테이블 · 이벤트 그룹 · 지표 도메인 | ★★★ |
| [11-architecture.md](./11-architecture.md) | 파이프라인 전체 아키텍처 (수집 → 가공 → 활용) | ★★ |
| [02-conventions-quick-ref.md](./02-conventions-quick-ref.md) | 시간대, 사용자 ID, 매출 정의 등 결정적 컨벤션 요약 | ★★★ |
| [03-known-caveats.md](./03-known-caveats.md) | 분석 시 주의할 함정 · 데이터 품질 갭 | ★★ |

### 📚 상세 카탈로그

| 문서 | 역할 | 우선도 |
|---|---|---|
| [20-mart-catalog.md](./20-mart-catalog.md) | 마트 인벤토리 (레이어별 인덱스) | ★★ |
| [21-event-catalog.md](./21-event-catalog.md) | Firebase · 서버 이벤트 전수 + 게이트키핑 정책 | ★★ |
| [22-metric-dictionary.md](./22-metric-dictionary.md) | 지표 정의 · 계산식 · 소스 (10 도메인) | ★★★ |
| [23-tables/](./23-tables/) | 테이블별 상세 (컬럼 · lineage · 그레인) | ★★ (필요 시) |

### 🔎 Top 자산 상세 분석 (보강 자료)

| 문서 | 역할 | 우선도 |
|---|---|---|
| [30-top-asset-deep-dives/intermediate_user_daily_info.md](./30-top-asset-deep-dives/intermediate_user_daily_info.md) | DAU 본진 (다운스트림 26) | ★★ |
| [30-top-asset-deep-dives/mart_user_server.md](./30-top-asset-deep-dives/mart_user_server.md) | 사용자 마스터 + CRM 본진 | ★★ |
| [30-top-asset-deep-dives/mart_skill_funnel_fb_legacy.md](./30-top-asset-deep-dives/mart_skill_funnel_fb_legacy.md) | 스킬 퍼널 v1 (레거시이지만 활성) | ★ |
| [30-top-asset-deep-dives/staging_fixed_menu_copy.md](./30-top-asset-deep-dives/staging_fixed_menu_copy.md) | 스킬(메뉴) 마스터 dimension | ★★ |
| [30-top-asset-deep-dives/core-metrics-overview.md](./30-top-asset-deep-dives/core-metrics-overview.md) | 핵심 지표 보존/합의/외부 의존 분류 | ★★ |

> 위 5개는 정식 카탈로그(`23-tables/`)에 카드가 누락된 자산을 보강하기 위한 내부 분석 산출물입니다. 본문에 "Tier 1~4", "dbt 마이그", "F-NNN" 등 내부 마커가 있으나 무시하셔도 됩니다. **그레인 · 컬럼 · 비즈 룰** 정보만 참고용으로 활용하세요. 각 문서 상단에 같은 안내가 있습니다.

---

## 2. 추천 학습 순서 (1~2일차)

```
Day 1 — 인프라 파악
  ├ 09:00  01-getting-started.md     ← gcloud / bq CLI 셋업
  ├ 10:00  10-infra-map.md           ← 전체 지도 (3분)
  ├ 10:30  02-conventions-quick-ref  ← 컨벤션 (5분)
  ├ 11:00  04-query-guide.md         ← 안전 쿼리 패턴
  ├ 11:30  ★ 첫 쿼리: DAU 조회 (mart_user_daily_info)
  ├ 14:00  11-architecture.md        ← 파이프라인 흐름
  ├ 15:00  03-known-caveats.md       ← 함정 인지
  └ 16:00  22-metric-dictionary.md   ← 지표 정의 훑기

Day 2 — 도메인 깊이
  ├ 09:00  21-event-catalog.md       ← 이벤트 스펙
  ├ 11:00  20-mart-catalog.md        ← 마트 인벤토리
  ├ 14:00  23-tables/ 의 Top 자산    ← 분석 본진 깊이 파악
  │        (union_mart_user_key_actions, mart_use_skill_se,
  │         mart_user_daily_info, mart_purchase_fb)
  └ 16:00  30-top-asset-deep-dives/  ← 카탈로그 갭 보강 자료
```

---

## 3. 핵심 자산 Top 10 (분석 진입점)

| # | 자산 | 그레인 | 본진 용도 | 카탈로그 |
|---|---|---|---|---|
| 1 | `hlb_mart_integrated.union_mart_user_key_actions` | event | 사용자 분석 본진 — 방문·스킬·결제 UNION | [📄](./23-tables/mart_integrated/union_mart_user_key_actions.md) |
| 2 | `hlb_intermediate.intermediate_user_daily_info` | user×date | DAU 본진 | [📄](./30-top-asset-deep-dives/intermediate_user_daily_info.md) |
| 3 | `hlb_mart.mart_use_skill_se` | event | 매출 정합 기준 (서버 스킬·결제) | [📄](./23-tables/mart/mart_use_skill_se.md) |
| 4 | `hlb_mart.mart_user_daily_info` | user×date | DAU·리텐션·신규/기존 분기 | [📄](./23-tables/mart/mart_user_daily_info.md) |
| 5 | `hlb_mart.mart_user_server` | user | 사용자 마스터 + CRM | [📄](./30-top-asset-deep-dives/mart_user_server.md) |
| 6 | `hlb_mart.mart_purchase_fb` | transaction | Firebase 스토어 인앱 결제 | [📄](./23-tables/mart/mart_purchase_fb.md) |
| 7 | `hlb_mart.mart_fixed_menu_server` | menu | 스킬(메뉴) 메타 마스터 | [📄](./23-tables/mart/mart_fixed_menu_server.md) |
| 8 | `hlb_mart.mart_home_action_fb` | event | 홈 배너·섹션·탭 액션 | [📄](./23-tables/mart/mart_home_action_fb.md) |
| 9 | `hlb_mart.mart_v2_skill_funnel_fb` | event | 스킬 퍼널 v2 | [📄](./23-tables/mart/mart_v2_skill_funnel_fb.md) |
| 10 | `hlb_mart_adhoc.adhoc_mart_user_rfm_info_daily` | user | RFM 스코어·12세그먼트 | [📄](./23-tables/mart_adhoc/adhoc_mart_user_rfm_info_daily.md) |

상세는 [10-infra-map.md](./10-infra-map.md) §핵심 테이블 10선 참조.

---

## 4. 문의

본 패키지로 답이 나오지 않는 항목 또는 추가 자료가 필요하면 의뢰자에게 문의 바랍니다. 본 패키지는 외부 분석 시작 시점의 스냅샷이며 카탈로그 SSOT 는 내부 리포에서 지속 갱신됩니다.
