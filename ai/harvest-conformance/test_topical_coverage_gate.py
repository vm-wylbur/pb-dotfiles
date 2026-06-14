# Author: PB and cc-dots 🧷
# Date: 2026-06-14
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/harvest-conformance/test_topical_coverage_gate.py
#
# Topical-coverage write gate contract (claude-mem#12; the Layer-1 near-dup
# gate). RED until cc-mem ships the gate in the /harvest ADD path. Build
# order: watermark -> consolidation+preservation -> THIS write-time gate
# (last), so these reds lead the furthest-out engine piece.
#
# Design (PB-arbitrated on #12, 2026-06-14): the redundancy incremental
# re-harvest produces is TOPICAL, not atomic (atom-level dup ~1.3%; a
# pre-registered, survivor-ground-truthed experiment, harness 305ddb4) ->
# keep blobs, gate at write time on TOPICAL COVERAGE keyed STRICTLY on the
# same source_doc_id. Cross-doc near-dups are deliberately NOT suppressed: a
# cross-doc "duplicate" is usually the same fact in a different useful
# context (a NIC fix in an incident doc vs a provisioning checklist), so
# merging-and-keeping-both-provenances is consolidation's job, not a blunt
# write-time drop. Suppressing cross-doc would repeat the atomic-unit
# context-destruction mistake one level up. The gate is distiller-path-only
# BY CONSTRUCTION: distiller memories carry source_doc_id, agent writes don't.
#
# Confirmed wire contract (cc-mem, verified against the live route at
# index-http.ts:345/:373):
#   * endpoint: POST /harvest (the distiller's keyed path, where W8 lives) --
#     not /store.
#   * source_doc_id: a FIRST-CLASS /harvest body field (not derived from
#     source_key); absent -> the gate does not engage -> stored:true.
#   * envelope: `stored` is ALWAYS present (the primary did-it-land signal,
#     unlike the omit-on-success anomaly signals evicted / deferred_to):
#       covered -> 200 {success:true, memoryId:<covering id>, stored:false,
#                       covered_by:[<ids>]}
#       stored  -> 200 {success:true, memoryId:<new id>, stored:true}
#
# Guard composition (cc-mem): W8 fires on an exact source_key collision
# (deferred_to); the coverage gate fires on same source_doc_id + near
# content (covered_by); W8 runs FIRST. Re-distillation produces a NEW
# source_key with near-dup content -> W8 misses it (no key collision) and
# coverage catches it. These tests therefore use a UNIQUE source_key per
# write so W8 never fires and the coverage gate is what is under test.
#
# Threshold note: the gate's similarity cutoff is cc-mem's to tune. To pin
# the KEYING decision (same-doc vs cross-doc) rather than the threshold
# value, these probes use NEAR-identical content (one shared core statement,
# trivial context variation) expected to clear any reasonable coverage
# threshold. They are intentionally NOT byte-identical: identical content +
# content_type collides on memory_id = hash(content ':' content_type), which
# is the W8 sticky path -- a different contract.
#
# All writes are seed-gated (writes_allowed) per suite policy -- run only
# against a disposable instance.

import uuid

from idlib import get_memory as _get_memory

_CORE = (
    "Lesson: blacklist the bnxt_en module for the BCM57416 NIC before the "
    "bond comes up, or the link flaps on boot."
)


def _near(tag: str) -> str:
    """Same substance, trivial context variation: a distinct memory_id with
    high similarity -- the genuine re-distillation / cross-context shape."""
    return f"{_CORE} (seen {tag})"


def _doc_id() -> str:
    return f"conformance-doc:{uuid.uuid4().hex[:12]}"


def _harvest(client, content, source_doc_id=None, content_type="decision"):
    body = {
        "content": content,
        "content_type": content_type,
        # unique per write -> the W8 source_key-collision guard never fires,
        # isolating the coverage gate (keyed on source_doc_id) as under test.
        "source_key": f"conformance:cov:{uuid.uuid4().hex[:12]}",
        "tags": ["type:conformance"],
    }
    if source_doc_id is not None:
        body["source_doc_id"] = source_doc_id
    return client.post("/harvest", json=body)


def _seed(client, content, source_doc_id):
    """Land a first memory; lenient (200 + memoryId) so the RED comes from
    the gate assertions below, not from the seed."""
    r = _harvest(client, content, source_doc_id=source_doc_id)
    assert r.status_code == 200, f"/harvest seed failed: {r.status_code} {r.text}"
    mid = r.json().get("memoryId")
    assert mid, "seed /harvest response must carry memoryId"
    return mid


# ── same source_doc_id + near content -> covered (the gate fires) ────────────


def test_same_doc_near_copy_is_covered(client, writes_allowed):
    """A near-dup under the SAME source_doc_id (fresh source_key, so W8 cannot
    fire) is suppressed: stored:false, memoryId + covered_by name the covering
    row, and that row is left intact."""
    doc = _doc_id()
    first = _seed(client, _near("incident"), doc)

    r = _harvest(client, _near("checklist"), source_doc_id=doc)
    assert r.status_code == 200, f"{r.status_code} {r.text}"
    j = r.json()
    assert j.get("stored") is False, f"same-doc near-copy must be covered (stored:false), got {j}"
    assert j.get("memoryId") == first, (
        f"covered response memoryId must be the covering row {first}, got {j.get('memoryId')}"
    )
    assert first in (j.get("covered_by") or []), (
        f"covered_by must name {first}, got {j.get('covered_by')}"
    )

    g = _get_memory(client, first)
    assert g.status_code == 200, f"covering row not readable: {g.status_code} {g.text}"
    assert g.json().get("content") == _near("incident"), "covering row content must be unchanged"


# ── different source_doc_id + near content -> stored (NOT suppressed) ─────────


def test_cross_doc_near_copy_is_stored(client, writes_allowed):
    """The guarantee that cross-doc context is never silently lost: a near-dup
    under a DIFFERENT source_doc_id lands as a new distinct row, not covered."""
    first = _seed(client, _near("incident"), _doc_id())

    r = _harvest(client, _near("checklist"), source_doc_id=_doc_id())
    assert r.status_code == 200, f"{r.status_code} {r.text}"
    j = r.json()
    assert j.get("stored") is True, f"cross-doc near-copy must store (stored:true), got {j}"
    assert j.get("memoryId") and j.get("memoryId") != first, (
        f"must be a new distinct row, got {j.get('memoryId')}"
    )
    assert not (j.get("covered_by") or []), (
        f"cross-doc write must not be marked covered, got {j.get('covered_by')}"
    )


# ── absent source_doc_id -> gate does not engage (cc-mem completeness) ────────


def test_absent_source_doc_id_falls_through_to_stored(client, writes_allowed):
    """Agent-path writes carry no source_doc_id; the gate must not engage and
    the write falls through to stored:true (cc-mem completeness note)."""
    r = _harvest(client, _near("solo"), source_doc_id=None)
    assert r.status_code == 200, f"{r.status_code} {r.text}"
    j = r.json()
    assert j.get("stored") is True, f"no source_doc_id must fall through to stored:true, got {j}"
