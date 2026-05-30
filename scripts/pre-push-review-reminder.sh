#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-30
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# ---
# dotfiles/scripts/pre-push-review-reminder.sh
#
# pre-commit `pre-push`-stage hook. Nag, NOT a blocker: prints the size of
# the outgoing push and reminds the pusher (human or cc) to run code review.
# Always exits 0 — bypass the whole push with `git push --no-verify`.
#
# Seeded into each repo root alongside .pre-commit-config.yaml by deploy-repos.

set -uo pipefail

upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
if [[ -n "$upstream" ]]; then
    range="${upstream}..HEAD"
else
    range="HEAD"   # no upstream yet (new branch): describe HEAD
fi

ncommits=$(git rev-list --count "$range" 2>/dev/null || echo "?")
if [[ "$upstream" ]]; then
    nfiles=$(git diff --name-only "$range" 2>/dev/null | wc -l | tr -d ' ')
else
    nfiles=$(git show --name-only --format= HEAD 2>/dev/null | wc -l | tr -d ' ')
fi

cat >&2 <<EOF
────────────────────────────────────────────────────────────
  pre-push  ·  ${ncommits} commit(s), ~${nfiles} file(s) outgoing
  Did you run  /code-review  (+ /security-review if this touches
  auth, user input, queries, file ops, secrets, or crypto)?
  This is a reminder, not a gate.  Bypass: git push --no-verify
────────────────────────────────────────────────────────────
EOF

exit 0
