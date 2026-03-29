# Full Mode Prompt Template (Opus, single-pass)

Spawn a single agent with `model: opus`. Fill in variables and
provide all packed repos as context.

---

```
You are coordinating a cross-repo decision.

Task: {task}
Repos involved: {repos}

The full contents of each repo are provided below (via repomix).

{packed_repo_1}

{packed_repo_2}

{packed_repo_3 (if applicable)}

Execute the following structured reasoning process. Do NOT skip steps
or combine them. Each step must be completed with file:line citations
before proceeding to the next.

## Step 1: Repo Perspectives

For EACH repo, write a perspective section that ADVOCATES for that
repo's needs. You are not neutral — represent each repo's interests
in turn.

For each repo state:
1. Current state — what exists today, with file:line citations
2. Constraints — what cannot change and why, with file:line citations
3. Dependencies — cross-repo dependencies (cite both sides)
4. Known issues — relevant TODOs, FIXMEs, GitHub issues
5. Requirements — what this repo needs from the solution
6. Initial proposal — concrete and specific, from this repo's POV

Primary obligation per perspective: PROTECT that repo's functionality.
If a solution would require the repo to change behavior, accept new
constraints, or give up capabilities, flag it and propose an
alternative. Only concede when you can verify the concession doesn't
break existing functions, citing the specific code paths that remain
safe.

## Step 2: Integrator

Now switch to Integrator role. Review all perspectives and:
1. Identify conflicts between the proposals
2. Identify gaps at repo boundaries that nobody owns
3. Identify implicit assumptions that could break
4. When you find a gap, verify it against the repo contents provided
   above — you have the full code, so re-read the relevant sections.
   Do NOT claim a gap exists without checking.
5. Propose a UNIFIED solution satisfying all constraints
6. Cite evidence for every claim (file:line from the repo contents
   or from a perspective's finding)
7. Be specific: exact commands, paths, config values

You are adversarial toward gaps. Find what's missing, not what's
already covered.

## Step 3: Adversary

Now switch to Adversary role. Try to break the Integrator's proposal:
1. What failure modes exist?
2. What happens during partial deployment (repo A updated, B not yet)?
3. What happens on a different host, OS, or filesystem (e.g. NFS)?
4. Spot-check at least 2 file:line citations by re-reading the
   repo contents — are they accurate?
5. Is there a simpler solution nobody considered?
6. What did the Integrator miss?

You MUST conclude with one of:
- PASS: {specific statement of what you verified and why it holds}
- FAIL: {specific, cited reasons with file:line evidence}

"Looks good" is not a valid PASS. You must cite specific verifications.

## Step 4: Iterate if needed

If FAIL: go back to Step 2. Revise the Integrator proposal addressing
every point in the Adversary's FAIL statement. Then re-run Step 3.
Repeat up to {max_iterations} times.

If after {max_iterations} the Adversary still FAILs, output:
- The best proposal so far
- The unresolved objections
- A recommendation for what the human should decide

## Step 5: Final artifact

Output the converged agreement as a clean markdown document:

### Agreed Solution
{the unified solution with exact commands/paths/configs}

### Constraints by Repo
{key constraints from each repo that shaped the solution}

### Verified By
{what the Adversary checked and confirmed}

### Action Items
{per-repo list of what needs to be implemented}

### Caveats
{edge cases or risks the Adversary flagged, even if PASS}
```
