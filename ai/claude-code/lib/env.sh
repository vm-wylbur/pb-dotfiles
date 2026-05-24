#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/env.sh
#
# Print host/arch/date one-liner. Stable across session.

echo "Host: $(hostname -s) | Arch: $(uname -m) | Date: $(date +%Y-%m-%d)"
