#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-13
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/fleet-brief-status.sh
#
# SessionStart line that closes the fleet-brief delivery loop: the scheduled
# run writes ~/docs/fleet-brief-<date>.md, and this surfaces it where PB
# already looks (session start). Without this the artifact is written for
# nobody.
#
# - brief exists for today  -> point at it.
# - missing AND past the scheduled hour (macOS only) -> one-line note that
#   the morning run didn't land (Mac asleep/off at 07:17, or job not
#   installed); suggests the on-demand /fleet-brief. Silent before the
#   scheduled hour (not yet expected) and on non-macOS (not scheduled there).

set -uo pipefail

DOCS="${HOME}/docs"
SCHED_HOUR=8   # the 07:17 job should have produced today's brief by 08:00

today=$(date +%Y-%m-%d 2>/dev/null) || exit 0
brief="${DOCS}/fleet-brief-${today}.md"

if [ -f "$brief" ]; then
    echo "Fleet brief ready: $brief"
    exit 0
fi

# Missing: only note on macOS (where it's scheduled) and only once the
# scheduled time has passed, so we don't nag every pre-dawn session.
if [ "$(uname -s)" = "Darwin" ]; then
    hour=$(date +%H 2>/dev/null || echo 0)
    # strip a leading zero so 08 isn't read as octal in the arithmetic test
    if [ "$((10#${hour}))" -ge "$SCHED_HOUR" ]; then
        echo "Fleet brief: none for $today (morning run didn't land — run /fleet-brief)."
    fi
fi
exit 0
