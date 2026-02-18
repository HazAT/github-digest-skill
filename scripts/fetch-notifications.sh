#!/usr/bin/env bash
# fetch-notifications.sh — Pull GitHub notifications via gh CLI
# Outputs structured JSON for agent consumption
#
# Usage: ./scripts/fetch-notifications.sh [--all] [--since TIMESTAMP] [--per-page N]

set -euo pipefail

ALL=""
SINCE=""
PER_PAGE=50

while [[ $# -gt 0 ]]; do
  case $1 in
    --all) ALL="true"; shift ;;
    --since) SINCE="$2"; shift 2 ;;
    --per-page) PER_PAGE="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Build query params
PARAMS="per_page=${PER_PAGE}"
[[ -n "$ALL" ]] && PARAMS="${PARAMS}&all=true"
[[ -n "$SINCE" ]] && PARAMS="${PARAMS}&since=${SINCE}"

# Quick SSO check with minimal data
SSO_WARNING=""
SSO_CHECK=$(gh api "notifications?per_page=1" --include 2>&1 | head -30)
if echo "$SSO_CHECK" | grep -q "X-Github-Sso: partial-results"; then
  SSO_WARNING="⚠️  SSO partial results — some org notifications are missing. Fix: gh auth refresh -h github.com -s notifications,read:org → then authorize for getsentry at github.com/settings/tokens"
fi

# Fetch full notifications
gh api "notifications?${PARAMS}" | jq --arg sso "$SSO_WARNING" '{
  sso_warning: (if $sso != "" then $sso else null end),
  count: length,
  notifications: [.[] | {
    id: .id,
    reason: .reason,
    unread: .unread,
    updated_at: .updated_at,
    subject: {
      title: .subject.title,
      type: .subject.type,
      url: .subject.url,
      latest_comment_url: .subject.latest_comment_url
    },
    repository: {
      full_name: .repository.full_name,
      owner: .repository.owner.login,
      private: .repository.private
    }
  }]
}'
