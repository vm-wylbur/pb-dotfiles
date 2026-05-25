## qfix — Infrastructure-of-Record drift queue

The qfix queue is an ansible-targeted drift queue. Use it to record host
changes that need to be encoded in the role tree but aren't going through
a normal PR right now.

**Tools** (claude-mem MCP):
- `mcp__claude-mem__queue-fix-store` — file a new entry
- `mcp__claude-mem__queue-fix-list` — list open entries
- `mcp__claude-mem__queue-fix-mark` — mark an entry processed

For full protocol details: `mem-search "queue-fix howto"`.

**Routing:**
- `cc-ansible-merger` drains `queue-fix-list` at session start.
- Other repos (tfcs / ntx / hmon / filelister / sysadmin) file GH issues
  in `hrdag/hrdag-ansible`, not queue entries.

## Filing shorthand

When PB says "qfix that" / "queue this" / "log this fix" (or similar
phrasing), call `queue-fix-store` with `target_repo="hrdag-ansible"` and
these fields extracted from preceding context:

- `host` (default: current shell host)
- `path`
- `before_state`
- `after_state`
- `why` (one line)
- `who="PB"`, `trust="PB"` (defaults)

If `host` / `path` / `before_state` / `after_state` can't be determined
from context, **ASK** — never guess.

## Proactive offer

When the session helps PB make a host change likely to need IaC encoding —
sudo on `/etc/`, `/usr/local/`, `/var/lib/`, systemd unit files, new files
in system paths — offer once at the end of the turn:

> qfix that?

Skip the offer for:
- `/tmp/` and `$HOME` (transient)
- Files inside a git repo (those go through git, not the queue)
