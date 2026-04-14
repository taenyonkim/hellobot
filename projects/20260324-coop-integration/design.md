# 기술 설계 — 카카오 선물하기 상품권 연동

## 1. 개요

쿠프마케팅 API를 통해 카카오 선물하기 상품권을 헬로우봇에서 사용할 수 있게 합니다. 기존 쿠폰 화면의 입력란을 재사용하며, 서버가 쿠폰 형식을 판별하여 분기합니다.

**두 가지 상품 유형**:
- **하트 충전권**: 상품권 등록 → 즉시 하트 충전
- **스킬 교환권**: 상품권 등록 → 100% 할인 쿠폰 발급 → 기존 스킬 구매 플로우로 0하트 구매

---

## 2. 시스템 데이터 흐름

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│  카카오       │     │  쿠프마케팅    │     │  헬로우봇 서버     │
│  선물하기     │────▶│  (인증 중계)   │◀───▶│  (상품제공업체)    │
└──────────────┘     └──────────────┘     └────────┬─────────┘
                                                    │
                                          ┌─────────┼─────────┐
                                          │         │         │
                                       ┌──▼──┐  ┌──▼──┐  ┌──▼──┐
                                       │ Web │  │ iOS │  │ AOS │
                                       └─────┘  └─────┘  └─────┘
```

### 전체 처리 시퀀스

```
클라이언트                    헬로우봇 서버                     쿠프마케팅 API
    │                            │                                │
    │  POST /api/coop/check      │                                │
    │ { couponCode }             │                                │
    │──────────────────────────▶│                                │
    │                            │  L0 조회 (쿠폰 유효성)          │
    │                            │──────────────────────────────▶│
    │                            │         L0 응답                │
    │                            │◀──────────────────────────────│
    │                            │  상품 매핑 (ProductCode → 상품)  │
    │   check 응답               │                                │
    │  { valid, productType,     │                                │
    │    heartQuantity 또는       │                                │
    │    fixedMenuSeq, ... }     │                                │
    │◀──────────────────────────│                                │
    │                            │                                │
    │  [사용자가 확인 팝업에서     │                                │
    │   "사용하기" 탭]            │                                │
    │                            │                                │
    │  POST /api/coop/use        │                                │
    │ { couponCode }             │                                │
    │──────────────────────────▶│                                │
    │                            │  L0 재조회 (유효성 재확인)       │
    │                            │──────────────────────────────▶│
    │                            │◀──────────────────────────────│
    │                            │  L1 사용 승인                   │
    │                            │──────────────────────────────▶│
    │                            │◀──────────────────────────────│
    │                            │                                │
    │                            │  [heart] HeartService.charge() │
    │                            │  [skill] CouponService.issue() │
    │                            │                                │
    │   use 응답                 │                                │
    │  { success, productType,   │                                │
    │    heartQuantity 또는       │                                │
    │    issuedCouponSeq, ... }  │                                │
    │◀──────────────────────────│                                │
    │                            │                                │
    │  [실패 시 자동 복구]         │                                │
    │                            │  L2 취소 또는 L3 망취소          │
    │                            │──────────────────────────────▶│
```

---

## 3. API 계약

상세 스펙: [api-spec.md](./api-spec.md)

| Method | Path | 설명 | 인증 |
|--------|------|------|------|
| POST | `/api/coop/check` | 쿠폰 유효성 확인 + 상품 정보 조회 | @Authorized (JWT) |
| POST | `/api/coop/use` | 쿠폰 사용 (하트 충전 또는 이용권 발급) | @Authorized (JWT) |

### check 응답 구조

```typescript
// valid: true — 하트 충전권
{
  valid: true,
  productType: "heart",
  productName: string,      // "카카오 하트 충전권 5천원"
  heartQuantity: number,    // 25
  couponName: string,       // "카카오 선물하기 하트 충전권"
}

// valid: true — 스킬 교환권
{
  valid: true,
  productType: "skill",
  productName: string,      // "그 사람과 나의 사주 궁합"
  fixedMenuSeq: number,     // 2166
  chatbotSeq: number,       // 123
  skillName: string,        // "그 사람과 나의 사주 궁합"
  couponName: string,       // "카카오 선물하기 스킬 교환권"
}

// valid: false — 에러
{
  valid: false,
  errorCode: string,        // "CM_001"
  errorMessage: string      // "유효하지 않은 쿠폰입니다" (로케일별 번역)
}
```

### use 응답 구조

```typescript
// 성공 — 하트 충전
{
  success: true,
  productType: "heart",
  heartQuantity: number,    // 25
  productName: string       // "카카오 하트 충전권 5천원"
}

// 성공 — 스킬 이용권 발급
{
  success: true,
  productType: "skill",
  issuedCouponSeq: number,  // 456 — 발급된 100% 할인 쿠폰 seq
  fixedMenuSeq: number,     // 2166
  chatbotSeq: number,       // 123
  skillName: string,        // "그 사람과 나의 사주 궁합"
  productName: string,      // "그 사람과 나의 사주 궁합"
  message: string           // "스킬 이용권이 등록되었어요"
}

// 실패 — HTTP 4xx/5xx
{
  code: string,             // "CM_007"
  message: string,          // "하트 충전에 실패했습니다"
  reason: string
}
```

### 에러 코드

| 코드 | HTTP | 설명 | 사용자 메시지 |
|------|------|------|-------------|
| CM_001 | 200(check) / 400(use) | 유효하지 않은 쿠폰 | 유효하지 않은 쿠폰입니다 |
| CM_002 | 200 / 400 | 기간 만료 | 기간이 만료된 쿠폰입니다 |
| CM_003 | 200 / 400 | 이미 사용됨 | 이미 사용된 쿠폰입니다 |
| CM_004 | 200 / 404 | 상품 매핑 없음 | 상품을 찾을 수 없습니다 |
| CM_005 | — / 400 | 쿠프마케팅 API 오류 | 쿠프마케팅 API 오류가 발생했습니다 |
| CM_006 | 200 / 500 | 통신 오류 | 일시적인 통신 오류가 발생했습니다 |
| CM_007 | — / 500 | 하트 충전 실패 | 하트 충전에 실패했습니다 |
| CM_008 | — / 500 | 이용권 발급 실패 | 스킬 이용권 발급에 실패했습니다 |
| CM_009 | — / 500 | 쿠폰 스펙 없음 | 쿠폰 스펙을 찾을 수 없습니다 |

> check API는 에러도 HTTP 200으로 반환 (`valid: false`), use API는 실패 시 HTTP 4xx/5xx

---

## 4. 데이터 모델

### 신규 테이블 (3개)

```
coupc_marketing_product          (상품 정의)
  │ 1:N
  └── coupc_marketing_coupon_usage   (사용 이력)
  │ 1:N
  └── coupc_marketing_api_log        (API 호출 로그)
```

#### coupc_marketing_product (상품 매핑)

쿠프마케팅 상품코드 ↔ 헬로우봇 내부 상품의 매핑.

| 필드 | 타입 | 설명 |
|------|------|------|
| seq | SERIAL PK | 고유 식별자 |
| product_code | VARCHAR(50) UNIQUE | 쿠프마케팅 상품코드 (예: KH00001) |
| product_name | VARCHAR(200) | 상품명 |
| product_type | VARCHAR(20) | `heart` / `skill` |
| price | INTEGER | 상품 금액(원) |
| heart_quantity | INTEGER? | 하트 충전 수량 (heart 전용) |
| fixed_menu_seq | INTEGER? | 스킬 식별자 (skill 전용) |
| coupon_spec_seq | INTEGER? | 100% 할인 쿠폰 스펙 FK (skill 전용) |
| is_active | BOOLEAN | 활성화 여부 |

#### coupc_marketing_coupon_usage (사용 이력)

사용자의 상품권 사용 현황. 쿠폰 1장 = 1행.

| 필드 | 타입 | 설명 |
|------|------|------|
| seq | SERIAL PK | 고유 식별자 |
| user_seq | INTEGER | 사용자 FK |
| coupon_code | VARCHAR(100) | 쿠폰번호 (user_seq + coupon_code UNIQUE) |
| coupc_product_seq | INTEGER | 상품 FK |
| product_type | VARCHAR(20) | `heart` / `skill` |
| status | VARCHAR(20) | `used` / `canceled` |
| brand_auth_code | VARCHAR(100) | 브랜드 승인번호 (취소 시 필요) |
| heart_log_seq | INTEGER? | 하트 충전 로그 FK (heart 전용) |
| issued_coupon_seq | INTEGER? | 발급된 쿠폰 FK (skill 전용) |

#### coupc_marketing_api_log (API 전문 로그)

트러블슈팅용. Append only.

| 필드 | 타입 | 설명 |
|------|------|------|
| seq | SERIAL PK | 고유 식별자 |
| process_type | VARCHAR(20) | `L0` / `L1` / `L2` / `L3` / `L1_COMPLETE` |
| coupon_code | VARCHAR(100) | 쿠폰번호 |
| request_data | JSONB | 요청 전문 |
| response_data | JSONB | 응답 전문 |

### 기존 테이블 연동

| 테이블 | 연동 방식 |
|--------|----------|
| `heart_log` | heart 충전 시 HeartService가 자동 생성 → `heart_log_seq`로 참조 |
| `coupon_spec` | skill 상품 등록 시 자동 생성 (100% 할인) → `coupon_spec_seq`로 참조 |
| `coupon` | skill 이용권 사용 시 CouponService가 발급 → `issued_coupon_seq`로 참조 |

---

## 5. 처리 로직

### 5-1. check 처리

```
1. 쿠폰번호 수신
2. 쿠프마케팅 L0 조회 API 호출
3. L0 응답 검증:
   - ResultCode ≠ "0000" → valid: false (CM_001)
   - EndDay < 현재일자 → valid: false (CM_002)
   - UseYN = "Y" → valid: false (CM_003)
4. ProductCode로 coupc_marketing_product 조회
   - 매핑 없음 또는 비활성 → valid: false (CM_004)
5. 상품 정보 반환 (productType에 따라 다른 필드 포함)
```

### 5-2. use 처리 — 하트 충전권

```
1. 쿠폰번호 수신
2. Redlock 획득 (coupon_code 기준, 중복 사용 방지)
3. L0 재조회 → 유효성 재확인
4. L1 사용 승인 요청
   - 실패/타임아웃 → L3 망취소 시도 → 에러 반환
5. L1 성공 → usage UPSERT (status: "used") — 먼저 기록
   - INSERT 또는 ON CONFLICT (user_seq, coupon_code) → UPDATE
6. HeartService.chargeHeart()
   - 실패 → L2 자동 취소 + usage UPDATE (status: "canceled") → 에러 반환 (CM_007)
7. usage에 heartLogSeq 업데이트
8. 응답 반환 { success: true, productType: "heart", heartQuantity }
```

### 5-3. use 처리 — 스킬 교환권

```
1. 쿠폰번호 수신
2. Redlock 획득 (coupon_code 기준)
3. L0 재조회 → 유효성 재확인
4. L1 사용 승인 요청
   - 실패/타임아웃 → L3 망취소 시도 → 에러 반환
5. L1 성공 → usage UPSERT (status: "used") — 먼저 기록
6. CouponService로 100% 할인 쿠폰 발급
   - 실패 → L2 자동 취소 + usage UPDATE (status: "canceled") → 에러 반환 (CM_008)
7. usage에 issuedCouponSeq 업데이트
8. 응답 반환 { success: true, productType: "skill", issuedCouponSeq, ... }
```

### 5-4. 자동 복구 (Compensation)

| 실패 시점 | 복구 동작 | 결과 |
|----------|----------|------|
| L1 타임아웃 | L3 망취소 | 쿠폰 원복, 사용자 재시도 가능 |
| L1 성공 후 하트 충전 실패 | L2 취소 + usage canceled | 쿠프마케팅 승인 취소, 쿠폰 원복. 하트 미지급 상태이므로 회수 불필요. |
| L1 성공 후 쿠폰 발급 실패 | L2 취소 + usage canceled | 쿠프마케팅 승인 취소, 쿠폰 원복. 이용권 미발급 상태이므로 회수 불필요. |

> **누수 방지**: usage를 상품 지급보다 먼저 기록하여, 지급 실패 시에도 중복 사용 방지 상태가 유지됨.
> **재사용 지원**: usage INSERT를 UPSERT로 처리하여, 취소 후 재사용 시 기존 레코드를 갱신.

### 5-5. Admin 수동 취소

운영자가 Admin에서 사용 완료된 쿠폰을 취소하는 경우, 지급된 상품 회수를 함께 수행한다.

```
1. Admin 취소 버튼 클릭
2. Guard 메시지에 상품 정보 + 회수 가능 여부 표시
   - 하트: 충전 수량, 현재 잔여 하트 (부족 시 경고)
   - 스킬: 이용권 사용 여부 (사용 완료 시 경고)
3. 운영자 확인 → 취소 진행 (회수 불가 상태에서도 진행 가능)
4. 상품 회수:
   - 하트: useHeart(UseByGiftCouponRecovery)로 차감 + 회수 로그. 잔여 부족 시 남은 만큼만 차감
   - 스킬: 발급된 100% 할인 쿠폰 삭제 (Coupon.delete)
5. 쿠프마케팅 L2 취소 API 호출
6. usage status → "canceled", canceledAt 기록
```

---

## 6. 파트별 구현 포인트

### 서버

- **구현 완료**: Entity 3개, Service, Controller, Admin (상품관리/사용이력/로그)
- **잔여**: Admin 정산 통계 custom page
- 상세 설계: `worktrees/hellobot-server/docs/features/.../backend-design.md`

### 웹 (hellobot-web)

- **구현 완료**: 타입, API 훅, 팝업 3종, 이용권 카드, CouponCodeRegister 통합, 번역, Figma 디자인 반영
- **잔여**: 모바일 웹뷰 환경 검증, 일본어 번역 검수
- 상세: `worktrees/hellobot-web/docs/features/.../status.md`

### iOS / Android (네이티브)

클라이언트 개발 가이드: [client-guide.md](./client-guide.md)

#### 쿠폰 화면 수정

- 기존 쿠폰 입력란 재사용 (별도 화면 없음)
- 쿠폰번호 프리픽스 `90`, `91`로 시작하면 → `POST /api/coop/check` 호출
- 그 외 → 기존 쿠폰 등록 API 호출
- 힌트 텍스트 변경: "쿠폰 코드를 입력해주세요"

#### 팝업 구현 (3종)

| 팝업 | 표시 조건 | 주요 데이터 | 사용자 액션 |
|------|----------|-----------|-----------|
| S2-A 하트 확인 | check → `heart` | productName, heartQuantity | "충전하기" → use API |
| S2-B 스킬 확인 | check → `skill` | skillName, 아이콘 | "받기" → use API |
| S3 하트 완료 | use → heart 성공 | heartQuantity | "확인" → 내 하트 페이지 |

> 팝업 디자인: Figma 확정 디자인 참조 ([designs/designs.md](./designs/designs.md))

#### 스킬 이용권 처리 (S4)

use API → skill 성공 시:
1. 팝업 닫기
2. 토스트: "스킬 이용권이 등록되었어요" (2.5초)
3. 쿠폰 리스트 최상단에 **이용권 카드** 추가
4. 이용권 카드 구성: "이용권" 태그, "100%", 스킬명, 만료일, "스킬 보러가기 >"
5. 카드 탭 → 스킬 상세 페이지 (`fixedMenuSeq`로 이동)

#### 에러 처리 (S5)

- check 실패: `errorMessage`를 **토스트**로 표시
- use 실패 (HTTP 4xx/5xx): `message`를 **토스트**로 표시
- 토스트 스타일: 검정 반투명 배경, 하단 중앙, 2.5초 자동 사라짐

#### 중복 탭 방지 (필수)

- 등록 버튼: check API 호출 중 disabled
- 확인 팝업 "사용하기"/"충전하기"/"받기" 버튼: use API 호출 중 disabled + 로딩
- 취소 버튼: use API 호출 중 disabled
- dim 영역 클릭: use API 호출 중 무시

#### 카카오 딥링크

- 카카오 선물하기에서 쿠폰 화면으로 직접 랜딩하는 딥링크 처리
- **딥링크 URL 스킴은 추후 확정** (client-guide.md 참조)

#### 페이지 이동

| 이동 | 방법 |
|------|------|
| 내 하트 페이지 | 기존 내 하트 화면 (하트 충전 내역에 "카카오 상품권 하트 충전" 항목) |
| 스킬 상세 페이지 | `fixedMenuSeq`로 기존 스킬 상세 이동 (쿠폰 적용 → 0하트 표시) |
| 챗봇 채팅방 | 스킬 상세에서 "지금 보러가기" → 기존 챗봇 진입 플로우 |

---

## 7. 확정 사항

| 항목 | 결정 |
|------|------|
| 상용 인증키 (Auth_Key) | 개발/상용 동일 |
| 쿠폰번호 프리픽스 | 90, 91 |
| 쿠폰 형식 판별 | 클라이언트에서 프리픽스로 분기 → coop check API 또는 기존 쿠폰 API |
| 스킬 교환 방식 | 100% 할인 쿠폰 발급 → 기존 구매 플로우로 0하트 구매 |
| 취소 정책 | 콘텐츠형 상품 — 사용 후 취소 불가, 내부 오류 시에만 자동 L2 |
| 에러 표시 | 팝업 → 토스트로 변경 (Figma 확정) |
| 이용권 카드 | 기존 쿠폰 카드 형식 (Figma 확정) |

---

## 8. 미확정 사항

| 항목 | 상태 | 영향 |
|------|------|------|
| 카카오 딥링크 URL 스킴 | 미확정 | iOS/Android 딥링크 처리 |
| Admin 정산 통계 | 미구현 | 운영 배포 전 필요 |

---

## 참조 문서

| 문서 | 설명 |
|------|------|
| [api-spec.md](./api-spec.md) | API 상세 명세 (필드, 에러 코드, 처리 흐름) |
| [client-guide.md](./client-guide.md) | 클라이언트 연동 가이드 (화면별 구현 상세, 에러 처리) |
| [screen-plan.md](./screen-plan.md) | 화면 기획서 (화면 흐름, 구성 요소, 인터랙션) |
| [designs/designs.md](./designs/designs.md) | Figma 디자인 링크 |
| [designs/design-review.md](./designs/design-review.md) | 디자인 리뷰 체크리스트 (웹 반영 완료) |
| [user-stories.md](./user-stories.md) | 사용자 스토리 (US-1~US-6) |
| [requirements.md](./requirements.md) | 요구사항 정의서 |
| [issues.md](./issues.md) | 이슈 목록 |

---

## Changelog

| 날짜 | 이슈 | 변경 내용 |
|------|------|----------|
| 2026-04-14 | ISS-003 | check API 응답에서 expiryDate 필드 제거. 교환된 상품(하트/이용권)에는 유효기간이 없으므로 쿠폰 만료일을 클라이언트에 전달할 필요 없음. |
| 2026-04-14 | ISS-001 | §5-2, §5-3: usage UPSERT 우선 기록 후 상품 지급 (순서 변경). §5-4: 자동 복구 시 usage canceled 처리 명시. §5-5: Admin 수동 취소 + 상품 회수 로직 추가. |
