# Author: PB and cc-dots 🧷
# Date: 2026-06-02
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/harvest-conformance/test_invariant_doc_hash.py
#
# Invariant #2 (neg-305c49e5): marker doc_hash == service doc_hash, sha256 over
# the EXACT ingested bytes. Seed-and-assert, so gated on
# HARVEST_CONFORMANCE_ALLOW_WRITES. The fixture is deliberately strip != raw so
# the equality is NOT vacuous: a service that normalised/stripped content before
# hashing or before returning it would fail here.

import hashlib
import uuid

# trailing + internal whitespace so RAW.strip() != RAW
RAW = f"#  conformance invariant probe  {uuid.uuid4()}   \n\n\n   body with trailing spaces   \n\n"


def test_doc_hash_is_sha256_of_raw_bytes(client, writes_allowed):
    assert RAW.strip() != RAW, "fixture must be strip != raw to be non-vacuous"
    doc_hash = hashlib.sha256(RAW.encode("utf-8")).hexdigest()
    filepath = f"__conformance__/invariant-{doc_hash[:12]}.md"
    doc_id = hashlib.sha256(filepath.encode("utf-8")).hexdigest()

    r = client.post(
        "/docs",
        json={
            "doc_id": doc_id,
            "filename": "invariant.md",
            "filepath": filepath,
            "content": RAW,
            "file_mtime": "2026-06-02T00:00:00Z",
            "doc_hash": doc_hash,
            "metadata": {"conformance": True},
        },
    )
    assert r.status_code in (200, 201), f"seed POST /docs failed: {r.status_code} {r.text}"

    g = client.get(f"/docs/{doc_id}")
    assert g.status_code == 200, f"endpoint missing today ({g.status_code})"
    doc = g.json()["doc"]
    assert doc["content"] == RAW, (
        "service must return the exact ingested bytes (no strip/normalize)"
    )
    assert doc["doc_hash"] == doc_hash
    assert hashlib.sha256(doc["content"].encode("utf-8")).hexdigest() == doc["doc_hash"]
