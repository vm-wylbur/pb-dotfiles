## Config-from-disk discipline

Before reasoning about file paths, key locations, identifiers, or anything
else that lives in config: **re-read the config file from disk every time.**

- Memory is context, not truth. Stored values from previous sessions may be
  stale.
- Especially critical for cryptographic key paths — read the TOML, every
  time, before any operation that depends on a key path.
- Do not paraphrase config values into your reasoning. Quote the literal
  string from the file.

When re-signing or rewriting manifests / configs, derive identity (key_id,
org, etc.) from the CURRENT config, not from the old artifact being
rewritten.

Before reasoning about network exposure, security boundaries, or node
capabilities: read the actual config. Do not assume based on general
knowledge.

This applies to: TOML configs, YAML inventories, JSON manifests, any file
whose contents drive downstream behavior.
