# 이슈 목록

## 이슈 분류
- **bug**: 구현이 설계와 다름
- **edge-case**: 설계에서 고려하지 못한 예외 상황
- **enhancement**: 기존 요구사항 범위 밖의 개선

---

## 미해결 이슈

### ISS-001: 쿠폰 취소 후 재사용 시 CM_007 에러 (유니크 제약 위반 + 하트 누수)

| 항목 | 내용 |
|------|------|
| 분류 | edge-case |
| 발견일 | 2026-04-13 |
| 발견 단계 | QA (TC-E08 관련) |
| 심각도 | P1 — 하트 누수 발생 |
| 영향 파트 | 서버 |
| 상태 | 등록 |

**현상**: 쿠폰을 사용한 후 취소(L2)하고, 동일 쿠폰을 다시 사용하면 `CM_007` (하트 충전에 실패했습니다) 에러가 발생한다.

**원인**: 두 가지 문제가 복합적으로 작용한다.

1. **유니크 제약 위반**: `coupc_marketing_coupon_usage` 테이블에 `(user_seq, coupon_code)` 유니크 인덱스(`UQ_coupc_usage_user_coupon`)가 있다. 취소 시 레코드를 DELETE하지 않고 `status`를 `"canceled"`로 UPDATE만 하므로, 재사용 시 동일 키로 INSERT를 시도하면 유니크 제약 위반이 발생한다.

2. **트랜잭션 분리로 인한 하트 누수**: `processHeartCoupon`(coupc-marketing.ts:326-382)에서 하트 충전(`chargeHeart`)과 usage 기록(`CoupcMarketingCouponUsage.create().save()`)이 별도 트랜잭션으로 실행된다. 하트 충전이 먼저 성공한 후 usage INSERT에서 유니크 위반으로 실패하면, catch 블록에서 L2 취소를 시도하지만 이미 충전된 하트는 롤백되지 않는다.

```
정상 흐름:  L1 승인 → chargeHeart ✅ → usage INSERT ✅
이슈 흐름:  L1 승인 → chargeHeart ✅ → usage INSERT 💥 (유니크 위반)
                                         → catch: L2 취소 시도
                                         → 하트는 이미 충전됨 (롤백 안됨) ← 누수
```

**비고**: 취소 로직(`cancelCoupon`, line 455-482)도 함께 검토 필요. 현재 취소 시 쿠프마케팅 L2 API 호출 + usage status UPDATE만 수행하며, 충전된 하트나 발급된 쿠폰의 원복 처리가 없음.

---

## 해결된 이슈

(없음)
