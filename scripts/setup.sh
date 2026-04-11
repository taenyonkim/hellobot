#!/bin/bash
# HelloBot 워크스페이스 전체 리포지토리 셋업 스크립트

set -e

REPOS=(
  "hellobot-server"
  "hellobot-studio-server"
  "hellobot-studio-web"
  "hellobot-web"
  "hellobot-webview"
  "hellobot-report-webview"
  "hellobot_android"
  "hellobot_iOS"
  "common-data-airflow"
)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"

# 전체 리포 git pull
pull_all() {
  echo "=== 전체 리포지토리 git pull ==="
  for repo in "${REPOS[@]}"; do
    if [ -d "$WORKSPACE_DIR/$repo/.git" ]; then
      echo "[$repo] pulling..."
      (cd "$WORKSPACE_DIR/$repo" && git pull --rebase 2>&1 | head -3)
    else
      echo "[$repo] .git 디렉토리 없음, 스킵"
    fi
  done
  echo "=== 완료 ==="
}

# 전체 리포 상태 확인
status_all() {
  echo "=== 전체 리포지토리 상태 ==="
  for repo in "${REPOS[@]}"; do
    if [ -d "$WORKSPACE_DIR/$repo/.git" ]; then
      branch=$(cd "$WORKSPACE_DIR/$repo" && git branch --show-current 2>/dev/null)
      changes=$(cd "$WORKSPACE_DIR/$repo" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      echo "[$repo] branch: $branch | changes: $changes"
    fi
  done
}

# 전체 리포 클론 (새 환경 셋업용)
clone_all() {
  echo "=== 전체 리포지토리 클론 ==="
  ORG="thingsflow"
  for repo in "${REPOS[@]}"; do
    if [ ! -d "$WORKSPACE_DIR/$repo" ]; then
      echo "[$repo] cloning..."
      git clone "git@github.com:$ORG/$repo.git" "$WORKSPACE_DIR/$repo"
    else
      echo "[$repo] 이미 존재, 스킵"
    fi
  done
  echo "=== 완료 ==="
}

case "${1:-status}" in
  pull)   pull_all ;;
  status) status_all ;;
  clone)  clone_all ;;
  *)
    echo "사용법: $0 {pull|status|clone}"
    echo "  pull   - 전체 리포 git pull --rebase"
    echo "  status - 전체 리포 브랜치/변경사항 확인"
    echo "  clone  - 전체 리포 클론 (신규 환경)"
    ;;
esac
