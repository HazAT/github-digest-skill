<!-- Copy everything below this line and paste it into Claude Code -->

Clone the GitHub Digest repo and install it locally. Here's what to do:

1. Clone the repo to a permanent location (it needs to stay here — the scheduled job references it):

```bash
git clone https://github.com/getsentry/github-digest-cc.git ~/.github-digest-cc
```

2. Symlink the CLI so it's available everywhere:

```bash
ln -sf ~/.github-digest-cc/github-digest /usr/local/bin/github-digest
```

3. Copy the Claude Code skill into the current project so it's available here:

```bash
mkdir -p .claude/skills
cp -r ~/.github-digest-cc/.claude/skills/github-digest .claude/skills/github-digest
```

4. Verify everything is in place:

```bash
test -x /usr/local/bin/github-digest && echo "CLI: ok" || echo "CLI: missing"
test -f .claude/skills/github-digest/SKILL.md && echo "Skill: ok" || echo "Skill: missing"
```

After all four steps succeed, ask the user: **"GitHub Digest is installed. Want me to run the setup and generate your first digest?"**

If they say yes, invoke the `github-digest` skill.
