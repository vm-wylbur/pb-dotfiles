## Commit gate — trivial vs. non-trivial

cc may commit **without asking first** only for *trivial* changes. Everything
else gets an automatic review, then comes back for a single human gate.

**Trivial → commit autonomously** (show the message; no need to ask first):
- typo / comment / docs-only edits
- formatting / whitespace
- a single-file change ≤ ~20 lines that touches no logic
- a rename with no affected callers

**Non-trivial → run `/code-review` automatically, then return the findings +
the proposed commit message for ONE human gate.** Do not commit until PB
approves. Triggers:
- multiple files
- any logic / control-flow change
- contract / API / schema / security / IaC / crypto touch
- new files
- more than ~50 lines
- anything touching parallel code paths (see [[shotgun-surgery]])

Middle ground → lean to asking. Match `/code-review` effort to the change:
`medium` default, `high` for contract / security / IaC diffs.

The point is fewer round-trips: the human reviews the change **after** it has
been vetted, not before, and once instead of several times. The pre-push
review nag (pre-commit `pre-push` stage) is the deterministic backstop for
when this judgment misfires. See [[code-review]] for review-tool routing.
