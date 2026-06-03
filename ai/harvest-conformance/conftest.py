# Author: PB and cc-dots 🧷
# Date: 2026-06-02
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/harvest-conformance/conftest.py
#
# Shared fixtures for the harvester read-path conformance suite. Config via env:
#   HARVEST_CONFORMANCE_BASE_URL      service base (default http://snowball:3456)
#   CLAUDE_MEM_SECRET                 auth; falls back to ~/.claude/settings.json
#   HARVEST_CONFORMANCE_ALLOW_WRITES  set to 1 to enable the seed-and-assert tests
#                                     (POST /docs|/decision). OFF by default so a
#                                     run against the LIVE store never pollutes it;
#                                     cc-mem sets it for a disposable gate instance.

import json
import os
import pathlib

import httpx
import pytest

BASE_URL = os.environ.get("HARVEST_CONFORMANCE_BASE_URL", "http://snowball:3456").rstrip("/")
ALLOW_WRITES = os.environ.get("HARVEST_CONFORMANCE_ALLOW_WRITES", "") not in (
    "",
    "0",
    "false",
    "no",
)


def _resolve_secret() -> str | None:
    s = os.environ.get("CLAUDE_MEM_SECRET")
    if s:
        return s
    settings = pathlib.Path.home() / ".claude" / "settings.json"
    try:
        return json.loads(settings.read_text())["env"]["CLAUDE_MEM_SECRET"]
    except Exception:
        return None


@pytest.fixture(scope="session")
def secret() -> str:
    s = _resolve_secret()
    if not s:
        pytest.skip("no CLAUDE_MEM_SECRET (env or ~/.claude/settings.json)")
    return s


@pytest.fixture(scope="session")
def client(secret):
    with httpx.Client(base_url=BASE_URL, timeout=30, headers={"X-Claude-Mem-Secret": secret}) as c:
        yield c


@pytest.fixture(scope="session")
def noauth_client():
    with httpx.Client(base_url=BASE_URL, timeout=30) as c:
        yield c


@pytest.fixture(scope="session")
def sample_doc_id(client) -> str:
    """A real doc_id from the live corpus via the existing manifest, so the
    GET /docs/:doc_id checks exercise real data without seeding. Skips if the
    manifest is unavailable (e.g. an empty disposable instance — use the
    seed-based tests there instead)."""
    r = client.get("/docs/manifest")
    if r.status_code != 200:
        pytest.skip(f"/docs/manifest unavailable ({r.status_code}); cannot source a doc_id")
    docs = r.json().get("docs", [])
    if not docs:
        pytest.skip("/docs/manifest returned no docs")
    return docs[0]["doc_id"]


@pytest.fixture
def writes_allowed():
    if not ALLOW_WRITES:
        pytest.skip(
            "seed-and-assert test; set HARVEST_CONFORMANCE_ALLOW_WRITES=1 "
            "(safe only against a disposable/local service instance)"
        )
