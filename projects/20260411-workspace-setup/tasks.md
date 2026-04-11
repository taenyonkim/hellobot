# 과업 목록

## 워크스페이스 구조 설계
- [x] 디렉토리 구조 제안 및 확정
- [x] CLAUDE.md 작성 (리포 구성, 의존 관계, 공유 인프라)
- [x] docs/architecture.md 작성 (시스템 아키텍처)
- [x] docs/api-contracts/ 디렉토리 생성
- [x] docs/decisions/ 디렉토리 생성
- [x] scripts/setup.sh 작성 (전체 리포 pull/status/clone)

## 에이전트 워크플로우 설계
- [x] 역할별 에이전트 정의 및 워크플로우 설계
- [x] 컨텍스트 관리 규칙 수립
- [x] CLAUDE.md에 에이전트 워크플로우 섹션 추가

## 에이전트 커맨드 구현
- [x] /analyze (PM/기획자) 커맨드
- [x] /design (기술 설계자) 커맨드
- [x] /dev-server (서버 개발자) 커맨드
- [x] /dev-ios (iOS 개발자) 커맨드
- [x] /dev-android (Android 개발자) 커맨드
- [x] /dev-web (웹 개발자) 커맨드
- [x] /dev-studio (스튜디오 개발자) 커맨드
- [x] /dev-data (데이터 엔지니어) 커맨드
- [x] /review (코드 리뷰어) 커맨드
- [x] /workspace (워크스페이스 관리자) 커맨드

## 피쳐 문서 체계
- [x] docs/features/readme.md 작성 (워크스페이스 레벨 피쳐 문서 가이드)
- [x] 문서 템플릿 정의 (readme, status, tasks, design, api-spec)

## 가이드 문서
- [x] docs/how-to-work.md 작성 (작업 가이드, 예시 포함)
- [x] CLAUDE.md에 가이드 문서 링크 추가

## 프로젝트 기록
- [x] 이 환경 구축 과정 자체를 피쳐로 기록

## 협업 환경 규칙
- [x] 리포별 Git 브랜치/배포 규칙 조사 및 임시 정리 (repo-git-deploy.md)
- [ ] CLAUDE.md에 Git 작업 규칙 추가 (피쳐 브랜치, 충돌 방지, 동시 작업)
- [ ] 피쳐 문서 status.md 템플릿에 브랜치 현황 섹션 추가
- [ ] 에이전트 커맨드에 작업 시작/종료 절차 반영

## 후속 과업 (미착수)
- [ ] 개별 리포지토리 CLAUDE.md 보완 — Git/배포 규칙 정식 문서화 (repo-git-deploy.md 기반)
- [ ] 실제 피쳐로 워크플로우 시범 운영
- [ ] 시범 운영 후 에이전트 커맨드 개선
