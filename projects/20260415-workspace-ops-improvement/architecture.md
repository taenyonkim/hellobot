# 워크스페이스 문서 구조 개선안

## 1. 문제 정의

coop-integration 프로젝트 운영을 통해 확인된 구조적 문제 3가지.

### 1-1. 정보 중복

같은 정보가 여러 문서에 반복 기록됨.

| 정보 | 기록되는 곳 | 중복률 |
|------|-----------|--------|
| 이슈 해결 상세 | issues.md + status.md 작업 로그 | 35-40% |
| 과업 체크박스 | tasks.md + 리포 status.md 진행률 | 25-30% |
| 작업 내역 | 프로젝트 status.md 로그 + 리포 status.md 로그 + git log | 10-15% |
| API 에러코드/응답 | architecture.md §3 + api-spec.md | 100% (동일 표) |

coop-integration 전체 문서 1,510줄 중 약 12-15%가 의미 있는 중복.

### 1-2. 업데이트 부담

하나의 행위에 여러 파일을 업데이트해야 함.

| 행위 | 업데이트 대상 | 파일 수 |
|------|-------------|--------|
| 이슈 해결 | issues.md (섹션 이동 + 해결 상세) + tasks.md (체크) + status.md (작업 로그) + 리포 status.md (로그) | **4곳** |
| 과업 완료 | tasks.md (체크) + 리포 status.md (체크) + status.md (작업 로그) | **3곳** |
| 설계 결정 | architecture.md + 리포 status.md 결정표 + status.md 확정사항 | **3곳** |

### 1-3. 컨텍스트 로딩 비효율

세션 시작 시 현황 파악에 필요한 읽기량이 큼.

- 프로젝트 status.md: 178줄 (대부분 작업 로그)
- 리포 서버 status.md: 261줄 (대부분 개발 로그 + 중복 체크박스)
- 현재 상태 파악에 실제 필요한 정보: ~30줄

---

## 2. 개선 원칙

**각 정보는 딱 한 곳에만 기록하고, 나머지는 링크로 참조한다.**

| 원칙 | 설명 |
|------|------|
| 단일 소스 | 모든 정보에 하나의 정본(source of truth)을 지정 |
| 역할 분리 | 각 문서가 하나의 명확한 역할만 담당 |
| 참조 > 복사 | 다른 문서의 정보가 필요하면 복사하지 않고 링크 |
| 도구 위임 | git log로 확인 가능한 정보는 문서에 기록하지 않음 |

---

## 3. 문서별 역할 재정의

### 3-1. TO-BE 문서별 역할 정의

#### 프로젝트 레벨 (`projects/YYYYMMDD-feature-name/`)

| 문서 | 역할 | 단일 소스 대상 | 작성자 | 읽는 사람 | 업데이트 시점 |
|------|------|-------------|--------|----------|-------------|
| `readme.md` | 프로젝트 개요 | 배경, 목표, 범위, 영향 범위 | /analyze | 모든 에이전트 | 프로젝트 초기 1회 (범위 변경 시 갱신) |
| `status.md` | 경량 대시보드 | 파트별 현재 상태, 브랜치/워크트리 현황, 블로커, 확정 사항 | 모든 에이전트 | 세션 시작 시 가장 먼저 읽음 | 파트 상태 변경 시, 블로커 발생/해소 시 |
| `tasks.md` | 과업 체크리스트 (단일 소스) | 모든 과업의 완료 여부 (기획/이슈 파생 포함) | /analyze 초안, 모든 에이전트 추가 | 담당 파트 에이전트 | 과업 추가 시, 완료 시 체크 |
| `issues.md` | 이슈 레지스트리 | 발견된 이슈의 현상, 원인, 상태 | 발견한 에이전트 | 관련 파트 에이전트 | 이슈 발견 시 등록, 해결 시 상태 변경 (1줄) |
| `architecture.md` | 기술 아키텍처 | 데이터 모델, 처리 로직, 파트별 구현 포인트 | /architect | /dev-* 에이전트 | 설계 변경 시 + Changelog 기록 |
| `api-spec.md` | API 명세 (단일 소스) | 엔드포인트, 요청/응답, 에러코드 | /architect | /dev-* 에이전트 (서버↔클라이언트 계약) | API 변경 시 |
| `qa-test-cases.md` | QA 테스트 케이스 | 테스트 시나리오, 수행 결과 | /qa | /qa, /review | QA 작성 시, 검수 수행 시 |

#### 리포 레벨 (`{리포}/docs/features/YYYYMMDD-feature-name/`)

| 문서 | 역할 | 단일 소스 대상 | 작성자 | 읽는 사람 | 업데이트 시점 |
|------|------|-------------|--------|----------|-------------|
| `status.md` | 파트별 설계 결정 + 잔여 작업 + 결정 로그 | 해당 파트의 의사결정 이력 | /dev-* | 해당 파트 에이전트, /review | 설계 결정 시 (왜 그렇게 했는지만 기록) |
| `*-guide.md` | 구현 가이드 (선택) | 수정 대상 파일, 컴포넌트 구조 등 | /dev-* | 해당 파트 에이전트 | 개발 시작 시 1회 |

#### 문서에 기록하지 않는 정보

| 정보 | 확인 방법 | 비고 |
|------|---------|------|
| 구현 이력 (무엇을 했나) | `git log` | 커밋 메시지로 추적 |
| 변경 파일 목록 | `git diff` | 문서에 별도 기록 불필요 |
| 이슈 해결 방안 상세 | tasks.md 과업 + 커밋 | issues.md에 중복하지 않음 |

### 3-2. 정보의 단일 소스 맵

| 정보 | 단일 소스 | 비고 |
|------|---------|------|
| 프로젝트 개요/범위 | readme.md | |
| 파트별 현재 상태 | status.md 표 | 대시보드 역할 |
| 과업 완료 여부 | **tasks.md** | 유일한 체크리스트 |
| 이슈 레지스트리 | **issues.md** | 수집/취합만 |
| 기술 설계 | architecture.md | |
| API 명세 | **api-spec.md** | architecture.md는 링크로 참조 |
| 파트별 설계 결정 | **리포 status.md** | 해당 파트의 의사결정 이력 |
| 구현 이력 (무엇을 했나) | **git log** | 문서에 기록하지 않음 |
| 의사결정 이력 (왜 그렇게 했나) | **리포 status.md** 결정 로그 | |

### 3-3. 에이전트별 역할과 문서 책임

#### 에이전트 역할 요약

| 에이전트 | 역할 | 담당 리포 |
|---------|------|----------|
| `/analyze` | PM/기획 — 요구사항 분석, 과업 분류 | 전체 (읽기만) |
| `/architect` | 기술 설계 — 데이터 모델, API 계약, 처리 로직 | 관련 리포 (읽기만) |
| `/dev-server` | 서버 개발 | hellobot-server |
| `/dev-ios` | iOS 개발 | hellobot_iOS |
| `/dev-android` | Android 개발 | hellobot_android |
| `/dev-web` | 웹 개발 | hellobot-web, hellobot-webview |
| `/dev-studio` | 스튜디오 개발 | hellobot-studio-server, hellobot-studio-web |
| `/dev-data` | 데이터 엔지니어 | common-data-airflow |
| `/review` | 코드 리뷰 — 설계 정합성, 파트 간 계약 검증 | 변경된 리포 전체 |
| `/qa` | QA — 테스트 케이스 작성, 검수 | 프로젝트 문서 |
| `/workspace` | 워크스페이스 관리 — 문서 정합성, 상태 최신화 | 워크스페이스 문서 |

#### 에이전트별 문서 읽기/쓰기 책임

| 에이전트 | 읽는 문서 | 작성/수정하는 문서 |
|---------|----------|-----------------|
| `/analyze` | CLAUDE.md | readme.md (작성), tasks.md (작성), status.md (초기 생성), issues.md (발견 시) |
| `/architect` | readme.md, tasks.md | architecture.md (작성), api-spec.md (작성), status.md (상태 변경) |
| `/dev-*` | readme.md, status.md, tasks.md (자기 파트), architecture.md, api-spec.md | tasks.md (체크), issues.md (발견 시), status.md (파트 상태 변경), 리포 status.md (설계 결정/결정 로그) |
| `/review` | readme.md, status.md, tasks.md, architecture.md, api-spec.md, 변경 코드 | issues.md (발견 시), tasks.md (이슈 과업 추가) |
| `/qa` | readme.md, architecture.md, api-spec.md, issues.md | qa-test-cases.md (작성), issues.md (발견 시), tasks.md (이슈 과업 추가) |
| `/workspace` | status.md, tasks.md, issues.md, 리포 status.md | status.md (파트 상태 동기화) |

#### 행위별 문서 업데이트 책임

| 행위 | 담당 에이전트 | 업데이트 대상 |
|------|------------|-------------|
| 과업 완료 | 작업한 `/dev-*` | tasks.md 체크 |
| 이슈 발견 | 발견한 에이전트 | issues.md 등록 + tasks.md 과업 추가 |
| 이슈 해결 | 작업한 `/dev-*` | issues.md 상태 변경 + tasks.md 체크 |
| 설계 결정 | `/architect` 또는 `/dev-*` | architecture.md (전체 설계) 또는 리포 status.md (파트 내 결정) |
| 파트 상태 변경 | 작업한 `/dev-*` | status.md 파트별 현황 표 |
| 문서 정합성 점검 | `/workspace` | status.md (리포 상태 반영) |

#### 문서 분류와 변경 추적 규칙

문서는 성격에 따라 3가지로 분류되며, 변경 추적 방법이 다름.

| 분류 | 문서 | 수정 주체 | 변경 추적 방법 |
|------|------|---------|-------------|
| **계약 문서** | architecture.md, api-spec.md | /architect + /dev-* | **Changelog 필수** (아래 참조) |
| **운영 문서** | status.md, tasks.md, issues.md | 모든 에이전트 | 문서 구조 자체가 추적 (체크박스, 상태 필드, 날짜) |
| **참조 문서** | readme.md, qa-test-cases.md | 각 작성자 | 거의 변경 없음, git diff로 충분 |

**계약 문서**는 파트 간 합의(API 필드, 데이터 모델, 처리 로직)를 정의하므로, 한 파트의 변경이 다른 파트에 영향을 줌. `/dev-*`가 구현 중 계약 문서를 수정할 수 있으나, 반드시 Changelog에 기록해야 함.

#### 계약 문서 Changelog 규칙

계약 문서(architecture.md, api-spec.md)는 하단에 Changelog 섹션을 두고, 변경 시 1줄을 추가한다. 다른 파트 에이전트는 자기 컨텍스트 로딩 시 Changelog를 확인하고, 확인 컬럼에 자신을 기록한다.

```markdown
## Changelog

| 날짜 | 변경자 | 변경 내용 | 확인 |
|------|--------|----------|------|
| 2026-04-14 | /dev-server | ISS-003: check 응답에서 expiryDate 필드 제거 | /dev-web, /dev-ios |
| 2026-04-14 | /dev-server | ISS-001: §5-2~§5-5 처리 순서 변경 (UPSERT 우선) | /dev-web |
| 2026-04-10 | /architect | 최초 작성 | /dev-server, /dev-web |
```

**운영 방법**:
- **변경자**: 계약 문서를 수정한 에이전트가 Changelog에 날짜 + 변경자 + 변경 내용을 추가. 확인 컬럼은 비워 둠.
- **확인자**: 다른 파트의 `/dev-*` 에이전트가 세션 시작 시 Changelog를 확인하고, 자신이 아직 기록되지 않은 행에 자기 에이전트명을 추가.
- **미확인 변경 식별**: 확인 컬럼에 자신이 없는 행 = 아직 반영하지 않은 변경. 해당 섹션을 읽고 자기 구현에 영향이 있는지 검토.

### 3-4. 문서별 AS-IS → TO-BE

#### status.md (프로젝트 레벨)

**역할: 대시보드 + 저널 + 확정사항 → 대시보드만**

| 섹션 | AS-IS | TO-BE | 변경 |
|------|-------|-------|------|
| 현재 상태 | 유지 | 유지 | — |
| 워크트리/브랜치 현황 | 별도 표 (8줄) | 삭제 — 파트별 현황 표에 통합 | 통합 |
| 파트별 진행 상태 | 별도 표 (14줄) | **통합 표** (상태+브랜치+워크트리+비고) | 통합 |
| 파트별 요약 | 별도 표 (9줄) | 삭제 — 통합 표의 비고로 충분 | 삭제 |
| 확정 사항 | 별도 표 (6줄) | 유지 (프로젝트 레벨 확정만) | — |
| 블로커 | 텍스트 (3줄) | 유지 | — |
| 작업 로그 | 날짜별 상세 (128줄) | **삭제** | 삭제 |

작업 로그 삭제 이유:
- 이슈 해결 내역 → issues.md에 존재
- 구현 상세 → git log로 확인
- 의사결정 → 리포 status.md 결정 로그에 기록

**예상 줄수: 178줄 → ~30줄**

#### tasks.md (프로젝트 레벨)

**역할: 과업 체크리스트의 유일한 소스 (변경 없음, 역할 명확화)**

- 기획/서버/iOS/Android/웹/스튜디오/데이터 파트별 체크리스트
- 이슈에서 파생된 과업도 여기에 등록 (`ISS-NNN: 과업 설명`)
- 의존 관계 섹션 유지

리포 status.md의 진행률 체크박스와 **중복하지 않음**.

**예상 줄수: ~75줄 (현행과 유사)**

#### issues.md (프로젝트 레벨)

**역할: 레지스트리 + 해결 상세 → 레지스트리만**

| 항목 | AS-IS | TO-BE | 변경 |
|------|-------|-------|------|
| 이슈 분류 정의 | 유지 | 유지 | — |
| 미해결/해결 섹션 구분 | 이슈를 섹션 간 이동 | **삭제** — 상태 필드로 대체 | 간소화 |
| 이슈별: 현상, 원인 | 유지 | 유지 | — |
| 이슈별: 해결 방안 상세 | 3~5줄 기록 | **삭제** | 삭제 |
| 이슈별: 관련 문서 변경 | 3~5줄 기록 | **삭제** | 삭제 |

해결 방안과 문서 변경 내역 삭제 이유:
- tasks.md의 과업이 "무엇을 했는지" 추적
- 커밋이 "어떻게 구현했는지" 기록
- issues.md에 중복할 이유 없음

AS-IS 이슈 1건 (22줄):
```markdown
### ISS-001: 쿠폰 취소 후 재사용 시 CM_007 에러

| 분류 | edge-case |
| 발견일 | 2026-04-13 |
| 해결일 | 2026-04-14 |
| 심각도 | P1 — 하트 누수 발생 |
| 영향 파트 | 서버 |

**현상**: 쿠폰 취소(L2) 후 재사용 시 usage 유니크 제약 위반 → CM_007 에러.
chargeHeart는 별도 트랜잭션이라 롤백 안 됨 → 하트 누수.

**원인**: usage DELETE 없이 status UPDATE만 수행. 재사용 시 INSERT 시도 →
유니크 제약 위반. chargeHeart가 usage와 다른 트랜잭션이라 부분 실패 시 하트만 충전됨.

**해결 방안**:
- usage INSERT → UPSERT (ON CONFLICT → UPDATE)로 재사용 시 유니크 제약 위반 방지
- 처리 순서 변경: usage UPSERT 우선 → chargeHeart/issueCoupon 후속
- Admin 수동 취소 시 상품 회수 추가

**관련 문서 변경**:
- requirements.md F4 (F4-1 자동 취소, F4-2 Admin 수동 취소 분리)
- architecture.md §5-2~§5-5 (처리 순서, 자동 복구, Admin 취소)
- HeartLog.ts: UseByGiftCouponRecovery 타입 추가
```

TO-BE 이슈 1건 (10줄):
```markdown
### ISS-001: 쿠폰 취소 후 재사용 시 CM_007 에러

| 분류 | edge-case |
| 발견일 | 2026-04-13 |
| 심각도 | P1 |
| 영향 파트 | 서버 |
| 상태 | 해결 (2026-04-14) |

**현상**: 쿠폰 취소(L2) 후 재사용 시 usage 유니크 제약 위반 + 하트 누수
**원인**: usage DELETE 없이 status UPDATE만, chargeHeart 별도 트랜잭션
```

**예상 줄수: 139줄 → ~70줄**

#### readme.md (프로젝트 레벨)

**변경 없음.** 프로젝트 개요, 목표, 범위, 영향 범위, 문서 목록.

#### architecture.md (프로젝트 레벨) — 구 design.md

**§3 API 계약 섹션 경량화**

| 섹션 | AS-IS | TO-BE |
|------|-------|-------|
| §3 API 계약 | 에러코드 표 + 응답 필드 상세 (87줄) | 엔드포인트 요약 + api-spec.md 링크 (~15줄) |
| 나머지 섹션 | 유지 | 유지 |

api-spec.md가 API의 단일 소스이므로, architecture.md에서 중복하지 않음.

**예상 줄수: 424줄 → ~350줄**

#### api-spec.md (프로젝트 레벨)

**변경 없음.** API 명세의 단일 소스.

#### 리포 status.md (리포 레벨)

**역할: 진행률+설계결정+남은할일+개발로그 → 설계결정+남은할일+결정로그**

| 섹션 | AS-IS | TO-BE | 변경 |
|------|-------|-------|------|
| 현재 상태 | 유지 | 유지 | — |
| 진행률 체크박스 | 31줄 (서버 기준) | **삭제** | tasks.md가 단일 소스 |
| 확정된 설계 결정 | 33줄 | 유지 | 해당 파트의 상세 결정 |
| 남은 할일 | 34줄 | 유지 | 해당 파트 잔여 작업 |
| 변경 파일 목록 (웹) | 29줄 | **삭제** | git diff로 대체 |
| 개발 로그 | 156줄 (서버 기준) | **결정 로그 ~30줄** | 의사결정만 기록 |

결정 로그 변환 예시:

AS-IS 개발 로그 (12줄):
```markdown
### 2026-04-09 (1차)
API 테스트 Phase 2~6 완료 및 코드 수정
- 수정: OriginalAuthCode UUID(36자) → 타임스탬프 20자 형식으로 변경
- 수정: CoupcMarketingApiLog.processType VARCHAR(2) → VARCHAR(20) 확장
- 수정: CoupcMarketingCouponUsage에 originalAuthCode 컬럼 추가
- 수정: createSkillCouponSpec()에 issueStartDate = new Date() 추가
- 수정: usableDays 365 → 36500으로 변경
- 수정: ProductCode 빈값 폴백 처리 추가
- 수정: CoupcMarketingCouponRequestDto에 @IsNotEmpty() 추가
- 테스트: 필수 동작 테스트 Phase 2~6 모두 통과
```

TO-BE 결정 로그 (3줄):
```markdown
### 2026-04-09
- OriginalAuthCode UUID → 타임스탬프 20자 — 쿠프마케팅 API 거래번호 길이 초과
- usableDays 365 → 36500 (사실상 무제한) — 스킬 이용권 만료 정책 변경
```

"무엇을 수정했나"는 git log, "왜 그렇게 결정했나"만 결정 로그에 기록.

**예상 줄수: 서버 261줄 → ~100줄, 웹 92줄 → ~40줄**

---

## 4. 전체 효과

### 4-1. 문서량 비교

| 문서 | AS-IS | TO-BE | 절감 |
|------|-------|-------|------|
| status.md (프로젝트) | 178 | ~30 | -83% |
| tasks.md | 71 | ~75 | 유지 |
| issues.md | 139 | ~70 | -50% |
| readme.md | 69 | 69 | 유지 |
| architecture.md | 424 | ~350 | -17% |
| api-spec.md | 276 | 276 | 유지 |
| 서버 status.md (리포) | 261 | ~100 | -62% |
| 웹 status.md (리포) | 92 | ~40 | -57% |
| **합계** | **1,510** | **~1,010** | **-33%** |

### 4-2. 업데이트 부담 비교

| 행위 | AS-IS | TO-BE |
|------|-------|-------|
| 이슈 발견 | issues.md 등록 + tasks.md 과업 추가 + status.md 로그 | issues.md 등록 + tasks.md 과업 추가 |
| 이슈 해결 | issues.md 섹션이동+해결상세 + tasks.md 체크 + status.md 로그 + 리포 status 로그 | issues.md 상태변경(1줄) + tasks.md 체크 |
| 일반 과업 완료 | tasks.md 체크 + 리포 status.md 체크 + status.md 로그 | tasks.md 체크 |
| 설계 결정 | architecture.md + 리포 status.md 결정표 + status.md 확정사항 | architecture.md + 리포 status.md 결정표 |
| 세션 시작 현황 파악 | status.md **178줄** 읽기 | status.md **~30줄** 읽기 |

### 4-3. 이슈 처리 흐름 비교

AS-IS:
```
이슈 발견
  → issues.md: 미해결 섹션에 등록 (현상+원인+심각도)
  → tasks.md: ISS-NNN 과업 추가
  → status.md: 작업 로그에 "이슈 등록" 기록
  
해결 결정 → 구현
  → 코드 수정 + 커밋

해결 완료
  → issues.md: 해결된 이슈 섹션으로 이동 + 해결방안 상세 + 관련 문서 변경 기록
  → tasks.md: [x] 체크
  → status.md: 작업 로그에 "이슈 해결 완료" + 구현 내역 기록
  → 리포 status.md: 작업 로그에 구현 내역 기록
  = 4개 파일, 20줄+ 작성
```

TO-BE:
```
이슈 발견
  → issues.md: 등록 (현상+원인+심각도+상태:미해결)
  → tasks.md: ISS-NNN 과업 추가

해결 결정 → 구현
  → 코드 수정 + 커밋

해결 완료
  → issues.md: 상태 필드 변경 (| 상태 | 해결 (날짜) |)
  → tasks.md: [x] 체크
  = 2개 파일, 각 1줄 수정
```

---

## 5. 문서 템플릿

### 5-1. status.md (프로젝트 레벨)

```markdown
# 개발 상태

## 현재 상태: {분석중|설계중|개발중|리뷰중|완료|보류}

## 파트별 현황

| 파트 | 상태 | 브랜치 | 워크트리 | 비고 |
|------|------|--------|---------|------|
| 기획 | - | - | - | |
| 서버 | 대기 | feat/xxx | worktrees/hellobot-server/ | |
| iOS | 대기 | - | - | 서버 API 완료 후 착수 |
| Android | 대기 | - | - | 서버 API 완료 후 착수 |
| 웹 | 해당없음 | - | - | |
| 스튜디오 | 해당없음 | - | - | |
| 데이터 | 해당없음 | - | - | |
| QA | 대기 | - | - | |

## 블로커

없음

## 확정 사항

| 항목 | 내용 |
|------|------|
```

### 5-2. issues.md (프로젝트 레벨)

```markdown
# 이슈 목록

## 이슈 분류
- **bug**: 구현이 설계와 다름
- **edge-case**: 설계에서 고려하지 못한 예외 상황
- **enhancement**: 기존 요구사항 범위 밖의 개선

---

### ISS-001: {이슈 제목}

| 분류 | {bug / edge-case / enhancement} |
| 발견일 | YYYY-MM-DD |
| 심각도 | {P1 / P2 / P3} |
| 영향 파트 | {서버, 웹, iOS 등} |
| 상태 | {미해결 / 해결 (YYYY-MM-DD)} |

**현상**: {무엇이 발생하는지 — 1~2줄}
**원인**: {왜 발생하는지 — 1~2줄}
```

### 5-3. 리포 status.md (리포 레벨)

```markdown
# {파트명} 개발 상태

## 현재 상태: {개발중|완료}

## 설계 결정

| 항목 | 결정 | 비고 |
|------|------|------|

## 남은 할일

| # | 항목 | 우선순위 | 설명 |
|---|------|---------|------|

## 결정 로그

### YYYY-MM-DD
- {결정 내용} — {이유}
```

---

## 6. 에이전트 운영 규칙 변경

> 이 섹션은 확정 후 CLAUDE.md, .claude/commands/*.md에 반영할 내용.

### 6-1. 과업 완료 시

AS-IS: tasks.md 체크 + 리포 status.md 체크 + status.md 작업 로그
**TO-BE: tasks.md 체크만**

### 6-2. 이슈 발견 시

AS-IS: issues.md 미해결 섹션 등록 + tasks.md 과업 추가 + status.md 작업 로그
**TO-BE: issues.md 등록 (상태: 미해결) + tasks.md 과업 추가**

### 6-3. 이슈 해결 완료 시

AS-IS: issues.md 섹션 이동 + 해결 상세 작성 + tasks.md 체크 + status.md 로그 + 리포 status 로그
**TO-BE: issues.md 상태 변경 (1줄) + tasks.md 체크**

### 6-4. 설계 결정 시

AS-IS: architecture.md + 리포 status.md 결정표 + status.md 확정사항
**TO-BE: architecture.md + 리포 status.md 결정표** (프로젝트 레벨 확정사항은 핵심 항목만)

### 6-5. 세션 시작 시 컨텍스트 로딩

AS-IS: status.md 178줄 전체 읽기
**TO-BE: status.md ~30줄 읽기** → 필요시 tasks.md, issues.md 추가 로드

---

## 7. 적용 계획

| 순서 | 작업 | 대상 |
|------|------|------|
| 1 | 이 설계 문서 확정 | 이 문서 |
| 2 | coop-integration에 적용 (검증) | coop-integration 프로젝트 문서 |
| 3 | projects/readme.md 템플릿 갱신 | 프로젝트 가이드 |
| 4 | CLAUDE.md 에이전트 규칙 갱신 | 워크스페이스 규칙 |
| 5 | .claude/commands/*.md 갱신 | 에이전트 커맨드 |
| 6 | docs/how-to-work.md 갱신 | 작업 가이드 |
