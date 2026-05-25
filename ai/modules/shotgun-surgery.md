## Parallel code paths

When two code paths perform the same operation (e.g. `process.py` and
`pgdump.py` both create commits), changes to one MUST be audited against the
other:

- Search for all callers of any function you modify.
- When adding cleanup/guards/fields to one path, grep for the parallel path.
- When adding a WHERE clause to one query, check ALL queries on the same
  table.

**Shotgun surgery must be exhaustive.** Missing one site is worse than
missing all because it creates silent inconsistency.
