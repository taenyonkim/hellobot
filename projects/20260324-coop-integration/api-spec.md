# API 명세 — 쿠프마케팅 카카오 선물하기

## 엔드포인트 목록

| Method | Path | 설명 | 인증 |
|--------|------|------|------|
| POST | /api/coop/check | 쿠폰 유효성 확인 및 상품 정보 조회 | @Authorized |
| POST | /api/coop/use | 쿠폰 사용 (하트 충전 또는 스킬 이용권 발급) | @Authorized |

---

## POST /api/coop/check

### 설명

쿠폰번호를 쿠프마케팅 API에 조회하여 유효성을 확인하고, 매핑된 헬로우봇 상품 정보를 반환합니다. 쿠폰이 유효하지 않거나 이미 사용된 경우에도 **HTTP 200**으로 응답하며, `valid: false`와 에러 정보를 함께 반환합니다.

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
  "couponCode": "string (필수) — 쿠프마케팅 쿠폰번호"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| couponCode | string | O | 쿠폰번호 (빈 문자열 불가) |

### Response

#### 성공 — 하트 충전권 (200)

```json
{
  "data": {
    "valid": true,
    "productType": "heart",
    "productName": "카카오 하트 충전권 5천원",
    "heartQuantity": 25,
    "couponName": "카카오 선물하기 하트 충전권",
    "expiryDate": "20270409"
  }
}
```

#### 성공 — 스킬 교환권 (200)

```json
{
  "data": {
    "valid": true,
    "productType": "skill",
    "productName": "그 사람과 나의 사주 궁합",
    "fixedMenuSeq": 2166,
    "chatbotSeq": 123,
    "skillName": "그 사람과 나의 사주 궁합",
    "couponName": "카카오 선물하기 스킬 교환권",
    "expiryDate": "20270409"
  }
}
```

#### 실패 — 유효하지 않은 쿠폰 (200)

```json
{
  "data": {
    "valid": false,
    "errorCode": "CM_001",
    "errorMessage": "유효하지 않은 쿠폰입니다"
  }
}
```

### Response 필드 설명

| 필드 | 타입 | 조건 | 설명 |
|------|------|------|------|
| valid | boolean | 항상 | 쿠폰 유효 여부 |
| productType | string | valid=true | `"heart"` 또는 `"skill"` |
| productName | string | valid=true | 상품명 |
| heartQuantity | number | heart 타입 | 충전될 하트 수량 |
| fixedMenuSeq | number | skill 타입 | 스킬 식별자 |
| chatbotSeq | number | skill 타입 | 챗봇 식별자 |
| skillName | string | skill 타입 | 스킬명 |
| couponName | string | valid=true | 쿠프마케팅 쿠폰명 |
| expiryDate | string | valid=true | 유효기간 만료일 (YYYYMMDD) |
| errorCode | string | valid=false | 에러 코드 |
| errorMessage | string | valid=false | 에러 메시지 (로케일별 번역) |

---

## POST /api/coop/use

### 설명

쿠폰을 사용하여 하트를 충전하거나 스킬 이용권(100% 할인 쿠폰)을 발급합니다. 내부적으로 쿠프마케팅 API에 L0(조회) → L1(사용) 순서로 호출하며, 실패 시 자동으로 L2(취소) 또는 L3(망취소)를 수행합니다.

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
  "couponCode": "string (필수) — 쿠프마케팅 쿠폰번호"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| couponCode | string | O | 쿠폰번호 (빈 문자열 불가) |

### Response

#### 성공 — 하트 충전 (200)

```json
{
  "data": {
    "success": true,
    "productType": "heart",
    "heartQuantity": 25,
    "productName": "카카오 하트 충전권 5천원"
  }
}
```

#### 성공 — 스킬 이용권 발급 (200)

```json
{
  "data": {
    "success": true,
    "productType": "skill",
    "issuedCouponSeq": 456,
    "fixedMenuSeq": 2166,
    "chatbotSeq": 123,
    "skillName": "그 사람과 나의 사주 궁합",
    "productName": "그 사람과 나의 사주 궁합",
    "message": "스킬 이용권이 등록되었어요"
  }
}
```

### Response 필드 설명

| 필드 | 타입 | 조건 | 설명 |
|------|------|------|------|
| success | boolean | 항상 | 사용 성공 여부 |
| productType | string | 성공 시 | `"heart"` 또는 `"skill"` |
| productName | string | 성공 시 | 상품명 |
| heartQuantity | number | heart 타입 | 충전된 하트 수량 |
| issuedCouponSeq | number | skill 타입 | 발급된 100% 할인 쿠폰의 seq |
| fixedMenuSeq | number | skill 타입 | 스킬 식별자 |
| chatbotSeq | number | skill 타입 | 챗봇 식별자 |
| skillName | string | skill 타입 | 스킬명 |
| message | string | skill 타입 | 사용자에게 표시할 메시지 |

### Error Response (4xx / 5xx)

```json
{
  "code": "CM_007",
  "message": "하트 충전에 실패했습니다",
  "reason": "하트 충전에 실패했습니다"
}
```

---

## 에러 코드

| 코드 | HTTP | 설명 | 사용자 안내 |
|------|------|------|-----------|
| CM_001 | 400 | 유효하지 않은 쿠폰 | "유효하지 않은 쿠폰입니다" |
| CM_002 | 400 | 기간 만료 쿠폰 | "기간이 만료된 쿠폰입니다" |
| CM_003 | 400 | 이미 사용된 쿠폰 | "이미 사용된 쿠폰입니다" |
| CM_004 | 404 | 상품 매핑 없음 | "상품을 찾을 수 없습니다" |
| CM_005 | 400 | 쿠프마케팅 API 오류 | "쿠프마케팅 API 오류가 발생했습니다" |
| CM_006 | 500 | 통신 오류 (타임아웃 등) | "일시적인 통신 오류가 발생했습니다" |
| CM_007 | 500 | 하트 충전 실패 | "하트 충전에 실패했습니다" |
| CM_008 | 500 | 스킬 이용권 발급 실패 | "스킬 이용권 발급에 실패했습니다" |
| CM_009 | 500 | 쿠폰 스펙 없음 | "쿠폰 스펙을 찾을 수 없습니다" |

### 에러 발생 시점

| 에러 | check | use | 설명 |
|------|-------|-----|------|
| CM_001 | O | O | L0 응답 ResultCode ≠ "0000" |
| CM_002 | O | O | L0 응답 EndDay < 현재일자 |
| CM_003 | O | O | L0 응답 UseYN = "Y" |
| CM_004 | O | O | ProductCode에 매핑된 상품 없음 |
| CM_005 | X | O | L1 응답 ResultCode ≠ "0000" |
| CM_006 | O | O | 쿠프마케팅 API 타임아웃/네트워크 오류 |
| CM_007 | X | O | HeartService.chargeHeart() 실패 (자동 L2 취소 시도) |
| CM_008 | X | O | CouponService 쿠폰 발급 실패 (자동 L2 취소 시도) |
| CM_009 | X | O | 스킬 상품의 couponSpecSeq에 해당하는 CouponSpec 없음 |

---

## 처리 흐름

### check 흐름

```
클라이언트 → POST /check → L0 조회 → 상품 매핑 → 상품 정보 반환
                                    ↓ (실패)
                              valid: false + errorCode 반환
```

### use 흐름

```
클라이언트 → POST /use → L0 조회 → L1 사용 승인
                                      ↓ (성공)
                          ┌─── heart ──→ chargeHeart() → 하트 충전 완료
                          │
                          └─── skill ──→ issueCoupon() → 이용권 발급 완료
                                      ↓ (L1 실패)
                                 자동 복구 (L2 취소 또는 L3 망취소)
                                      ↓
                                 에러 반환 (CM_005 ~ CM_009)
```

### 자동 복구 (Compensation)

| 실패 시점 | 복구 동작 | 설명 |
|----------|----------|------|
| L1 타임아웃 | L3 망취소 | 네트워크 오류 시 쿠폰 원복 시도 |
| L1 성공 후 하트 충전 실패 | L2 취소 | 쿠프마케팅 승인 취소 → 쿠폰 원복 |
| L1 성공 후 쿠폰 발급 실패 | L2 취소 | 쿠프마케팅 승인 취소 → 쿠폰 원복 |

---

## 클라이언트 연동 참고

### 하트 충전권 사용 후

- 하트가 즉시 충전됨
- "충전 확인하기" → 내 하트 페이지로 이동

### 스킬 교환권 사용 후

- 100% 할인 쿠폰이 사용자 쿠폰 리스트에 추가됨
- `issuedCouponSeq`로 발급된 쿠폰 식별 가능
- `fixedMenuSeq`로 스킬 상세 페이지 이동 가능
- 스킬 상세에서 ♥0으로 표시 → 기존 구매 플로우로 0하트 구매

### 중복 사용 방지

- 동일 쿠폰번호를 같은 유저가 다시 사용하면 쿠프마케팅 API에서 "이미 사용된 쿠폰" 응답
- `coupc_marketing_coupon_usage` 테이블에 `(user_seq, coupon_code)` UNIQUE 제약

### 쿠폰번호 입력

- 기존 쿠폰 탭의 쿠폰 입력 필드 재사용
- 서버가 쿠폰번호 형식으로 쿠프마케팅 쿠폰 여부를 판별
