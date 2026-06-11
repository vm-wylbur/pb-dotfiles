# Author: PB and cc-dots 🧷
# Date: 2026-06-11
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/harvest-conformance/idlib.py
#
# Shared by-id access helpers for the suite, carrying the claude-mem#22
# workaround in ONE place: the DB historically stored memory ids as UNPADDED
# hex (toString(16) — leading zeros stripped) while responses echo 16-char
# padded, so an echoed id can 404 on by-id surfaces (~1/16). Engine HEAD now
# pads at generation and migration 005 canonicalizes existing rows; until the
# gate instance is guaranteed post-005, these helpers retry with leading
# zeros stripped. REMOVE the stripped-variant retry (and assert verbatim
# round-trips) once #22's migration is confirmed deployed.

UNKNOWN_ID = "0" * 16  # memory ids are 16-char hex (canonical post-#22 form)


def by_id_paths(mid: str, suffix: str = "") -> list[str]:
    """Candidate by-id paths for an echoed memory id — the padded echo first,
    then the unpadded pre-#22 DB form (leading zeros stripped)."""
    variants = [mid]
    stripped = mid.lstrip("0")
    if stripped and stripped != mid:
        variants.append(stripped)
    return [f"/memory/{v}{suffix}" for v in variants]


def get_memory(client, mid: str) -> dict:
    """GET /memory/:id tolerant of #22 id padding. Raises AssertionError if
    no variant serves the row."""
    last = None
    for path in by_id_paths(mid):
        last = client.get(path)
        if last.status_code == 200:
            return last.json()["memory"]
    raise AssertionError(f"by-id read failed for {mid}: {last.status_code} {last.text}")


def post_by_id(client, mid: str, verb: str, body: dict):
    """POST /memory/:id/{evict|unevict} tolerant of #22 id padding."""
    last = None
    for path in by_id_paths(mid, f"/{verb}"):
        last = client.post(path, json=body)
        if last.status_code != 404:
            return last
    return last
