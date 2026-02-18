# GitHub Digest

**A daily AI-powered summary of your GitHub notifications, filtered to what actually matters for your role.**

GitHub Digest fetches your notifications locally, runs them through Claude, and delivers a tight briefing — no noise, no endless scrolling. The first time you run it, Claude walks you through setup, learns your role, and builds a personalized profile. Every run after that is automatic.

---

## Prerequisites

You need two things before you start — both are required, not optional.

**[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** — the AI engine that reads your notifications and writes the digest. Install it and make sure `claude` is on your PATH.

**[GitHub CLI](https://cli.github.com)** (`gh`) — handles all GitHub authentication. Your token never leaves your machine.

```bash
# Verify both are ready
claude --version
gh auth status
```

If `gh auth status` shows you're not authenticated, run `gh auth login` first.

---

## Install

Clone the repo:

```bash
git clone https://github.com/getsentry/github-digest-cc.git
cd github-digest-cc
```

That's it. Run `./github-digest` from the repo directory, or open Claude Code here and say "give me my GitHub digest" to use the built-in skill.

---

## Getting Started

```bash
github-digest
```

That's it. If this is your first run, onboarding starts automatically. If you're already set up, it generates today's digest.

---

## What Happens on First Run

Claude walks you through a short setup conversation — more like a chat than a form. It'll:

1. Check that `gh` is authenticated and has the right scopes
2. Ask about your role (IC, tech lead, EM, director, PM — the answer shapes how aggressively notifications get filtered)
3. Learn what you care about and what's noise
4. Ask whether you want a daily schedule, macOS notifications, and auto-marking notifications as read
5. Write a personalized `profile.md` that becomes your permanent digest configuration

The whole thing takes a few minutes. At the end, Claude offers to generate your first digest right then.

---

## How It Works

```
GitHub API → fetch scripts → sanitize → Claude → digest.md
```

1. Shell scripts call the GitHub API via `gh` and collect your notifications
2. Content is sanitized locally before Claude ever sees it (more on this below)
3. Claude reads your profile, analyzes the notifications, fetches details on anything interesting, and writes a concise digest
4. The digest is saved as a markdown file in `~/.github-digest/digests/`

**Your GitHub token never touches Claude.** The scripts handle all API calls locally; Claude only sees the sanitized notification content.

---

## Configuration

Everything lives in `~/.github-digest/`:

| File | What it is |
|------|------------|
| `profile.md` | Your personalized digest prompt — edit this to adjust what gets surfaced |
| `config.json` | Schedule time, macOS notification preference, mark-as-read setting |
| `digests/` | Saved digests, one markdown file per day |
| `logs/` | Logs from scheduled runs (if you set up a schedule) |

The most useful file to edit is `profile.md`. It controls exactly what Claude looks for and how it formats the output. Open it, read it, tweak it — it's plain English.

To redo the full setup conversation:

```bash
github-digest --setup
```

---

## Commands

```bash
github-digest                    # Generate today's digest (or run onboarding on first use)
github-digest --setup            # Re-run onboarding to update your profile or schedule
github-digest --view             # View today's digest (or the most recent one)
github-digest --view 2026-02-14  # View a specific date's digest
github-digest --status           # Show config, schedule, and last digest info
github-digest --help             # Show usage
```

---

## Security

GitHub Digest is designed so that untrusted content from GitHub never influences Claude's behavior.

**What the security model looks like:**

- `gh` handles all GitHub authentication — your token is never passed to Claude
- Shell scripts fetch notification data locally and pipe it through `sanitize.sh` before Claude sees it
- `sanitize.sh` scans for prompt injection patterns (things like "ignore previous instructions", jailbreak attempts, system prompt leaks) and flags them
- If injection is detected, Claude is told to skip that content entirely and surface a `🚨` warning in the digest
- Claude is explicitly instructed to treat all GitHub content as **data to summarize**, never as instructions to follow

The sanitizer catches common injection techniques but no filter is perfect. If you see unexpected behavior in a digest, check `--status` and inspect the raw digest file.

---

## FAQ

**I'm getting a scope error from `gh auth status`.**

Run this to add the required scopes:

```bash
gh auth refresh -h github.com -s notifications,read:org
```

Then go to [github.com/settings/tokens](https://github.com/settings/tokens) and click **Authorize** next to any organization you want to include (e.g. `getsentry`).

---

**I want to re-run onboarding.**

```bash
github-digest --setup
```

This re-runs the full conversation and overwrites your profile and config.

---

**How do I change my schedule?**

Run `github-digest --setup` and answer the scheduling questions again. The launchd plist will be updated and reloaded.

To check what's currently configured:

```bash
github-digest --status
```

---

**Where are my digests?**

In `~/.github-digest/digests/`, as markdown files named by date (`2026-02-18.md`). View them with:

```bash
github-digest --view           # today or most recent
github-digest --view 2026-02-14
```

Or open them in any text editor or markdown viewer.

---

**Claude isn't finding some of my notifications.**

This is usually a GitHub SSO issue. If the digest mentions partial results or SSO warnings, go to [github.com/settings/tokens](https://github.com/settings/tokens) and authorize your token for the relevant organization. Then re-run.

---

## Project Structure

Everything lives inside the Claude Code skill at `.claude/skills/github-digest/`:

```
.claude/skills/github-digest/
├── SKILL.md              # Claude Code skill — the inline integration
├── scripts/              # All shell scripts (fetch, sanitize, schedule)
└── references/           # Prompts (onboarding, digest runner template)

github-digest             # CLI entry point (thin wrapper)
README.md
```

## Contributing

This is a Sentry internal tool but PRs are welcome. The skill is self-contained in `.claude/skills/github-digest/`; the `github-digest` script at the root is just a CLI wrapper.
