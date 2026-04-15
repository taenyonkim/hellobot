# 디자인 스펙 — 카카오 선물하기 상품권

## Figma 원본

- **확정 디자인**: https://www.figma.com/design/hedYMUTlEPft16RaXdHAn0/-26.04--%EC%B9%B4%EC%B9%B4%EC%98%A4%EC%84%A0%EB%AC%BC%ED%95%98%EA%B8%B0-%EC%BF%A0%ED%8F%B0-%EB%B0%9C%EA%B8%89-%EB%B0%8F-%EC%82%AC%EC%9A%A9?node-id=1-7235&m=dev
- **디자인 페이지**: `1:7235` (🎨 디자인)
- **섹션**: App (`1:9442`), Web (`7:2607`), 이용권 쿠폰 설명 (`10:10900`), Flow (`9:5632`)

---

## 공통 스타일

### 디자인 토큰 — 컬러

| 토큰 | 색상 | 용도 |
|------|------|------|
| PRIMARY YELLOW 400 | `#FFE967` | 확인/충전/받기 버튼, 로그인 안내 배너 |
| GRAY 900 | `#242526` | 기본 텍스트, 버튼 텍스트 |
| GRAY 600 | `#7E8185` | 보조 텍스트, 만료일 텍스트, 이용권 태그 |
| GRAY 500 | `#A4A7AD` | placeholder, 빈 상태 텍스트 |
| GRAY 400 | `#C6C8CC` | 비활성 버튼 배경 |
| GRAY 200 | `#EDEDEE` | 취소 버튼 배경, 카드 테두리, 이용권 태그 테두리 |
| GRAY 100 | `#F5F5F5` | 인풋 배경 |
| WHITE | `#FFFFFF` | 팝업/카드 배경 |
| SUB RED 400 | `#FF5D7A` | 캡션 (하트 충전 쿠폰/스킬 이용 쿠폰), 만료 임박 |
| SUB RED 600 | `#F23658` | 만료 임박 "N일 남음" |
| SUB PURPLE | `#BE7AFE` | "스킬 보러가기 >" 링크 |
| Overlay | `rgba(36,37,38,0.7)` | 팝업 배경 오버레이 |
| Toast BG | `rgba(36,37,38,0.8)` | 토스트 배경 |

### 디자인 토큰 — 타이포그래피

| 토큰 | 폰트 | 크기 | 굵기 | 행간 | 자간 | 용도 |
|------|------|------|------|------|------|------|
| Heading 2 | Pretendard | 22px | Bold (700) | 28px | -0.1px | 팝업 제목 |
| Body 3 (Bold) | Pretendard | 16px | SemiBold (600) | 24px | -0.1px | 버튼 텍스트 |
| Label 1 | Pretendard | 14px | Regular (400) | 20px | -0.1px | 팝업 본문 설명 |
| Caption 1 | Pretendard | 12px | Regular (400) | 16px | -0.1px | 캡션 (쿠폰 유형) |
| Body 3 (App) | Apple SD Gothic Neo | 16px | Regular (400) | 24px | -0.6px | 앱 본문 |
| Body 1 (App) | Apple SD Gothic Neo | 13px | Regular (400) | 19px | -0.3px | 앱 안내 배너 |

### 공통 컴포넌트 — 팝업

| 속성 | 값 |
|------|-----|
| 너비 | 288px |
| border-radius | 20px |
| padding | 24px |
| 그림자 | `0px 8px 24px rgba(0,0,0,0.24)` |
| 오버레이 | `rgba(36,37,38,0.7)` |
| 내부 구조 | textSet (gap 12px) + buttonSet (gap 8px), 전체 gap 20px |

### 공통 컴포넌트 — 버튼 (Button/Sub)

| 속성 | 확인 버튼 | 취소 버튼 |
|------|---------|---------|
| 배경 | `#FFE967` | `#EDEDEE` |
| 텍스트 색상 | `#242526` | `#242526` |
| 높이 | 48px | 48px |
| border-radius | 26px |
| padding | 12px 24px |
| min-width | 100px |
| 폰트 | Pretendard SemiBold 16px |
| 레이아웃 | flex: 1 (2버튼 시 균등 분할, gap 8px) |

### 공통 컴포넌트 — 등록 버튼

| 상태 | 배경 | 텍스트 |
|------|------|--------|
| 활성 | `#FFE967` | `#242526` "등록" |
| 비활성 | `#C6C8CC` | `#EDEDEE` "등록" |

---

## 화면별 스펙

### S2-A: 하트 충전 확인 팝업 (Figma node `23:4064`)

| 요소 | 스펙 |
|------|------|
| 아이콘 | HeartList/Large 24x24 (`icon_heart_24.svg`) |
| 캡션 | "하트 충전 쿠폰" — Caption 1, `#FF5D7A` |
| 제목 | "하트 {N}개 충전" — Heading 2, `#242526` |
| 본문 | "이 쿠폰을 사용해서\n하트 {N}개를 충전할까요?" — Label 1, `#7E8185` |
| 취소 버튼 | "취소" |
| 확인 버튼 | "충전하기" |
| 레이아웃 | 아이콘 → 캡션 → 제목 (gap 6px) → 본문 (gap 12px) → 버튼 (gap 20px) |

### S2-B: 스킬 교환 확인 팝업 (Figma node `23:4095`)

| 요소 | 스펙 |
|------|------|
| 아이콘 | coupon/Large 24x24 (`icon_coupon_24.svg`) |
| 캡션 | "스킬 이용 쿠폰" — Caption 1, `#FF5D7A` |
| 제목 | "{스킬명}" — Heading 2, `#242526` |
| 본문 | "이 쿠폰을 사용해서\n{스킬명} 이용권을 받을까요?" — Label 1, `#7E8185` |
| 취소 버튼 | "취소" |
| 확인 버튼 | "받기" |

### S3: 하트 충전 완료 팝업

| 요소 | 스펙 |
|------|------|
| 일러스트 | 캐릭터+하트 이미지 (`img_heart_complete.png`), 높이 약 140px |
| 캡션 | 이벤트/상품명 — Caption 1, `#FF5D7A` |
| 제목 | "하트가 {N}개 충전되었어요!" — Heading 2, `#242526` |
| 본문 | "하트는 \<프로필\>탭에서 확인 가능해요" — Label 1, `#7E8185` |
| 버튼 | "확인" 노란 단일 버튼 (취소 버튼 없음) |

### S4: 스킬 이용권 카드

기존 쿠폰 카드 형식을 따름.

| 요소 | 스펙 |
|------|------|
| 카드 배경 | white, border `#EDEDEE` |
| 라벨 | "이용권" 태그 — 11px Bold, `#7E8185`, border `#EDEDEE`, 흰 배경 |
| 할인율 | "100%" — 18px Bold, `#FF5D7A` |
| 쿠폰명 | 스킬명 — 16px Bold, `#242526` |
| 챗봇명 | 미노출 (opacity: 0) |
| 만료일 | "YYYY.MM.DD HH:mm까지" — 12px Regular, `#7E8185` |
| 만료 임박 | "N일 남음" — 12px Regular, `#F23658` + 구분선 (1px, `#EDEDEE`) |
| 링크 | "스킬 보러가기 >" — 12px Bold, `#BE7AFE` |
| 동작 | 카드 탭 → 스킬 상세 페이지 이동 |

### S6: 로그인 안내 팝업 (Figma node `23:3813`)

팝업 내부 + 팝업 외부(dim 영역) "다음에 할래요" 텍스트 구조.

| 요소 | 스펙 |
|------|------|
| 아이콘 | Connect/Idea 24x24 (`icon_warning_24.svg`, 빨간 원형 느낌표) |
| 제목 | "로그인하지 않고\n쿠폰을 등록하면 위험해요" — Heading 2, `#242526` |
| 본문 | "소중한 선물이 사라질 수 있어요\n꼭 로그인하고 입력해 주세요" — Label 1, `#7E8185` |
| 확인 버튼 | "로그인하기" — 노란 단일 버튼 (팝업 내부) |
| 닫기 | "다음에 할래요" — 14px Regular, white, 팝업 **외부** 하단 (dim 영역 위) |
| dim 클릭 | 닫기 차단 — 반드시 버튼으로만 닫기 |
| 1회 노출 | "다음에 할래요" 클릭 시 세션 내 재노출 안 함 (sessionStorage) |
| 팝업-텍스트 간격 | gap 24px |

### 에러 토스트

| 요소 | 스펙 |
|------|------|
| 배경 | `rgba(36,37,38,0.8)`, radius 8px |
| 텍스트 | 14px Regular, white, tracking -0.3px |
| 패딩 | px 20px, pt 13px, pb 11px |
| 위치 | 하단 중앙 |
| 자동 사라짐 | 2.5초 |

### 쿠폰 입력 영역

| 요소 | 스펙 |
|------|------|
| 인풋 배경 | `#F5F5F5`, radius 20px, h 40px, px 16px |
| placeholder | "쿠폰 코드를 입력해주세요" — 16px Regular, `#A4A7AD` |
| X 클리어 버튼 | 입력 중일 때 표시 |

---

## 에셋 목록

| 파일명 | 용도 | 크기 | 포맷 | Figma Node |
|--------|------|------|------|-----------|
| `icon_heart_24.svg` | S2-A 하트 확인 팝업 아이콘 | 24x24 | SVG | `23:4085` |
| `icon_coupon_24.svg` | S2-B 스킬 확인 팝업 아이콘 | 24x24 | SVG | `23:4233` |
| `icon_warning_24.svg` | S6 로그인 안내 팝업 경고 아이콘 | 24x24 | SVG | `23:3938` |
| `img_heart_complete.png` | S3 하트 완료 팝업 일러스트 | 1184x576 | PNG | `9:5569` |

> 앱(iOS/Android)에서 동일 에셋이 필요합니다. Figma에서 각 플랫폼 규격에 맞게 export하세요.

---

## 파트별 가이드

### 웹 (hellobot-web) — 반영 완료

- **스택**: Next.js 14 / React 18 / Tailwind CSS
- **에셋 경로**: `public/images/coop/`
- **팝업 컴포넌트 경로**: `app/coupon/components/coop*.tsx`
- 주요 Tailwind 매핑:
  - 팝업: `w-[288px] rounded-[20px] p-[24px] shadow-[0px_8px_24px_rgba(0,0,0,0.24)]`
  - 확인 버튼: `bg-[#FFE967] h-[48px] rounded-[26px]`
  - 취소 버튼: `bg-[#EDEDEE] h-[48px] rounded-[26px]`
  - 오버레이: `bg-[rgba(36,37,38,0.7)]`
- 상세 리뷰: [designs/design-review.md](./designs/design-review.md) — 전항목 체크 완료

### iOS (hellobot_iOS) — 미착수

- **폰트**: 앱 기본 폰트는 Apple SD Gothic Neo, 팝업 내부는 Pretendard
- **에셋**: Figma에서 @1x/@2x/@3x 규격으로 export 필요
- **팝업 구현**: UIKit 기반 커스텀 모달 또는 기존 팝업 컴포넌트 활용
- **토스트**: 기존 앱 토스트 컴포넌트가 있으면 재사용, 없으면 스타일 맞춰 구현
- **이용권 카드**: 기존 쿠폰 카드 UI에 "이용권" 라벨 + "스킬 보러가기" 링크 추가
- **로그인 안내 팝업**: dim 클릭 닫기 차단, "다음에 할래요"는 팝업 외부에 위치

### Android (hellobot_android) — 개발중

- **폰트**: Pretendard (팝업), 시스템 폰트 (앱 기본)
- **에셋**: Figma에서 mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi 규격으로 export 필요
- **팝업 구현**: DialogFragment 또는 Compose Dialog
- **dp 변환**: 디자인 기준 375px 폭 → dp로 비율 변환 (288px → ~288dp 그대로 사용 가능, 모바일 기준)
- **컬러**: colors.xml에 디자인 토큰 컬러 추가 또는 기존 매핑 확인
- **이용권 카드**: RecyclerView 내 기존 쿠폰 카드 ViewHolder에 이용권 타입 분기 추가

---

## 디자인 리뷰 체크리스트

### 웹 — 반영 완료

- [x] S2-A: 팝업 크기, 아이콘, 캡션, 제목, 버튼
- [x] S2-B: 팝업 크기, 아이콘, 캡션, 제목, 버튼
- [x] S3: 일러스트, 제목, 단일 버튼
- [x] S4: 카드 형식, 라벨, 할인율, 만료일, 링크
- [x] S6: 경고 아이콘, 제목, dim 닫기 차단, 1회 노출 제한
- [x] 에러 토스트: 스타일, 자동 사라짐
- [x] 인풋 placeholder 변경

### iOS — 미착수

- [ ] S2-A: 팝업 크기(288px), 아이콘(heart 24px), 캡션 색상(#FF5D7A), 버튼 스타일
- [ ] S2-B: 팝업 크기, 아이콘(coupon 24px), 버튼 "받기"
- [ ] S3: 일러스트 이미지, 단일 "확인" 버튼
- [ ] S4: 이용권 태그, 100% 할인율, 만료일 포맷, "스킬 보러가기" 링크
- [ ] S6: 경고 아이콘, "다음에 할래요" 팝업 외부 위치, dim 닫기 차단, sessionStorage 1회
- [ ] 에러 토스트: 스타일, 2.5초 자동 사라짐
- [ ] 인풋 placeholder: "쿠폰 코드를 입력해주세요"

### Android — 미착수

- [ ] S2-A: 팝업 크기(288dp), 아이콘(heart 24dp), 캡션 색상, 버튼 스타일
- [ ] S2-B: 팝업 크기, 아이콘(coupon 24dp), 버튼 "받기"
- [ ] S3: 일러스트 이미지, 단일 "확인" 버튼
- [ ] S4: 이용권 태그, 100% 할인율, 만료일 포맷, "스킬 보러가기" 링크
- [ ] S6: 경고 아이콘, "다음에 할래요" 팝업 외부 위치, dim 닫기 차단, SharedPreferences 1회
- [ ] 에러 토스트: 스타일, 2.5초 자동 사라짐
- [ ] 인풋 placeholder: "쿠폰 코드를 입력해주세요"

---

## Changelog

| 날짜 | 변경자 | 변경 내용 | 확인 |
|------|--------|----------|------|
| 2026-04-16 | /design | 최초 작성 (기존 designs/ 스펙 + Figma 추출 통합) | /dev-web (기반영) |
