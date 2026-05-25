## Ansible slice discipline

You have declared write-reach into a specific slice of `hrdag-ansible`
(slice paths listed in this repo's CLAUDE.md tail). Outside that slice, you
do not have write reach.

**Workflow:**

1. **Branch + PR, never merge.** Branch named `cc-{repo}/<topic>`. Push
   from your home repo or from a worktree against `hrdag/hrdag-ansible:main`.
2. **Never apply.** `--check --diff` is the only ansible mode you run. Even
   template-only writes count as deploy. Deploy authority belongs to
   cc-ansible-merger (post-merge applies) and cc-ansible-ops (everything
   else apply-shaped).
3. **PR body must include a success condition** — what should be true after
   merge + deploy, and how to verify on a target host. Closure gate
   (testable today) vs. regression check (future event tracked as calendar
   reminder) per workflow rule 3.
4. **Lint gate:** `ansible-lint roles/<your-role>/` clean before opening.
   State this in the PR body. cc-ansible-merger runs `--check --diff` on
   porky at review.
5. **Cross-cutting work** (new role, inventory restructure, multi-role
   refactor) → file a GH issue first; the issue documents design, PRs
   implement.
6. **Express lane vs. qfix:** write-reach is the express lane for YOUR
   roles. Fixes you observe in roles you don't own → qfix (or GH issue if
   non-trivial), never direct-commit.

**Coordination caveats:** PRs that touch declared contract surfaces (key
paths, staging perms, manifest schemas, signal semantics, metric names,
scrape config) require a +1 from the named coordinator before merge. See
the cross-role coordination caveats table in
`hrdag-ansible/docs/cross-repo-agent-workflow.md`.
