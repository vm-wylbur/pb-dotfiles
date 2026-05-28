## Session-start: triage your own-repo issues

The SessionStart hook (`lib/triage-issues.sh`) automatically lists open
issues in the current repo whose body carries this agent's signature
(e.g. `cc-dots`). The block appears at session start under
`Triage queue (...):` with title, body excerpt, and latest comment per
issue. No manual `gh issue list` is needed — the data is already
there.

For each triaged issue, judge:

- **Success condition met?** The body says "resolved when X passes /
  Y is observed." Verify against the current code/state.
  - **Met** → comment the closing evidence (commit hash, test output,
    config change) and close.
  - **Not met but progressed** → comment what advanced.
  - **Not met and no progress** → address it this session if related
    to the user's request, otherwise leave a status note and move on.
- **Owner already responded?** If the latest comment is from someone
  other than you, acknowledge their feedback in your next reply — do
  not repeat the complaint.
- **Stale issue?** If the body's premise no longer matches reality
  (refactor obsoleted it), close with a one-line note explaining why.

The hook is bounded (default limit 5 issues, 1 most-recent comment
each) — if there's important context beyond what's shown, fetch it
explicitly with `gh issue view N`. Do not blindly act on the excerpt
alone for high-stakes operations.

## Filing new issues

Before filing, search open issues in this repo. If your concern is
already open, comment on the existing issue rather than filing a
duplicate.
