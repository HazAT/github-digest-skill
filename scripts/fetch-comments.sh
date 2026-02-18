#!/usr/bin/env bash
# fetch-comments.sh — Fetch recent comments on a PR/issue
# Useful for understanding the tone and context of a discussion
#
# Usage: ./scripts/fetch-comments.sh <owner/repo> <number> [--limit N]
#
# Example: ./scripts/fetch-comments.sh getsentry/sentry 12345 --limit 10

set -euo pipefail

REPO="$1"
NUMBER="$2"
LIMIT=10

shift 2
while [[ $# -gt 0 ]]; do
  case $1 in
    --limit) LIMIT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Fetch issue/PR comments (general comments)
COMMENTS=$(gh api "repos/${REPO}/issues/${NUMBER}/comments?per_page=${LIMIT}&direction=desc" 2>&1) || {
  echo "{\"error\": \"Failed to fetch comments for ${REPO}#${NUMBER}\"}"
  exit 1
}

echo "$COMMENTS" | jq '[.[] | {
  user: .user.login,
  body: (.body | .[0:1000]),
  created_at: .created_at,
  reactions: {
    total: .reactions.total_count,
    thumbs_up: .reactions["+1"],
    thumbs_down: .reactions["-1"],
    confused: .reactions.confused
  }
}]'
