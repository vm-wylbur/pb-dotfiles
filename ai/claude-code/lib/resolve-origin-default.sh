#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-02
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/resolve-origin-default.sh
#
# Fetch origin (read-only — never touches the working tree) and print the repo's
# origin default-branch ref, e.g. "origin/main". Prints nothing and exits 1 if
# none resolves. Single source of truth for the resolution, shared by
# repo-diff-since.sh and git-version-tags-since.sh (it used to be duplicated in
# both — a shotgun-surgery hazard).
#
# Resolution order:
#   1. AUTHORITATIVE remote HEAD via `ls-remote --symref` (pure-read). The local
#      origin/HEAD symref goes stale after an upstream master->main rename, which
#      would silently log a dead branch — so the live remote wins.
#   2. the local origin/HEAD cache (offline fallback),
#   3. origin/main, then origin/master.
#
# Usage: DEFAULT=$(bash lib/resolve-origin-default.sh REPO_PATH) || exit 0

REPO=${1:-}
[ -z "$REPO" ] && { echo "usage: resolve-origin-default.sh REPO_PATH" >&2; exit 1; }
[ -d "$REPO/.git" ] || exit 1

git -C "$REPO" fetch --quiet origin 2>/dev/null

branch=$(git -C "$REPO" ls-remote --symref origin HEAD 2>/dev/null \
         | awk '/^ref:/ {sub(/refs\/heads\//,"",$2); print $2; exit}')
if [ -n "$branch" ] && git -C "$REPO" rev-parse --verify --quiet "origin/$branch" >/dev/null 2>&1; then
    printf 'origin/%s\n' "$branch"
    exit 0
fi

# Local cache fallback. `rev-parse --abbrev-ref origin/HEAD` prints the literal
# "origin/HEAD" and exits non-zero when the symref is unset, so guard on both.
cand=$(git -C "$REPO" rev-parse --abbrev-ref origin/HEAD 2>/dev/null) || cand=""
if [ -n "$cand" ] && [ "$cand" != "origin/HEAD" ] \
   && git -C "$REPO" rev-parse --verify --quiet "$cand" >/dev/null 2>&1; then
    printf '%s\n' "$cand"
    exit 0
fi

for c in origin/main origin/master; do
    if git -C "$REPO" rev-parse --verify --quiet "$c" >/dev/null 2>&1; then
        printf '%s\n' "$c"
        exit 0
    fi
done

exit 1
