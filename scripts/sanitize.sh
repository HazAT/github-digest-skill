#!/usr/bin/env bash
# sanitize.sh — Scan GitHub content for prompt injection attempts
#
# Usage: echo "$content" | ./scripts/sanitize.sh
#        ./scripts/sanitize.sh < file.json
#
# Outputs: JSON {clean: bool, warning: string|null, matches: [...]}

set -euo pipefail

INPUT=$(cat)

# Single mega-pattern for common prompt injection techniques
INJECTION_RE='ignore (all |your |previous |prior |above )?(instructions|prompts)|disregard (all |your )?instructions|forget (all |your )?instructions|override (all |your )?instructions|new instructions:|system prompt[:.]|you are now |act as if |pretend you are |jailbreak|DAN mode|repeat (all |your |the )?(system )?instructions|show (me |your )?(system |initial )?prompt|reveal your (system )?prompt|output your (system )?prompt|IMPORTANT:.*ignore|<\|im_start\|>|<\|im_end\|>|\[INST\]|\[\/INST\]|<<SYS>>|<\/SYS>'

MATCHES=$(echo "$INPUT" | grep -inE "$INJECTION_RE" | head -10) || true

if [[ -n "$MATCHES" ]]; then
  echo "$MATCHES" | jq -Rs '{
    clean: false,
    warning: "⚠️ POTENTIAL PROMPT INJECTION DETECTED in GitHub content",
    matches: (split("\n") | map(select(length > 0)) | map(.[0:200]))
  }'
else
  echo '{"clean": true, "warning": null, "matches": []}'
fi
