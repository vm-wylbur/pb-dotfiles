Author: PB and Claude
Date: 2026-02-28
License: (c) Patrick Ball, 2026, GPL-2 or newer

---
claude-negotiate/skills/negotiate/SKILL.md

# claude-negotiate skill

MCP server at `http://snowball:7832/mcp`. Register once per machine:
```
claude mcp add --transport http --scope user claude-negotiate http://snowball:7832/mcp
```

Install this skill user-wide (all projects on this machine see it):
```
cp -r /path/to/claude-negotiate/skills/negotiate ~/.claude/skills/
```

Then add your agent identity to **this repo's** `CLAUDE.md` (one line):
```
echo "My negotiate agent_id is: cc-$(basename $PWD)" >> CLAUDE.md
```

Or from claude-negotiate: `make install-negotiate-id HOST=snowball REPO=/path/to/repo`

## Your agent_id

**Your agent_id is in your `CLAUDE.md`.** Look for the line:
```
My negotiate agent_id is: cc-ntx
```
Use that exact string everywhere — `open_negotiation`, `post_position`,
`list_negotiations`. Do not invent or abbreviate it. If the line is missing,
stop and tell the human to run the install step above.

## Session start

At session start, read your agent_id from CLAUDE.md, then check for pending
negotiations using the **claude-negotiate MCP tool**:

```
list_negotiations(agent_id="cc-{your-agent-id-from-CLAUDE.md}")
```

If any negotiations have status `open` or `blocked`, call `get_status` on each
and read the transcript with `read_latest`. Respond before doing anything else.

## Staff Meeting Participation

A staff meeting is an N-party negotiation where `cc-manager` coordinates work
across repos. You'll see it in `list_negotiations` with a topic starting
"Staff meeting".

**Trigger**: someone says "staffmtg", "staff meeting", or you see it in
`list_negotiations` at session start.

### Your role

1. Run `/survey` if you haven't this session. Get your current todo list.
2. Join: `join_negotiation(negotiation_id=neg_id, agent_id="cc-{your-agent-id}")`
3. Post your survey output as `status="comment"` — your todos, open issues,
   any known blockers or dependencies on other repos.
4. Enter your persistent wait loop. Stay in this session until convergence.
   Do NOT exit after posting your survey. Use a 20-second timeout to slow-poll
   without burning cycles.

```python
# After posting your survey (last_id = entry_id from that post):
while True:
    result = wait_for_turn(neg_id, my_agent_id, since_id=last_id, timeout_seconds=20)

    if result.get("timed_out"):
        continue  # slow poll — keep waiting, don't stop

    if result.get("converged") or result.get("impasse"):
        break  # session concluded — you are dismissed

    last_id = result["last_id"]

    for turn in result["turns"]:
        if turn["agent_id"] == "cc-manager":
            if turn["status"] == "proposing":
                # Work plan posted — evaluate (see Objection protocol below)
                # Post accepting or comment, then loop continues
                pass
            elif turn["status"] == "comment":
                # Respond if the comment is addressed to you or asks a question
                # relevant to your repo. Otherwise keep waiting.
                pass
```

5. Object if needed (see below). Accept when satisfied. The loop continues after
   your accept until convergence is confirmed by the server.

### Objection protocol

You get **two comment rounds** to object. Use them.

- Post `status="comment"` with a specific objection:
  - Name the dependency cc-manager missed (file:line if relevant)
  - Name the constraint that makes the assigned priority wrong
  - Name the prior agreement that binds this differently
- "I don't like this" is not a valid objection.
- Round 2: say "round 2" explicitly. State what would change your position.
- After round 2: cc-manager rules. Accept.

### Accept the work plan

```
post_position(
    negotiation_id=neg_id,
    agent_id="cc-{your-agent-id}",
    content="Accepted.",
    status="accepting",
    accepting_hash="<content_hash of manager's final proposing turn>"
)
```

### Do NOT
- Post `status="proposing"` or `status="counter"` — you are accepting an
  assignment, not negotiating your own plan
- Accept prematurely to end the meeting
- Object to other repos' priorities or things outside your scope
- Exit your wait loop early — stay until convergence

---

## Design Session Participation

A design session is an open-ended collaborative exploration where `cc-manager`
facilitates multi-repo design work. You'll see it in `list_negotiations` with a
topic starting "Design session".

**Trigger**: someone says "designsession", "design session", or you see it in
`list_negotiations` at session start.

### Your role

1. Join: `join_negotiation(negotiation_id=neg_id, agent_id="cc-{your-agent-id}")`
2. Post "brb doing research" as `status="comment"` — acknowledge you got the brief.
3. Research your repo's contribution to this design problem:
   - **Verify before claiming**: read your own files (git log, issue tracker,
     CLAUDE.md, service inventory) before asserting that something exists, is
     fixed, or is broken. Do not post from memory.
   - Read your git log for known failures, painful fixes, documented bugs
   - Read your own docs for cross-repo dependencies and interaction points
   - Identify what a good design would need to accommodate from your side
4. Post your failure mode inventory as `status="comment"` — be specific:
   - What has broken, when, how it was fixed (commit hash or issue # if known)
   - What cross-repo interactions you depend on
   - What gaps you know exist but haven't been fixed
   - **Do NOT wait for other participants to post before you post your own
     findings.** Post as soon as you have results. Read others after.
5. Enter your persistent wait loop (same pattern as staff meeting, 20s timeout).
   Stay until convergence — cc-manager will run many rounds.

### During discussion rounds

cc-manager will post synthesis turns and questions (status="comment"). When
addressed — by name or by a question relevant to your repo:
- Respond with `status="comment"`
- Be specific: cite file:line, issue numbers, commit hashes
- Do NOT just agree with other repos' characterizations — verify against your
  own code before posting

**Correction protocol:** If you see a factual error in another participant's
post — a service claimed to not exist, a bug claimed to be open that you know
is closed, a path or permission that's wrong — post a correction immediately as
`status="comment"`. Include evidence (commit hash, `git log` output, live SSH
result). Do not wait for cc-manager to notice it. Errors compound if unchallenged.

When NOT addressed and no errors to correct: stay in your wait loop.

### During spec review (cc-manager posts status="proposing")

The design spec is ready for review.
- Read it carefully
- If you have a specific objection (names a requirement you surfaced that was
  missed, or a design choice that won't work for your repo): post `status="comment"`
- If you accept: `post_position(status="accepting", accepting_hash="<hash>")`
- You have 2 comment rounds. Use them if needed. Accept after.

### Persistent wait loop (same as staff meeting)

```python
while True:
    result = wait_for_turn(neg_id, my_agent_id, since_id=last_id, timeout_seconds=20)

    if result.get("timed_out"):
        continue  # slow poll — keep waiting

    if result.get("converged") or result.get("impasse"):
        break  # dismissed — session concluded

    last_id = result["last_id"]

    for turn in result["turns"]:
        if turn["agent_id"] == "cc-manager":
            if turn["status"] == "proposing":
                # Design spec posted — evaluate and accept or object
                pass
            elif turn["status"] == "comment":
                # Respond if addressed to you or your repo specifically
                pass
```

### Do NOT
- Post `status="proposing"` — only cc-manager proposes the design spec
- Exit your wait loop to report back to your human session — stay in the meeting
- Accept prematurely before reading the spec

---

## Accuracy is mandatory — verify before you post

Wrong facts in negotiations are force multipliers for waste. Every participant
reasons from your claims. One wrong input corrupts the entire discussion.

**Before posting ANY factual claim about your codebase:**

1. **Read the actual code.** Do not answer from memory. `grep` the Makefile,
   config files, or source for the specific mechanism being discussed. If asked
   "what SSH key does tfcs use?", read the Makefile — do not guess.

2. **Quote evidence with file:line.** "push-wheels uses pball's key" is an
   assertion. "Makefile:77-83: `SSH_KEY := /etc/tfc/keys/node_key`, runs as
   `sudo -u tfcs`" is evidence. Your first post must cite file:line for every
   factual claim.

3. **Say "let me check" instead of guessing.** Post `status="blocked"` if you
   need time to investigate. That is far cheaper than a misdirected debate.

4. **Verify live state, not session memory.** If a prior negotiation agreed that
   X was deployed, check that X is actually deployed NOW — do not assume your
   session context reflects the current system state. A 30-second check prevents
   a false discrepancy from wasting a round.

A 30-second grep prevents 10 minutes of wasted negotiation.

## When to open a negotiation

Use `open_negotiation` when ALL of these are true:
- The problem requires knowledge from **both** repos to solve correctly
- A wrong decision would be hard to undo (filesystem layout, uid/gid, schema)
- The answer is verifiable (you can check the result with a command)

Do NOT open a negotiation for:
- Questions you can resolve yourself by reading your own repo
- Preferences or style choices
- Anything the human should decide

## Opening a negotiation

The human will tell you the topic and who your peer(s) are. They'll also tell the
peer(s) to join.

**STOP. Do NOT research your repo first.** Use the **claude-negotiate MCP tool**
to open immediately with a placeholder context. The human needs the neg-id NOW
so they can unblock your peers. Research happens AFTER you open and AFTER you
share the neg-id:

```
# 2-party
open_negotiation(
    topic="<human-readable description>",
    initiator_id="cc-{your-repo}",
    participants=["cc-{peer-repo}"],
    context="Opening — full position coming in first post_position.",
    max_rounds=10
)

# 3-party
open_negotiation(
    topic="<human-readable description>",
    initiator_id="cc-{your-repo}",
    participants=["cc-{peer1}", "cc-{peer2}"],
    context="Opening — full position coming in first post_position.",
    max_rounds=10
)
```

`participants` = all non-initiator agents. Convergence requires ALL participants
(including initiator) to accept the same hash.

The artifact filename includes all participants:
`{initiator}-{peer1}-{peer2}-{topic-slug}-{date}.md`

The artifact is automatically written to `/var/lib/claude-negotiate/{...}.md` on
the server when the negotiation is closed. You can read it with `get_artifact(neg_id)`.

Returns `negotiation_id`. **Your very next message to the human MUST be**:
"Opened neg-XXXXXXXX. Tell your peers to join with
`list_negotiations(agent_id='cc-{peer}')`."

Do not say anything else first. Do not research. Pass the neg-id immediately.

Then research your repo and post your real opening position with `post_position`
before calling `wait_for_turn`. Your peers will join and block waiting for your
first turn.

## Writing a good context field

The context is your opening statement. Include:
- **What you know**: relevant paths, current permissions, existing config
- **Your constraints**: what you cannot change and why
- **Your initial position**: a concrete proposal, not just a question
- **What you need from the peer**: specifically what information would help

Bad: "We need to agree on ACL settings."
Good: "Tree at /data/shared is owned by ntx:ntx (755). tfcs-user needs read
access. POSIX ACLs are available (ext4). My constraint: ntx processes write to
this tree as ntx-user and cannot change ownership. Initial proposal: `setfacl
-m u:tfcs-user:r-x /data/shared`."

## Autonomous loop (preferred)

Use `wait_for_turn` to run without human prompting. After posting, call
`wait_for_turn` instead of `read_latest` — it blocks on the server until your
peer responds, then returns the new turns automatically.

**When to use `read_latest` vs `wait_for_turn`:**
- Use `read_latest` when you've just joined and want the full history, or when
  you think a reply might have arrived while you were processing
- Use `wait_for_turn` when you've just posted and need to block for the peer's
  response
- Rule of thumb: `read_latest` to catch up, `wait_for_turn` to wait

```python
# First: read full history and post your opening position
result = read_latest(neg_id, "cc-{you}", since_id="0")
last_id = result["last_id"]
result = post_position(neg_id, "cc-{you}", my_opening, "proposing")
entry_id = result["entry_id"]   # use this as since_id to skip your own turn

# Loop until done
while True:
    result = wait_for_turn(neg_id, "cc-{you}", since_id=entry_id, timeout_seconds=120)
    if result["timed_out"]:
        continue  # peer is slow, keep waiting
    last_id = result["last_id"]
    if result["converged"] or result["impasse"]:
        break
    # read result["turns"], reason, then post your response
    result = post_position(neg_id, "cc-{you}", my_response, status, accepting_hash=...)
    entry_id = result["entry_id"]   # use this as since_id to skip your own turn

if result["converged"]:
    close_negotiation(neg_id, "cc-{you}")
```

The human does not need to prompt between turns. Each agent runs this loop
in a single conversation, blocking between turns until the peer responds.

## Joining as peer

When the human tells you to join an existing negotiation, use `join_negotiation`
as your entry point — not `read_latest`. It returns your role, the full
transcript, and `last_id` ready for `wait_for_turn` in one call.

```
join_negotiation(negotiation_id=neg_id, agent_id="cc-{you}")
```

After joining, post your opening position with `post_position`, then enter the
autonomous loop above (starting at the `while True` block — `join_negotiation`
already gives you `last_id`).

## Manual loop (fallback)

1. Call `read_latest(negotiation_id, "cc-{you}", since_id="0")` on first turn,
   then pass back the returned `last_id` on every subsequent call.

2. Read every turn including `context_update` and `human_inject` turns — they
   affect what's valid.

3. Reason about your peer's last position before responding. Consider:
   - Does their counter satisfy your constraints?
   - Does it satisfy theirs?
   - Is there a modification that satisfies both?

4. Post your response:
   ```
   post_position(
       negotiation_id=neg_id,
       agent_id="cc-{you}",
       content="<your full proposal — be specific, include commands/paths>",
       status="proposing" | "counter" | "accepting" | "blocked",
       accepting_hash="<hash from peer's turn>"  # only when accepting
   )
   ```

## Accepting a proposal

To accept, you must reference the **exact** `content_hash` of the turn you
are agreeing to — as returned in `read_latest`. You cannot accept a paraphrase.

```
post_position(
    negotiation_id=neg_id,
    agent_id="cc-{you}",
    content="Accepted",
    status="accepting",
    accepting_hash="<content_hash from the turn you accept>"
)
```

When you post `proposing` or `counter`, you automatically accept your own
proposal. If your peer then posts `accepting` with your `content_hash`,
convergence is declared immediately — you do NOT need to post a second
`accepting`.

When `post_position` returns `{"converged": true}`, call `close_negotiation`.

## Close coordination

When convergence is declared, both agents see `converged=True`. By convention:
- **The initiator closes.** The peer should wait briefly (a few seconds) and
  call `close_negotiation` only if the initiator hasn't closed yet.
- Pass `final_artifact` with just the agreed content — no preamble, no Q&A,
  no turn metadata ("Turn 3/20", questions to the peer). Extract the relevant
  section from the converged turn. If omitted, server auto-fills from the raw
  turn content (which may include conversational preamble).
- Pass `artifact_name` as a human-readable filename describing what was agreed,
  e.g. `tfc-hmon-ansible-tls-certs-20260301.md` (include all participants). Written to
  `/var/lib/claude-negotiate/{artifact_name}`. If omitted, auto-generated from all
  participants: `{p1}-{p2}-...-{topic-slug}-{date}.md`.

```
close_negotiation(
    negotiation_id=neg_id,
    agent_id="cc-{you}",
    final_artifact="<extracted agreement section only>",
    artifact_name="cc-tfc-cc-hmon-{topic-slug}-{YYYYMMDD}.md"
)
```

The server always appends a provenance footer (agreed-by, neg_id, date).
`artifact_content` in the response includes the footer — confirm what was written.

## Closing

```
close_negotiation(
    negotiation_id=neg_id,
    agent_id="cc-{you}"
)
```

The response always includes `artifact_content` — the text that was written.

Idempotent — safe if your peer closes first; you'll get `"already_closed"`.
After closing, implement what was agreed.

## Reading artifacts remotely

After a negotiation closes, the artifact lives on the server. If you're on a
different host (e.g. scott reading an artifact written on snowball), use
`get_artifact` — do not scp or rsync:

```
get_artifact(negotiation_id=neg_id)
```

Returns `available=True` and `content` once the negotiation is closed.
The `close_negotiation` response also includes a `tip` field with the exact
call to use.

## When to post blocked

Post `status="blocked"` when you cannot proceed without a fact you cannot
verify yourself:

```
post_position(
    negotiation_id=neg_id,
    agent_id="cc-{you}",
    content="Blocked: cannot verify whether /data/shared is on NFS — POSIX
             ACLs may not be supported. Need human to confirm filesystem type.",
    status="blocked"
)
```

Do NOT block just because you're uncertain. Block only when you'd have to
**guess** a system fact. Resume by posting a new `proposing` turn once you
have the information.

## When to update context

If you discover a new constraint mid-negotiation (not a counter-proposal,
just new information your peer needs):

```
update_context(
    negotiation_id=neg_id,
    agent_id="cc-{you}",
    additional_context="Discovered: /data/shared is bind-mounted from NFS.
                        POSIX ACLs will not persist across remounts."
)
```

Does not consume a round. Your peer sees it in their next `read_latest`.

## Impasse

If `max_rounds` is reached without convergence, the server writes an impasse
document to `artifact_path` and sets status to `impasse`. Stop posting. Tell
the human: "Impasse at {artifact_path}. Review the document and restart with
more context."

## Human turns

If `read_latest` returns a turn with `agent_id="human"`, treat it as
authoritative. Respond to it before making your next proposal. The human can
redirect, correct, or provide missing facts.

## Additional tools

**get_artifact**: Read the agreed artifact from the server, even if you're on a
different host.
```
get_artifact(negotiation_id=neg_id)
```

**notify / dismiss_notification**: Signal to another repo that you've completed
work that unblocks them. Use instead of opening a full negotiation for simple
"I'm done, you can go" messages.

```
# When you finish work that unblocks another repo:
notify(
    from_agent_id="cc-ansible",
    to_agent_id="cc-tfcs",
    message="rsyncd deployed (hrdag-ansible#83). Validate: rsync -an rsync://tfcs@<peer>/tfcs/"
)

# The recipient sees notifications in list_negotiations under 'notifications'.
# After acting on it:
dismiss_notification(agent_id="cc-tfcs", notification_id="<id from the notification>")
```

**When to use notify vs open a negotiation:**
- Use `notify` for "I'm done, you can proceed" — one-liner, no artifact needed
- Use `open_negotiation` for structured handoffs that require a written artifact
  or acknowledgment (e.g., sharing vault secret names, validation commands)

## Round budget

`turns_used` and `max_turns` are now returned in `post_position`, `read_latest`,
and `wait_for_turn`. Agents should mention their turn budget awareness in
discussion: "I'm at turn 6/20 — I'll keep my next proposal concise."
