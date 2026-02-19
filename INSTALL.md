<!-- Copy everything below this line and paste it into Claude Code -->

Install GitHub Digest — a daily AI-powered summary of your GitHub notifications.

1. Clone the repo:

```bash
git clone https://github.com/HazAT/github-digest-skill.git ~/.github-digest-skill
```

2. Symlink the skill into Claude's global skills directory so it's available in every session:

```bash
ln -sf ~/.github-digest-skill/.claude/skills/github-digest ~/.claude/skills/github-digest
```

3. Verify:

```bash
test -f ~/.claude/skills/github-digest/SKILL.md && echo "Skill: ok" || echo "Skill: missing"
```

4. Now read the skill file and follow it (this starts the onboarding):

```bash
cat ~/.claude/skills/github-digest/SKILL.md
```

The scripts directory is `~/.github-digest-skill/.claude/skills/github-digest/scripts/`. The user data directory is `~/.github-digest/`.

Follow the skill instructions. If the state is `NEEDS_SETUP`, read the onboarding reference at `~/.github-digest-skill/.claude/skills/github-digest/references/onboarding.md` and run through it.
