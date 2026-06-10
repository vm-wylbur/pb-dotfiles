# Author: PB and cc-dots 🧷
# Date: 2026-06-09
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/harvest-conformance/test_provenance_roundtrip.py
#
# Provenance round-trip contract (Workstream B items W2/W9, ratified
# neg-6b0a3bf5; claude-mem#12). Three layers:
#
#   GREEN today (regression guards on claude-mem PR #11, deployed):
#     POST /store accepts session_id/host/agent_id and echoes accepted input;
#     '' -> 400; absent -> 200 back-compat.
#
#   RED until cc-mem ships GET /memory/:memory_id (the neg-6b0a3bf5 W9 read
#   surface, in the migration-003 deployable unit):
#     by-id read returns provenance + eviction columns; round-trip asserts
#     PERSISTENCE (the /store echo is accepted-input, not a DB read-back —
#     these tests are the difference).
#
#   RED until cc-mem extends /harvest (the W9 contract extension cc-mem
#   raised: harvested memories currently land with NULL provenance):
#     POST /harvest accepts the same three optional fields and stamps them;
#     its response carries memoryId so the round-trip is assertable.
#
# Eviction fields (evicted_at/evicted_by/evict_reason) are asserted PRESENT
# (nullable) in the by-id read; asserting a real tombstone round-trip waits
# for the forget verb (W5, gated on the engine's W3 read-path sweep).
#
# All POSTing tests are seed-gated (writes_allowed) per suite policy.

import uuid

UNKNOWN_ID = "0" * 16  # memory ids are 16-char hex (verified against GET /recent)

PROVENANCE_FIELDS = ("session_id", "host", "agent_id")
EVICTION_FIELDS = ("evicted_at", "evicted_by", "evict_reason")
BY_ID_FIELDS = (
    "memory_id",
    "content",
    "created_at",
    "updated_at",
    *PROVENANCE_FIELDS,
    *EVICTION_FIELDS,
)


def _stamp(suffix: str) -> dict:
    return {
        "session_id": f"conformance-{suffix}",
        "host": "conformance-host",
        "agent_id": "cc-conformance",
    }


def _store(client, **extra):
    body = {
        "content": f"# conformance provenance probe {uuid.uuid4()}\n\nbody.\n",
        "tags": ["type:conformance"],
        **extra,
    }
    return client.post("/store", json=body), body


# ── POST /store contract (GREEN: regression guards on PR #11) ────────────────


def test_store_accepts_and_echoes_provenance(client, writes_allowed):
    """200; the response echoes the ACCEPTED provenance (PR #11 contract:
    echo-of-accepted-input, explicitly not a DB read-back)."""
    stamp = _stamp(uuid.uuid4().hex[:8])
    r, _ = _store(client, **stamp)
    assert r.status_code in (200, 201), f"stamped /store failed: {r.status_code} {r.text}"
    body = r.json()
    for f in PROVENANCE_FIELDS:
        assert body.get(f) == stamp[f], f"response must echo accepted {f}"


def test_store_empty_string_provenance_400(client, writes_allowed):
    """'' is not a valid provenance value (PR #11: non-string OR empty -> 400)."""
    r, _ = _store(client, agent_id="")
    assert r.status_code == 400, f"empty-string agent_id must 400, got {r.status_code}"


def test_store_absent_provenance_backcompat(client, writes_allowed):
    """No provenance fields -> 200 (nullable contract; legacy clients keep working)."""
    r, _ = _store(client)
    assert r.status_code in (200, 201), f"unstamped /store must succeed: {r.status_code}"


# ── GET /memory/:memory_id (RED until the W9 read surface ships) ─────────────


def test_memory_fetch_by_id_shape(client):
    """200 {memory:{...}} carrying provenance + eviction columns (nullable, but
    the KEYS must be present). Sources a real id from GET /recent (read-only)."""
    rr = client.get("/recent", params={"n": 1})
    assert rr.status_code == 200, f"/recent unavailable ({rr.status_code}); cannot source an id"
    memories = rr.json().get("memories", [])
    assert memories, "/recent returned no memories"
    # /recent names the field `id` today; tolerate a future rename to memory_id
    mid = memories[0].get("memory_id") or memories[0]["id"]

    r = client.get(f"/memory/{mid}")
    assert r.status_code == 200, f"expected 200, got {r.status_code} (endpoint missing today)"
    mem = r.json()["memory"]
    for field in BY_ID_FIELDS:
        assert field in mem, f"missing field: {field}"
    assert mem["memory_id"] == mid
    assert mem["content"], "content must be non-empty"


def test_memory_fetch_unknown_id_404_json(client):
    """Unknown memory_id -> 404 with a JSON {error} envelope, not HTML."""
    r = client.get(f"/memory/{UNKNOWN_ID}")
    assert r.status_code == 404, f"expected 404, got {r.status_code}"
    try:
        body = r.json()
    except ValueError:
        raise AssertionError("404 body is not JSON; expected a {error} envelope") from None
    assert "error" in body


def test_memory_fetch_requires_auth(noauth_client):
    """The by-id read inherits the service's secret auth."""
    r = noauth_client.get(f"/memory/{UNKNOWN_ID}")
    assert r.status_code in (401, 403), (
        f"unauthenticated read must be rejected, got {r.status_code}"
    )


# ── the round-trips: PERSISTENCE, not echo (RED until by-id read ships) ──────


def test_store_provenance_persists(client, writes_allowed):
    """THE W2/W9 assertion: a stamped /store write survives to a DB read.
    The /store echo alone cannot prove this (it reflects accepted input)."""
    stamp = _stamp(uuid.uuid4().hex[:8])
    r, _ = _store(client, **stamp)
    assert r.status_code in (200, 201), f"stamped /store failed: {r.status_code} {r.text}"
    mid = r.json().get("memoryId")
    assert mid, "/store response must carry memoryId"

    g = client.get(f"/memory/{mid}")
    assert g.status_code == 200, f"by-id read failed: {g.status_code} (endpoint missing today)"
    mem = g.json()["memory"]
    for f in PROVENANCE_FIELDS:
        assert mem[f] == stamp[f], f"persisted {f} != stored {f} (round-trip broken)"
    for f in EVICTION_FIELDS:
        assert mem[f] is None, f"fresh memory must not carry {f}"


def test_harvest_provenance_persists(client, writes_allowed):
    """The W9 /harvest contract extension (raised by cc-mem): the distiller
    write path accepts the same optional provenance and stamps it — harvested
    memories must not silently land with NULL provenance once the harvester
    emits it. Requires /harvest to return memoryId (contract addition)."""
    stamp = _stamp(uuid.uuid4().hex[:8])
    hv = client.post(
        "/harvest",
        json={
            "content": f"conformance harvest provenance probe {uuid.uuid4()}",
            "content_type": "reference",
            "source_key": f"conformance:prov:{uuid.uuid4().hex[:12]}",
            "tags": ["type:conformance"],
            **stamp,
        },
    )
    assert hv.status_code in (200, 201), f"stamped /harvest failed: {hv.status_code} {hv.text}"
    mid = hv.json().get("memoryId")
    assert mid, "/harvest response must carry memoryId (contract addition, missing today)"

    g = client.get(f"/memory/{mid}")
    assert g.status_code == 200, f"by-id read failed: {g.status_code} (endpoint missing today)"
    mem = g.json()["memory"]
    for f in PROVENANCE_FIELDS:
        assert mem[f] == stamp[f], f"persisted {f} != harvested {f} (round-trip broken)"
