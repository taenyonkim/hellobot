#!/bin/bash
# HelloBot 워크스페이스 온보딩 스크립트
#
# 사용법:
#   ./scripts/setup.sh              # 전체 온보딩 (clone → worktree)
#   ./scripts/setup.sh clone        # 리포 클론만
#   ./scripts/setup.sh worktree     # 워크트리 세팅만
#   ./scripts/setup.sh pull         # 전체 리포 pull
#   ./scripts/setup.sh status       # 전체 상태 확인

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
ORG="thingsflow"

# ── 리포지토리 정의 (이름 | 기본 브랜치) ──────────────────────────
REPO_DEFS=(
  "hellobot-server|master"
  "hellobot-studio-server|master"
  "hellobot-studio-web|master"
  "hellobot-web|main"
  "hellobot-webview|main"
  "hellobot-report-webview|main"
  "hellobot_android|master"
  "hellobot_iOS|develop"
  "common-data-airflow|develop"
)

# ── 활성 프로젝트 워크트리 정의 (프로젝트 | 리포 | 브랜치) ────────
# 활성 프로젝트의 워크트리가 추가/제거되면 여기를 업데이트합니다.
WORKTREE_DEFS=(
  "20260324-coop-integration|hellobot-server|feat/coupnc-integration"
  "20260324-coop-integration|hellobot-web|feat/coop-integration"
)

# ── 색상 ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ── 리포 클론 ────────────────────────────────────────────────────
clone_all() {
  info "전체 리포지토리 클론"
  echo ""

  for def in "${REPO_DEFS[@]}"; do
    IFS='|' read -r repo default_branch <<< "$def"
    repo_dir="$WORKSPACE_DIR/$repo"

    if [ -d "$repo_dir/.git" ]; then
      ok "$repo — 이미 존재, 스킵"
    else
      info "$repo — 클론 중..."
      git clone "git@github.com:$ORG/$repo.git" "$repo_dir"
      ok "$repo — 클론 완료"
    fi
  done

  echo ""
  ok "리포 클론 완료"
}

# ── 기본 브랜치 체크아웃 ─────────────────────────────────────────
checkout_default_branches() {
  info "원본 리포를 기본 브랜치로 체크아웃"
  echo ""

  for def in "${REPO_DEFS[@]}"; do
    IFS='|' read -r repo default_branch <<< "$def"
    repo_dir="$WORKSPACE_DIR/$repo"

    if [ ! -d "$repo_dir/.git" ]; then
      warn "$repo — 리포 없음, 스킵"
      continue
    fi

    current_branch=$(cd "$repo_dir" && git branch --show-current 2>/dev/null)
    if [ "$current_branch" = "$default_branch" ]; then
      ok "$repo — 이미 $default_branch"
    else
      info "$repo — $current_branch → $default_branch 전환 중..."
      (cd "$repo_dir" && git checkout "$default_branch" 2>/dev/null)
      ok "$repo — $default_branch 체크아웃 완료"
    fi
  done

  echo ""
}

# ── 워크트리 세팅 ────────────────────────────────────────────────
setup_worktrees() {
  if [ ${#WORKTREE_DEFS[@]} -eq 0 ]; then
    info "활성 워크트리 없음"
    return
  fi

  info "프로젝트 워크트리 세팅"
  echo ""

  for def in "${WORKTREE_DEFS[@]}"; do
    IFS='|' read -r project repo branch <<< "$def"
    repo_dir="$WORKSPACE_DIR/$repo"
    worktree_dir="$WORKSPACE_DIR/projects/$project/worktrees/$repo"

    if [ ! -d "$repo_dir/.git" ]; then
      error "$repo — 원본 리포 없음, 워크트리 생성 불가"
      continue
    fi

    if [ -d "$worktree_dir" ]; then
      ok "$project/$repo — 워크트리 이미 존재 ($branch)"
      continue
    fi

    # 프로젝트 worktrees 디렉토리 생성
    mkdir -p "$(dirname "$worktree_dir")"

    # 리모트에서 브랜치 fetch
    info "$project/$repo — 브랜치 $branch fetch 중..."
    (cd "$repo_dir" && git fetch origin "$branch" 2>/dev/null) || true

    # 로컬 브랜치가 없으면 리모트에서 생성
    if ! (cd "$repo_dir" && git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null); then
      if (cd "$repo_dir" && git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null); then
        info "$project/$repo — 리모트 브랜치에서 로컬 브랜치 생성..."
        (cd "$repo_dir" && git branch "$branch" "origin/$branch")
      else
        # 리모트에도 없으면 기본 브랜치에서 생성
        IFS='|' read -r _ default_branch <<< "$(printf '%s\n' "${REPO_DEFS[@]}" | grep "^$repo|")"
        warn "$project/$repo — 브랜치 $branch 없음, $default_branch에서 새로 생성"
        (cd "$repo_dir" && git branch "$branch" "$default_branch")
      fi
    fi

    # 워크트리 생성
    info "$project/$repo — 워크트리 생성 중..."
    (cd "$repo_dir" && git worktree add "$worktree_dir" "$branch")
    ok "$project/$repo — 워크트리 생성 완료 ($branch)"
  done

  echo ""
  ok "워크트리 세팅 완료"
}

# ── 전체 리포 pull ───────────────────────────────────────────────
pull_all() {
  info "전체 리포지토리 git pull"
  echo ""

  for def in "${REPO_DEFS[@]}"; do
    IFS='|' read -r repo default_branch <<< "$def"
    repo_dir="$WORKSPACE_DIR/$repo"

    if [ -d "$repo_dir/.git" ]; then
      info "$repo — pulling..."
      (cd "$repo_dir" && git pull --rebase 2>&1 | head -3) || warn "$repo — pull 실패"
    else
      warn "$repo — .git 디렉토리 없음, 스킵"
    fi
  done

  echo ""
  ok "pull 완료"
}

# ── 상태 확인 ────────────────────────────────────────────────────
status_all() {
  info "전체 리포지토리 상태"
  echo ""

  printf "  %-30s %-15s %s\n" "리포" "브랜치" "변경"
  printf "  %-30s %-15s %s\n" "────────────────────────" "──────────" "────"

  for def in "${REPO_DEFS[@]}"; do
    IFS='|' read -r repo default_branch <<< "$def"
    repo_dir="$WORKSPACE_DIR/$repo"

    if [ -d "$repo_dir/.git" ]; then
      branch=$(cd "$repo_dir" && git branch --show-current 2>/dev/null)
      changes=$(cd "$repo_dir" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      if [ "$changes" -gt 0 ]; then
        printf "  %-30s %-15s ${YELLOW}%s files${NC}\n" "$repo" "$branch" "$changes"
      else
        printf "  %-30s %-15s ${GREEN}clean${NC}\n" "$repo" "$branch"
      fi
    else
      printf "  %-30s ${RED}NOT FOUND${NC}\n" "$repo"
    fi
  done

  echo ""

  # 워크트리 상태
  if [ ${#WORKTREE_DEFS[@]} -gt 0 ]; then
    info "활성 워크트리"
    echo ""
    printf "  %-35s %-25s %-20s %s\n" "프로젝트" "리포" "브랜치" "상태"
    printf "  %-35s %-25s %-20s %s\n" "──────────────────────────" "──────────────────" "──────────────" "────"

    for def in "${WORKTREE_DEFS[@]}"; do
      IFS='|' read -r project repo branch <<< "$def"
      worktree_dir="$WORKSPACE_DIR/projects/$project/worktrees/$repo"

      if [ -d "$worktree_dir" ]; then
        changes=$(cd "$worktree_dir" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        if [ "$changes" -gt 0 ]; then
          printf "  %-35s %-25s %-20s ${YELLOW}%s files${NC}\n" "$project" "$repo" "$branch" "$changes"
        else
          printf "  %-35s %-25s %-20s ${GREEN}clean${NC}\n" "$project" "$repo" "$branch"
        fi
      else
        printf "  %-35s %-25s %-20s ${RED}missing${NC}\n" "$project" "$repo" "$branch"
      fi
    done
    echo ""
  fi
}

# ── 전체 온보딩 ──────────────────────────────────────────────────
onboard() {
  echo ""
  echo "=========================================="
  echo "  HelloBot 워크스페이스 온보딩"
  echo "=========================================="
  echo ""

  clone_all
  echo ""
  checkout_default_branches
  pull_all
  echo ""
  setup_worktrees
  echo ""

  echo "=========================================="
  echo "  온보딩 완료!"
  echo "=========================================="
  echo ""
  status_all
}

# ── 메인 ─────────────────────────────────────────────────────────
case "${1:-onboard}" in
  onboard)   onboard ;;
  clone)     clone_all ;;
  worktree)  setup_worktrees ;;
  pull)      pull_all ;;
  status)    status_all ;;
  *)
    echo "HelloBot 워크스페이스 셋업 스크립트"
    echo ""
    echo "사용법: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  (없음)     전체 온보딩 (clone → checkout → pull → worktree)"
    echo "  clone      리포지토리 클론만"
    echo "  worktree   프로젝트 워크트리 세팅만"
    echo "  pull       전체 리포 git pull --rebase"
    echo "  status     전체 상태 확인"
    ;;
esac
