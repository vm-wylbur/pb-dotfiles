## Python conventions

- Use `uv`. Do **not** use naked `python` / `python3`.
- Look for a `Makefile` first — it encodes what we've learned about running,
  paths, users, and environments. Read it; do not reinvent.
- Module / script invocation goes through the patterns Makefile targets
  establish (e.g. `make test`, `make report`); add a target rather than
  bypassing the Makefile.
