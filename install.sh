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

# ── Install Claude Code skill ─────────────────────────────────────────────────

SKILL_SRC="$REPO_DIR/.claude/skills/github-digest"
SKILL_DST="$HOME/.claude/skills/github-digest"

if [[ -d "$SKILL_SRC" ]]; then
  mkdir -p "$HOME/.claude/skills"
  if [[ -L "$SKILL_DST" ]]; then
    existing_target="$(readlink "$SKILL_DST")"
    if [[ "$existing_target" == "$SKILL_SRC" ]]; then
      echo "Skill already installed: $SKILL_DST → $SKILL_SRC"
    else
      echo "Replacing skill symlink: $SKILL_DST → $existing_target"
      rm "$SKILL_DST"
      ln -s "$SKILL_SRC" "$SKILL_DST"
      echo "Skill installed: $SKILL_DST → $SKILL_SRC"
    fi
  elif [[ -d "$SKILL_DST" ]]; then
    echo "Skill directory already exists at $SKILL_DST — skipping (remove it to re-link)"
  else
    ln -s "$SKILL_SRC" "$SKILL_DST"
    echo "Skill installed: $SKILL_DST → $SKILL_SRC"
  fi
  echo ""
  echo "Claude Code skill 'github-digest' is now available."
  echo "Say \"give me my github digest\" in any Claude Code session."
fi

# ── Verify it's on PATH ───────────────────────────────────────────────────────

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
  echo ""
  echo "Note: '$INSTALL_DIR' is not on your PATH."
  echo "Add this to your shell profile (~/.zshrc or ~/.bashrc):"
  echo ""
  echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
fi
