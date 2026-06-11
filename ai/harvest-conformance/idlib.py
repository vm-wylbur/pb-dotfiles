# Author: PB and cc-dots 🧷
# Date: 2026-06-11
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/harvest-conformance/idlib.py
#
# Shared by-id access helpers for the suite. Memory ids are canonical
# 16-char zero-padded hex: the engine pads at generation and migration 005
# canonicalized pre-existing rows (claude-mem#22, confirmed deployed
# 2026-06-11 on #12). Echoed ids therefore round-trip VERBATIM — the suite
# asserts that; a 404 on an echoed id is a real contract violation, no
# retry, no workaround.

UNKNOWN_ID = "0" * 16  # memory ids are 16-char hex (canonical post-#22 form)


def get_memory(client, mid: str) -> dict:
    """GET /memory/:id; the echoed id must serve verbatim (#22 is fixed)."""
    r = client.get(f"/memory/{mid}")
    assert r.status_code == 200, (
        f"by-id read failed for {mid}: {r.status_code} {r.text} "
        "(echoed ids must round-trip verbatim post-#22)"
    )
    return r.json()["memory"]


def post_by_id(client, mid: str, verb: str, body: dict):
    """POST /memory/:id/{evict|unevict} on the verbatim echoed id."""
    return client.post(f"/memory/{mid}/{verb}", json=body)
