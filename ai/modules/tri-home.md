## Session-start: triage your own-repo issues

At every session start:

1. **Search known issue numbers.** Look in your memory files and this
   repo's `.md` files (`TODO.md`, `STATUS.md`, `PLAN.md`, `PROBLEM.md`,
   etc.) for issue numbers. For each, check:

       gh issue view {number} --repo hrdag/{repo}

   - **If closed**: verify the success condition is met. Not met → reopen
     with specific evidence. Met → update your files and stop mentioning it.
   - **If still open**: read new comments. If the owner has responded or
     partially addressed it, acknowledge and update the issue — don't repeat
     the complaint.

2. **List open issues with your signature.** Catch issues you filed but
   didn't record locally:

       gh issue list --repo hrdag/{repo} --state open --json number,title,body

   Filter for your `cc-{repo}` signature in the body. Apply step 1 to any
   found.

## Filing new issues

Before filing, search open issues in this repo. If your concern is already
open, comment on the existing issue rather than filing a duplicate.
