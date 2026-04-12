# 기프티엘(Giftiel) 연동 구조 분석

> PR #1580 (`Feature/#1577 giftiel 연동`) 코드 리뷰 기반 분석

## 1. 개요

기프티엘은 외부 상품권(모바일 쿠폰) 인증/사용 처리를 제공하는 업체이며, 헬로봇에서는 사용자가 외부에서 받은 기프티엘 쿠폰 코드를 입력하면 특정 스킬(콘텐츠)을 제공하는 방식으로 연동되어 있다.

### 핵심 흐름 요약

```
사용자가 쿠폰 코드 입력
  → 기프티엘 API로 쿠폰 유효성 확인 (L0)
  → 유효하면 기프티엘 API로 사용 처리 (L1)
  → 쿠폰에 매핑된 스킬(블록)으로 이동
  → 사용 이력 DB 저장
```

---

## 2. 변경 파일 목록

| 파일 | 역할 | 유형 |
|------|------|------|
| `src/common/config.ts` | 기프티엘 API 설정 (URL, 커맨드 코드 등) | 설정 |
| `src/controllers/giftiel.ts` | 쿠폰 조회/사용취소 API 엔드포인트 | Controller |
| `src/services/giftiel.ts` | 핵심 비즈니스 로직 | Service |
| `src/dtos/giftiel.dto.ts` | Request/Response DTO | DTO |
| `src/models/entities/GiftielProduct.ts` | 기프티엘 상품-스킬 매핑 엔티티 | Entity |
| `src/models/entities/GiftielCouponLog.ts` | 쿠폰 사용 이력 엔티티 | Entity |
| `src/repositories/giftiel-product.ts` | GiftielProduct Repository | Repository |
| `src/repositories/giftiel-coupon-log.ts` | GiftielCouponLog Repository | Repository |
| `src/models/send.ts` | 채팅 메시지 처리에 쿠폰 타입 추가 | 기존 수정 |
| `src/deprecated-controllers/chat-rooms.ts` | sendMessage에 coupon 타입 파라미터 추가 | 기존 수정 |
| `src/types/server.d.ts` | SendMessageType에 "coupon" 추가 | 타입 |
| `src/models/entities/SnapshotBlock.ts` | GiftielProduct 관계 추가 | 기존 수정 |
| `src/models/entities/SnapshotFixedMenu.ts` | GiftielProduct/CouponLog 관계 추가 | 기존 수정 |
| `src/models/entities/User.ts` | GiftielCouponLog 관계 추가 | 기존 수정 |
| `src/models/migrations/` | 테이블 생성 마이그레이션 3개 | Migration |

---

## 3. 기프티엘 외부 API 구조

### 3.1 API 엔드포인트

```
POST http://tposapi.giftiel.kr/WebAuthServiceJson.asmx/COUPON_AUTH
```

### 3.2 요청 형식

```json
{
  "COUPON_TYPE": "00",
  "COMMAND": "{L0|L1|L2}",
  "COMP_CODE": "A294",
  "BRANCH_CODE": "HELLOBOT1",
  "COUPON_NUMBER": "{쿠폰코드}",
  "USE_PRICE": ""
}
```

### 3.3 커맨드 코드

| 커맨드 | 코드 | 설명 |
|--------|------|------|
| check | `L0` | 쿠폰 유효성 조회 (사용 여부, 상품 정보 확인) |
| use | `L1` | 쿠폰 사용 처리 |
| unuse | `L2` | 쿠폰 사용 취소 |

### 3.4 응답 형식 (GiftielResponseType)

```typescript
{
  RESULTCODE: string;    // "00" = 성공
  RESULTMSG: string;     // 결과 메시지
  COMMAND: string;       // 요청한 커맨드
  COUPON_NAME: string;   // 쿠폰명
  USE_PRICE: string;     // 사용 금액
  PRODUCT_CODE: string;  // 상품 코드 (예: "XXX_YYY_{giftielProductSeq}")
  BAL_PRICE: string;     // 잔액
  COUPON_TYPE: string;   // 쿠폰 타입
  USE_YN: string;        // "Y" = 사용됨, "N" = 미사용
  BI_CODE: string;       // BI 코드
  AUTH_CODE: string;     // 인증 코드
  START_DAY: string;     // 유효기간 시작일
  END_DAY: string;       // 유효기간 종료일
  CREDIT_CARD_CODE: string;
  CREDIT_CARD_NAME: string;
}
```

### 3.5 유효성 판단 기준

```typescript
// 성공 코드 && 미사용 상태 → 유효한 쿠폰
valid = (RESULTCODE === "00") && (USE_YN === "N")
```

---

## 4. DB 설계

### 4.1 `giftiel_product` - 상품-스킬 매핑 테이블

기프티엘의 PRODUCT_CODE에서 추출한 seq와 헬로봇의 스킬(SnapshotFixedMenu/SnapshotBlock)을 연결하는 매핑 테이블.

```sql
CREATE TABLE "thingsflow"."giftiel_product" (
  seq SERIAL PRIMARY KEY,
  fixed_menu_seq INTEGER NOT NULL,    -- SnapshotFixedMenu FK (chatbot의 스킬)
  block_seq INTEGER NOT NULL,         -- SnapshotBlock FK (스킬 내 특정 블록)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(fixed_menu_seq, block_seq)
);
```

**관계**:
- `GiftielProduct` → `SnapshotFixedMenu` (ManyToOne, FK 미생성)
- `GiftielProduct` → `SnapshotBlock` (ManyToOne, FK 미생성)

### 4.2 `giftiel_coupon_log` - 쿠폰 사용 이력 테이블

```sql
CREATE TABLE "thingsflow"."giftiel_coupon_log" (
  seq SERIAL PRIMARY KEY,
  coupon_code VARCHAR NOT NULL,       -- 기프티엘 쿠폰 코드
  fixed_menu_seq INTEGER NOT NULL,    -- 사용된 스킬
  user_seq INTEGER NOT NULL,          -- 사용한 유저 (User FK)
  is_canceled BOOLEAN DEFAULT FALSE,  -- 취소 여부
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_seq, coupon_code)       -- 유저당 쿠폰 중복 사용 방지
);
```

**관계**:
- `GiftielCouponLog` → `User` (ManyToOne, FK 생성)
- `GiftielCouponLog` → `SnapshotFixedMenu` (ManyToOne, FK 미생성)

---

## 5. API 설계

### 5.1 `POST /api/giftiel/check` - 쿠폰 유효성 확인

클라이언트가 쿠폰 코드를 입력했을 때 유효한지 확인하고, 유효하면 연결된 chatbot 정보를 반환.

**인증**: 없음 (공개 API)

**Request**:
```json
{ "couponCode": "string" }
```

**Response**:
```json
{
  "data": {
    "valid": true,
    "chatbotSeq": 123
  }
}
```

**처리 흐름**:
1. 기프티엘 API에 `L0` (check) 요청
2. `RESULTCODE === "00"` && `USE_YN === "N"` 인지 확인
3. 유효하면 `PRODUCT_CODE`에서 `giftiel_product.seq` 추출
4. `GiftielProduct` → `SnapshotFixedMenu` → `chatbotSeq` 조회
5. `linkChatbotSeq`가 있으면 해당 chatbot의 seq 반환 (복사본 챗봇 지원)

### 5.2 `POST /api/giftiel/unuse` - 쿠폰 사용 취소

**인증**: 없음 (공개 API)

**Request**:
```json
{
  "couponCode": "string",
  "userSeq": 123
}
```

**Response**:
```json
{
  "data": {
    "success": true
  }
}
```

**처리 흐름**:
1. 기프티엘 API에 `L2` (unuse) 요청
2. 성공 시 `GiftielCouponLog`의 `isCanceled`를 `true`로 업데이트

### 5.3 채팅 메시지를 통한 쿠폰 사용 (내부 흐름)

사용자가 채팅에서 쿠폰을 사용하는 경우, 기존 `sendMessage` 플로우에 통합됨.

**진입점**: `POST /chat-rooms` (deprecated-controllers/chat-rooms.ts)
- `type: "coupon"`, `couponCode: "쿠폰코드"` 파라미터 추가

**처리 흐름** (`src/models/send.ts` - `getNextMessages`):
```
1. input.type === "coupon" 감지
2. giftielService.useCoupon(userSeq, couponCode) 호출
   a. 기프티엘 API에 L1 (use) 요청
   b. PRODUCT_CODE에서 giftielProduct.seq 추출
   c. GiftielProduct 조회
   d. 성공 시 GiftielCouponLog 생성/업데이트 (isCanceled: false)
   e. GiftielProduct 반환
3. input.type을 "block"으로 변경
4. input.blockSeq를 giftielProduct.blockSeq로 설정
5. → 이후 일반 블록 이동 로직으로 처리 (딥링크와 동일)
```

에러 발생 시: 에러 메시지를 텍스트 메시지로 반환

---

## 6. 상품 코드 ↔ GiftielProduct 매핑 규칙

기프티엘 응답의 `PRODUCT_CODE`에서 `GiftielProduct.seq`를 추출하는 로직:

```typescript
getGiftielProductSeq(productCode: string): number {
  const splitedCode = productCode.split("_");
  return Number(splitedCode[2]);  // "PREFIX_XXX_{seq}" 형식에서 세 번째 요소
}
```

즉, 기프티엘 측에 상품을 등록할 때 `PRODUCT_CODE`를 `{prefix}_{category}_{giftiel_product_seq}` 형식으로 설정해야 함.

---

## 7. 아키텍처 특이사항

### 7.1 Repository 패턴 사용

이 PR은 프로젝트의 현재 표준(Active Record + Service 직접 접근)과 달리 **Repository 패턴**을 사용한다.

```
Controller → Service → Repository → Entity
```

현재 프로젝트 표준:
```
Controller → Service → Entity (직접 접근)
```

> **참고**: CLAUDE.md에 따르면 Repository는 레거시 패턴이며, 새 코드는 Service에서 Entity에 직접 접근하는 것이 권장됨. 다만 이 PR은 2022년 코드(마이그레이션 타임스탬프 `1670983630490` = 2022-12-14)로, 당시에는 Repository 패턴이 표준이었을 수 있음. **쿠프마케팅 구현 시에는 현재 프로젝트 표준(Service에서 Entity 직접 접근)을 따릅니다.**

### 7.2 인증 부재

`/api/giftiel/check`와 `/api/giftiel/unuse` API에 `@Authorized()` 데코레이터가 없다.

- `/check`: 쿠폰 유효성만 확인하므로 공개 API로 문제없을 수 있음
- `/unuse`: `userSeq`를 body로 직접 받는 방식 → **인증 없이 다른 유저의 쿠폰 취소가 가능한 보안 이슈**

### 7.3 기프티엘 쿠폰 코드 파일명 이슈

`src/repositories/giftiel-coupon-log.ts` 파일명에 백스페이스 문자(`\b`)가 포함되어 있음:
```
src/repositories/\bgiftiel-coupon-log.ts
```
이는 의도치 않은 특수 문자이며, 일부 OS/도구에서 파일 접근 문제를 일으킬 수 있음.

### 7.4 쿠폰 사용 시 에러 처리

`send.ts`에서 쿠폰 사용 실패 시:
```typescript
catch (error) {
  return [{ data: util.createTextMessageData(errorMessage[error.code]?.ko) }];
}
```
- 기프티엘 API 에러를 그대로 사용자에게 텍스트 메시지로 전달
- `error.code`가 `errorMessage` 맵에 없으면 `undefined` 메시지가 노출될 수 있음

---

## 8. 쿠프마케팅 연동 설계 시 참고사항

기프티엘 연동 구조에서 쿠프마케팅 연동에 재사용 가능한 패턴:

| 항목 | 기프티엘 패턴 | 쿠프마케팅 적용 가능성 |
|------|-------------|---------------------|
| 외부 API 통신 | axios POST → 응답 파싱 | 동일 구조 적용 가능 |
| 쿠폰 검증 | L0 (check) | 유사한 검증 API 필요 |
| 쿠폰 사용 | L1 (use) → 스킬 블록 이동 | 하트 충전의 경우 블록 이동 대신 heartService.chargeHeart() 호출 필요 |
| 쿠폰 취소 | L2 (unuse) → isCanceled 플래그 | 하트 충전 취소 시 환불 로직 필요 |
| 상품 매핑 | GiftielProduct (상품→스킬 매핑) | 하트충전권: 매핑 불필요 / 스킬교환권: 유사 매핑 필요 |
| 사용 이력 | GiftielCouponLog | 유사한 이력 테이블 필요 |
| 채팅 통합 | sendMessage의 "coupon" 타입 | 동일 또는 유사한 타입 추가 필요 |

### 기프티엘과의 주요 차이점 (예상)

1. **하트 충전권**: 기프티엘은 스킬 제공만 하지만, 쿠프마케팅은 하트 충전이 필요 → `heartService.chargeHeart()` 연동 필요
2. **API 인증 방식**: 기프티엘은 COMP_CODE/BRANCH_CODE 기반이지만, 쿠프마케팅은 다른 인증 방식일 수 있음
3. **상품 유형**: 기프티엘은 스킬 교환만 지원하지만, 쿠프마케팅은 하트충전권 + 스킬교환권 두 가지를 지원해야 함
