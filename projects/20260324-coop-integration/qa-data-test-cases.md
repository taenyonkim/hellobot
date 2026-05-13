# 데이터 QA 테스트 케이스 (Data QA)

## 프로젝트: coop-integration (카카오 선물하기 상품권 연동)
## 작성일: 2026-05-06
## 상태: 작성중

> **범위**: Firebase 클라이언트 이벤트 3종 발화 검증.
> **참조 SSOT**: [event-spec.md](./event-spec.md) §3 (스펙) / §5 (응답 DTO 의존성)
> **검증 방법**: iOS/Android/Web 디버그 모드 활성화 후 Firebase DebugView (~5초 지연) 또는 BQ `events_intraday_*` 에서 파라미터 캡처.

---

## 1. EVT-1 `view_coupon_register`

### 발생 시점
쿠폰 등록 화면 진입 시 1회.
- iOS: `CouponListViewController.viewDidLoad`
- Android: `CouponListActivity.onCreate(savedInstanceState=null)` — 회전 시 중복 발화 없음
- Web: `app/coupon/page.tsx` 마운트 1회

### 파라미터
| 파라미터 | 필수 | 가능한 값 | 비고 |
|---------|------|----------|------|
| (없음) | — | — | Firebase 자동 수집 `user_id`, `platform` 만 사용 |

### 검증 TC

| ID | 플랫폼 | 시나리오 | 기대 결과 | 결과 |
|----|--------|---------|---------|------|
| TC-D-V01 | iOS / Android / Web | 쿠폰 등록 화면 진입 1회 | `view_coupon_register` 1건 발화. 추가 파라미터 없음 | - |

---

## 2. EVT-2 `register_coupon_success`

### 발생 시점
`POST /api/coupon/register` **200 응답 직후**.

### 파라미터
| 파라미터 | 타입 | 필수 | 가능한 값 | 소스 |
|---------|------|------|----------|------|
| `coupon_number` | string | ✅ | 12자리 숫자 (사용자 입력값) | 클라이언트 입력값 |
| `coupon_type` | string | ✅ | `kakao` \| `hellobot` \| `giftiel` | 응답 `data.couponType` (D1=a) |
| `issued_type` | string | ✅ | `heart` \| `skill` \| `coupon` | 응답 `data.issuedType` |
| `product_code` | string | conditional | `KH00001`~`KH99999`, `KS00001`~`KS99999` 등 (`coop_marketing_product.product_code`) | 응답 `data.productCode`. 카카오 한정 — `coupon_type=hellobot/giftiel` 인 경우 키 omit |
| `fixed_menu_seq` | int | conditional | 정수 | `issued_type=skill` 한정. 그 외 키 omit |
| `heart_quantity` | int | conditional | 정수 (예: 25, 60, 210, 360) | `issued_type=heart` 한정. `CoopMarketingProduct.heartQuantity` 그대로 (D2=a, paid 100%) |
| `latency_ms` | int | ✅ | 양의 정수 | 클라이언트 측정 (등록 버튼 탭 → 응답 수신) |

> ❌ **포함되면 안 되는 키**: `bonus_heart_amount` (D2=a 결정으로 폐기), `heart_amount` (D2=a 후 `heart_quantity` 로 리네임)

### 검증 TC

| ID | 시나리오 | 사전조건 | 기대 파라미터 (값 예시) | 결과 |
|----|---------|---------|----------------------|------|
| TC-D-S01 | 카카오 하트 충전권 등록 (KH00001 / 하트 25개, 쿠폰번호 912685375753) | 서버 D1=a 배포 완료 | `coupon_type='kakao'`, `issued_type='heart'`, `product_code='KH00001'`, `heart_quantity=25`, `latency_ms>0`. `fixed_menu_seq` 키 omit | - |
| TC-D-S02 | 카카오 스킬 교환권 등록 (KS00005 / 솔로 탈출 시기, 쿠폰번호 916557334133) | 서버 D1=a 배포 완료 | `coupon_type='kakao'`, `issued_type='skill'`, `product_code='KS00005'`, `fixed_menu_seq=<정수>`, `latency_ms>0`. `heart_quantity` 키 omit | - |
| TC-D-S03 | 일반 쿠폰(hellobot) 등록 (예: '50%') | — | `coupon_type='hellobot'`, `issued_type='coupon'`, `latency_ms>0`. `product_code`/`fixed_menu_seq`/`heart_quantity` 키 omit | - |
| TC-D-S04 | giftiel 쿠폰 등록 | giftiel 쿠폰 준비 가능 시 | `coupon_type='giftiel'`. `product_code` 키 omit | - |
| TC-D-S05 | `bonus_heart_amount` / `heart_amount` 키 잔존 회귀 | TC-D-S01 직후 | 두 키 모두 절대 발화되지 않음 (D2=a 정합) | - |

---

## 3. EVT-3 `register_coupon_failure`

### 발생 시점
`POST /api/coupon/register` **non-200 응답 또는 네트워크 에러 직후**.

### 파라미터
| 파라미터 | 타입 | 필수 | 가능한 값 | 소스 |
|---------|------|------|----------|------|
| `coupon_number` | string | ✅ | 사용자 입력값 | 클라이언트 입력값 |
| `coupon_type` | string | nullable | `kakao` \| `hellobot` \| `giftiel` \| (omit) | 클라이언트 prefix 룩업 (`90`/`91` → `kakao`). 미매칭 시 키 omit (D3=a, 에러 응답에 미포함) |
| `coupon_prefix` | string | ✅ | 2자리 문자열 (예: `91`, `AB`) | 클라이언트 입력값 앞 2자 |
| `error_code` | string | ✅ | `CM001`~`CM010`, `CO012`, `NETWORK_ERROR`, `UNKNOWN` | HTTP 응답 `code` 또는 클라이언트 분류 |
| `reason` | string | ✅ | 자유 텍스트 | 응답 `message` 또는 에러 객체 |
| `latency_ms` | int | ✅ | 양의 정수 | 클라이언트 측정 |

> ❌ **포함되면 안 되는 값** (`error_code` enum 외):
> - `CM_001`~`CM_010` (언더바 표기) — ISS-050 으로 폐기
> - `CO_APP_UPDATE_REQUIRED` — `CO012` 로 통합

### 검증 TC

| ID | 시나리오 | 사전조건 | 기대 파라미터 (값 예시) | 결과 |
|----|---------|---------|----------------------|------|
| TC-D-F01 | CM001 — 미존재 카카오 쿠폰 | 임의 카카오 쿠폰번호 `910000000000` | `error_code='CM001'`, `coupon_type='kakao'`, `coupon_prefix='91'`, `latency_ms>0` | - |
| TC-D-F02 | CM002 — 만료 쿠폰 | `918799132824` (KS00005 만료) | `error_code='CM002'`, `coupon_type='kakao'`, `coupon_prefix='91'` | - |
| TC-D-F03 | CM003 — 사용 완료 쿠폰 | 이미 사용된 카카오 쿠폰 | `error_code='CM003'`, `coupon_type='kakao'` | - |
| TC-D-F04 | CM010 — 결제 취소 쿠폰 | `918354799178` (KH00004 결제 취소) 또는 `916900621001` (KS00005 결제 취소) | `error_code='CM010'`, `coupon_type='kakao'` | - |
| TC-D-F05 | CO012 — 구버전 앱 가드 | 구버전 앱 + 카카오 쿠폰 입력 | `error_code='CO012'`, `coupon_type='kakao'` | - |
| TC-D-F06 | NETWORK_ERROR — 비행기 모드 | 오프라인 | `error_code='NETWORK_ERROR'` | - |
| TC-D-F07 | UNKNOWN — 5xx 서버 에러 | 서버 강제 5xx | `error_code='UNKNOWN'` | - |
| TC-D-F08 | 비카카오 prefix 미매칭 | 임의 prefix(예: `ABC123`) 미존재 | `error_code='CM001'`, `coupon_prefix='AB'`, `coupon_type` 키 omit | - |
| TC-D-F09 | ISS-050 표기 회귀 | 위 케이스 모두 1회씩 발화 후 BQ 조회 | `error_code` distinct ⊆ {CM001..CM010, CO012, NETWORK_ERROR, UNKNOWN}. `CM_xxx` / `CO_APP_UPDATE_REQUIRED` 0건 | - |

---

## 4. 결과 요약

| 항목 | 수치 |
|------|------|
| 전체 케이스 | 15 |
| Pass | 0 |
| Fail | 0 |
| 미수행 | 15 |
| 통과율 | - |

### 실패 항목 상세
| ID | 증상 | 재현 조건 | 비고 |
|----|------|----------|------|
| (미수행 — 발견 시 추가) | | | |
