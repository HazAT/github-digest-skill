## Review Complete

**Verdict: NEEDS CHANGES** — 3 real issues, 2 worth considering.

### Critical findings:

1. **[P0] `--run-now` doesn't exist** — Onboarding's "first run" offer calls `./github-digest --run-now` which exits with an error. One-line fix: just use `./github-digest` (default mode runs digest when profile exists).

2. **[P1] PR type detection broken** — `fetch-details.sh` checks `.pull_request` which doesn't exist on PR API responses. All PRs silently fall through to the "issue" case, losing `merged`, `draft`, `changed_files`, `additions`, `deletions`, and `review_comments`. Confirmed with a jq test. Fix: check `.head` instead.

3. **[P1] Relative paths break scheduled runs** — Prompts use `./scripts/...` but `run-digest.sh` never `cd`s to the repo root. When launchd runs it, CWD is `/` or `$HOME` and everything fails. Fix: add `cd "$REPO_DIR"` before the `claude -p` call.

### Minor:
- Onboarding writes plist XML inline instead of using the existing `schedule.sh`
- No pagination (caps at 50 notifications)

Everything else is clean — security model is solid, bash is well-written, onboarding prompt is thorough, README is honest. Full details in `review.md`.