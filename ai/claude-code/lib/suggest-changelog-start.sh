#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-02
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/suggest-changelog-start.sh
#
# Suggest a start date for the next changelog: the END date of the most recent
# ~/docs/changelog-*.md minus one day (a small overlap avoids a seam gap between
# reports). Prints YYYY-MM-DD, or nothing if no prior changelog exists (the skill
# then asks for an explicit start date). An explicit arg to the skill overrides.
#
# Filenames are changelog-<start>-to-<end>.md; the end date is parsed from the
# name (after the last "-to-"), and the latest end date wins.
#
# Usage: bash lib/suggest-changelog-start.sh [DOCS_DIR]

DOCS=${1:-$HOME/docs}
[ -d "$DOCS" ] || exit 0

# Newest end-date among changelog-*-to-<end>.md (ISO dates sort lexically).
end=$(find "$DOCS" -maxdepth 1 -name 'changelog-*-to-*.md' 2>/dev/null \
      | sed -E 's#.*-to-([0-9]{4}-[0-9]{2}-[0-9]{2})\.md$#\1#' \
      | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' \
      | sort | tail -1)
[ -z "$end" ] && exit 0

# end - 1 day, portable across BSD (macOS) and GNU date; fall back to end itself.
if start=$(date -j -v-1d -f "%Y-%m-%d" "$end" "+%Y-%m-%d" 2>/dev/null); then
    :
elif start=$(date -d "$end -1 day" "+%Y-%m-%d" 2>/dev/null); then
    :
else
    start="$end"
fi

printf '%s\n' "$start"
