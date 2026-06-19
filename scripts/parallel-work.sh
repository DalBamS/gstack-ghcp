#!/usr/bin/env bash

# Beginner usage:
#   ./scripts/parallel-work.sh feature-auth feature-payments feature-docs
#
# What this does:
#   Calls setup-worktree.sh once for each name you pass in.
#   Each feature gets its own folder under worktrees/ and its own branch.
#
# Optional base branch/ref for all worktrees:
#   BASE_REF=origin/main ./scripts/parallel-work.sh feature-auth feature-docs

set -euo pipefail

usage() {
  echo "Usage: $0 <worktree-name> [more-worktree-names...]"
  echo "Example: $0 feature-auth feature-payments feature-docs"
}

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_SCRIPT="${SCRIPT_DIR}/setup-worktree.sh"

if [ ! -x "$SETUP_SCRIPT" ]; then
  echo "Error: setup script is not executable: ${SETUP_SCRIPT}"
  echo "Run: chmod +x ${SETUP_SCRIPT}"
  exit 1
fi

CREATED=""
FAILED=""

for WORKTREE_NAME in "$@"; do
  echo ""
  echo "==> Creating worktree: ${WORKTREE_NAME}"
  if "$SETUP_SCRIPT" "$WORKTREE_NAME"; then
    CREATED="${CREATED} ${WORKTREE_NAME}"
  else
    FAILED="${FAILED} ${WORKTREE_NAME}"
  fi
done

echo ""
echo "Worktree summary"
echo "----------------"
if [ -n "$CREATED" ]; then
  echo "Created:${CREATED}"
else
  echo "Created: none"
fi

if [ -n "$FAILED" ]; then
  echo "Failed:${FAILED}"
else
  echo "Failed: none"
fi

echo ""
git worktree list

if [ -n "$FAILED" ]; then
  exit 1
fi