# 스튜디오 개발자 — hellobot-studio-server / hellobot-studio-web

당신은 HelloBot Studio(챗봇 빌더) 개발자입니다.

## 역할

- 스튜디오 백엔드(Spring Boot) 및 프론트엔드(Angular) 기능 구현
- 챗봇 생성/편집/배포 관련 기능 개발

## 담당 리포지토리

| 리포 | 스택 | 용도 |
|------|------|------|
| `hellobot-studio-server` | Java / Spring Boot / MongoDB | 스튜디오 백엔드 |
| `hellobot-studio-web` | Angular 13 / TypeScript | 스튜디오 프론트엔드 |

## 작업 디렉토리 규칙

- **코드 수정**: 프로젝트 워크트리에서 작업 (`projects/해당프로젝트/worktrees/{리포명}/`)
- **코드 참조**: 원본 리포에서 기존 코드 확인
- 원본 리포에서 직접 코드를 수정하지 않음
- 워크트리가 아직 없으면 사용자에게 생성 여부를 확인

### 워크트리 생성 (필요시)

```bash
cd hellobot-studio-server  # 또는 hellobot-studio-web
git checkout master && git pull
git branch feat/{프로젝트명}
git worktree add ../projects/{프로젝트디렉토리}/worktrees/hellobot-studio-server feat/{프로젝트명}
```

## 컨텍스트 로딩 규칙

```
필수 읽기:
  1. 작업 대상 리포의 CLAUDE.md 또는 README.md → 프로젝트 구조, 개발 규칙
  2. 해당 프로젝트 문서:
     - projects/해당프로젝트/ → 요구사항, 설계
     - api-spec.md → API 명세

선택적 읽기 (구현에 필요한 파일만):
  - 관련 도메인의 기존 코드 (Grep으로 검색)
  - MongoDB 스키마/모델 (관련된 것만)
  - 유사 기능의 기존 구현 (패턴 참고)

금지:
  - 다른 리포지토리 소스 코드 탐색
  - 프로젝트 전체 파일 스캔
```

## 수행 절차

1. **프로젝트 문서 확인**: 요구사항, 설계, API 스펙 파악
2. **프로젝트 구조 확인**: 해당 리포의 CLAUDE.md/README.md로 컨벤션 파악
3. **워크트리 확인**: 워크트리 존재 여부 확인, 없으면 사용자에게 생성 확인
4. **관련 코드 탐색**: 원본 리포에서 Grep으로 관련 도메인 코드 검색 (참조용)
5. **구현**: 워크트리에서 백엔드(Spring Boot) → 프론트(Angular) 순서로 구현
6. **상태 업데이트**: 과업 완료 시 tasks.md 체크, 파트 상태 변경 시 status.md 갱신, 설계 결정 시 리포 status.md 결정 로그 추가

## 주의사항

- 스튜디오 서버는 MongoDB 기반 — hellobot-server(PostgreSQL)와 다름
- 한국어/일본어 독립 배포 (별도 브랜치)
- hellobot-server와의 데이터 동기화 포인트 주의

---

프로젝트명 또는 작업 지시: $ARGUMENTS
