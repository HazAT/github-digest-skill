#!/usr/bin/env bash
# schedule.sh — Manage the launchd schedule for github-digest
#
# Usage:
#   scripts/schedule.sh install <HH:MM> <daily|weekdays>
#   scripts/schedule.sh uninstall
#   scripts/schedule.sh status

set -euo pipefail

# ── Resolve paths ─────────────────────────────────────────────────────────────

SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" == /* ]] || SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$SOURCE"
done
REPO_DIR="$(cd "$(dirname "$SOURCE")/../../../.." && pwd)"

PLIST_LABEL="com.github-digest.daily"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"
LOG_DIR="$HOME/.github-digest/logs"
PROGRAM="$REPO_DIR/github-digest"

# ── Helpers ───────────────────────────────────────────────────────────────────

die() { echo "Error: $*" >&2; exit 1; }

usage() {
  cat >&2 <<EOF
Usage:
  $(basename "$0") install <HH:MM> <daily|weekdays>
  $(basename "$0") uninstall
  $(basename "$0") status
EOF
  exit 1
}

# Build a single <dict> entry for StartCalendarInterval
calendar_entry() {
  local hour="$1" minute="$2" weekday="${3:-}"
  if [[ -n "$weekday" ]]; then
    cat <<XML
        <dict>
            <key>Weekday</key>
            <integer>${weekday}</integer>
            <key>Hour</key>
            <integer>${hour}</integer>
            <key>Minute</key>
            <integer>${minute}</integer>
        </dict>
XML
  else
    cat <<XML
        <dict>
            <key>Hour</key>
            <integer>${hour}</integer>
            <key>Minute</key>
            <integer>${minute}</integer>
        </dict>
XML
  fi
}

# ── install ───────────────────────────────────────────────────────────────────

cmd_install() {
  local time_arg="${1:-}" days_arg="${2:-}"

  [[ -z "$time_arg" ]] && die "Missing time argument (e.g. 08:00)"
  [[ -z "$days_arg" ]] && die "Missing days argument: 'daily' or 'weekdays'"

  # Validate time format
  if [[ ! "$time_arg" =~ ^([0-9]{2}):([0-9]{2})$ ]]; then
    die "Invalid time format '$time_arg' — expected HH:MM (e.g. 08:00)"
  fi
  local hour="${BASH_REMATCH[1]}" minute="${BASH_REMATCH[2]}"

  # Validate days
  case "$days_arg" in
    daily|weekdays) ;;
    *) die "Invalid days '$days_arg' — expected 'daily' or 'weekdays'" ;;
  esac

  # Verify the main binary exists
  if [[ ! -f "$PROGRAM" ]]; then
    die "github-digest binary not found at $PROGRAM"
  fi

  # Ensure log directory exists
  mkdir -p "$LOG_DIR"

  # Build StartCalendarInterval XML
  local interval_xml
  if [[ "$days_arg" == "daily" ]]; then
    interval_xml="$(calendar_entry "$hour" "$minute")"
  else
    # weekdays: Monday=1 through Friday=5
    interval_xml=""
    for weekday in 1 2 3 4 5; do
      interval_xml+="$(calendar_entry "$hour" "$minute" "$weekday")"$'\n'
    done
  fi

  # Wrap in <array> for weekdays, bare <dict> for daily
  local sci_xml
  if [[ "$days_arg" == "daily" ]]; then
    sci_xml="$interval_xml"
  else
    sci_xml="        <array>
${interval_xml}        </array>"
  fi

  # Build PATH: prepend common tool dirs, fall back gracefully
  local effective_path="/usr/local/bin:/opt/homebrew/bin:${PATH}"

  # Write the plist
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_LABEL}</string>

    <key>ProgramArguments</key>
    <array>
        <string>${PROGRAM}</string>
    </array>

    <key>StartCalendarInterval</key>
${sci_xml}

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>${effective_path}</string>
        <key>HOME</key>
        <string>${HOME}</string>
    </dict>

    <key>StandardOutPath</key>
    <string>${LOG_DIR}/stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/stderr.log</string>

    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
PLIST

  # Unload any existing job before (re-)loading
  if launchctl list "$PLIST_LABEL" &>/dev/null; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
  fi

  launchctl load "$PLIST_PATH"

  echo "✅  Scheduled github-digest to run at ${time_arg} (${days_arg})"
  echo "    Plist: $PLIST_PATH"
  echo "    Logs:  $LOG_DIR/"
}

# ── uninstall ─────────────────────────────────────────────────────────────────

cmd_uninstall() {
  if [[ ! -f "$PLIST_PATH" ]]; then
    echo "No plist found at $PLIST_PATH — nothing to remove."
    exit 0
  fi

  if launchctl list "$PLIST_LABEL" &>/dev/null; then
    launchctl unload "$PLIST_PATH"
    echo "✅  Job unloaded."
  fi

  rm -f "$PLIST_PATH"
  echo "✅  Plist removed: $PLIST_PATH"
}

# ── status ────────────────────────────────────────────────────────────────────

cmd_status() {
  if [[ ! -f "$PLIST_PATH" ]]; then
    echo "⬜  Not installed (no plist at $PLIST_PATH)"
    exit 0
  fi

  if launchctl list "$PLIST_LABEL" &>/dev/null; then
    # Extract PID and last exit code from launchctl output
    local info
    info="$(launchctl list "$PLIST_LABEL" 2>/dev/null)"
    local pid exit_code
    pid="$(echo "$info" | grep '"PID"' | grep -oE '[0-9]+' || echo "-")"
    exit_code="$(echo "$info" | grep '"LastExitStatus"' | grep -oE '[0-9]+' || echo "-")"
    echo "🟢  Loaded — PID: ${pid:-none}  LastExitStatus: ${exit_code:-unknown}"
    echo "    Plist: $PLIST_PATH"
    echo "    Logs:  $LOG_DIR/"
  else
    echo "🔴  Plist exists but job is not loaded"
    echo "    Plist: $PLIST_PATH"
  fi
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

[[ $# -lt 1 ]] && usage

case "$1" in
  install)   shift; cmd_install "$@" ;;
  uninstall) cmd_uninstall ;;
  status)    cmd_status ;;
  *)         die "Unknown command '$1'"; usage ;;
esac
