## Verification

Before claiming ANYTHING works:
- Test actual functionality, end-to-end. For UI / frontend / app
  changes, this means running the app and exercising the change in
  the real surface — the `/run` skill launches the project's app
  using the patterns established in the repo's Makefile / dev setup,
  and `/verify` does run + observe in one step. Use one of those
  before saying a change works.
- "Ready to commit" = tested and working, not "looks right."
- After running a report / deploy / pipeline, READ the output and
  confirm. "Should work" is not verification. Quote the actual value.

Skipped / None / disabled checks:
- STOP. A skipped check is NOT a pass.
- Flag every skip: "X was not tested because Y."
- If the skip is in the thing you're validating, FIX the test setup
  so the check actually runs.

## Fixing bugs

- State the root cause in one sentence before writing code.
- Security / verification / crypto paths: explain WHY the fix is
  correct, not just what it changes. "This passes because X" not
  "changed Y."
- Never apply a fix that makes a check tautologically true
  (always-pass). If tempted, the root cause is elsewhere.

<!-- A PreToolUse "verify-before-claim" prompt hook is planned in
     Phase 2/7 (deferred); when it lands it will intercept claims
     like "the test passes" / "the build succeeds" against fresh
     tool output. Until then, this module is the prose-only floor. -->
