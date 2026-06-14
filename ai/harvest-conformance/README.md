<!--
Author: PB and cc-dots 🧷
Date: 2026-06-02
License: (c) HRDAG, 2026, GPL-2 or newer

---
dotfiles/ai/harvest-conformance/README.md
-->

# harvester read-path conformance suite

The executable contract for the claude-mem harvester's two REST **read** endpoints, owned by **cc-dots** under the platform/consumer boundary ratified in negotiation **neg-305c49e5** (artifact `cc-mem-cc-dots-platform-consumer-harvest-contract-20260603.md`). cc-dots specs the schema + this test; **cc-mem implements until it is green**. The suite is published from cc-dots's slice (this repo) and is **never committed into claude-mem** — cc-mem pins a version and pulls it (no live cross-host reach).

It tracks claude-mem issue **#5**: the two endpoints retire the last `ssh snowball psql` client paths, so "green" means the harvester runs with **zero snowball SSH**.

## The two endpoints

- `GET /docs/:doc_id` → `{doc: {doc_id, filename, filepath, content, file_mtime, doc_hash, metadata}}`, or `404 {error}`. Replaces `eval.py`'s `load_docs` (fetch by `doc_id` — the PK that `extraction_decisions` reference; `doc_hash` is not unique, so id is the key). Returns full **content**, which `/docs/manifest` does not.
- `GET /docs/backlog?limit=N&offset=M` → `{docs: [{doc_id, doc_hash, filepath, content}], limit, offset, total}`. Replaces `distill.py`'s backlog query. Rows are **distinct by `doc_hash`**, and a `doc_hash` is excluded once **any** of its doc_ids has a decision or a `source_doc_id`-linked memory — exclusion is by `doc_hash`, not by the `DISTINCT ON`-picked `doc_id`. (That correctness point is the HIGH dedup bug in the old client query; moving the corrected query server-side fixes it at the source. The suite pins it in `test_backlog_excludes_decided_content`.)

## Provenance round-trip (v1.2.0, neg-6b0a3bf5)

`test_provenance_roundtrip.py` pins the Workstream-B provenance contract (claude-mem#12): `POST /store` accepts optional `session_id`/`host`/`agent_id` (green — regression guards on the deployed PR #11: echo-of-accepted-input, `''` → 400, absent → 200); `GET /memory/:memory_id` returns `{memory: {memory_id, content, created_at, updated_at, session_id, host, agent_id, evicted_at, evicted_by, evict_reason}}` with a JSON 404 envelope and secret auth (**red** until the migration-003 unit ships); the store→read round-trip asserts **persistence**, which the echo cannot (**red**); and `POST /harvest` accepts + stamps the same fields and returns `memoryId` (**red** — the contract extension cc-mem raised, so harvested memories stop landing with NULL provenance). POSTing tests are seed-gated per suite policy.

## W8 write guards (v1.3.0, claude-mem#12 — the 951-doc re-run gate)

`test_w8_write_guards.py` pins the engine half of W8 (main `b05a252` + PR #20), all seed-gated; **green on a disposable instance = re-run go**:

- **No-clobber** — the `/harvest` keyed upsert is ownership-guarded: cross-agent and provenance-less writes to an owned `source_key` are refused with 200 `{updated: false, deferred_to: <owner>}` and the owner's row untouched; same-agent re-writes and writes to unowned (`agent_id IS NULL`) rows still upsert.
- **Sticky tombstone** (PB-ratified 2026-06-11) — a `/store` or `/harvest` collision with a tombstoned row signals `evicted: true` and leaves the row evicted; revival is only the explicit `/unevict` verb. The collision scope is pinned as **(content, content_type)** — `memory_id = hash(content ':' content_type)`, so identical text under a different type is a new live row, not a collision.
- **Evict/unevict round-trip** (PR #20, the W5 mutation surface) — `POST /memory/:id/evict {evicted_by, evict_reason}` → 200 `{memory, already_evicted}` with first-evictor-wins; `/unevict` → `{memory, was_evicted}`, idempotent on a live row; JSON 404 envelopes; secret auth.
- **Additive back-compat** — a clean first write carries neither `updated` nor `evicted`; the signals appear only on effect.

v1.3.1: **claude-mem#22 is fixed** (generation pads to 16 chars; migration 005 canonicalized old rows — confirmed deployed 2026-06-11 on #12), so `idlib.py` asserts that echoed ids round-trip **verbatim**: a 404 on an echoed id is a contract violation, not a known flake.

## Consolidation round-trip (v1.4.0, claude-mem#12 — synthesize-then-evict)

`test_consolidation_roundtrip.py` pins the mechanical contract of the consolidation pass exactly as first executed (2026-06-11: 2 survivors, 20 tombstones): `/store` accepts `consolidated_from: [<sibling ids>]` with an **outcome-gated echo** (engine `ee8f4e3` — a clean store echoes and persists the lineage edge; a refused store must not claim it), the tombstone's `evict_reason` is a machine-parsable `superseded-by <16-hex>` pointer, following it reaches the **live** survivor whose `consolidated_from` closes the loop, and re-storing an evicted sibling's content stays sticky (`evicted: true`, composing the v1.3.0 pin). Retrieval quality ("search serves the survivor") is deliberately NOT pinned — that is eval-harness territory.

## Topical-coverage write gate (v1.5.0, claude-mem#12 — the Layer-1 near-dup gate)

`test_topical_coverage_gate.py` pins the write-time topical-coverage gate that makes unattended incremental harvesting safe. Design (PB-arbitrated on #12, 2026-06-14): incremental re-harvest produces **topical**, not atomic, redundancy (atom-level dup ~1.3%, survivor-ground-truthed) — so keep blobs and gate at write time on topical coverage keyed **strictly on the same `source_doc_id`**. Cross-doc near-dups are deliberately **not** suppressed (a cross-doc "duplicate" is usually the same fact in a useful different context — merging that is consolidation's job, not a write-time drop), which makes the gate distiller-path-only by construction (agent writes carry no `source_doc_id`). Confirmed wire contract (cc-mem, against the live route `index-http.ts:345/:373`): the gate lives on `POST /harvest`; `source_doc_id` is a first-class body field; the response always carries `stored` (`stored:false` + `covered_by:[…]` when covered, `stored:true` otherwise). Two assertions pin the keying decision and guarantee cross-doc context is never silently lost: same-doc near-copy → covered; different-doc near-copy → stored. A unique `source_key` per probe isolates the coverage gate from the W8 source_key-collision guard (which runs first; re-distillation produces a new `source_key` with near-dup content — the exact case W8 misses and coverage catches).

## Invariants pinned

Beyond endpoint shape, the suite pins the two contract invariants from neg-305c49e5:

- **#1 embed-on-write** (`test_invariant_embed.py`) — a memory stored via `POST /harvest` must be retrievable by vector `POST /search`; a direct SQL insert that skips embedding would leave it invisible. This exercises endpoints that exist today, so it is **green** against a correct service (a regression guard, not red-until-built).
- **#2 doc_hash byte-exactness** (`test_invariant_doc_hash.py`) — `doc_hash` is sha256 over the EXACT ingested bytes; a `strip != raw` fixture keeps the equality non-vacuous.

Both are seed-gated (they write), so run them with `ALLOW_WRITES=1` against a disposable instance.

## Run it

```
HARVEST_CONFORMANCE_BASE_URL=http://localhost:3456 \
CLAUDE_MEM_SECRET=<secret> \
HARVEST_CONFORMANCE_ALLOW_WRITES=1 \
uv run pytest -q
```

Env:

- `HARVEST_CONFORMANCE_BASE_URL` — service base (default `http://snowball:3456`).
- `CLAUDE_MEM_SECRET` — `X-Claude-Mem-Secret` value; falls back to `~/.claude/settings.json` (`.env.CLAUDE_MEM_SECRET`).
- `HARVEST_CONFORMANCE_ALLOW_WRITES` — set to `1` to enable the seed-and-assert tests (`test_backlog_excludes_decided_content`, the invariant-#2 test). They `POST /docs` + `/decision`, so run them **only against a disposable / local service instance** — they are skipped by default so a run against the live store never pollutes it (a seeded doc would otherwise land in the real backlog).

## Expected state

- **Today (red):** the read-endpoint tests fail — `GET /docs/:doc_id` and `GET /docs/backlog` return 404 because the routes do not exist. `test_read_endpoints_require_auth` passes (the service already enforces the secret). The topical-coverage gate tests (v1.5.0) are red until the gate ships in the `/harvest` ADD path — it is last in the build order (watermark → consolidation+preservation → write-time gate), so these reds lead the furthest-out piece. Seed-gated tests skip unless `ALLOW_WRITES=1`.
- **After cc-mem implements (green):** all tests pass against an instance that has the two routes; cc-mem runs the pinned version as its pre-deploy gate.

## Versioning / pinning

`VERSION` carries the human label (`1.0.0`); cc-mem **pins the dotfiles commit SHA** and pulls that exact tree — e.g.

```
git -C <pb-dotfiles clone> archive <sha> ai/harvest-conformance | tar -x
```

or fetch the files at the pinned SHA. A new red assertion ships as a new commit + a `VERSION` bump and is announced on claude-mem #5 (the contract's R4 trigger). The registry/transport is an impl detail; the contract is: pinned by SHA, no live reach into porky.
