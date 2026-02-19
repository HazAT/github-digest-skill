# GitHub Digest

Daily AI-powered summary of your GitHub notifications, filtered to what matters for your role.

Fetches notifications locally via `gh`, runs them through Claude, saves a markdown digest. A background job generates it daily — when you ask for it, it's already there.

## Install

```bash
git clone https://github.com/getsentry/github-digest-cc.git
cd github-digest-cc
```

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`claude`) and [GitHub CLI](https://cli.github.com) (`gh`). Both will be checked on first run — if anything's missing, you'll be offered to install it.

## Usage

**From Claude Code** (recommended) — open the repo and say:

> "github digest"

If it's your first run, a short setup conversation asks your role and org. After that, it checks for today's digest file and shows it instantly — or generates a fresh one if needed.

**From the terminal:**

```bash
./github-digest              # Generate digest (or onboard on first run)
./github-digest --setup      # Redo onboarding
./github-digest --view       # View today's or most recent digest
./github-digest --status     # Show config and schedule info
```

## How It Works

1. Shell scripts fetch notifications via `gh` (your token never touches Claude)
2. Content is sanitized for prompt injection before Claude sees it
3. Claude applies your profile — role, org tiers, what to surface vs skip
4. Digest saved to `~/.github-digest/digests/YYYY-MM-DD.md`

A launchd job runs this daily in the background. When you ask for your digest, the skill serves the pre-generated file.

## Configuration

All user data lives in `~/.github-digest/`:

| File | Purpose |
|------|---------|
| `profile.md` | Your filtering rules — role, orgs, what matters. Edit anytime. |
| `config.json` | Schedule time, mark-as-read preference |
| `digests/` | One markdown file per day |

To redo setup: `./github-digest --setup` or tell Claude "redo my digest setup".

## Project Structure

```
github-digest              # CLI entry point
.claude/skills/github-digest/
├── SKILL.md               # Claude Code skill definition
├── references/            # Onboarding + digest runner prompts
└── scripts/               # fetch, sanitize, schedule, batch-fetch
```
