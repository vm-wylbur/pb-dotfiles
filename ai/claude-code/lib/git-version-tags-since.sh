#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/git-version-tags-since.sh
#
# Scan a repo for AUTHOR commits since DATE that look like version bumps
# (bump to, version, release, v\d+.\d+). Used by changelog skill as
# navigation aids — readers cite "shipped as tfcs v0.12.0" to find work
# in git history.
#
# Silent if REPO isn't a git repo.
#
# Usage: bash lib/git-version-tags-since.sh REPO_PATH YYYY-MM-DD
#        AUTHOR=alice bash lib/git-version-tags-since.sh ~/projects/foo 2026-05-01

REPO=${1:-}
DATE=${2:-}
if [ -z "$REPO" ] || [ -z "$DATE" ]; then
    echo "usage: git-version-tags-since.sh REPO_PATH YYYY-MM-DD" >&2
    exit 1
fi
[ -d "$REPO/.git" ] || exit 0

AUTHOR=${AUTHOR:-pball}

# Resolve the origin default branch via the shared helper (read-only fetch +
# authoritative resolution), so version bumps merged but not pulled are seen.
DEFAULT=$(bash "$(dirname "$0")/resolve-origin-default.sh" "$REPO") || exit 0

git -C "$REPO" log "$DEFAULT" \
    --author="$AUTHOR" \
    --since="$DATE" \
    --format="%h %s" 2>/dev/null | \
    grep -iE 'bump to|version|release|v[0-9]+\.[0-9]+'
