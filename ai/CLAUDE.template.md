<!--
Author: PB and Claude
Original: 2025-06-30 (as docs/meta-CLAUDE.md)
Refactored: 2026-05-25 (cc-dots: modular composition; renamed from
            docs/meta-CLAUDE.md to ai/CLAUDE.md as part of the
            composable-CLAUDE.md design)
License: (c) HRDAG, 2026, GPL-2 or newer

---
ai/CLAUDE.md

This is the user-wide CLAUDE.md, symlinked from ~/.claude/CLAUDE.md and
loaded into every Claude Code session as the global floor. Composed from
modules at ai/modules/ via `claude-md render`. Per-repo CLAUDE.md files
ADD repo-specific modules on top of this floor.

Design + module catalog: ai/docs/composable-CLAUDE.md-design.md.
-->

# User-wide Claude rules for PB

<!-- compose: {"modules": ["base", "verify-discipline", "output-budget", "web-access", "settings-hygiene", "git-basics", "commit-gate", "python-uv", "file-headers", "markdown-format", "shotgun-surgery", "gh-signature", "tri-home", "qfix", "code-review", "built-ins-routing", "goal-lock", "multi-agent"], "output": "~/.claude/CLAUDE.md"} -->

<!-- BEGIN module:base -->
<!-- END module:base -->

<!-- BEGIN module:verify-discipline -->
<!-- END module:verify-discipline -->

<!-- BEGIN module:output-budget -->
<!-- END module:output-budget -->

<!-- BEGIN module:web-access -->
<!-- END module:web-access -->

<!-- BEGIN module:settings-hygiene -->
<!-- END module:settings-hygiene -->

<!-- BEGIN module:git-basics -->
<!-- END module:git-basics -->

<!-- BEGIN module:commit-gate -->
<!-- END module:commit-gate -->

<!-- BEGIN module:python-uv -->
<!-- END module:python-uv -->

<!-- BEGIN module:file-headers -->
<!-- END module:file-headers -->

<!-- BEGIN module:markdown-format -->
<!-- END module:markdown-format -->

<!-- BEGIN module:shotgun-surgery -->
<!-- END module:shotgun-surgery -->

<!-- BEGIN module:gh-signature -->
<!-- END module:gh-signature -->

<!-- BEGIN module:tri-home -->
<!-- END module:tri-home -->

<!-- BEGIN module:qfix -->
<!-- END module:qfix -->

<!-- BEGIN module:code-review -->
<!-- END module:code-review -->

<!-- BEGIN module:built-ins-routing -->
<!-- END module:built-ins-routing -->

<!-- BEGIN module:goal-lock -->
<!-- END module:goal-lock -->

<!-- BEGIN module:multi-agent -->
<!-- END module:multi-agent -->

## Universal deployment rule

The HRDAG cluster uses PULL-based deployment. Never push code or wheels
directly to nodes. Build, tag, `make release`. Nodes pull via
auto-update.
