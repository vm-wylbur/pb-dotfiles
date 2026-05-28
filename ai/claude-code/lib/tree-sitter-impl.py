"""
Author: PB and cc-dots
Date: 2026-05-27
License: (c) HRDAG, 2026, GPL-2 or newer

---
dotfiles/ai/claude-code/lib/tree-sitter-impl.py

CLI shim over mcp_server_tree_sitter — re-uses the project-aware analysis
functions that backed the MCP server, but invoked as a subprocess from
the lib/ substrate. Replaces the mcp__tree_sitter__* MCP tool surface
with a single subcommand-driven script that the new tree-sitter skill
calls.

Run via lib/tree-sitter.sh, which sets the venv python path and forwards
argv. Outputs JSON on stdout; non-zero exit on error.
"""

import argparse
import hashlib
import json
import sys
from pathlib import Path

try:
    from mcp_server_tree_sitter import api
    from mcp_server_tree_sitter.tools.analysis import (
        analyze_project_structure,
        extract_symbols,
    )
    from mcp_server_tree_sitter.tools.ast_operations import get_file_ast
    from mcp_server_tree_sitter.tools.search import search_text
except ImportError as e:
    print(json.dumps({"error": f"mcp_server_tree_sitter not importable: {e}"}),
          file=sys.stderr)
    sys.exit(1)


def _project_for(path: str):
    """Register (idempotently) and return a project for the given root path.

    Uses a deterministic synthetic name so repeat calls don't re-scan, and
    so the project registry stays bounded across sessions.
    """
    root = Path(path).resolve()
    if not root.is_dir():
        raise ValueError(f"path is not a directory: {root}")
    h = hashlib.sha256(str(root).encode()).hexdigest()[:12]
    name = f"cli_{h}"
    registry = api.get_project_registry()
    try:
        return registry.get_project(name)
    except Exception:
        api.register_project(str(root), name=name)
        return registry.get_project(name)


def cmd_analyze(args):
    project = _project_for(args.path)
    return analyze_project_structure(
        project, api.get_language_registry(), args.scan_depth, None,
    )


def cmd_find_text(args):
    project = _project_for(args.path)
    return search_text(
        project,
        args.pattern,
        args.file_pattern,
        args.max_results,
        args.case_sensitive,
        args.whole_word,
        args.use_regex,
        args.context_lines,
    )


def cmd_get_symbols(args):
    project = _project_for(args.path)
    types = args.symbol_types.split(",") if args.symbol_types else None
    return extract_symbols(
        project, args.file_path, api.get_language_registry(), types,
    )


def cmd_get_ast(args):
    project = _project_for(args.path)
    return get_file_ast(
        project,
        args.file_path,
        api.get_language_registry(),
        api.get_tree_cache(),
        max_depth=args.max_depth,
        include_text=args.include_text,
    )


def main():
    p = argparse.ArgumentParser(
        prog="tree-sitter",
        description="Project-aware AST + semantic-search ops "
                    "(re-uses the mcp_server_tree_sitter analyzers).",
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    a = sub.add_parser("analyze", help="Analyze project structure")
    a.add_argument("--path", required=True)
    a.add_argument("--scan-depth", type=int, default=3)
    a.set_defaults(fn=cmd_analyze)

    f = sub.add_parser("find-text", help="Search text across project files")
    f.add_argument("--path", required=True)
    f.add_argument("--pattern", required=True)
    f.add_argument("--file-pattern", default=None)
    f.add_argument("--max-results", type=int, default=100)
    f.add_argument("--case-sensitive", action="store_true")
    f.add_argument("--whole-word", action="store_true")
    f.add_argument("--use-regex", action="store_true")
    f.add_argument("--context-lines", type=int, default=2)
    f.set_defaults(fn=cmd_find_text)

    s = sub.add_parser("get-symbols",
                       help="Extract symbols (functions, classes, etc.) from a file")
    s.add_argument("--path", required=True, help="project root")
    s.add_argument("--file-path", required=True, help="file under project root")
    s.add_argument("--symbol-types", default=None,
                   help="comma-separated subset; default = all")
    s.set_defaults(fn=cmd_get_symbols)

    t = sub.add_parser("get-ast", help="Get AST of a file")
    t.add_argument("--path", required=True, help="project root")
    t.add_argument("--file-path", required=True)
    t.add_argument("--max-depth", type=int, default=10)
    t.add_argument("--include-text", action="store_true")
    t.set_defaults(fn=cmd_get_ast)

    args = p.parse_args()
    try:
        result = args.fn(args)
    except Exception as e:
        print(json.dumps({"error": str(e), "cmd": args.cmd}), file=sys.stderr)
        sys.exit(1)
    json.dump(result, sys.stdout, default=str, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
