#!/usr/bin/env bash

# Beginner usage:
#   ./scripts/setup-worktree.sh feature-auth
#
# What this does:
#   1. Creates worktrees/feature-auth/
#   2. Creates a new branch named feature-auth
#   3. Checks that branch out inside the new worktree
#
# Optional base branch/ref:
#   ./scripts/setup-worktree.sh feature-auth main
#   BASE_REF=origin/main ./scripts/setup-worktree.sh feature-auth

set -euo pipefail

usage() {
  echo "Usage: $0 <worktree-name> [base-ref]"
  echo "Example: $0 feature-auth main"
}

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

WORKTREE_NAME="$1"
BASE_REF="${2:-${BASE_REF:-main}}"

case "$WORKTREE_NAME" in
  *[!A-Za-z0-9._-]* | .* | *..*)
    echo "Error: worktree name must use only letters, numbers, dots, underscores, or hyphens."
    echo "Example: feature-auth"
    exit 1
    ;;
esac

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

WORKTREE_ROOT="worktrees"
WORKTREE_PATH="${WORKTREE_ROOT}/${WORKTREE_NAME}"
BRANCH_NAME="$WORKTREE_NAME"

if [ -e "$WORKTREE_PATH" ]; then
  echo "Error: ${WORKTREE_PATH} already exists."
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
  echo "Error: branch ${BRANCH_NAME} already exists. Choose a new worktree name."
  exit 1
fi

if git rev-parse --verify --quiet "$BASE_REF" >/dev/null; then
  START_POINT="$BASE_REF"
elif git rev-parse --verify --quiet "origin/${BASE_REF}" >/dev/null; then
  START_POINT="origin/${BASE_REF}"
else
  echo "Error: base ref not found: ${BASE_REF}"
  echo "Try: $0 ${WORKTREE_NAME} main"
  exit 1
fi

mkdir -p "$WORKTREE_ROOT"

git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$START_POINT"

echo "Created worktree: ${WORKTREE_PATH}"
echo "Created branch:   ${BRANCH_NAME}"
echo "Next step:        cd ${WORKTREE_PATH}"