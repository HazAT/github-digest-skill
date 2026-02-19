<!-- Copy everything below this line and paste it into Claude Code -->

Uninstall GitHub Digest completely. Remove the skill, data, scheduled job, and cloned repo:

```bash
# Stop and remove the scheduled background job
launchctl unload ~/Library/LaunchAgents/com.github-digest.daily.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/com.github-digest.daily.plist

# Remove the skill from Claude
rm -f ~/.claude/skills/github-digest

# Remove user data (profile, config, saved digests)
rm -rf ~/.github-digest

# Remove the cloned repo
rm -rf ~/.github-digest-skill
```

Run all of the above, then confirm to the user that GitHub Digest has been fully uninstalled.
