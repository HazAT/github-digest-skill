---
name: github-digest
description: Generate a personalized GitHub notification digest, or set up the tool for first-time users. Use when asked for "github digest", "daily digest", "github notifications", "check my notifications", "what are my github notifications", "morning digest", "run digest", "notification summary", "what did I miss on github", "set up github digest", or "configure my digest".
---

# GitHub Digest

Personalized GitHub notification digests — fetched locally, analyzed by Claude, filtered to what matters for your role.

## Determine Mode

Check the current state silently:

```bash
test -f ~/.github-digest/profile.md && echo "READY" || echo "NEEDS_SETUP"
```

| State | Action |
|-------|--------|
| `NEEDS_SETUP` | → Read `${CLAUDE_SKILL_ROOT}/references/onboarding.md` and follow it to set up the user's profile. The scripts directory is `${CLAUDE_SKILL_ROOT}/scripts/`. The user data directory is `~/.github-digest/`. |
| `READY` | → Continue to **Run Digest** below |

If the user explicitly asks to reconfigure (e.g., "redo setup", "change my digest settings"), treat as `NEEDS_SETUP` regardless of state.

## Run Digest

### Prerequisites

```bash
S="${CLAUDE_SKILL_ROOT}/scripts"
gh auth status 2>&1
```

If `gh` is not authenticated, guide the user through `gh auth login` and stop.

### Load Profile

```bash
cat ~/.github-digest/profile.md
```

This is the user's personalized filtering profile — their role, orgs, tiers, what to surface vs skip. **These rules govern all filtering decisions below.**

### Generate

Read `${CLAUDE_SKILL_ROOT}/references/digest-runner.md` for the full generation workflow. Follow it step by step — it covers fetching, triaging, fetching details, sanitization, output format, security rules, and edge cases.

All scripts are at `${CLAUDE_SKILL_ROOT}/scripts/`:

| Script | Purpose |
|--------|---------|
| `fetch-notifications.sh` | Fetch all GitHub notifications as JSON |
| `fetch-details.sh` | Fetch full PR/issue context from a subject URL |
| `fetch-comments.sh` | Fetch comment threads for a PR/issue |
| `sanitize.sh` | Scan content for prompt injection before processing |
| `mark-read.sh` | Mark GitHub notifications as read |

### After Generating

1. Save the digest to `~/.github-digest/digests/YYYY-MM-DD.md`
2. Check config for mark-read preference:
   ```bash
   jq -r '.mark_read // false' ~/.github-digest/config.json 2>/dev/null
   ```
   If `true`, run `"$S/mark-read.sh"`
3. Present the full digest to the user in the conversation
4. Mention where it's saved
