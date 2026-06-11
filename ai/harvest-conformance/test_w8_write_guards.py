# Author: PB and cc-dots 🧷
# Date: 2026-06-11
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/harvest-conformance/test_w8_write_guards.py
#
# W8 write-guard contract (claude-mem#12, engine main b05a252 + PR #20) — the
# v1.3.0 gate for the 951-doc harvester re-run. Pins three surfaces:
#
#   NO-CLOBBER (keyed upsert ownership): the /harvest source_key DO UPDATE is
#   guarded `WHERE memories.agent_id IS NULL OR memories.agent_id =
#   EXCLUDED.agent_id`. A cross-agent (or provenance-less) write to an owned
#   key is REFUSED with 200 {success, memoryId, updated:false,
#   deferred_to:<owner>} and the owner's row is untouched. Same-owner and
#   unowned-row (NULL agent_id) updates still go through.
#
#   STICKY TOMBSTONE (PB-ratified 2026-06-11, option A): a /store or /harvest
#   colliding with a tombstoned row leaves it evicted; the response carries
#   evicted:true. Revival is ONLY the explicit /unevict verb, never a
#   content-collision side effect. The collision is (content, content_type)-
#   scoped — memory_id = hash(content ':' content_type) — so identical text
#   under a different content_type is a NEW live row, not a collision (cc-mem
#   discovery, pinned here per their ask).
#
#   EVICT/UNEVICT (PR #20, the W5 mutation surface): POST /memory/:id/evict
#   {evicted_by, evict_reason} → 200 {memory, already_evicted}; first-evictor-
#   wins (re-evict returns the ORIGINAL tombstone + already_evicted:true);
#   POST /memory/:id/unevict → 200 {memory, was_evicted}, idempotent no-op on
#   a live row; JSON 404 envelopes; secret auth.
#
# All mutating tests are seed-gated (writes_allowed) per suite policy — run
# only against a disposable instance. Green there = re-run go.
#
# By-id access goes through idlib (the claude-mem#22 padding workaround lives
# there, shared with the v1.2.0 round-trip tests).

import uuid

from idlib import UNKNOWN_ID
from idlib import get_memory as _get_memory
from idlib import post_by_id as _post_by_id


def _unique(tag: str) -> str:
    return f"# conformance w8 {tag} {uuid.uuid4()}\n\nbody.\n"


def _key() -> str:
    """A fresh conformance-namespace source_key (never the distiller's
    harvest:* namespace — these rows are disposable probes)."""
    return f"conformance:w8:{uuid.uuid4().hex[:12]}"


def _harvest(client, content: str, content_type: str, source_key: str, **extra):
    return client.post(
        "/harvest",
        json={
            "content": content,
            "content_type": content_type,
            "source_key": source_key,
            "tags": ["type:conformance"],
            **extra,
        },
    )


def _mint(client, content: str) -> str:
    """Create a memory via /store and return its id."""
    r = client.post("/store", json={"content": content, "tags": ["type:conformance"]})
    assert r.status_code in (200, 201), f"/store seed failed: {r.status_code} {r.text}"
    mid = r.json().get("memoryId")
    assert mid, "/store response must carry memoryId"
    return mid


def _evict(client, mid: str, reason: str):
    r = _post_by_id(client, mid, "evict", {"evicted_by": "cc-conformance", "evict_reason": reason})
    assert r.status_code == 200, f"evict failed: {r.status_code} {r.text}"
    return r.json()


# ── no-clobber: keyed upsert ownership (engine b05a252) ──────────────────────


def test_keyed_write_cross_agent_defers_to_owner(client, writes_allowed):
    """Agent Y writing to agent X's source_key is refused: 200 with
    updated:false + deferred_to:X, and X's content is untouched."""
    key = _key()
    owned = _unique("owner-content")
    r1 = _harvest(
        client,
        owned,
        "reference",
        key,
        agent_id="cc-conf-owner",
        session_id="conformance-w8",
        host="conformance-host",
    )
    assert r1.status_code in (200, 201), f"owner /harvest failed: {r1.status_code} {r1.text}"
    mid = r1.json().get("memoryId")
    assert mid, "/harvest response must carry memoryId"

    r2 = _harvest(
        client,
        _unique("intruder-content"),
        "reference",
        key,
        agent_id="cc-conf-intruder",
        session_id="conformance-w8",
        host="conformance-host",
    )
    assert r2.status_code in (200, 201), f"refusal must still be 200: {r2.status_code} {r2.text}"
    body = r2.json()
    assert body.get("updated") is False, (
        f"cross-agent keyed write must signal updated:false, got {body}"
    )
    assert body.get("deferred_to") == "cc-conf-owner", (
        f"deferred_to must name the owner, got {body.get('deferred_to')!r}"
    )

    mem = _get_memory(client, mid)
    assert mem["content"] == owned, "owner's content was clobbered by a refused write"
    assert mem["agent_id"] == "cc-conf-owner", "owner's agent_id was clobbered"


def test_keyed_write_same_agent_updates(client, writes_allowed):
    """The owner re-writing its own key still upserts (the guard must not
    break the distiller's re-run idempotency)."""
    key = _key()
    r1 = _harvest(
        client,
        _unique("v1"),
        "reference",
        key,
        agent_id="cc-conf-owner",
        session_id="conformance-w8",
        host="conformance-host",
    )
    assert r1.status_code in (200, 201), f"owner /harvest failed: {r1.status_code} {r1.text}"
    mid = r1.json().get("memoryId")

    v2 = _unique("v2")
    r2 = _harvest(
        client,
        v2,
        "reference",
        key,
        agent_id="cc-conf-owner",
        session_id="conformance-w8",
        host="conformance-host",
    )
    assert r2.status_code in (200, 201), f"same-agent re-write failed: {r2.status_code} {r2.text}"
    body = r2.json()
    assert body.get("updated") is not False, f"same-agent keyed write must not be refused: {body}"
    assert "deferred_to" not in body, f"same-agent write must not defer: {body}"

    mem = _get_memory(client, body.get("memoryId") or mid)
    assert mem["content"] == v2, "same-agent keyed update did not persist"


def test_keyed_write_unowned_row_is_updatable(client, writes_allowed):
    """A keyed row with NULL agent_id is unowned — any stamped writer may
    update it (the guard's `IS NULL` arm; legacy rows stay maintainable)."""
    key = _key()
    r1 = _harvest(client, _unique("unowned-v1"), "reference", key)  # no provenance
    assert r1.status_code in (200, 201), f"unstamped /harvest failed: {r1.status_code} {r1.text}"

    v2 = _unique("claimed-v2")
    r2 = _harvest(
        client,
        v2,
        "reference",
        key,
        agent_id="cc-conf-claimer",
        session_id="conformance-w8",
        host="conformance-host",
    )
    assert r2.status_code in (200, 201), f"claim of unowned key failed: {r2.status_code} {r2.text}"
    body = r2.json()
    assert body.get("updated") is not False, f"write to an unowned key must not be refused: {body}"

    mem = _get_memory(client, body.get("memoryId") or r1.json()["memoryId"])
    assert mem["content"] == v2, "update of an unowned keyed row did not persist"


def test_keyed_write_provenanceless_cannot_clobber_owned(client, writes_allowed):
    """NULL ≠ owner: an unstamped write to an OWNED key is refused — the
    asymmetry that protects agent-written rows from legacy clients."""
    key = _key()
    owned = _unique("owned-content")
    r1 = _harvest(
        client,
        owned,
        "reference",
        key,
        agent_id="cc-conf-owner",
        session_id="conformance-w8",
        host="conformance-host",
    )
    assert r1.status_code in (200, 201), f"owner /harvest failed: {r1.status_code} {r1.text}"
    mid = r1.json().get("memoryId")

    r2 = _harvest(client, _unique("anonymous-overwrite"), "reference", key)
    assert r2.status_code in (200, 201), f"refusal must still be 200: {r2.status_code} {r2.text}"
    body = r2.json()
    assert body.get("updated") is False, (
        f"provenance-less write to an owned key must be refused: {body}"
    )
    assert body.get("deferred_to") == "cc-conf-owner"

    mem = _get_memory(client, mid)
    assert mem["content"] == owned, "owned content was clobbered by a provenance-less write"


# ── sticky tombstone: collision leaves the row evicted (PB-ratified) ─────────


def test_store_collision_with_tombstone_stays_evicted(client, writes_allowed):
    """Re-storing tombstoned content does NOT revive it: the response carries
    evicted:true and the row keeps its tombstone. Revival is /unevict only."""
    content = _unique("sticky-store")
    mid = _mint(client, content)
    _evict(client, mid, "conformance sticky-tombstone probe")

    r = client.post("/store", json={"content": content, "tags": ["type:conformance"]})
    assert r.status_code in (200, 201), f"collision /store must still 200: {r.status_code} {r.text}"
    body = r.json()
    assert body.get("evicted") is True, f"tombstone collision must signal evicted:true, got {body}"

    mem = _get_memory(client, mid)
    assert mem["evicted_at"] is not None, (
        "content collision REVIVED a tombstoned row (must stay evicted)"
    )


def test_harvest_collision_with_tombstone_stays_evicted(client, writes_allowed):
    """Same sticky contract on the distiller's write path — the doc is flagged
    (evicted:true), never silently revived nor the write silently dropped
    without signal."""
    content = _unique("sticky-harvest")
    key1 = _key()
    r1 = _harvest(client, content, "reference", key1)
    assert r1.status_code in (200, 201), f"seed /harvest failed: {r1.status_code} {r1.text}"
    mid = r1.json()["memoryId"]
    _evict(client, mid, "conformance sticky-tombstone probe")

    key2 = _key()
    r2 = _harvest(client, content, "reference", key2)
    assert r2.status_code in (200, 201), (
        f"collision /harvest must still 200: {r2.status_code} {r2.text}"
    )
    body = r2.json()
    assert body.get("evicted") is True, (
        f"/harvest tombstone collision must signal evicted:true, got {body}"
    )

    mem = _get_memory(client, mid)
    assert mem["evicted_at"] is not None, "/harvest collision revived a tombstoned row"


def test_tombstone_collision_is_content_type_scoped(client, writes_allowed):
    """memory_id = hash(content ':' content_type): identical text under a
    DIFFERENT content_type is a new live row, not a collision (cc-mem's
    contract subtlety #1 — pinned so the distiller's conformance matches the
    engine's actual collision scope)."""
    content = _unique("type-scope")
    key1 = _key()
    r1 = _harvest(client, content, "reference", key1)
    assert r1.status_code in (200, 201), f"seed /harvest failed: {r1.status_code} {r1.text}"
    mid = r1.json()["memoryId"]
    _evict(client, mid, "conformance type-scope probe")

    key2 = _key()
    r2 = _harvest(client, content, "decision", key2)
    assert r2.status_code in (200, 201), f"cross-type /harvest failed: {r2.status_code} {r2.text}"
    body = r2.json()
    assert body.get("evicted") is not True, (
        "identical content under a different content_type must NOT collide "
        f"with the tombstone (collision is (content, type)-scoped): {body}"
    )
    new_mid = body.get("memoryId")
    assert new_mid and new_mid != mid, "cross-type write must mint a distinct memory_id"
    mem = _get_memory(client, new_mid)
    assert mem["evicted_at"] is None, "the cross-type row must be live"


def test_clean_store_carries_no_signal_fields(client, writes_allowed):
    """Additive back-compat (engine b05a252): a clean first write carries
    neither `updated` nor `evicted` — the signals appear only on effect."""
    r = client.post("/store", json={"content": _unique("clean"), "tags": ["type:conformance"]})
    assert r.status_code in (200, 201), f"/store failed: {r.status_code} {r.text}"
    body = r.json()
    assert "updated" not in body, f"clean store must not carry `updated`: {body}"
    assert "evicted" not in body, f"clean store must not carry `evicted`: {body}"


# ── evict / unevict round-trip (PR #20, the W5 mutation surface) ─────────────


def test_evict_unevict_roundtrip(client, writes_allowed):
    """The full forget verb cycle: evict → tombstone served with the stamp;
    re-evict → first-evictor-wins (original tombstone + already_evicted);
    unevict → restored; re-unevict → idempotent no-op."""
    mid = _mint(client, _unique("roundtrip"))

    body = _evict(client, mid, "conformance round-trip")
    assert not body.get("already_evicted"), "first evict must not report already_evicted"
    mem = body["memory"]
    assert mem["evicted_at"] is not None
    assert mem["evicted_by"] == "cc-conformance"
    assert mem["evict_reason"] == "conformance round-trip"

    r2 = _post_by_id(
        client, mid, "evict", {"evicted_by": "cc-conf-second", "evict_reason": "second evictor"}
    )
    assert r2.status_code == 200, f"re-evict must 200 with the original tombstone: {r2.status_code}"
    b2 = r2.json()
    assert b2.get("already_evicted") is True
    assert b2["memory"]["evicted_by"] == "cc-conformance", "first-evictor-wins violated"
    assert b2["memory"]["evict_reason"] == "conformance round-trip", "first-evictor-wins violated"

    r3 = _post_by_id(client, mid, "unevict", {})
    assert r3.status_code == 200, f"unevict failed: {r3.status_code} {r3.text}"
    b3 = r3.json()
    assert b3.get("was_evicted") is True
    assert b3["memory"]["evicted_at"] is None, "unevict must clear the tombstone"

    r4 = _post_by_id(client, mid, "unevict", {})
    assert r4.status_code == 200, f"idempotent unevict failed: {r4.status_code}"
    assert r4.json().get("was_evicted") is False, "unevict on a live row must be a no-op"

    mem = _get_memory(client, mid)
    assert mem["evicted_at"] is None, "row must be live after the round-trip"


def test_evict_unknown_id_404_json(client, writes_allowed):
    """Unknown id → 404 JSON {error} envelope on the mutation surface too."""
    r = client.post(
        f"/memory/{UNKNOWN_ID}/evict",
        json={"evicted_by": "cc-conformance", "evict_reason": "probe"},
    )
    assert r.status_code == 404, f"expected 404, got {r.status_code}"
    try:
        body = r.json()
    except ValueError:
        raise AssertionError("404 body is not JSON; expected a {error} envelope") from None
    assert "error" in body


def test_evict_requires_auth(noauth_client):
    """The mutation surface inherits the service's secret auth."""
    r = noauth_client.post(
        f"/memory/{UNKNOWN_ID}/evict", json={"evicted_by": "x", "evict_reason": "y"}
    )
    assert r.status_code in (401, 403), (
        f"unauthenticated evict must be rejected, got {r.status_code}"
    )
