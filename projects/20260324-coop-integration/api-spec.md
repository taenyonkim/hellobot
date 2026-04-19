# API 명세 — 카카오 선물하기 상품권 통합 쿠폰 등록

## 엔드포인트 목록

### 현행 엔드포인트

| Method | Path | 설명 | 인증 |
|--------|------|------|------|
| POST | `/api/coupon/register` | **[NEW]** 쿠폰 통합 등록 (일반/하트/스킬 모두 처리) | @Authorized |
| POST | `/api/coupon` | (기존) 쿠폰 발급 — 프리픽스 가드 추가 | @Authorized |
| GET | `/api/coupon` | (기존) 쿠폰 리스트 조회 — `CouponDto`에 `fixedMenuSeq` optional 필드 | @Authorized |

### Deprecated 엔드포인트

| Method | Path | 상태 | 대체 |
|--------|------|------|------|
| POST | `/api/coop/check` | Deprecated (Phase 1 유지, Phase 2 제거) | `POST /api/coupon/register` |
| POST | `/api/coop/use` | Deprecated (Phase 1 유지, Phase 2 제거) | `POST /api/coupon/register` |

---

## POST /api/coupon/register

### 설명

쿠폰 코드를 받아 서버가 `coupon_prefix_rule` 테이블 기반으로 쿠폰 종류를 분류하고, 각 종류별 처리를 수행합니다. 쿠프마케팅 쿠폰(하트/스킬)은 L0 조회 + L1 사용을 한 번에 원샷으로 처리합니다. 실패 시 자동 복구(L2/L3)를 수행합니다.

### 응답 포맷 — ResWrapper 구조 (확정)

신규 API는 HelloBot 공통 `ResWrapper` 패턴을 따릅니다. **폴리모픽 필드는 모두 `data` 내부에 배치**합니다.

- 성공: `{ status: number, data: { resultType, issuedType, ... } }`
- 실패: `{ status: number, error: { code, message } }` (표준 HttpError 핸들러 경유)

기존 `POST /api/coupon`이 `issuedCoupon`을 `data` 바깥에 두었던 하이브리드 구조는 신규 API에서는 **사용하지 않음**. 팝업 표시용 정보가 필요한 경우 `data.coupon.issuedCoupon`처럼 `data` 내부 nested 필드로 통일.

### 인증

- `@Authorized()` — JWT 토큰 필요

### Request

**Headers**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Body**:
```json
{
  "code": "string (필수) — 쿠폰 코드"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| code | string | O | 쿠폰 코드 (빈 문자열 불가). 일반 쿠폰 또는 쿠프마케팅 쿠폰 코드 모두 허용 |

### Response

**응답 구조 (성공)**: 모든 성공 응답은 `resultType: "ISSUED"`로 통일되며, `issuedType`으로 발급된 상품 종류를 구분합니다. `issuedType`별로 추가 필드가 포함됩니다.

#### 성공 — 일반 쿠폰 발급 (201)

```json
{
  "data": {
    "resultType": "ISSUED",
    "issuedType": "coupon",
    "coupon": {
      "seq": 12345,
      "specSeq": 678,
      "name": "신년 할인 쿠폰",
      "tags": [],
      "platform": "ALL",
      "discountType": "percentage",
      "discountValue": 10,
      "minPurchasePrice": 0,
      "maxDiscountPrice": null,
      "expiresAt": "2026-07-18T23:59:59+09:00"
    },
    "issuedCoupon": {
      "popupTitle": "쿠폰이 발급되었어요",
      "coupons": [ { "seq": 12345, ... } ]
    }
  }
}
```

> FeatureFlag `SkillPurchasePromotion` 활성화 시 SINGLE_CODE/MULTI_CODE 타입 쿠폰은 추가로 `data.issuedCoupon` 필드(팝업 표시용)가 포함됩니다. `data` 내부 nested 구조로 통일.
> DOWNLOAD 타입은 `/api/coupon/register`의 `code` 기반 호출로는 발생하지 않음 (DOWNLOAD는 couponSpecSeq 기반이며 기존 `POST /api/coupon` 사용).

#### 성공 — 쿠프마케팅 하트 충전권 (200)

```json
{
  "data": {
    "resultType": "ISSUED",
    "issuedType": "heart",
    "productName": "카카오 하트 충전권 5천원",
    "heartQuantity": 25
  }
}
```

#### 성공 — 쿠프마케팅 스킬 교환권 (200)

```json
{
  "data": {
    "resultType": "ISSUED",
    "issuedType": "skill",
    "productName": "그 사람과 나의 사주 궁합",
    "skillName": "그 사람과 나의 사주 궁합",
    "fixedMenuSeq": 2166,
    "chatbotSeq": 123,
    "issuedCouponSeq": 456
  }
}
```

### Response 필드 설명

| 필드 | 타입 | 조건 | 설명 |
|------|------|------|------|
| resultType | string | 항상 | 고정값 `"ISSUED"` |
| issuedType | string | 항상 | `"coupon"` \| `"heart"` \| `"skill"` |
| coupon | CouponDto | issuedType=coupon | 기존 쿠폰 DTO 구조 (기존 `POST /api/coupon` 응답과 동일) |
| issuedCoupon | IssuedCouponDto | issuedType=coupon 일부 | FeatureFlag `SkillPurchasePromotion` 활성 + SINGLE_CODE/MULTI_CODE 타입일 때만 포함. 팝업 표시용 `{ popupTitle, coupons: CouponDto[] }`. `data.issuedCoupon`으로 data 내부에 포함 |
| productName | string | issuedType=heart/skill | 상품명 (쿠프마케팅 상품 이름) |
| heartQuantity | number | issuedType=heart | 충전된 하트 수량 |
| skillName | string | issuedType=skill | 스킬명 |
| fixedMenuSeq | number | issuedType=skill | 스킬 식별자 (스킬 상세 페이지 이동용) |
| chatbotSeq | number | issuedType=skill | 챗봇 식별자 |
| issuedCouponSeq | number | issuedType=skill | 발급된 100% 할인 쿠폰의 seq |

### Error Response (4xx / 5xx)

HTTP 표준 에러 포맷을 사용합니다.

```json
{
  "error": {
    "code": "CM_001",
    "message": "유효하지 않은 쿠폰이에요"
  }
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| error.code | string | 에러코드 (아래 [에러 코드](#에러-코드) 섹션 참조) |
| error.message | string | 사용자에게 표시할 메시지 (로케일별 번역됨) |

클라이언트는 `error.message`를 토스트로 그대로 표시합니다.

---

## POST /api/coupon (기존 + 가드 추가)

### 변경 사항 (Phase 1, 2026-04-19)

기존 쿠폰 발급 API에 **프리픽스 가드**가 추가됩니다. 신버전 클라이언트는 **code 경로로는 이 API를 호출하지 않으나**, **couponSpecSeq 경로(배너 클레임 등)는 계속 사용**합니다. 가드는 code 경로에만 적용됩니다.

### 이중 경로 정리

| 경로 | 요청 파라미터 | 용도 | 신버전 호출 여부 | 가드 대상 |
|------|-------------|------|---------------|---------|
| code | `{ code }` | 사용자가 쿠폰 코드 문자열 직접 입력 (SINGLE_CODE/MULTI_CODE) | ❌ (신버전은 `/register`로) | **가드 적용** |
| couponSpecSeq | `{ couponSpecSeq }` | 배너/프로모션에서 CouponSpec 클레임 (DOWNLOAD) | ✅ (계속 사용) | 가드 미적용 |

### 가드 로직

```
1. 요청 수신: { couponSpecSeq?, code? }
2. code가 "비어있지 않은 문자열"일 때만 가드 체크:
   - CouponPrefixRule.find WHERE is_active = true AND requires_new_flow = true
   - code.startsWith(prefix) 매칭되는 rule 존재 시
     → throw HttpError(HTTP 406 NOT_ACCEPTABLE, CO_APP_UPDATE_REQUIRED)
3. 가드 통과 → 기존 로직 수행 (변경 없음)
```

### 가드 발동 조건 상세

| 요청 입력 | 가드 동작 | 결과 |
|----------|---------|------|
| `{ couponSpecSeq: 123 }` | 가드 통과 (code 없음) | 기존 DOWNLOAD 로직 수행 |
| `{ couponSpecSeq: 123, code: "91..." }` | **가드 발동** | HTTP 406 + CO_APP_UPDATE_REQUIRED |
| `{ code: "91..." }` | **가드 발동** | HTTP 406 + CO_APP_UPDATE_REQUIRED |
| `{ code: "ABC123" }` (비매칭) | 가드 통과 | 기존 SINGLE_CODE/MULTI_CODE 로직 수행 |
| `{ code: "" }` | 가드 통과 (빈 문자열 검증 대상 아님) | 기존 로직의 파라미터 검증 에러 |
| `{ }` (둘 다 없음) | 가드 통과 | 기존 로직의 파라미터 검증 에러 |

### 가드 에러 응답 (HTTP 406)

```json
{
  "error": {
    "code": "CO_APP_UPDATE_REQUIRED",
    "message": "앱 업데이트가 필요한 쿠폰이에요."
  }
}
```

구버전 앱의 기존 에러 토스트 로직이 `message`를 그대로 표시 → 사용자에게 업데이트 안내 자동 노출.

### 기존 성공 응답 (변경 없음)

Request/Response 스키마는 기존과 동일:
- Body: `{ couponSpecSeq?: number, code?: string }`
- Response: `{ data: CouponDto, issuedCoupon?: IssuedCouponDto }` (HTTP 201) — `issuedCoupon`은 `data` 바깥 위치(기존 하이브리드 구조 유지, 하위 호환)

---

## GET /api/coupon (기존 API 확장)

기존 쿠폰 리스트 API의 응답 DTO에 optional 필드(`fixedMenuSeq`)를 추가합니다. 기존 필드는 변경하지 않으며, 구버전 클라이언트 호환을 유지합니다.

### Response — CouponDto 확장

```json
{
  "data": {
    "coupons": [
      {
        "seq": 12345,
        "specSeq": 678,
        "name": "카카오 선물하기 스킬 교환권",
        "tags": ["이용권"],
        "platform": "ALL",
        "discountType": "percentage",
        "discountValue": 100,
        "minPurchasePrice": 0,
        "maxDiscountPrice": null,
        "expiresAt": "2026-07-18T23:59:59+09:00",
        "fixedMenuSeq": 2166
      }
    ]
  }
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| fixedMenuSeq | number | X | 단일 스킬에 고정된 쿠폰(coop 스킬 이용권 등)일 때 해당 스킬 식별자. `CouponSpec.conditions[*].skillSeqs` 길이가 1인 경우에만 제공 |

### 적용 규칙

- **추가 조건**: `couponSpec.conditions`의 `skillSeqs`가 정확히 1개이고 단일 스킬에 귀속되는 쿠폰에 한해 값 세팅
- **그 외 쿠폰**: 필드 미제공(omit) 또는 `null`
- **클라이언트**: optional로 해석 (iOS `fixedMenuSeq: Int?`, Android `fixedMenuSeq: Int?`). 존재 시 쿠폰 카드 탭 → `SkillDetail(fixedMenuSeq)` 네비게이션

### 관련 이슈

- ISS-010: 본 필드 추가로 iOS/Android S4 스킬 상세 이동 구현 완료 (2026-04-18)

---

## 에러 코드

| 코드 | HTTP | 발생 대상 | 설명 | 사용자 안내 |
|------|------|----------|------|-----------|
| CO_APP_UPDATE_REQUIRED | 406 | `/api/coupon` 가드 / `/api/coupon/register` (미지원 타입, 확장 대비) | 구버전 앱에서 신규 쿠폰(90/91 프리픽스) 입력 또는 현재 클라이언트 버전이 지원하지 않는 신규 coupon_type | "앱 업데이트가 필요한 쿠폰이에요." |
| CM_001 | 400 | `/api/coupon/register` (coop 플로우) | 유효하지 않은 쿠폰 | "유효하지 않은 쿠폰이에요" |
| CM_002 | 400 | `/api/coupon/register` (coop 플로우) | 기간 만료 쿠폰 | "기간이 만료된 쿠폰이에요" |
| CM_003 | 400 | `/api/coupon/register` (coop 플로우) | 이미 사용된 쿠폰 | "이미 사용된 쿠폰이에요" |
| CM_004 | 404 | `/api/coupon/register` (coop 플로우) | 상품 매핑 없음 | "상품을 찾을 수 없어요" |
| CM_005 | 400 | `/api/coupon/register` (coop 플로우) | 쿠프마케팅 L1 외부 서비스 오류 | "일시적인 서비스 오류가 발생했어요" |
| CM_006 | 500 | `/api/coupon/register` (coop 플로우) | 쿠프마케팅 API 통신 오류 (타임아웃 등) | "일시적인 통신 오류가 발생했어요" |
| CM_007 | 500 | `/api/coupon/register` (coop 플로우) | 하트 충전 실패 (L2 자동 취소) | "하트 충전에 실패했어요" |
| CM_008 | 500 | `/api/coupon/register` (coop 플로우) | 스킬 이용권 발급 실패 (L2 자동 취소) | "스킬 이용권 발급에 실패했어요" |
| CM_009 | 500 | `/api/coupon/register` (coop 플로우) | 쿠폰 스펙 없음 | "쿠폰 스펙을 찾을 수 없어요" |
| CM_010 | 400 | `/api/coupon/register` (coop 플로우) | 결제 취소된 쿠폰 (쿠프마케팅 8099) | "결제가 취소된 쿠폰이에요" |

> CM_001~CM_010은 모두 **coop_marketing 타입 쿠폰(90/91 프리픽스) 처리 시에만** 발생. 일반 쿠폰(issuedType=coupon) 처리 시에는 기존 쿠폰 발급 에러(`CO_*`, `PARAMETER_ERROR` 등)가 반환됩니다.

### CM 에러 발생 시점

| 에러 | 발생 단계 | 설명 |
|------|----------|------|
| CM_001 | L0 조회 응답 | ResultCode ≠ "0000" (그 외) |
| CM_002 | L0 조회 응답 | ResultCode = "8003" 또는 EndDay < 현재일자 |
| CM_003 | L0 조회 응답 | ResultCode = "8005" 또는 UseYN = "Y" |
| CM_004 | 상품 매핑 | ProductCode에 매핑된 `coupc_marketing_product` 없음 또는 비활성 |
| CM_005 | L1 사용 응답 | ResultCode ≠ "0000" |
| CM_006 | L0/L1 | 쿠프마케팅 API 타임아웃/네트워크 오류 |
| CM_007 | 상품 지급 | HeartService.chargeHeart() 실패 (자동 L2 취소) |
| CM_008 | 상품 지급 | CouponService 쿠폰 발급 실패 (자동 L2 취소) |
| CM_009 | 상품 지급 | 스킬 상품의 couponSpecSeq에 해당하는 CouponSpec 없음 |
| CM_010 | L0 조회 응답 | ResultCode = "8099" (결제 취소) |

---

## 처리 흐름

### `/api/coupon/register` 흐름

```
클라이언트 → POST /coupon/register
    │
    ▼
[1] 프리픽스 분류 (coupon_prefix_rule 조회)
    │
    ├── coupon_type = "coop_marketing"
    │     │
    │     ▼
    │   [2-A] Coop 원샷 처리
    │     Redlock 획득
    │     L0 조회 → 상품 매핑 → L1 사용 → usage UPSERT → 상품 지급
    │     (실패 시 자동 L2/L3 복구)
    │     │
    │     ├── heart → HeartService.chargeHeart
    │     │     → { resultType: "ISSUED", issuedType: "heart", productName, heartQuantity }
    │     │
    │     └── skill → CouponService.issueCoupon (100% 할인)
    │           → { resultType: "ISSUED", issuedType: "skill", productName, skillName, fixedMenuSeq, chatbotSeq, issuedCouponSeq }
    │
    ├── coupon_type = 미지원
    │     │
    │     → throw HttpError(406, CO_APP_UPDATE_REQUIRED)
    │     (현재 시점엔 발생 경로 없음 — 미래 대비)
    │
    └── 매칭 없음 (일반 쿠폰)
          │
          ▼
        [2-B] 기존 CouponService.issueCoupon 호출
          → { resultType: "ISSUED", issuedType: "coupon", coupon }
```

### `/api/coupon` 가드 흐름 (구버전 앱 전용)

```
구버전 앱 → POST /coupon
    │
    ▼
[0] 프리픽스 가드
    code.startsWith(rule.prefix) WHERE requires_new_flow = true
    │
    ├── 매칭 → throw HttpError(406, CO_APP_UPDATE_REQUIRED)
    │       → 구버전 앱의 기존 에러 토스트로 표시
    │
    └── 매칭 없음 → 기존 로직 (변경 없음)
```

### 자동 복구 (Compensation)

| 실패 시점 | 복구 동작 | 설명 |
|----------|----------|------|
| L0 실패 | 없음 | 쿠폰 미소진, 사용자 재시도 가능 |
| L1 타임아웃 | L3 망취소 | 네트워크 오류 시 쿠폰 원복 시도 |
| L1 성공 후 하트 충전 실패 | L2 취소 + usage canceled | 쿠프마케팅 승인 취소 → 쿠폰 원복 |
| L1 성공 후 쿠폰 발급 실패 | L2 취소 + usage canceled | 쿠프마케팅 승인 취소 → 쿠폰 원복 |

---

## 클라이언트 연동 참고

### 하트 충전권 사용 후 (issuedType: "heart")

- 하트가 즉시 충전됨 (1단계 원샷 처리)
- S3 완료 팝업 표시 → "확인" → 프로필 탭으로 이동

### 스킬 교환권 사용 후 (issuedType: "skill")

- 100% 할인 쿠폰이 사용자 쿠폰 리스트에 즉시 추가됨 (1단계 원샷 처리)
- `issuedCouponSeq`로 발급된 쿠폰 식별 가능
- `fixedMenuSeq`로 스킬 상세 페이지 이동 가능
- 스킬 상세에서 ♥0으로 표시 → 기존 구매 플로우로 0하트 구매

### 중복 사용 방지

- 동일 쿠폰번호를 같은 유저가 다시 사용하면 쿠프마케팅 API에서 "이미 사용된 쿠폰" 응답 (CM_003)
- `coupc_marketing_coupon_usage` 테이블에 `(user_seq, coupon_code)` UNIQUE 제약
- 서버 내부에서 Redlock으로 동시 요청 차단

### 쿠폰번호 입력

- 기존 쿠폰 탭의 쿠폰 입력 필드 재사용
- **클라이언트는 프리픽스 분기를 수행하지 않음** — 모든 코드를 `POST /api/coupon/register`로 단일 전송
- 서버가 `coupon_prefix_rule` 기반으로 분류

### 구버전 앱 호환

- 구버전 앱은 여전히 `POST /api/coupon` 호출 (신규 API 모름)
- 90/91 프리픽스 입력 시 서버 가드가 `CO_APP_UPDATE_REQUIRED`(HTTP 406) 반환
- 구버전 앱의 기존 에러 토스트 로직이 `message`를 그대로 표시 → "앱 업데이트가 필요한 쿠폰이에요."

---

## Deprecated API (Phase 1 유지, Phase 2 제거 예정)

### ~~POST /api/coop/check~~

`POST /api/coupon/register`로 통합.

**Phase 1 기간 동작**:
- 기존 요청/응답 스키마 그대로 동작 (`valid: true/false` + 상품 정보)
- 서버 코드 변경 없음, `@deprecated` JSDoc 주석만 추가
- 신버전 클라이언트는 호출 안 함, 기존 배포된 구버전 웹 JS / 구버전 앱이 호출할 수 있음
- 신규 구현 시 사용 금지 — 코드 리뷰에서 차단

### ~~POST /api/coop/use~~

`POST /api/coupon/register`로 통합.

**Phase 1 기간 동작**:
- 기존 요청/응답 스키마 그대로 동작 (`success: true/false` + 상품 정보)
- 서버 코드 변경 없음, `@deprecated` JSDoc 주석만 추가
- 신버전 클라이언트는 호출 안 함
- 신규 구현 시 사용 금지

### Phase 2 제거 조건

다음 조건 모두 만족 시 두 엔드포인트 제거 (architecture.md §9 참조):
- Phase 1 배포 후 최소 4주 경과
- 최근 2주간 `/api/coop/*` 호출률 ≤ 0.1%
- 구버전(Phase 1 이전 빌드) 사용자 비율 ≤ 5%

---

## Changelog

| 날짜 | 변경자 | 변경 내용 | 확인 |
|------|--------|----------|------|
| 2026-04-19 | /dev-server | **Phase 1 서버 구현 완료** — `CouponPrefixRule` 엔티티/마이그레이션(시드 90/91 → coop_marketing), `ErrorCode.CO_APP_UPDATE_REQUIRED`+i18n(ko 확정, ja/en placeholder), `POST /api/coupon/register` + `CouponRegisterService`, `CoopMarketingService.registerOneShot` (Redlock + check + use 원샷, 보상 완료 후 lock 해제), `POST /api/coupon` code 경로 가드(HTTP 406), AdminJS `CouponPrefixRule` 등록, `/api/coop/*` `@deprecated` JSDoc. `/api/coop/*` 동작 변경 없음. TS/ESLint 통과. | 클라이언트(웹/iOS/Android) 구현 대기 |
| 2026-04-19 | /review 반영 | **설계 보완** (리뷰 발견 사항 반영): 응답 포맷 섹션 신설 — `/api/coupon/register`는 `data` 내부 nested 구조 통일(issuedCoupon 포함), `/api/coupon`은 기존 하이브리드 구조 유지 명시. `/api/coupon` 이중 경로(code/couponSpecSeq) 테이블 추가 — 가드는 code 경로에만 적용. 가드 발동 조건 상세 테이블 추가(6가지 입력 케이스별). 에러코드 표에 CM_001~CM_010 "(coop 플로우)" 명시 — 일반 쿠폰 플로우에서는 발생 안 함. Deprecated API 섹션에 Phase 1 동작 명시(기존 스키마 유지, @deprecated 주석만 추가) + Phase 2 정량 제거 조건. | 전파트 구현 예정 |
| 2026-04-19 | /architect | **API 전면 개편** (ISS-011, ISS-009 해결): `POST /api/coupon/register` 신규 단일 진입점 추가 (폴리모픽 성공 응답 `resultType: "ISSUED"` + `issuedType: "coupon"\|"heart"\|"skill"`). 에러는 HTTP 표준 포맷 `{ error: { code, message } }` 사용. `POST /api/coupon`에 프리픽스 가드 추가 (구버전 앱 대응, `CO_APP_UPDATE_REQUIRED` 신규 에러코드). `/api/coop/check`, `/api/coop/use`는 Deprecated (Phase 2에서 제거). | 전파트 구현 예정 |
| 2026-04-18 | /architect (via /workspace) | GET /api/coupon 응답 `CouponDto`에 `fixedMenuSeq?: number` optional 필드 추가 — ISS-010 대응 | 전파트 구현 완료 |
| 2026-04-18 | /dev-server | GET /api/coupon 서버 구현 완료 — `CouponCondition.skillSeqs` 길이가 1인 경우에만 `fixedMenuSeq` 노출. DB/마이그레이션 무변경 | |
| 2026-04-18 | /dev-ios, /dev-android | ISS-010 클라이언트 구현 완료 — iOS: Coupon/CouponModel 필드 추가 + CouponListViewController 바인딩, Android: CouponData.fixedMenuSeq + onClick 핸들러 | |
