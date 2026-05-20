# 카카오 선물하기 SKU 선정용 스킬 데이터

## 파일

| 파일 | 그레인 | 행 수 | 설명 |
|---|---|---:|---|
| [`skills-by-segment-12m.csv`](./skills-by-segment-12m.csv) | 스킬 (menu_seq) | 2,587 | 1년간 APP 결제된 모든 스킬 + 메타 + 12M/6M/30D 트렌드 + 연령대 13구간 |
| [`topic-by-age-12m.csv`](./topic-by-age-12m.csv) | 카테고리 (topic) | 9 | topic × 연령대 매트릭스 (연애·총운·결혼·일반운세·가족자녀·학업직업·재물금전·기타·자기탐구) |

## 공통 추출 조건

| 항목 | 값 |
|---|---|
| 기간 | 2025-05-17 ~ 2026-05-16 (최근 12개월) |
| 플랫폼 | APP only (`platform_appweb='APP'`) |
| 이벤트 | `pay_for_contents`, `pay_under_750` |
| 필터 | `menu_seq IS NOT NULL` |
| 추출일 | 2026-05-17 |
| BQ 스캔 | skills 2.35 GB + topic 1.55 GB = **3.90 GB** |
| 출처 | `hlb_mart_integrated.union_mart_user_key_actions` × `server_rdb.snapshot_fixed_menu` |

> **JOIN 컨벤션**: `union.menu_seq` (STRING) × `snapshot.seq` (INTEGER) — `CAST(m.seq AS STRING) = u.menu_seq` 필수. 2026-05-17 카탈로그 반영 ([union_mart_user_key_actions.md §스킬/챗봇](../../../../../common-data-airflow/docs/hellobot-data/catalog/tables/mart_integrated/union_mart_user_key_actions.md)).

---

## skills-by-segment-12m.csv

### 컬럼 (29개)

#### 스킬 메타 (snapshot_fixed_menu)
| 컬럼 | 의미 | 비고 |
|---|---|---|
| `menu_seq` | 스킬 ID (STRING) | union의 menu_seq |
| `menu_name` | 스킬명 | union ANY_VALUE |
| `price_amount` | 현재 판매가 (KRW) | snapshot 현재 시점 |
| `open_date` | 스킬 오픈일 | **스테디셀러 vs 신규 판별 기준** |
| `is_open` | 현재 노출 여부 | TRUE/FALSE |
| `is_stop_selling` | 판매 중단 여부 | `is_open=TRUE AND is_stop_selling=FALSE` = **현재 판매중** |
| `menu_type` | 메뉴 타입 | 대부분 `clickableMenu` |

#### 콘텐츠 메타 (union)
| 컬럼 | 의미 |
|---|---|
| `chatbot_content_type` | 사주 / 타로 / 점성학 / 손금 / 기타 / 진단 |
| `topic` | 연애 · 총운 · 결혼 · 일반운세 · 가족자녀 · 학업직업 · 재물금전 · 기타 · 자기탐구 |
| `intents` | `\|` 구분자 복수값 |
| `temporal` | 시즈널 라벨 (예: `신년운세`) |

#### 결제 집계 — 12M / 6M / 30D 트렌드 (★ 신규)
| 컬럼 | 기간 | 의미 |
|---|---|---|
| `buyers_12m` | 2025-05-17 ~ 2026-05-16 | 12개월 결제자 (DISTINCT user_id) |
| `revenue_12m` | 동일 | 12개월 매출 (KRW) |
| `buyers_6m` | 2025-11-17 ~ 2026-05-16 | 6개월 결제자 |
| `revenue_6m` | 동일 | 6개월 매출 |
| `buyers_30d` | 2026-04-17 ~ 2026-05-16 | 30일 결제자 |
| `revenue_30d` | 동일 | 30일 매출 |

> 트렌드 활용: `revenue_30d / revenue_6m` 또는 `buyers_30d / (buyers_6m - buyers_30d)` 비교로 모멘텀 식별. 12M/6M = 평탄 / 6M·30D 급상승 = **신규 hit** / 12M 매출 있으나 30D=0 = **퇴조 SKU**.

#### 연령대별 결제자 수 (13개)
| 컬럼 | 5세 단위 | 세그먼트 (01-segment-targeting-strategy) |
|---|---|---|
| `age_13_15` | 13-15 | (학부모 발신 수신처) |
| `age_16_20` | 16-20 | **C3 빈도** |
| `age_21_25` | 21-25 | **C3 빈도** |
| `age_26_30` | 26-30 | **C1 코어 ★** |
| `age_31_35` | 31-35 | **C1 코어 ★** |
| `age_36_40` | 36-40 | **C2 구매력** |
| `age_41_45` | 41-45 | **C2 구매력** |
| `age_46_50` | 46-50 | **C2 구매력** |
| `age_51_55` ~ `age_66plus` | 51+ | (소량) |
| `age_unknown` | 정보없음 | 비로그인·미동의 |

### 매출 TOP 5 (12M 기준, 현재 판매중)

| # | menu_name | 매출(12M) | 매출(6M) | 매출(30D) | 가격 |
|:-:|---|---:|---:|---:|---:|
| 1 | 2026년 신년운세 보고서 | 3.38억 | 2.12억 | 606만 | ₩37,500 |
| 2 | 내 팔자에 새겨진 천년배필 | 1.69억 | 3,159만 | 243만 | ₩21,000 |
| 3 | 2026년 솔로 탈출 시기 | 1.49억 | — | — | ₩24,000 |
| 4 | 사주 궁합으로 보는 우리의 현재와 미래 | 996만 | — | — | ₩21,000 |
| 5 | 연봉 상승 비책: 올해 취업·이직운 | 991만 | — | — | ₩18,000 |

> 신년운세 보고서가 12M의 절반(2.12억)이 6M 집중 — 시즌 SKU 특성 명확. 30D는 비시즌이라 급락 (606만).

---

## topic-by-age-12m.csv

### 컬럼 (18개)

| 컬럼 | 의미 |
|---|---|
| `topic` | 카테고리 (9종) |
| `skill_count` | topic에 속한 스킬 수 (DISTINCT menu_seq) |
| `buyers` | 12M 결제자 |
| `revenue_krw` | 12M 매출 |
| `arppu` | revenue / buyers |
| `age_13_15` ~ `age_unknown` | 13개 연령대별 결제자 |

### topic 매출 순위 (12M)

| # | topic | skill_count | buyers | revenue | ARPPU | C1 (26-35) buyers |
|:-:|---|---:|---:|---:|---:|---:|
| 1 | **연애** | 1,723 | 86,262 | **33.3억 (76%)** | 38,561 | 42,904 |
| 2 | 총운 | 41 | 14,941 | 5.70억 (13%) | 38,125 | 8,784 |
| 3 | 결혼 | 82 | 18,860 | 4.25억 (10%) | 22,560 | 12,053 |
| 4 | 일반운세 | 151 | 10,821 | 1.58억 | 14,575 | 5,301 |
| 5 | 가족자녀 | 28 | 3,991 | 1.35억 | **33,946** ★ | 2,730 |
| 6 | 학업직업 | 79 | 8,482 | 1.10억 | 12,914 | 4,669 |
| 7 | 재물금전 | 50 | 6,311 | 9,688만 | 15,351 | 3,300 |
| 8 | 기타 | 380 | 9,083 | 2,586만 | 2,847 | 4,632 |
| 9 | 자기탐구 | 26 | 1,497 | 646만 | 4,317 | 695 |

### 핵심 관찰

- **연애 단일 카테고리가 매출의 76% (33.3억)** — A.7.2 "사주 콘텐츠 우세" 안에서도 topic 단위로는 연애가 압도적. 카카오 1차 라인업의 연애·궁합 비중 강화 정당화
- **가족자녀 ARPPU 33,946원 (최고)** — C2 (36-50) 구매력 흡수처. 단 buyers 3,991명으로 시장 작음 → **카테고리 First Mover 가능성**
- **결혼 ARPPU 22,560원** — 카카오 1차 가격대(₩17K~22K)와 정확히 일치, 12,053명의 C1 결제자 보유 → **결혼 SKU 1차 라인업 핵심 정당화**
- **자기탐구 매출 646만 (0.1%)** — 비중 거의 없음. 01-segment-targeting-strategy 의 "셀프 보상" SKU는 자기탐구 외 연애·총운에 묻혀있을 가능성
- **학업직업 26-30 buyers 2,761명** — 카카오 KS00022 직업 컨설팅 타깃 명확

---

## 데이터 활용 가이드 — 01-segment-targeting-strategy.md 와 함께

### C1 (26-35 여성 코어) 매핑 후보
```python
# skills-by-segment-12m.csv
df[(df.is_open == True) & (df.is_stop_selling == False)] \
  .assign(c1_buyers=lambda x: x.age_26_30 + x.age_31_35) \
  .assign(c1_ratio=lambda x: x.c1_buyers / x.buyers_12m) \
  .query("price_amount.between(17000, 22500) and c1_ratio >= 0.50") \
  .sort_values("c1_buyers", ascending=False)
```

### C2 (36-50 프리미엄) 매핑 후보
```python
df[df.chatbot_content_type == "사주"] \
  .query("price_amount >= 22500 and topic in ['가족자녀', '결혼', '총운']") \
  .sort_values(lambda x: x.age_36_40 + x.age_41_45 + x.age_46_50, ascending=False)
```

### C3 (15-29 라이트) 매핑 후보
```python
df.query("price_amount <= 9900 and is_open == True") \
  .sort_values(lambda x: x.age_16_20 + x.age_21_25, ascending=False)
```

### 신규 hit 식별 (모멘텀)
```python
df.query("open_date >= '2025-11-17' and revenue_30d > 0") \
  .assign(momentum_score=lambda x: x.revenue_30d / (x.revenue_6m + 1)) \
  .sort_values("momentum_score", ascending=False)
```

### 퇴조 SKU 식별 (컷오버 후보)
```python
df.query("is_open == True and revenue_12m > 1000000 and revenue_30d == 0")
```

### Topic 단위 세그먼트 적합도
```python
# topic-by-age-12m.csv
topic_df.assign(c1_share=lambda x: (x.age_26_30 + x.age_31_35) / x.buyers) \
        .sort_values("c1_share", ascending=False)
```

---

## 카카오 1차 라인업(KS) 대비 데이터 매칭

[skill-priority-analysis-v2-market-fit.md](../skill-priority-analysis-v2-market-fit.md) 의 KS00001~KS00029는 카카오 등록용 별도 SKU. 실제 헬봇 메뉴 시스템에서는 menu_seq가 별도. 매핑 예:
- KS00001 "2026년 신년운세 보고서" → menu_seq **55360** (12M 매출 1위, 6M 점유 63%)
- 다른 KS는 menu_name LIKE 매칭 + 수기 검증 필요

---

## 추가 분석 후보

| # | 분석 | 방법 |
|:-:|---|---|
| 1 | KS00001~29 ↔ menu_seq 매핑 시트 | menu_name LIKE 매칭 + 수기 |
| 2 | 매출 vs 가격 산점도 | pandas + matplotlib |
| 3 | 세그먼트 친화도 점수 (c1·c2·c3 ratio) | (age_xx + age_yy) / buyers_12m |
| 4 | 모멘텀 코호트 (open_date 기준) | open_date × buyers_30d / buyers_6m |
| 5 | WEB 매출 별도 추출 | platform_appweb='WEB' 필터 |
| 6 | intents 단일값 펼침 (\| 구분자) | UNNEST 후 별도 CSV |

---

## Changelog

| 날짜 | 변경자 | 변경 내용 |
|---|---|---|
| 2026-05-17 | /dev-data | 초안. 12개월 APP 결제 스킬 2,587건 추출. menu_seq × 메타 × 연령대 13구간 wide CSV. 매출 TOP 사주 우세 확인. 출처: union × snapshot_fixed_menu, BQ scan 2.35 GB |
| 2026-05-17 | /dev-data | **트렌드 컬럼 추가** — skills CSV 에 `buyers_6m`, `revenue_6m`, `buyers_30d`, `revenue_30d` 4개 컬럼 추가 (단일 base CTE 조건부 집계로 동일 테이블 1회 스캔 유지). **topic-by-age-12m.csv 신규** — 9개 카테고리 × 연령대 13구간 매트릭스. 연애 단일 매출 76% 압도 확인, 가족자녀 ARPPU 33,946원 최고. 카탈로그 갱신: `union.menu_seq` STRING + `snapshot.seq` INTEGER JOIN 컨벤션 SSOT 반영 |
