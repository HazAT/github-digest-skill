#!/usr/bin/env bash
# install.sh — Symlink github-digest to a directory on your PATH
#
# Usage:
#   ./install.sh              # installs to /usr/local/bin (default)
#   ./install.sh ~/bin        # installs to ~/bin

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="$REPO_DIR/github-digest"
INSTALL_DIR="${1:-/usr/local/bin}"
LINK="$INSTALL_DIR/github-digest"

# ── Sanity checks ────────────────────────────────────────────────────────────

if [[ ! -f "$BINARY" ]]; then
  echo "Error: '$BINARY' not found." >&2
  echo "Make sure you're running install.sh from inside the github-digest-cc repo." >&2
  exit 1
fi

if [[ ! -d "$INSTALL_DIR" ]]; then
  echo "Error: install directory '$INSTALL_DIR' does not exist." >&2
  exit 1
fi

# ── Install (idempotent) ─────────────────────────────────────────────────────

if [[ -L "$LINK" ]]; then
  existing_target="$(readlink "$LINK")"
  if [[ "$existing_target" == "$BINARY" ]]; then
    echo "Already installed: $LINK → $BINARY"
    exit 0
  else
    echo "Replacing existing symlink: $LINK → $existing_target"
    rm "$LINK"
  fi
elif [[ -e "$LINK" ]]; then
  echo "Error: '$LINK' already exists and is not a symlink." >&2
  echo "Remove it manually, then re-run install.sh." >&2
  exit 1
fi

ln -s "$BINARY" "$LINK"
echo "Installed: $LINK → $BINARY"

# ── Verify it's on PATH ───────────────────────────────────────────────────────

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
  echo ""
  echo "Note: '$INSTALL_DIR' is not on your PATH."
  echo "Add this to your shell profile (~/.zshrc or ~/.bashrc):"
  echo ""
  echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
fi
