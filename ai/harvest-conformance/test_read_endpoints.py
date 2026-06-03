# Author: PB and cc-dots 🧷
# Date: 2026-06-02
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/harvest-conformance/test_read_endpoints.py
#
# RED until cc-mem implements the two harvester read endpoints (neg-305c49e5,
# claude-mem #5). "Green" == the harvester runs with ZERO snowball SSH:
#   GET /docs/:doc_id    replaces eval.py  load_docs
#   GET /docs/backlog    replaces distill.py backlog (currently `ssh psql`)
# Contract owned by cc-dots; cc-mem implements to these assertions.

import hashlib
import uuid

# ── GET /docs/:doc_id ─────────────────────────────────────────────────────────


def test_doc_fetch_by_id_returns_full_doc(client, sample_doc_id):
    """200 {doc:{...}} with full content -- eval needs the content, which the
    existing /docs/manifest does not return."""
    r = client.get(f"/docs/{sample_doc_id}")
    assert r.status_code == 200, f"expected 200, got {r.status_code} (endpoint missing today)"
    doc = r.json()["doc"]
    for field in (
        "doc_id",
        "filename",
        "filepath",
        "content",
        "file_mtime",
        "doc_hash",
        "metadata",
    ):
        assert field in doc, f"missing field: {field}"
    assert doc["doc_id"] == sample_doc_id
    assert doc["content"], "content must be non-empty"


def test_doc_fetch_doc_hash_matches_content(client, sample_doc_id):
    """Returned doc_hash == sha256 of the returned content bytes (invariant #2,
    service side: the stored doc_hash is sha256 of the content as ingested)."""
    r = client.get(f"/docs/{sample_doc_id}")
    assert r.status_code == 200, f"expected 200, got {r.status_code} (endpoint missing today)"
    doc = r.json()["doc"]
    assert hashlib.sha256(doc["content"].encode("utf-8")).hexdigest() == doc["doc_hash"]


def test_doc_fetch_unknown_id_404_json(client):
    """Unknown doc_id -> 404 with a JSON {error} envelope, not an HTML default."""
    r = client.get(f"/docs/{'0' * 64}")
    assert r.status_code == 404, f"expected 404, got {r.status_code}"
    try:
        body = r.json()
    except ValueError:
        raise AssertionError(
            "404 body is not JSON; expected a {error} envelope (HTML default today)"
        ) from None
    assert "error" in body, "404 must carry a JSON {error} envelope"


# ── GET /docs/backlog ─────────────────────────────────────────────────────────


def test_backlog_shape(client):
    """200 {docs:[...], limit, offset, total}; rows carry content + doc_hash and
    are DISTINCT by doc_hash (distill distills once per distinct content)."""
    r = client.get("/docs/backlog", params={"limit": 5})
    assert r.status_code == 200, f"expected 200, got {r.status_code} (endpoint missing today)"
    body = r.json()
    for field in ("docs", "limit", "offset", "total"):
        assert field in body, f"missing field: {field}"
    docs = body["docs"]
    assert len(docs) <= 5
    for d in docs:
        assert d.get("content"), "backlog rows must include content (distill needs it)"
        assert "doc_hash" in d and "doc_id" in d and "filepath" in d
    hashes = [d["doc_hash"] for d in docs]
    assert len(hashes) == len(set(hashes)), "backlog must be DISTINCT by doc_hash"


def test_backlog_pagination_no_overlap(client):
    """limit/offset page consistently; adjacent windows do not overlap."""
    first = client.get("/docs/backlog", params={"limit": 3, "offset": 0})
    second = client.get("/docs/backlog", params={"limit": 3, "offset": 3})
    assert first.status_code == 200 and second.status_code == 200, "endpoint missing today"
    ids1 = {d["doc_id"] for d in first.json()["docs"]}
    ids2 = {d["doc_id"] for d in second.json()["docs"]}
    assert not (ids1 & ids2), "paged windows must not overlap"


def _seed_two_paths(client, content):
    """Seed identical content at two filepaths (same doc_hash, two doc_ids).
    Returns (doc_hash, [doc_id_1, doc_id_2])."""
    doc_hash = hashlib.sha256(content.encode("utf-8")).hexdigest()
    ids = []
    for i in (1, 2):
        filepath = f"__conformance__/dedup-{doc_hash[:12]}-{i}.md"
        doc_id = hashlib.sha256(filepath.encode("utf-8")).hexdigest()
        ids.append(doc_id)
        r = client.post(
            "/docs",
            json={
                "doc_id": doc_id,
                "filename": f"dedup-{i}.md",
                "filepath": filepath,
                "content": content,
                "file_mtime": "2026-06-02T00:00:00Z",
                "doc_hash": doc_hash,
                "metadata": {"conformance": True},
            },
        )
        assert r.status_code in (200, 201), f"seed POST /docs failed: {r.status_code} {r.text}"
    return doc_hash, ids


def _all_backlog_hashes(client):
    """Every doc_hash in the backlog, paged to completion and bounded by the
    reported `total` so the scan can't stop short and false-pass an exclusion."""
    seen, offset, total = set(), 0, None
    while True:
        rr = client.get("/docs/backlog", params={"limit": 200, "offset": offset})
        assert rr.status_code == 200, f"endpoint missing today ({rr.status_code})"
        body = rr.json()
        total = body["total"] if total is None else total
        page = body["docs"]
        if not page:
            break
        seen.update(d["doc_hash"] for d in page)
        offset += len(page)
        if offset >= total:
            break
    return seen


def test_backlog_excludes_decided_content(client, writes_allowed):
    """THE dedup-correctness contract (the HIGH bug), DECISION path: exclusion is
    by doc_hash, not the DISTINCT-ON-picked doc_id. Seeds content at two paths,
    decides ONE sibling, asserts the doc_hash leaves the backlog."""
    doc_hash, ids = _seed_two_paths(
        client, f"# conformance dedup/decision {uuid.uuid4()}\n\nbody.\n"
    )
    dr = client.post(
        "/decision",
        json={
            "doc_id": ids[0],
            "doc_filename": "dedup-1.md",
            "insight_number": 1,
            "insight_content": "conformance dedup probe",
            "action": "skipped",
            "skip_reason": "conformance dedup probe",
        },
    )
    assert dr.status_code in (200, 201), f"seed POST /decision failed: {dr.status_code} {dr.text}"
    assert doc_hash not in _all_backlog_hashes(client), (
        "decided content still in backlog -> exclusion is by doc_id, not doc_hash (the HIGH bug)"
    )


def test_backlog_excludes_distilled_content(client, writes_allowed):
    """Same contract, MEMORY path: a doc_hash is excluded once ANY sibling has a
    source_doc_id-linked memory (no decision needed). Seeds content at two paths,
    stores a memory linked to ONE via /harvest, asserts the doc_hash leaves the
    backlog. Covers the exclusion branch the decision test does not."""
    doc_hash, ids = _seed_two_paths(client, f"# conformance dedup/memory {uuid.uuid4()}\n\nbody.\n")
    hv = client.post(
        "/harvest",
        json={
            "content": "conformance distilled insight",
            "content_type": "reference",
            "source_key": f"conformance:mem:{doc_hash[:12]}",
            "source_doc_id": ids[0],
            "tags": ["type:conformance"],
        },
    )
    assert hv.status_code in (200, 201), f"seed POST /harvest failed: {hv.status_code} {hv.text}"
    assert doc_hash not in _all_backlog_hashes(client), (
        "distilled content still in backlog -> memory-path exclusion is by doc_id, not doc_hash"
    )


# ── auth (already enforced today; stays green) ────────────────────────────────


def test_read_endpoints_require_auth(noauth_client):
    """The read endpoints inherit the service's secret auth."""
    r = noauth_client.get("/docs/backlog", params={"limit": 1})
    assert r.status_code in (401, 403), (
        f"unauthenticated read must be rejected, got {r.status_code}"
    )
