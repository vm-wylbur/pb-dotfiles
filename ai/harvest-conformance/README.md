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

- **Today (red):** the read-endpoint tests fail — `GET /docs/:doc_id` and `GET /docs/backlog` return 404 because the routes do not exist. `test_read_endpoints_require_auth` passes (the service already enforces the secret). Seed-gated tests skip unless `ALLOW_WRITES=1`.
- **After cc-mem implements (green):** all tests pass against an instance that has the two routes; cc-mem runs the pinned version as its pre-deploy gate.

## Versioning / pinning

`VERSION` carries the human label (`1.0.0`); cc-mem **pins the dotfiles commit SHA** and pulls that exact tree — e.g.

```
git -C <pb-dotfiles clone> archive <sha> ai/harvest-conformance | tar -x
```

or fetch the files at the pinned SHA. A new red assertion ships as a new commit + a `VERSION` bump and is announced on claude-mem #5 (the contract's R4 trigger). The registry/transport is an impl detail; the contract is: pinned by SHA, no live reach into porky.
