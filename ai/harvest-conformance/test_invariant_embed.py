# Author: PB and cc-dots 🧷
# Date: 2026-06-02
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/harvest-conformance/test_invariant_embed.py
#
# Invariant #1 (neg-305c49e5): a stored memory is retrievable by vector query.
# /harvest (like /store) must embed BEFORE insert -- a direct SQL insert would
# leave the memory unembedded and invisible to vector search. Seed-and-assert,
# so gated on HARVEST_CONFORMANCE_ALLOW_WRITES. Unlike the read-endpoint tests
# this exercises endpoints that exist today, so it is GREEN against a correct
# service (a regression guard, not red-until-built).

import time
import uuid


def _search_ids(client, query, limit=20):
    sr = client.post("/search", json={"query": query, "limit": limit})
    assert sr.status_code == 200, f"/search failed: {sr.status_code} {sr.text}"
    return [m.get("memory_id") for m in sr.json()["memories"]]


def test_stored_memory_is_retrievable_by_vector_query(client, writes_allowed):
    nonce = uuid.uuid4().hex
    content = (
        f"Conformance embed probe {nonce}: a harvested memory must be embedded on "
        f"write so it is retrievable by vector similarity search."
    )
    hv = client.post(
        "/harvest",
        json={
            "content": content,
            "content_type": "reference",
            "source_key": f"conformance:embed:{nonce}",
            "tags": ["type:conformance"],
        },
    )
    assert hv.status_code in (200, 201), f"seed POST /harvest failed: {hv.status_code} {hv.text}"
    memory_id = hv.json().get("memoryId")
    assert memory_id, "/harvest must return memoryId"

    # Embed-before-insert is synchronous per the contract; the short retries only
    # guard against incidental index lag, not a missing embedding (4 tries won't
    # make an unembedded memory appear).
    for _ in range(4):
        if memory_id in _search_ids(client, content):
            return
        time.sleep(0.5)
    raise AssertionError(
        "stored memory not retrievable by vector search -> not embedded on write "
        "(a direct SQL insert would skip the embedding the contract requires)"
    )
