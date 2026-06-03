#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-02
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/resolve-clone.sh
#
# Resolve a GitHub repo (OWNER/REPO) to its local clone path by matching the
# origin remote URL — NOT the directory name (the GitHub name can differ from
# the local dir, e.g. pb-dotfiles -> ~/dotfiles). Clones span several bases.
# Prints the local path on a match, nothing if no clone is found. Exit 0 either
# way, so callers can branch on an empty result:
#
#   path=$(bash lib/resolve-clone.sh hrdag/tfcs)
#   [ -n "$path" ] && ... || ...  # messages-only fallback
#
# Usage: bash lib/resolve-clone.sh OWNER/REPO

REPO=${1:-}
[ -z "$REPO" ] && { echo "usage: resolve-clone.sh OWNER/REPO" >&2; exit 1; }

# Normalize the target to lowercase owner/repo, no .git suffix.
want=$(printf '%s' "$REPO" | tr '[:upper:]' '[:lower:]')
want=${want%.git}

# Known clone bases. Each is either a repo itself (~/dotfiles) or a container
# of repo dirs (~/projects/*). We check the base and one level of subdirs only
# — no deep scans.
BASES=( "$HOME/dotfiles" "$HOME/projects/hrdag" "$HOME/projects/personal" "$HOME/projects" )

# Does directory $1's origin remote resolve to the wanted owner/repo?
match_dir() {
    local d=$1 url owner_repo
    [ -d "$d/.git" ] || return 1
    url=$(git -C "$d" remote get-url origin 2>/dev/null) || return 1
    [ -n "$url" ] || return 1
    url=${url%/}  # tolerate a trailing slash before the owner/repo extraction
    # git@github.com:owner/repo.git  and  https://github.com/owner/repo.git  -> owner/repo
    owner_repo=$(printf '%s' "$url" | sed -E 's#^.*[:/]([^/]+/[^/]+)$#\1#; s#\.git$##' | tr '[:upper:]' '[:lower:]')
    [ "$owner_repo" = "$want" ]
}

for base in "${BASES[@]}"; do
    [ -d "$base" ] || continue
    if match_dir "$base"; then
        printf '%s\n' "$base"
        exit 0
    fi
    for d in "$base"/*/; do
        [ -d "$d" ] || continue
        if match_dir "${d%/}"; then
            printf '%s\n' "${d%/}"
            exit 0
        fi
    done
done

# No local clone found — print nothing, exit 0 (caller falls back to messages-only).
exit 0
