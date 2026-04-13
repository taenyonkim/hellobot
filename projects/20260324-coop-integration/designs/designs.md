# 디자인 자료 — 카카오 선물하기 상품권

## Figma

- **확정 디자인**: https://www.figma.com/design/hedYMUTlEPft16RaXdHAn0/-26.04--%EC%B9%B4%EC%B9%B4%EC%98%A4%EC%84%A0%EB%AC%BC%ED%95%98%EA%B8%B0-%EC%BF%A0%ED%8F%B0-%EB%B0%9C%EA%B8%89-%EB%B0%8F-%EC%82%AC%EC%9A%A9?node-id=1-7235&m=dev

## 와이어프레임

- [wireframe-v3.html](./wireframe-v3.html) — 인터랙티브 와이어프레임 확정본 (디자인 이전 단계)

## 디자인 반영 현황

| 파트 | 상태 | 리뷰 문서 | 비고 |
|------|------|----------|------|
| 웹 (hellobot-web) | 반영 완료 | [design-review.md](./design-review.md) | 전항목 체크 완료 |
| iOS | 미착수 | - | Figma 디자인 참조하여 구현 |
| Android | 미착수 | - | Figma 디자인 참조하여 구현 |

## 화면 목록

Figma 디자인에 포함된 화면:

| 화면 | 설명 | 비고 |
|------|------|------|
| 쿠폰 화면 | 기존 화면 + 입력란 힌트 변경 | 네이티브 |
| S2-A 하트 확인 팝업 | 하트 아이콘(24px), "충전하기" 버튼 | 288px, rounded-20 |
| S2-B 스킬 확인 팝업 | 쿠폰 아이콘(24px), "받기" 버튼 | 288px, rounded-20 |
| S3 하트 완료 팝업 | 캐릭터+하트 일러스트, "확인" 단일 버튼 | 288px, rounded-20 |
| S4 이용권 카드 | 쿠폰 리스트 내 카드 (이용권 태그, 100%, 만료일) | 기존 쿠폰 카드 형식 |
| 에러 토스트 | 하단 중앙 토스트 (2.5초 자동 사라짐) | 팝업 아닌 토스트 |

## 공통 디자인 스펙

### 팝업

- 너비: **288px**, radius: **20px**, padding: **24px**
- 그림자: `0px 8px 24px rgba(0,0,0,0.24)`
- 오버레이: `rgba(36,37,38,0.7)`
- 확인 버튼: `#FFE967` (노란), 텍스트 `#242526`, h-48, rounded-26
- 취소 버튼: `#EDEDEE`, 텍스트 `#242526`, h-48, rounded-26

### 토스트

- 배경: `rgba(36,37,38,0.8)`, radius: **8px**
- 텍스트: 14px Regular, white, `tracking-[-0.3px]`
- 패딩: `px-20 pt-13 pb-11`
- 위치: 하단 중앙
- 자동 사라짐: 2.5초

### 이용권 카드

- 배경: white, 테두리: `#EDEDEE`
- "이용권" 태그: 흰 배경, `border-[#EDEDEE]`, `text-[#7E8185]`, 11px Bold
- 할인율: "100%", 18px Bold, `#FF5D7A`
- 만료일: "YYYY.MM.DD HH:mm까지", 12px Regular, `#7E8185`
- 만료 임박: "N일 남음", 12px Regular, `#F23658`
- 링크: "스킬 보러가기 >", 12px Bold, `#BE7AFE`

## 이미지 에셋

### 웹용 (public/images/coop/)

| 파일 | 용도 | 크기 |
|------|------|------|
| `icon_heart_24.svg` | 하트 확인 팝업 아이콘 | 24x24, 2.0K |
| `icon_coupon_24.svg` | 스킬 확인 팝업 아이콘 | 24x24, 2.6K |
| `img_heart_complete.png` | 하트 완료 팝업 일러스트 | 1184x576, 32K |

### 앱용

iOS/Android에서 동일 에셋이 필요합니다. 앱 디자인 시스템에 맞는 에셋 형식으로 Figma에서 export하세요.

- 하트 아이콘 (24px) — 확인 팝업용
- 쿠폰 아이콘 (24px) — 확인 팝업용
- 캐릭터+하트 일러스트 — 완료 팝업용 (앱 공통 에셋에 동일 이미지가 있는지 확인 필요)
