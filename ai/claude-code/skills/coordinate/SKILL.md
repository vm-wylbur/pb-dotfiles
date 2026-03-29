---
name: coordinate
description: >
  Cross-repo coordination using structured multi-perspective reasoning.
  Use when a task touches 2+ repos under a shared parent directory and
  requires agreement across repo boundaries — filesystem layouts, shared
  configs, uid/gid, schema changes, service interfaces, deployment order,
  ACLs, or any decision where getting it wrong in one repo breaks another.
  Also use when the human says "coordinate", "across repos", "check with
  the other repo", or names multiple repos in a single task. Do NOT use
  for single-repo tasks even if they mention another repo in passing.
---

# coordinate

Structured multi-perspective reasoning for cross-repo decisions.
One CC session, multiple subagent roles, real adversarial critique.

## Prerequisites

**Disable oh-my-claudecode before using this skill.** OMC's agent
orchestration (executor, architect, etc.) intercepts subagent spawns
and overrides the role prompts defined here. Run:
```
/plugin disable oh-my-claudecode
```
Re-enable after the coordination is complete.

**repomix** must be installed (`npm install -g repomix`).

## When to use

All of these must be true:
- The task touches **2+ repos** under a shared parent directory
- A wrong decision would be **hard to undo** (filesystem layout, uid/gid,
  schema, shared config, service interface, deployment order)
- The answer is **verifiable** (you can check the result with a command)

Do NOT use for:
- Single-repo tasks
- Style or preference choices
- Questions the human should decide

## Configuration

The human provides these when invoking:

- **repos**: which repos are involved (e.g., `ntx`, `tfcs`, `filelister`)
- **task**: what needs to be coordinated
- **max_iterations**: convergence cap (default: 5)

Repos live under a shared parent directory. Discover it:
```bash
# The parent of the current repo — typically ~/projects/ or similar
PARENT=$(git rev-parse --show-toplevel 2>/dev/null | xargs dirname)
```

## Roles

### Repo Perspective (one per repo)

Each repo gets a subagent whose job is to **advocate for** that repo's
constraints, current state, and requirements. The subagent:

- Reads its assigned repo as primary source of truth
- MAY read other repos and GitHub issues to understand the full picture,
  but always **advocates for its own repo's needs** — it is not neutral
- States constraints with **file:line citations** for every factual claim
- Proposes or critiques from its repo's perspective
- Says "I need to check" rather than guessing — accuracy is mandatory

**Primary obligation: protect your repo's functionality.** Evaluate
every proposal — including from the Integrator — against the question:
does this preserve, support, and not degrade what this repo currently
does? If a proposal requires your repo to change behavior, accept new
constraints, or give up capabilities, flag it and propose an
alternative that doesn't. Concede only when you've verified that the
concession doesn't break your repo's existing functions, citing the
specific code paths that remain safe.

### Integrator

Sees all Repo Perspective outputs. Evaluates system-level coherence:

- Do the proposals conflict?
- Are there integration gaps nobody mentioned?
- Does the combined solution actually work end-to-end?
- What breaks at the boundaries between repos?

The Integrator proposes a unified solution and must cite evidence from
the repo perspectives for every claim.

**The Integrator does NOT explore repos.** It works only from the
perspective outputs. When it finds a gap that no perspective addressed,
it flags it as UNRESOLVED and names which repo perspective should be
recalled to investigate. The orchestrator then re-spawns that
perspective agent. This prevents the Integrator from going on open-ended
exploration tours.

The Integrator is **adversarial toward gaps**: its job is to find the
thing nobody mentioned, the implicit assumption, the dependency that
crosses a repo boundary without anyone owning it.

### Adversary

Sees the Integrator's unified proposal. Tries to break it:

- What failure modes exist?
- What happens if this runs on a different host / different OS / NFS?
- What happens during partial deployment (repo A updated, B not yet)?
- Is there a simpler solution nobody considered?
- Are the file:line citations accurate? (spot-check at least 2)

The Adversary must either:
- **PASS** with a specific statement of what was verified
- **FAIL** with specific, cited reasons

"Looks good" is not a valid PASS. "I verified that tfcs/Makefile:77
uses SSH_KEY := /etc/tfc/keys/node_key as claimed, and that
ntx/config/acl.conf:12 sets the permission mask as proposed" is valid.

## Execution Protocol

### Phase 0: Pack and select mode

Before spawning any subagents, pack each repo with repomix to
provide context. **Always use separate subagents** — never collapse
roles into a single agent, regardless of repo size. The adversarial
value comes from independent reasoning per role.

```bash
# Pack each repo with standard exclusions
EXCLUDE="--ignore 'sims/**,simulations/**,benchmarks/**,perf-*/**,\
diagnostics/**,tests/**,test/**,__pycache__/**,.venv/**,venv/**,\
.omc/**,node_modules/**,*.pyc,logs/**,docs/archive/**'"

for repo in {repos}; do
  repomix {parent}/${repo} --compress --style xml \
    ${EXCLUDE} \
    -o /tmp/coordinate-${repo}.xml
done
```

The human may specify additional exclusions per repo (e.g.,
`tfcs: exclude sims/logs/perf-*/diagnostics`). Merge those with
the defaults above.

Repomix prints token counts **per repo**.

**Per-repo context check:**

Each perspective subagent receives only its own repo's pack. The
limit is per-repo, not total — a subagent can handle ~200k tokens
of context comfortably.

- **Per-repo pack < 200k tokens**: PACKED. Feed the pack directly
  to that repo's perspective subagent as context.
- **Per-repo pack > 200k tokens**: FILTERED. Extract task keywords,
  re-pack with `--include` for matching files only. If still > 200k
  after filtering, the subagent gets the filtered pack but may also
  explore additional files on its own.

```bash
# Filter oversized repos by task keywords
KEYWORDS=$(extract_keywords_from_task)  # orchestrator determines these
RELEVANT=$(grep -rl "${KEYWORDS}" {parent}/${repo} \
  --include='*.py' --include='*.yml' --include='*.toml' \
  --include='*.cfg' --include='*.conf' --include='*.md' \
  --include='Makefile' --include='*.sh' | \
  sed "s|{parent}/${repo}/||")
repomix {parent}/${repo} --compress --style xml \
  --include "${RELEVANT}" \
  -o /tmp/coordinate-${repo}.xml
```

Print the results:
```
[coordinate] Packed repos (after exclusions):
  ntx        =  61k tokens (58 files) → PACKED
  tfcs       = 128k tokens (51 files) → PACKED
  filelister =  27k tokens (35 files) → PACKED
[coordinate] Spawning perspective subagents with packs as context
```

or if filtering was needed:
```
[coordinate] Packed repos (after exclusions):
  ntx        = 311k tokens (217 files) → over 200k, filtering...
  ntx        =  61k tokens (58 files) → FILTERED by keywords
  tfcs       = 128k tokens (51 files) → PACKED
  filelister =  27k tokens (35 files) → PACKED
```

### Subagent execution

**Model selection per role:**
- Repo Perspective agents: `model: sonnet` (focused, scoped work)
- Integrator: `model: opus` (cross-cutting synthesis, hardest reasoning)
- Adversary: `model: opus` (critical review requires strongest reasoning)

Each perspective subagent receives its repo's pack as context
(inlined in the prompt). The pack IS the context — no exploration:

```
THE FULL CONTENTS OF YOUR REPO ARE PROVIDED BELOW (via repomix).
DO NOT use Read, Grep, Glob, Search, or Bash tools. Work EXCLUSIVELY
from the provided text. All file contents and line numbers are in
the pack below. If something is not in the pack, state that it is
missing — do not go looking for it.

{packed_repo_content}
```

### Phase 1: Gather

Spawn one subagent per repo, in parallel if possible.

**When packs are available, restrict subagent tools.** Spawn with
`tools: []` (no tools) or at most `tools: [Read]` as a fallback.
This prevents the subagent from ignoring the pack and exploring
on its own. The prompt tells it not to, but tool restriction
enforces it.

```
Task: "You are the perspective agent for the {repo} repo.
The coordination task is: {task}.

THE FULL CONTENTS OF YOUR REPO ARE PROVIDED BELOW (via repomix).
DO NOT use Read, Grep, Glob, Search, or Bash tools. Work EXCLUSIVELY
from the provided text. All file contents and line numbers are in
the pack below. If something is not in the pack, state that it is
missing — do not go looking for it.

{packed_repo_content}

You ADVOCATE for {repo}'s needs. You are not neutral.

Your primary obligation is to PROTECT {repo}'s functionality. Any
proposal — including from the Integrator — must be evaluated against:
does this preserve, support, and not degrade what {repo} currently
does? If something requires {repo} to change behavior, accept new
constraints, or give up capabilities, flag it and propose an
alternative. Only concede when you have verified the concession does
not break existing functions, citing the specific code paths that
remain safe.

State:
1. Current state — what exists today, with file:line citations
   (cite from the pack contents above)
2. Constraints — what cannot change and why, with file:line citations
3. Dependencies — what this repo depends on from other repos, and
   what other repos depend on from this one (look for imports,
   config references, and paths in the pack)
4. Known issues — any TODOs or FIXMEs visible in the pack
5. Requirements — what this repo needs from the solution
6. Initial proposal — a concrete, specific proposal from this repo's
   perspective (commands, paths, config changes — not abstractions)

ACCURACY IS MANDATORY. Cite file:line from the pack contents.
Do not invent file paths or line numbers. If the pack does not
contain enough information to answer a point, say so explicitly."
```

Collect all repo perspectives.

### Phase 2: Integrator

Spawn the Integrator subagent:

```
Task: "You are the Integrator for a cross-repo coordination task.

Task: {task}
Repos involved: {repos}

Here are the perspectives from each repo:

{repo_1_perspective}

{repo_2_perspective}

{repo_3_perspective (if applicable)}

WORK ONLY FROM THE PERSPECTIVES ABOVE. Do NOT explore the repos
yourself. Do NOT read files, grep, or search. The repo perspective
agents have already done that work — use their findings.

Your job:
1. Identify conflicts between the proposals
2. Identify gaps — things at repo boundaries that nobody owns
3. Identify implicit assumptions that could break
4. For gaps that are CRITICAL (would cause the solution to fail),
   flag them as UNRESOLVED and recommend which repo perspective
   should be recalled to investigate. Do NOT investigate yourself.
5. Propose a UNIFIED solution that satisfies all repo constraints
6. For every claim, cite the repo perspective that established it
   (e.g., 'per ntx perspective: Makefile:77')
7. Be specific: exact commands, exact paths, exact config values

You are adversarial toward gaps. Your job is to find what's missing,
not to rubber-stamp the proposals.

If you flag any UNRESOLVED gaps, list them at the end:
UNRESOLVED: {repo} should verify {specific question}"
```

If the Integrator flags UNRESOLVED gaps, the orchestrator re-spawns
those repo perspective agents (using the repo recall prompt) before
proceeding to the Adversary. This keeps exploration in the hands of
the perspective agents where it belongs.

### Phase 3: Adversary

Spawn the Adversary subagent:

```
Task: "You are the Adversary reviewing a cross-repo coordination proposal.

Task: {task}

Integrator's unified proposal:
{integrator_output}

Original repo perspectives (for reference):
{all_repo_perspectives}

Your job: try to break this proposal.
1. What failure modes exist?
2. What happens during partial deployment?
3. Are the citations accurate? Spot-check at least 2 by reading
   the actual files at the cited paths.
4. Is there a simpler solution?
5. What did the Integrator miss?

You MUST return one of:
- PASS: {specific statement of what you verified and why it holds}
- FAIL: {specific, cited reasons with file:line references}

'Looks good' is not a valid PASS. You must cite specific verifications."
```

### Phase 4: Iterate or Converge

If Adversary returns **PASS**: proceed to artifact writing.

If Adversary returns **FAIL**: the orchestrator decides what to do next:

- If the failure is about **system-level integration** (gaps, conflicts,
  ordering): feed the critique to the Integrator for revision.
- If the failure is about **a specific repo's constraints** (e.g.,
  "this breaks ntx's ZFS layout"): re-spawn that repo's perspective
  agent with the Integrator's proposal and the Adversary's objection.
  The perspective agent responds with updated constraints or a
  counter-proposal. Then the Integrator revises with this new input.

After revision, the Adversary reviews again. Repeat up to `max_iterations`.

If `max_iterations` is reached without PASS: stop and report to
the human. Include the last proposal and the Adversary's objections.
The human decides.

**Iteration protocol:**
```
iteration = 1
while iteration <= max_iterations:
    if iteration == 1:
        integrator_input = repo_perspectives
    else:
        # If Adversary flagged a repo-specific issue, recall that repo
        if adversary_feedback.names_specific_repo:
            updated_perspective = spawn_repo_perspective(
                repo=flagged_repo,
                extra_context=integrator_output + adversary_feedback
            )
            integrator_input = repo_perspectives + updated_perspective + adversary_feedback
        else:
            integrator_input = repo_perspectives + adversary_feedback
    
    integrator_output = spawn_integrator(integrator_input)
    adversary_result = spawn_adversary(integrator_output, repo_perspectives)
    
    if adversary_result.startswith("PASS"):
        break
    
    adversary_feedback = adversary_result
    iteration += 1

if iteration > max_iterations:
    report_impasse_to_human()
else:
    write_artifact()
```

**Repo recall prompt:**
```
Task: "You are the perspective agent for {repo}. You were previously
consulted and gave your initial perspective (included below).

The Integrator proposed a unified solution. The Adversary found a problem
that affects your repo:

Integrator's proposal:
{integrator_output}

Adversary's objection:
{adversary_feedback}

Your original perspective:
{original_perspective}

Your primary obligation is to PROTECT {repo}'s functionality. Does
the Integrator's proposal preserve, support, and not degrade what
{repo} currently does? If it requires {repo} to change behavior or
give up capabilities, say so — and propose an alternative that
doesn't. Only concede if you can verify the concession is safe,
citing the specific code paths that remain unaffected.

Review the Adversary's concern against your repo's actual code. Either:
- Confirm the problem with file:line evidence and propose a fix
- Refute it with file:line evidence showing it's not actually an issue
- Provide new constraints the Integrator didn't know about

Do not guess. Read the files."
```

### Phase 5: Artifact

Write the converged agreement to a markdown file:

```
{parent}/.coordination/{repos_joined}-{topic_slug}-{YYYYMMDD}.md
```

The artifact contains:
- The agreed solution (from the Integrator's final proposal)
- Key constraints from each repo (summarized)
- What the Adversary verified
- Action items per repo (what each repo needs to implement)

Append a provenance footer:
```markdown
---
Coordinated: {repo1} × {repo2} × {repo3}
Iterations: {n}
Date: {iso_timestamp}
Adversary PASS: {adversary's pass statement}
```

After writing, tell the human:
- Where the artifact is
- What each repo needs to do next
- Any caveats or edge cases the Adversary flagged

## Evidence standards

These apply to ALL roles, not just repo perspectives:

1. **Read the actual code.** Do not answer from memory. `grep` the
   Makefile, config files, or source for the specific mechanism being
   discussed. If asked "what SSH key does tfcs use?", read the
   Makefile — do not guess.

2. **Quote evidence with file:line.** "push-wheels uses pball's key"
   is an assertion. "Makefile:77-83: `SSH_KEY := /etc/tfc/keys/node_key`,
   runs as `sudo -u tfcs`" is evidence.

3. **Say "let me check" instead of guessing.** If a subagent cannot
   verify a claim, it must say so explicitly. This is far cheaper
   than a wrong answer propagating through the Integrator and Adversary.

## Output to human

During execution, print a brief status line per phase:

```
[coordinate] Packed 3 repos: ntx=45k, tfcs=62k, filelister=28k → 135k total
[coordinate] Mode: FULL (opus, single-pass)
[coordinate] Running structured analysis...
[coordinate] Adversary: PASS at iteration 1
[coordinate] Artifact: .coordination/ntx-tfcs-filelister-acl-scheme-20260307.md
```

or for multi-subagent mode:

```
[coordinate] Packed 3 repos: ntx=180k, tfcs=95k, filelister=28k → 303k total
[coordinate] Mode: TARGETED (sonnet, filtered packs)
[coordinate] Filtered: ntx=32k, tfcs=18k, filelister=11k → 61k total
[coordinate] Phase 1: Gathering perspectives from ntx, tfcs, filelister
[coordinate] Phase 2: Integrator synthesizing (iteration 1/5)
[coordinate] Phase 3: Adversary reviewing...
[coordinate] Phase 3: FAIL — re-entering Phase 2 (iteration 2/5)
[coordinate] Phase 3: PASS at iteration 2
[coordinate] Artifact: .coordination/ntx-tfcs-filelister-acl-scheme-20260307.md
```

Do not dump full subagent outputs to the human unless asked.
Show the final artifact and the action items.

## Relationship to claude-negotiate

This skill replaces the multi-session negotiation workflow for cases
where all repos are accessible from a single machine. Use
claude-negotiate (MCP) when repos are on different hosts and agents
genuinely cannot share filesystem access.
