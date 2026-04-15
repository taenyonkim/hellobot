# 디자인 자료 — 카카오 선물하기 상품권

## Figma

- **확정 디자인**: https://www.figma.com/design/hedYMUTlEPft16RaXdHAn0/-26.04--%EC%B9%B4%EC%B9%B4%EC%98%A4%EC%84%A0%EB%AC%BC%ED%95%98%EA%B8%B0-%EC%BF%A0%ED%8F%B0-%EB%B0%9C%EA%B8%89-%EB%B0%8F-%EC%82%AC%EC%9A%A9?node-id=1-7235&m=dev

## 와이어프레임

- [wireframe-v3.html](./wireframe-v3.html) — 인터랙티브 와이어프레임 확정본 (디자인 이전 단계)

## 화면 목록

| 화면 | 설명 | Figma Node | 비고 |
|------|------|-----------|------|
| 쿠폰 화면 | 기존 화면 + 입력란 힌트 변경 | App `1:8459`, Web `9:5306` | 네이티브 |
| S2-A 하트 확인 팝업 | 하트 아이콘, "충전하기" 버튼 | `23:4064` | 288px, rounded-20 |
| S2-B 스킬 확인 팝업 | 쿠폰 아이콘, "받기" 버튼 | `23:4095` | 288px, rounded-20 |
| S3 하트 완료 팝업 | 캐릭터+하트 일러스트, "확인" 단일 버튼 | - | 288px, rounded-20 |
| S4 이용권 카드 | 쿠폰 리스트 내 카드 | `10:10900` 섹션 | 기존 쿠폰 카드 형식 |
| S6 로그인 안내 팝업 | 경고 아이콘, "로그인하기"/"다음에 할래요" | App `23:3813`, Web `23:5028` | 288px, rounded-20 |
| 에러 토스트 | 하단 중앙 토스트 (2.5초 자동 사라짐) | - | 팝업 아닌 토스트 |

## 디자인 반영 현황

| 파트 | 상태 | 비고 |
|------|------|------|
| 웹 (hellobot-web) | 반영 완료 | [design-review.md](./design-review.md) 전항목 체크 |
| iOS | 미착수 | design-spec.md 참조하여 구현 |
| Android | 개발중 | design-spec.md 참조하여 구현 |

> 디자인 스펙 상세: [design-spec.md](../design-spec.md)
