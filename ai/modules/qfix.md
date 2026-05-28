## qfix — Infrastructure-of-Record drift queue

The qfix queue is an ansible-targeted drift queue. Use it to record host
changes that need to be encoded in the role tree but aren't going through
a normal PR right now.

**Tools** (REST shims over claude-mem on snowball; replace the
previous `mcp__claude-mem__queue-fix-*` MCP tools as of 2026-05-27):

```bash
# file a new entry
echo '{"target_repo":"...", "host":"...", "path":"...",
       "before_state":"...", "after_state":"...", "why":"...",
       "who":"PB"}' \
    | bash ~/.claude/lib/qfix-store.sh
# returns {"id": N}

# list open entries (FIFO)
bash ~/.claude/lib/qfix-list.sh --target-repo hrdag-ansible --status open

# mark consumed / escalated / superseded
echo '{"id": N, "status":"consumed",
       "consumed_by_commit":"abc123",
       "consumed_in_repo":"hrdag-ansible",
       "consumed_in_path":"roles/foo/tasks/main.yml"}' \
    | bash ~/.claude/lib/qfix-mark.sh
```

For full protocol details, search the memory store:

```bash
echo '{"query":"queue-fix howto","limit":3}' \
    | bash ~/.claude/lib/mem-search.sh
```

**Routing:**
- `cc-ansible-merger` drains the qfix list at session start.
- Other repos (tfcs / ntx / hmon / filelister / sysadmin) file GH
  issues in `hrdag/hrdag-ansible`, not queue entries.

## Filing shorthand

When PB says "qfix that" / "queue this" / "log this fix" (or similar
phrasing), call `qfix-store.sh` with `target_repo="hrdag-ansible"` and
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
