## Documentation-drift session-start ritual

This repo's mission is to keep infrastructure documentation in sync with
infrastructure reality. The session-start ritual surfaces drift before it
ages:

1. **FIXME grep.** Search the active doc tree for `FIXME` markers across
   `machines/*.yaml`, `architecture/`, and `guides/`. Each FIXME is a
   declared but unresolved discrepancy.
2. **WATCH.md check.** Read `WATCH.md` for date-driven follow-ups whose
   date is at or past today.
3. **Open issues.** `gh issue list --repo hrdag/server-documentation --state open`.
4. **Drift check.** `make drift-check` — expect 100% / 0 errors. A non-zero
   exit means the doc tree and the asserted state diverged; surface and
   triage.
5. **Recent upstream commits.** Scan `git log` across hrdag repos for
   recent `cc-*` commits whose subject suggests doc follow-up (new role,
   inventory shift, deprecation). Add follow-up notes / FIXMEs where
   merited.

Consider invoking the `survey` skill to automate steps 1-3 + 5 when the
session starts cold.

## Stewardship discipline

When you propose changes to documentation, the bar is: would a fresh agent,
reading only this doc, understand the current state of the infrastructure
it describes? If no, the doc is drifting — fix the doc, not the assertion.
