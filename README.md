# GitHub Digest

Daily AI-powered summary of your GitHub notifications, filtered to what matters for your role.

## Install

Tell your agent:

```
Download and follow: https://raw.githubusercontent.com/HazAT/github-digest-skill/refs/heads/main/INSTALL.md
```

That's it. It will clone, install, and offer to run your first digest.

## How It Works

1. Shell scripts fetch notifications via `gh` (your token never touches Claude)
2. Content is sanitized for prompt injection before Claude sees it
3. Claude applies your profile — role, org tiers, what to surface vs skip
4. Digest saved to `~/.github-digest/digests/YYYY-MM-DD.md`

A launchd job runs this daily in the background. When you ask for your digest, the skill serves the pre-generated file.

## License

MIT
