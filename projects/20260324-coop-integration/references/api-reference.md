# 쿠프마케팅 API 레퍼런스 (사용자 스토리 기준 정리)

> 원본: `통합 쿠폰인증 연동가이드 HTTP v1.1.1.pdf` (2025-09-08, 기프트카드 상품권 추가)

---

## 1. 연동 기본 정보

| 항목 | 값 |
|------|-----|
| 엔드포인트 | 단일 API: `POST /AuthUse` |
| 개발 서버 | `http://test.authapi.inumber.co.kr:9999` |
| 상용 서버 | **별도 제공** (미확정) |
| 데이터 포맷 | JSON (XML도 지원 가능) |
| 방화벽 | 헬로우봇 서버 공인 IP 오픈 필요 |
| 테스트 인증키 | `g9PJGmeh6BaSfprJx1xkAQ` |

---

## 2. 요청/응답 전문 상세

### 2-1. Request 필드

| 필드명 | 설명 | 타입 | 길이 | 필수 | 비고 |
|--------|------|------|------|------|------|
| `Auth_Key` | 인증키 | String | 22 | O | 고정값 (테스트: `g9PJGmeh6BaSfprJx1xkAQ`) |
| `ProcessType` | 처리유형 | String | 2 | O | `L0`/`L1`/`L2`/`L3`/`A1`~`A3`/`C1`~`C3` |
| `CompCode` | 브랜드코드 | String | 8 | O | **미확정 (Q3)** |
| `CouponNum` | 쿠폰번호 | String | 30 | O | 쿠폰사 발행번호, **하이픈(`-`) 제외** |
| `BranchCode` | 가맹점코드 | String | 20 | O | **미확정 (Q4)** |
| `PosNum` | POS코드 | String | 4 | S | 온라인 서비스에서 고정값 사용 가능한지 확인 필요 (Q8) |
| `CouponType` | 쿠폰종류코드 | String | 2 | O | `00`/`01`/`02`/`03` (아래 상세) |
| `AuthPrice` | 사용금액 | String | 9 | S | **CouponType=`02` 금액권 처리 시 필수** |
| `Auth_Date` | 사용일자 | String | 20 | X | `yyyy-mm-dd HH:mm:ss` 형식 |
| `BrandAuthCode` | 승인번호 | String | 20 | S | **L2 사용취소 시 필수** — L1 응답에서 받은 값 |
| `OriginalAuthCode` | 거래번호 | String | 20 | O | 우리(브랜드사)가 생성/관리하는 고유 번호 |

#### OriginalAuthCode 규칙

- **모든 요청에 필수** (L0 조회 시에만 공백 허용)
- 형식 권고: `YYYYMMDDHHMMSS` + 추가 6자리 (총 20자)
- **L1/L2 각 요청마다 유니크하게 생성**해야 함
- L3 망취소 시에는 **원거래의 동일한 OriginalAuthCode**를 재사용

#### CouponType 상세

| 코드 | 종류 | 설명 | AuthPrice 필수 |
|------|------|------|:--------------:|
| `00` (또는 공백) | 교환권 | 상품교환형 | X |
| `01` | 할인권 | 상품교환형 | X |
| `02` | 잔액관리형 | 금액권 | **O** |
| `03` | 카카오 직발급 잔액관리형 | 카카오 금액권 | **O** |

> **중요**: CouponType 불일치 시 `8006` 에러 반환. L0 조회에서 응답의 CouponType을 확인한 후, L1 사용 시 **동일한 CouponType으로 전송**해야 함.

### 2-2. Response 필드

| 필드명 | 설명 | 타입 | 길이 | 필수 | 비고 |
|--------|------|------|------|------|------|
| `ResultCode` | 응답코드 | String | 4 | O | `0000`=성공 |
| `ResultMsg` | 응답메시지 | String | 100 | O | |
| `CouponType` | 쿠폰종류코드 | String | 2 | O | |
| `CompCode` | 브랜드코드 | String | 8 | O | 쿠프마케팅 관리 코드 |
| `CouponNum` | 쿠폰번호 | String | 30 | O | |
| `BranchCode` | 가맹점코드 | String | 20 | O | |
| `PosNum` | POS코드 | String | 4 | S | |
| `CouponName` | 쿠폰명 | String | 80 | O | 쿠폰 시스템에서 관리되는 이름 |
| `StartDay` | 유효기간 시작일 | String | 10 | S | `yyyy-MM-dd` |
| `EndDay` | 유효기간 종료일 | String | 10 | S | `yyyy-MM-dd` |
| `UsePrice` | 소비자 가격 | String | 9 | O | 쿠폰 등록된 소비자가 |
| `BalPrice` | 쿠폰 잔액 | String | 9 | S | 최초 사용 가능 금액 또는 잔액 |
| `SelPrice` | 판매가 | String | 9 | S | 협의된 브랜드에 한함 |
| `UseYN` | 사용 여부 | String | 1 | S | `Y`=사용됨, `N`=사용가능 |
| `ProductState` | 상품권 상태 | String | 2 | S | `IF`=정상, `AW`=비활성화 |
| `AuthDate` | 사용일시 | String | 20 | S | 사용된 쿠폰인 경우 |
| `BrandAuthCode` | 승인번호 | String | 20 | S | 쿠프마케팅 승인번호 |
| `OriginalAuthCode` | 거래번호 | String | 20 | S | 요청 시 보낸 거래번호 에코백 |
| `ProductCode` | 브랜드 상품코드 | String | 40 | S | **브랜드사에서 관리하는 상품코드** |

### 2-3. 응답 코드표

| 코드 | 메시지 | 설명 | 사용자 안내 (제안) |
|------|--------|------|-------------------|
| `0000` | 완료 | 정상 처리 | — |
| `8001` | 미존재쿠폰 | 발급정보 확인 불가 | "유효하지 않은 쿠폰번호예요" |
| `8002` | 비정상쿠폰번호 | 발급정보 확인 불가 | "유효하지 않은 쿠폰번호예요" |
| `8003` | 기간만료쿠폰 | 유효기간 종료 (연장 후 처리 가능) | "기간이 만료된 쿠폰이에요" |
| `8005` | 사용된 쿠폰 / 취소된 쿠폰 | 요청에 따른 반전 메시지 | "이미 사용된 쿠폰이에요" |
| `8006` | 쿠폰타입불일치 | CouponType 불일치 | (내부 처리 오류 — 사용자 노출 X) |
| `8099` | 결제취소 쿠폰 | 결제 자체가 취소된 쿠폰 | "취소된 쿠폰이에요" |
| `9981` | 입력데이터 형식오류 | NULL 등 입력값 오류 | (내부 처리 오류) |
| `9982` | 데이터 오류 | 데이터 오류 | "일시적 오류가 발생했어요" |
| `9983` | 데이터 처리 실패 | 처리 실패 | "일시적 오류가 발생했어요" |
| `9999` | 기타오류 | 모든 기타 오류 | "일시적 오류가 발생했어요" |

---

## 3. 사용자 스토리별 API 호출 흐름

### 3-1. US-1/US-2: 쿠폰 조회 → 사용 (L0 → L1)

사용자가 카카오 선물하기로 받은 쿠폰번호를 입력하면, 서버가 해당 쿠폰을 조회(L0)하여 유효한 쿠폰인지 확인한다. 유효하면 상품 정보(하트 수량 또는 스킬명)를 보여주고, 사용자가 "사용하기"를 누르면 쿠폰 사용(L1) 처리 후 즉시 하트 충전 또는 스킬을 제공한다.

#### Step 1: 쿠폰 조회 (L0)

```json
// Request
{
  "Auth_Key": "{AUTH_KEY}",
  "ProcessType": "L0",
  "CompCode": "{COMP_CODE}",
  "CouponNum": "619917794132",
  "BranchCode": "{BRANCH_CODE}",
  "PosNum": "",
  "CouponType": "00",
  "AuthPrice": "",
  "Auth_Date": "",
  "BrandAuthCode": "",
  "OriginalAuthCode": ""          // L0는 공백 허용
}
```

```json
// Response (성공)
{
  "ResultCode": "0000",
  "ResultMsg": "정상 처리",
  "CouponType": "03",             // ← 실제 쿠폰종류 (이 값을 L1에서 사용)
  "CompCode": "A604",
  "CouponNum": "722259158866",
  "CouponName": "금액권 인증 테스트 1만원권",
  "EndDay": "2025-06-20",
  "UsePrice": "10000",            // ← 소비자가
  "BalPrice": "1000",             // ← 잔액
  "UseYN": "N",                   // ← N이어야 사용 가능
  "ProductCode": "9999999",       // ← 상품코드 (상품 매핑에 사용)
  "BrandAuthCode": "",
  "OriginalAuthCode": ""
}
```

**L0 응답에서 추출할 정보**:
1. `ResultCode` → `0000` 확인
2. `UseYN` → `N` 확인 (사용 가능)
3. `CouponType` → L1 요청 시 이 값 그대로 사용 (불일치 시 8006 에러)
4. `ProductCode` → `coupc_marketing_product` 테이블 조회용 **(S 필드 — 항상 반환되는지 확인 필요 → NEW-2)**
5. `UsePrice` → 소비자가
6. `BalPrice` → 잔액 (잔액관리형)
7. `EndDay` → 유효기간
8. `CouponName` → 쿠폰명 (사용자 화면 표시용)

#### Step 2: 쿠폰 사용 (L1)

```json
// Request
{
  "Auth_Key": "{AUTH_KEY}",
  "ProcessType": "L1",
  "CompCode": "{COMP_CODE}",
  "CouponNum": "619917794132",
  "BranchCode": "{BRANCH_CODE}",
  "PosNum": "",
  "CouponType": "03",             // ← L0 응답의 CouponType 그대로
  "AuthPrice": "10000",           // ← CouponType=02/03일 때 필수
  "Auth_Date": "",
  "BrandAuthCode": "",
  "OriginalAuthCode": "20260401143000123456"  // ← 유니크 거래번호 생성
}
```

```json
// Response (성공)
{
  "ResultCode": "0000",
  "ResultMsg": "정상 처리",
  "BrandAuthCode": "20250908194756013",  // ← 저장 필수 (L2 취소 시 필요)
  "OriginalAuthCode": "20260401143000123456",
  "ProductCode": "9999999",
  // ...기타 필드
}
```

**L1 성공 후 저장할 정보**:
1. `BrandAuthCode` → `coupc_marketing_coupon_usage.brand_auth_code` (취소 시 필수)
2. `OriginalAuthCode` → `coupc_marketing_api_log.original_auth_code`

#### 하트 충전권 vs 스킬 교환권 분기

| 단계 | 하트 충전권 (US-1) | 스킬 교환권 (US-2) |
|------|-------------------|-------------------|
| L0 조회 | CouponType 확인 (`02` or `03`) | CouponType 확인 (`00`) |
| L1 사용 | **AuthPrice 필수** (상품 금액) | AuthPrice 불필요 |
| L1 후 처리 | `HeartService.chargeHeart()` | 스킬 제공 (S1 확정 필요) |

---

### 3-2. US-5: 사용취소 (L2)

사용자가 CS 문의를 하거나 오류가 발생한 경우, 관리자가 AdminJS에서 해당 사용 이력을 찾아 "취소" 버튼을 누른다. 서버가 쿠프마케팅에 사용취소(L2)를 요청하여 쿠폰을 미사용 상태로 원복한다.

```json
// Request
{
  "Auth_Key": "{AUTH_KEY}",
  "ProcessType": "L2",
  "CompCode": "{COMP_CODE}",
  "CouponNum": "619917794132",
  "BranchCode": "{BRANCH_CODE}",
  "PosNum": "",
  "CouponType": "03",
  "AuthPrice": "",
  "Auth_Date": "",
  "BrandAuthCode": "20250908194756013",    // ← L1 응답에서 받은 승인번호 (금액권 시 필수)
  "OriginalAuthCode": "20260401144000654321"  // ← 새 거래번호 생성
}
```

```json
// Response (성공)
{
  "ResultCode": "0000",
  "ResultMsg": "정상 처리",
  "BrandAuthCode": "20250908194758445",    // ← L2의 새 승인번호
  "UseYN": "N",                            // ← 사용 취소되어 N으로 복원
  // ...기타 필드
}
```

**핵심**: `BrandAuthCode`는 금액권(`02`/`03`) 취소 시 필수. 교환권(`00`) 취소 시에도 포함하는 것이 안전.

---

### 3-3. 망취소 (L3) — 에러 복구

사용자가 쿠폰을 사용(L1)하거나 관리자가 취소(L2)를 요청했는데, 네트워크 타임아웃 등으로 정상 응답을 받지 못한 경우에 사용한다. 쿠프마케팅 서버에서는 처리가 완료되었을 수 있으므로, 망취소(L3)로 해당 거래를 롤백하여 데이터 불일치를 방지한다.

```json
// Request — 원거래와 동일한 OriginalAuthCode 사용
{
  "Auth_Key": "{AUTH_KEY}",
  "ProcessType": "L3",
  "CompCode": "{COMP_CODE}",
  "CouponNum": "619917794132",
  "BranchCode": "{BRANCH_CODE}",
  "PosNum": "",
  "CouponType": "03",
  "AuthPrice": "",
  "Auth_Date": "",
  "BrandAuthCode": "",
  "OriginalAuthCode": "20260401143000123456"  // ← 원거래의 거래번호 그대로
}
```

**망취소 동작 원리**:
- L1(사용) 후 장애 → L3 요청 → 쿠폰이 [사용] 상태면 → [사용취소] 처리
- L2(사용취소) 후 장애 → L3 요청 → 쿠폰이 [사용취소] 상태면 → [사용] 복원

**망취소 대체 방식** (문서 섹션 3-7):
L3 대신 클라이언트 측에서 직접 처리 가능:
1. L1 사용 후 장애 → L0 조회 → UseYN=`Y`(사용됨)이면 → L2 사용취소 판단
2. L2 취소 후 장애 → L0 조회 → UseYN=`N`(사용취소됨)이면 → L1 재사용 판단

---

## 4. 설계 영향 분석

PDF 원문 분석을 통해 기존 설계 문서에서 누락/부정확했던 부분을 정리합니다.

### 4-1. 기존 설계 확정 (PDF 근거)

| 항목 | 기존 가정 | PDF 확인 결과 | 영향 |
|------|----------|--------------|------|
| CouponType 필수 여부 | 요청에 포함 | **모든 요청에 O(필수)** — L0 포함 | L0 조회 시에도 CouponType을 보내야 함. 모르는 경우 빈 문자열/공백 가능한지 확인 필요 |
| ProductCode 응답 포함 | 가정했으나 미확인 | 응답 필드에 **S(선택적)** 로 존재 | **항상 반환되는지 확인 필요** → NEW-2 유지. 미반환 시 상품 매핑 불가 |
| OriginalAuthCode 형식 | UUID 가정 | `YYYYMMDDHHMMSS` + 6자리 권고 (총 20자, String) | UUID(36자) → 20자 이내로 변경 필요 |
| L0 조회 시 OriginalAuthCode | 필수 | **L0에서만 공백 허용** | L0 호출 시 공백 전송 가능 |
| Auth_Date | 미고려 | **X(임의)** — 필수 아님 | 전송하지 않아도 됨 |
| BrandAuthCode | L2 시 필수 | 문서 명시: **금액권(`02`)인 경우 L2 시 필수** | 교환권(`00`)은 필수 아닐 수 있으나, 전송하는 것이 안전 |

### 4-2. 설계 수정 필요 사항

#### (1) OriginalAuthCode 생성 방식 변경

```
기존 설계: UUID (예: "550e8400-e29b-41d4-a716-446655440000") — 36자
PDF 권고:  YYYYMMDDHHMMSS + 6자리 (예: "20260401143000123456") — 20자

→ 20자 이내의 유니크 거래번호 생성 로직 필요
→ 형식 예: `{YYYYMMDDHHMMSS}{6자리 랜덤/시퀀스}`
```

#### (2) L0 요청 시 CouponType 처리

L0 조회 시 아직 쿠폰의 종류를 모르는 상태. 두 가지 방식:
- **방식 A**: CouponType에 공백/`00` 전송 → L0 응답의 CouponType으로 실제 종류 파악
- **방식 B**: 상품 유형을 미리 선택하게 하여 CouponType을 알고 전송

> PDF 예시에서 L0 요청 시 `"CouponType": "00"`을 전송하고 응답에서 실제 `"CouponType": "03"`이 돌아옴. **L0에서는 CouponType 불일치로 에러가 나지 않는 것으로 보임** (에러는 L1에서 발생).

#### (3) 망취소 대체 방식 설계 반영

PDF 섹션 3-7에서 L3 대신 **L0 조회 → 상태 확인 → L2 판단** 방식을 안내함. 두 방식을 모두 고려:

```
방식 1 (L3 직접 호출):
  L1 타임아웃 → L3(원거래 번호) → 롤백

방식 2 (L0 → L2 대체):
  L1 타임아웃 → L0 조회 → UseYN="Y"면 → L2 사용취소

→ 어느 방식을 쓸지 결정 필요 (또는 L3 우선, 실패 시 방식 2 폴백)
```

### 4-3. 기존 미확정 사항 해소/갱신

| # | 항목 | PDF로 해소 여부 | 결과 |
|---|------|:---------------:|------|
| Q5 | 하트충전권 CouponType | **부분** | PDF 예시에서 금액권은 `03`(카카오 직발급 잔액관리형) 사용. 하트충전권이 이에 해당하는지 쿠프마케팅 확인 필요 |
| Q6 | 스킬교환권 CouponType | **추정 가능** | 교환권이면 `00`. 쿠프마케팅 확인 필요 |
| Q8 | POS코드 필수 여부 | **부분** | S(선택적 필수) — 온라인 서비스에서 빈 문자열 전송 가능한지 확인 필요 |
| NEW-2 | L0 응답 ProductCode | **확인** | 응답 필드에 존재 (S). PDF 예시에서 `"ProductCode": "9999999"` 반환됨. 단, S이므로 항상 반환 보장은 쿠프마케팅에 확인 필요 |

### 4-4. 쿠프마케팅 확인 요청 사항 (갱신)

PDF 분석 후 갱신된 질문 목록:

**개발 차단 (필수)**:
| # | 질문 | 근거 |
|---|------|------|
| Q3 | CompCode (브랜드코드) 값 | 요청 필수 필드 (O), 8자 |
| Q4 | BranchCode (가맹점코드) 값 | 요청 필수 필드 (O), 20자 |
| Q10 | 테스트 쿠폰번호 | 개발/QA 검증 |

**설계 확정**:
| # | 질문 | 근거 |
|---|------|------|
| Q5 | 하트충전권 CouponType: `02` vs `03`? | PDF 예시는 `03`(카카오 직발급). 하트충전권이 카카오 선물하기 발급이므로 `03`일 가능성 높음 |
| Q6 | 스킬교환권 CouponType: `00`? | 교환권이면 `00`이 맞는지 확인 |
| Q8 | PosNum: 빈 문자열 전송 가능? | 온라인 서비스라 POS 없음. PDF 예시에서 빈 문자열 사용 케이스 있음 |
| NEW-2 | ProductCode가 **모든 상품에서 항상 반환**되는가? | 응답 필드가 S(선택적). 상품 매핑의 핵심이라 반드시 확인 |
| NEW-4 | L0 조회 시 CouponType을 모를 때 **공백 또는 `00` 전송**해도 되는가? | PDF 예시에서 `00`으로 보냈는데 응답이 `03`으로 오는 케이스 확인. L0에서는 불일치 에러가 안 나는 것 같으나 명시적 확인 필요 |
| NEW-5 | OriginalAuthCode **정확한 형식 제약**은? `YYYYMMDDHHMMSS` + 6자리가 권고인지 필수인지 | 문서에 "권고"라고 되어 있으나, 다른 형식 허용 여부 확인 |

---

## 5. 구현 체크리스트 (PDF 기반)

PDF 원문에서 도출된, 구현 시 반드시 지켜야 할 사항:

### 5-1. 요청 구성

- [ ] `CouponNum`에서 하이픈(`-`) 제거 후 전송
- [ ] `OriginalAuthCode`는 20자 이내, `YYYYMMDDHHMMSS` + 6자리 형식
- [ ] `OriginalAuthCode`는 L1/L2 요청마다 새로 생성 (유니크)
- [ ] `OriginalAuthCode`는 L3 망취소 시 원거래 번호 재사용
- [ ] `OriginalAuthCode`는 L0 조회 시 공백 허용
- [ ] `CouponType`은 L0 응답에서 받은 값을 L1/L2에서 그대로 사용
- [ ] `AuthPrice`는 CouponType=`02`/`03`(금액권)일 때 필수
- [ ] `BrandAuthCode`는 L2 사용취소 시 L1 응답의 값 전송 (금액권 필수)

### 5-2. 응답 처리

- [ ] `ResultCode` === `"0000"` 으로 성공 판단 (문자열 비교)
- [ ] L0 응답에서 `UseYN` === `"N"` 확인 (사용 가능 여부)
- [ ] L0 응답에서 `CouponType` 추출 → 이후 L1/L2에 사용
- [ ] L0 응답에서 `ProductCode` 추출 → 상품 매핑 (S 필드 — null 체크 필수)
- [ ] L1 응답에서 `BrandAuthCode` 저장 (취소 시 필요)
- [ ] 에러 코드별 분기 처리 (8001/8002 → 미존재, 8003 → 만료, 8005 → 사용/취소됨, 8099 → 결제취소)

### 5-3. 타입 주의사항

- [ ] 모든 숫자 필드가 **String 타입** (`AuthPrice`, `UsePrice`, `BalPrice` 등) — 숫자 변환 시 파싱 필요
- [ ] `UseYN`은 `"Y"` / `"N"` 문자열 (boolean 아님)
- [ ] `ResultCode`는 4자리 문자열 (`"0000"`, `"8001"` 등)

---

## 6. PDF 예시 전문 (원본)

### 조회(L0) Request 예시

```json
{
  "AuthKey": "g9PJGmeh6BaSfprJx1xkAQ",
  "ProcessType": "L0",
  "CouponType": "00",
  "CompCode": "NB01",
  "CouponNum": "619917794132",
  "BranchCode": "3212",
  "PosNum": "0001",
  "AuthPrice": "",
  "AuthDate": "",
  "BrandAuthCode": "",
  "OriginalAuthCode": ""
}
```

### 조회(L0) Response 예시

```json
{
  "ResultCode": "0000",
  "ResultMsg": "정상 처리",
  "CouponType": "03",
  "CompCode": "A604",
  "CouponNum": "722259158866",
  "BranchCode": "",
  "PosNum": "",
  "CouponName": "금액권 인증 테스트 1만원권",
  "StartDay": "",
  "EndDay": "2025-06-20",
  "UsePrice": "10000",
  "BalPrice": "1000",
  "SelPrice": "10000",
  "UseYN": "Y",
  "ProductState": "",
  "AuthDate": "",
  "BrandAuthCode": "20240805180923937",
  "OriginalAuthCode": "2202202020",
  "ProductCode": "9999999"
}
```

> **참고**: 이 예시는 `UseYN: "Y"` (이미 사용된 쿠폰)를 조회한 결과. 사용 가능한 쿠폰이면 `UseYN: "N"`이고 `BrandAuthCode`는 빈 값.

### 필드명 주의

PDF 예시에서 Request의 인증키 필드명이 `AuthKey`로 표기되어 있으나, 스펙 테이블에서는 `Auth_Key`로 표기. **실제 필드명은 쿠프마케팅 테스트 서버에서 확인 필요**.
