#!/usr/bin/env bash

# Beginner usage:
#   ./scripts/merge-worktree.sh feature-auth
#   ./scripts/merge-worktree.sh worktrees/feature-auth
#
# What this does:
#   1. Checks that the worktree has no uncommitted changes
#   2. Checks out main in the primary repository
#   3. Merges the worktree branch into main
#   4. Removes the worktree folder after a successful merge
#
# Optional target branch:
#   BASE_BRANCH=develop ./scripts/merge-worktree.sh feature-auth
#
# Optional branch deletion after merge:
#   DELETE_BRANCH=1 ./scripts/merge-worktree.sh feature-auth

set -euo pipefail

usage() {
  echo "Usage: $0 <worktree-name-or-path>"
  echo "Example: $0 feature-auth"
}

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

INPUT_PATH="$1"
BASE_BRANCH="${BASE_BRANCH:-main}"
DELETE_BRANCH="${DELETE_BRANCH:-0}"

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

if [ -d "$INPUT_PATH" ]; then
  WORKTREE_PATH="$INPUT_PATH"
else
  WORKTREE_PATH="worktrees/${INPUT_PATH}"
fi

if [ ! -d "$WORKTREE_PATH" ]; then
  echo "Error: worktree path not found: ${WORKTREE_PATH}"
  exit 1
fi

if ! git -C "$WORKTREE_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: path is not a git worktree: ${WORKTREE_PATH}"
  exit 1
fi

WORKTREE_BRANCH="$(git -C "$WORKTREE_PATH" branch --show-current)"
if [ -z "$WORKTREE_BRANCH" ]; then
  echo "Error: worktree is in detached HEAD state. Merge manually."
  exit 1
fi

if [ -n "$(git -C "$WORKTREE_PATH" status --porcelain)" ]; then
  echo "Error: ${WORKTREE_PATH} has uncommitted changes. Commit or stash them first."
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: primary repository has uncommitted changes. Commit or stash them first."
  exit 1
fi

if ! git show-ref --verify --quiet "refs/heads/${BASE_BRANCH}"; then
  echo "Error: target branch not found: ${BASE_BRANCH}"
  exit 1
fi

echo "Merging branch ${WORKTREE_BRANCH} into ${BASE_BRANCH}"

git checkout "$BASE_BRANCH"
git merge --no-ff "$WORKTREE_BRANCH"
git worktree remove "$WORKTREE_PATH"
git worktree prune

if [ "$DELETE_BRANCH" = "1" ]; then
  git branch -d "$WORKTREE_BRANCH"
  echo "Deleted branch: ${WORKTREE_BRANCH}"
fi

echo "Merged and removed worktree: ${WORKTREE_PATH}"