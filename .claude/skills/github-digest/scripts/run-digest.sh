#!/usr/bin/env bash
# run-digest.sh — Orchestrate GitHub digest generation
#
# Called by the main `github-digest` CLI when a profile exists.
# Fetches notifications, calls claude -p with the combined system prompt,
# saves the resulting digest, and optionally marks notifications as read
# and fires a macOS notification.

set -euo pipefail

# ── Resolve paths ─────────────────────────────────────────────────────────────

SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" == /* ]] || SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$SOURCE"
done
SKILL_DIR="$(cd "$(dirname "$SOURCE")/.." && pwd)"
SCRIPTS_DIR="$SKILL_DIR/scripts"

DATA_DIR="$HOME/.github-digest"
CONFIG="$DATA_DIR/config.json"
PROFILE="$DATA_DIR/profile.md"
DIGESTS_DIR="$DATA_DIR/digests"
RUNNER_PROMPT="$SKILL_DIR/references/digest-runner.md"

TODAY="$(date +%Y-%m-%d)"
DIGEST_FILE="$DIGESTS_DIR/${TODAY}.md"

# ── Preflight checks ──────────────────────────────────────────────────────────

if [[ ! -f "$PROFILE" ]]; then
  echo "Error: No profile found at $PROFILE" >&2
  echo "Run 'github-digest --setup' to create one." >&2
  exit 1
fi

if [[ ! -f "$RUNNER_PROMPT" ]]; then
  echo "Error: Digest runner prompt not found at $RUNNER_PROMPT" >&2
  echo "Your github-digest installation may be incomplete." >&2
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "Error: 'claude' CLI not found." >&2
  echo "Install Claude Code: https://claude.ai/code" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: 'jq' not found. Install with: brew install jq" >&2
  exit 1
fi

# ── Read config (optional — use defaults if missing) ──────────────────────────

MARK_READ="false"

if [[ -f "$CONFIG" ]]; then
  MARK_READ="$(jq -r '.mark_read // false' "$CONFIG" 2>/dev/null || echo "false")"
fi

# ── Build combined system prompt ──────────────────────────────────────────────
# Profile comes first (personalization layer), then the operational template.
# A clear delimiter separates the two sections so Claude sees both cleanly.

COMBINED_PROMPT="$(cat "$PROFILE")

---
<!-- digest-runner template below -->

$(cat "$RUNNER_PROMPT")"

# ── Fetch notifications ───────────────────────────────────────────────────────

echo "📡  Fetching GitHub notifications..."

NOTIFICATIONS=""
if ! NOTIFICATIONS="$("$SCRIPTS_DIR/fetch-notifications.sh" --all)"; then
  echo "Error: Failed to fetch notifications." >&2
  echo "Check that 'gh' is installed and authenticated: gh auth status" >&2
  exit 1
fi

NOTIFICATION_COUNT="$(echo "$NOTIFICATIONS" | jq -r '.count // 0')"
echo "    Found ${NOTIFICATION_COUNT} notification(s)."

# ── Handle zero notifications ─────────────────────────────────────────────────
# Save a minimal digest and exit early — no need to invoke claude.

if [[ "$NOTIFICATION_COUNT" == "0" ]]; then
  mkdir -p "$DIGESTS_DIR"
  cat > "$DIGEST_FILE" <<EOF
---
date: ${TODAY}
total_notifications: 0
surfaced: 0
---

# GitHub Digest — ${TODAY}

No new notifications.
EOF
  echo "✅  No notifications — saved empty digest to $DIGEST_FILE"
  exit 0
fi

# ── Call claude -p ────────────────────────────────────────────────────────────

# Change to skill dir so Claude's allowed tools resolve correctly.
# This matters when launchd runs us with CWD=/ or $HOME.
cd "$SKILL_DIR"

echo "🤖  Generating digest with Claude..."

mkdir -p "$DIGESTS_DIR"

DIGEST_OUTPUT=""
if ! DIGEST_OUTPUT="$(echo "$NOTIFICATIONS" | claude -p \
  --system-prompt "$COMBINED_PROMPT" \
  --allowedTools "Bash($SCRIPTS_DIR/*)" \
  --dangerously-skip-permissions)"; then
  echo "Error: Claude failed to generate the digest." >&2
  echo "Check that the 'claude' CLI is authenticated and working." >&2
  exit 1
fi

if [[ -z "$DIGEST_OUTPUT" ]]; then
  echo "Error: Claude returned empty output." >&2
  exit 1
fi

# ── Save digest ───────────────────────────────────────────────────────────────

echo "$DIGEST_OUTPUT" > "$DIGEST_FILE"
echo "💾  Digest saved to $DIGEST_FILE"

# ── Mark notifications as read ────────────────────────────────────────────────

if [[ "$MARK_READ" == "true" ]]; then
  echo "✔️   Marking notifications as read..."
  if ! "$SCRIPTS_DIR/mark-read.sh" > /dev/null; then
    echo "Warning: Failed to mark notifications as read." >&2
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo "✅  GitHub Digest for ${TODAY} — ${NOTIFICATION_COUNT} notifications processed → $DIGEST_FILE"
