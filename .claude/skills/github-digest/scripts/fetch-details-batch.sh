#!/usr/bin/env bash
# fetch-details-batch.sh — Fetch full details for multiple notification subjects in parallel
#
# Usage: ./scripts/fetch-details-batch.sh <url1> <url2> ...
#        echo "url1\nurl2\nurl3" | ./scripts/fetch-details-batch.sh --stdin
#
# Outputs a JSON array of results, one per URL. Each element includes the
# original URL for correlation. Failed fetches are included as error objects.
# Fetches up to 5 URLs in parallel.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FETCH_DETAILS="$SCRIPT_DIR/fetch-details.sh"

URLS=()

if [[ "${1:-}" == "--stdin" ]]; then
  while IFS= read -r url; do
    [[ -n "$url" ]] && URLS+=("$url")
  done
else
  URLS=("$@")
fi

if [[ ${#URLS[@]} -eq 0 ]]; then
  echo '[]'
  exit 0
fi

# Create temp dir for parallel output
TMPDIR_BATCH="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_BATCH"' EXIT

# Fetch in parallel (up to 5 concurrent)
fetch_one() {
  local idx="$1"
  local url="$2"
  local outfile="$TMPDIR_BATCH/$(printf '%04d' "$idx").json"

  local result
  if result="$(bash "$FETCH_DETAILS" "$url" 2>/dev/null)"; then
    # Add source_url to the result
    echo "$result" | jq --arg url "$url" '. + {source_url: $url}' > "$outfile"
  else
    echo "{\"error\": \"fetch failed\", \"source_url\": \"$url\"}" > "$outfile"
  fi
}

idx=0
active=0
MAX_PARALLEL=5

for url in "${URLS[@]}"; do
  fetch_one "$idx" "$url" &
  ((active++)) || true
  ((idx++)) || true

  if [[ $active -ge $MAX_PARALLEL ]]; then
    wait -n 2>/dev/null || wait
    ((active--)) || true
  fi
done

wait

# Combine results in order
echo '['
first=true
for f in "$TMPDIR_BATCH"/*.json; do
  [[ -f "$f" ]] || continue
  if $first; then
    first=false
  else
    echo ','
  fi
  cat "$f"
done
echo ']'
