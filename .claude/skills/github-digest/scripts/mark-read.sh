#!/usr/bin/env bash
# mark-read.sh — Mark all GitHub notifications as read
#
# Usage: ./scripts/mark-read.sh [--before TIMESTAMP]
#
# Marks all notifications as read. Optionally only those before a timestamp.

set -euo pipefail

LAST_READ_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

while [[ $# -gt 0 ]]; do
  case $1 in
    --before) LAST_READ_AT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

gh api -X PUT notifications -f "last_read_at=${LAST_READ_AT}" -f "read=true" --silent 2>&1
echo "{\"marked_read_at\": \"${LAST_READ_AT}\"}"
