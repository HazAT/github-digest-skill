#!/usr/bin/env bash
# fetch-details.sh — Fetch full details for a notification's subject
# Reads the subject URL from notification data and pulls the full context
#
# Usage: ./scripts/fetch-details.sh <subject_api_url>
#
# Example: ./scripts/fetch-details.sh https://api.github.com/repos/getsentry/sentry/pulls/12345

set -euo pipefail

URL="$1"

if [[ -z "$URL" || "$URL" == "null" ]]; then
  echo '{"error": "No URL provided"}'
  exit 1
fi

# Strip the base URL to get the API path
API_PATH="${URL#https://api.github.com/}"

# Fetch the subject (PR, Issue, Release, etc.)
SUBJECT=$(gh api "$API_PATH" 2>&1) || {
  if echo "$SUBJECT" | grep -qi "403\|404\|SAML\|Resource protected\|Not Found\|repo.*scope"; then
    echo "{\"skipped\": true, \"reason\": \"private repo (no access)\", \"url\": \"$API_PATH\"}"
    exit 0
  fi
  echo "{\"error\": \"Failed to fetch: $API_PATH\"}"
  exit 1
}

# Detect type and extract relevant fields
TYPE=$(echo "$SUBJECT" | jq -r 'if .head then "pr" elif .release_id then "release" elif .number then "issue" else "other" end')

case "$TYPE" in
  pr)
    echo "$SUBJECT" | jq '{
      type: "pull_request",
      number: .number,
      title: .title,
      state: .state,
      draft: .draft,
      user: .user.login,
      body: (.body // "" | .[0:2000]),
      labels: [.labels[].name],
      requested_reviewers: [.requested_reviewers[].login],
      merged: .merged,
      mergeable_state: .mergeable_state,
      comments: .comments,
      review_comments: .review_comments,
      changed_files: .changed_files,
      additions: .additions,
      deletions: .deletions,
      created_at: .created_at,
      updated_at: .updated_at,
      html_url: .html_url
    }'
    ;;
  issue)
    echo "$SUBJECT" | jq '{
      type: "issue",
      number: .number,
      title: .title,
      state: .state,
      user: .user.login,
      body: (.body // "" | .[0:2000]),
      labels: [.labels[].name],
      assignees: [.assignees[].login],
      comments: .comments,
      created_at: .created_at,
      updated_at: .updated_at,
      html_url: .html_url
    }'
    ;;
  *)
    echo "$SUBJECT" | jq '{
      type: "other",
      title: (.title // .name // .tag_name // "unknown"),
      body: ((.body // "") | .[0:2000]),
      html_url: (.html_url // null),
      created_at: (.created_at // null)
    }'
    ;;
esac
