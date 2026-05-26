## Multi-agent coordination — which mechanism

Five tools cover the multi-agent space. Picking the wrong one wastes
significant effort or misses the point of the exercise.

| Mechanism | Use when | Failure it addresses |
|---|---|---|
| `Task` / `Agent` tool | Subagent spawning within one session | Context bloat; need a specialist lens |
| `/coordinate` skill | Single host, decision spans 2+ repos under a shared parent | Cross-repo edits that break consistency (layouts, schemas, deployment order) |
| `/negotiate` skill | Cross-host, peer-to-peer convergence (MCP-backed) | Two agents on different machines need to agree on a shared decision |
| `/facilitator` skill | Single-session adversarial review of a negotiation | Negotiations that need a 5-advisor panel adjudicating before close |
| Agent Teams | Local parallel exploration with teammate↔teammate messaging | Direct subagent collaboration without round-tripping through the orchestrator. **Experimental, env-gated.** Not yet integrated; track upstream before reaching for it. |

**Decision tree:**

1. Is the work within a single session, one orchestrator + helpers?
   → `Task`/`Agent` tool. Done.
2. Does it cross repo boundaries on this machine?
   → `/coordinate`.
3. Does it cross host boundaries (peer agents)?
   → `/negotiate`. Add `/facilitator` if the negotiation needs panel
     review before close.
4. Is the work better as parallel subagents talking directly?
   → Agent Teams (experimental). Default to `Task` until Agent Teams
     is GA.

**Anti-patterns:**

- Reaching for `/negotiate` when both agents are on the same host —
  use `/coordinate` (cheaper, no MCP roundtrip).
- Reaching for `/coordinate` when the decision is single-repo — just
  do the work.
- Spawning a panel of subagents for a one-shot question. Pick the one
  most-fit specialist instead.
- Using `Task` to dodge a decision that actually needs cross-host
  convergence. If two hosts will diverge, you need `/negotiate`.
