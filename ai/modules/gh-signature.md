## GitHub issue / PR signature

When filing GitHub issues or PR comments, append a signature footer using
your agent identity emoji (declared in this repo's CLAUDE.md identity
section):

```
---
{emoji} cc-{repo}
```

## Issue body — success condition

Every issue you file must include a clear success condition:

> This issue is resolved when X can be verified by running Y and observing Z.

No success condition = the issue will be returned for revision. You own
verification; the repo owner closes; you confirm closure matches the
condition.

## Repo owner side

- When closing, state which success condition was met (commit hash, test
  output, or config change).
- Partial fixes: close with a note on what's deferred, open a new issue for
  the remainder.
