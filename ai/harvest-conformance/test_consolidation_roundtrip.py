# Author: PB and cc-dots 🧷
# Date: 2026-06-11
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/harvest-conformance/test_consolidation_roundtrip.py
#
# Consolidation round-trip (v1.4.0; claude-mem#12 consolidation pass, first
# instance executed 2026-06-11 — 2 survivors, 20 tombstones). Pins the
# MECHANICAL contract of synthesize-then-evict, exactly as executed:
#
#   1. survivor stored via /store with consolidated_from: [<sibling ids>]
#      (engine ee8f4e3) — the reverse lineage edge, echoed on a CLEAN store
#      and persisted to metadata.consolidated_from;
#   2. sibling evicted with evict_reason 'superseded-by <survivor_id>' —
#      the tombstone serves a machine-parsable pointer;
#   3. following the pointer reaches the LIVE survivor whose
#      consolidated_from closes the loop back to the tombstone;
#   4. re-storing the evicted sibling's content signals evicted:true and
#      revives nothing (sticky tombstone, composed from v1.3.0);
#   5. a REFUSED store must NOT echo consolidated_from (outcome-gated echo:
#      a refusal path cannot claim an edge it did not store).
#
# Deliberately NOT pinned: "search serves the survivor" — retrieval quality
# is eval-harness territory (cc-mem's lane), and a conformance flake on
# embedding behavior would erode the suite's authority.
#
# All tests are seed-gated (writes_allowed) per suite policy.

import re
import uuid

from idlib import get_memory as _get_memory
from idlib import post_by_id as _post_by_id

SUPERSEDES = re.compile(r"^superseded-by ([0-9a-f]{16})$")


def _unique(tag: str) -> str:
    return f"# conformance consolidation {tag} {uuid.uuid4()}\n\nbody.\n"


def _store(client, content: str, **extra):
    r = client.post("/store", json={"content": content, "tags": ["type:conformance"], **extra})
    assert r.status_code in (200, 201), f"/store failed: {r.status_code} {r.text}"
    return r.json()


def _seed_family(client):
    """Two siblings + a survivor carrying their lineage. Returns
    (sibling_ids, survivor_id)."""
    sids = [_store(client, _unique(f"sibling-{i}"))["memoryId"] for i in (1, 2)]
    sv = _store(client, _unique("survivor"), consolidated_from=sids)
    return sids, sv


def test_store_echoes_and_persists_consolidated_from(client, writes_allowed):
    """A clean keyless store with consolidated_from echoes the accepted edge
    AND persists it to metadata (the reverse lineage edge, ee8f4e3)."""
    sids, sv = _seed_family(client)
    assert sv.get("consolidated_from") == sids, (
        f"clean store must echo consolidated_from, got {sv.get('consolidated_from')!r}"
    )
    mem = _get_memory(client, sv["memoryId"])
    assert mem["metadata"].get("consolidated_from") == sids, (
        "consolidated_from must persist to metadata (round-trip, not echo)"
    )


def test_supersedes_pointer_roundtrip(client, writes_allowed):
    """The full loop: evict a sibling with the supersedes reason; the
    tombstone's pointer parses, leads to the LIVE survivor, and the
    survivor's lineage closes the loop back to the evicted sibling."""
    sids, sv = _seed_family(client)
    svid = sv["memoryId"]

    r = _post_by_id(
        client,
        sids[0],
        "evict",
        {"evicted_by": "cc-conformance", "evict_reason": f"superseded-by {svid}"},
    )
    assert r.status_code == 200, f"evict failed: {r.status_code} {r.text}"

    tomb = _get_memory(client, sids[0])
    assert tomb["evicted_at"] is not None, "sibling must be tombstoned"
    m = SUPERSEDES.match(tomb["evict_reason"] or "")
    assert m, f"evict_reason must be a parseable supersedes pointer: {tomb['evict_reason']!r}"

    target = _get_memory(client, m.group(1))
    assert target["evicted_at"] is None, "the supersedes pointer must reach a LIVE survivor"
    assert sids[0] in (target["metadata"].get("consolidated_from") or []), (
        "survivor's consolidated_from must close the loop back to the tombstone"
    )


def test_evicted_sibling_content_stays_evicted(client, writes_allowed):
    """Re-deriving an evicted sibling's exact content does not revive it:
    sticky evicted:true (v1.3.0 contract composed into the consolidation
    flow — this is what keeps the distiller from undoing a merge)."""
    _sids, sv = _seed_family(client)
    content = _unique("sticky-sibling")
    sid = _store(client, content)["memoryId"]
    r = _post_by_id(
        client,
        sid,
        "evict",
        {"evicted_by": "cc-conformance", "evict_reason": f"superseded-by {sv['memoryId']}"},
    )
    assert r.status_code == 200, f"evict failed: {r.status_code} {r.text}"

    again = _store(client, content)
    assert again.get("evicted") is True, f"tombstone collision must signal evicted:true: {again}"
    assert _get_memory(client, sid)["evicted_at"] is not None, "collision revived the tombstone"


def test_refused_store_does_not_claim_lineage(client, writes_allowed):
    """Outcome-gated echo (ee8f4e3): a store that collides with a tombstone
    is REFUSED — its response must not echo consolidated_from, because no
    edge was stored."""
    sids, sv = _seed_family(client)
    content = _unique("refused-lineage")
    sid = _store(client, content)["memoryId"]
    r = _post_by_id(
        client,
        sid,
        "evict",
        {"evicted_by": "cc-conformance", "evict_reason": f"superseded-by {sv['memoryId']}"},
    )
    assert r.status_code == 200, f"evict failed: {r.status_code} {r.text}"

    again = _store(client, content, consolidated_from=[sids[0]])
    assert again.get("evicted") is True, f"expected the sticky collision: {again}"
    assert "consolidated_from" not in again, (
        "a refused store must NOT echo consolidated_from (unstored edge claimed)"
    )
