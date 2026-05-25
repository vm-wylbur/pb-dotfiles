## Session-start: triage your hrdag-ansible slice

Per cross-repo workflow rule (request channel §2): at session start, read
open issues in `hrdag-ansible` filtered to your declared slice — not just
those signed with your `cc-{repo}` identity in your home repo.

Your slice is declared in this repo's CLAUDE.md (under "Slice paths"). It
corresponds to the per-agent reach section of
`hrdag-ansible/docs/cross-repo-agent-workflow.md`.

**Standard query:**

    gh issue list --repo hrdag/hrdag-ansible \
                  --label {your-slice-label} \
                  --state open

(Labels match agent identity: `tfcs`, `ntx`, `hmon`, `filelister`, etc.
If labels are not yet applied to all relevant issues, also search by your
slice's role-path strings.)

**For each issue found:**

- If it requests action from you (Type A — "please do X in your slice"),
  acknowledge in a comment and add to your work queue.
- If it asks an architectural question (Type B — "is this state correct?"),
  answer in a comment; merge or close per workflow rule.
- If it's drift surfaced by `audit-drift` and routed to your slice, treat
  with the working-deadline contract: own it, date it, acknowledge — or
  kick back to merger to re-route.
