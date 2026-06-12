"""
Author: PB and cc-dots
Date: 2026-06-11
License: (c) HRDAG, 2026, GPL-2 or newer

---
dotfiles/ai/claude-code/lib/grep-replay-impl.py

Phase 0 of the tree-sitter adoption plan
(docs/tree-sitter-adoption-plan-20260611.md): replay identifier-shaped
greps from session transcripts through prototype find-definition /
find-callers verbs, and measure whether tree-sitter would have been
strictly better at the moments the agent actually reached for grep.

Pre-registered decision rule: if tree-sitter is strictly better on
< 30% of sampled symbol-shaped greps, PARK the adoption effort.
"strictly better" = definition found AND materially fewer hits than
the grep's observed output (see verdict()).

Implementation note: builds DIRECTLY on tree_sitter 0.25 +
tree_sitter_language_pack 1.8 (std Parser/Query/QueryCursor over pack
grammars). The vendored mcp_server_tree_sitter 0.7.0 AST path is
broken against these versions (its parsers want str, its query
helpers want the pre-0.25 captures API) — only its pure-python
search_text works, which is exactly the grep-shaped verb we are
trying to replace. self_check() asserts the API surface at startup so
version drift aborts loudly instead of silently zeroing the indexes.

Honest caveats, recorded in the output: replay drift (repos changed
since the transcript was written), per-host transcript retention
window, lib-from-lib greps (inside heredocs) are skipped, and
grep_lines is the output the agent actually SAW (post-pipe, post
-c/-l, post-truncation) — faithful to the registered rule, but it
understates the noise of greps the agent had already narrowed.

Run via grep-replay.sh, which supplies the ~/.venv-mcp python.

Usage:
  grep-replay.sh [--since YYYY-MM-DD] [--rows /path/rows.jsonl] [--verbose]
"""

import argparse
import json
import re
import shlex
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

import tree_sitter as ts
import tree_sitter_language_pack as tlp

IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*\Z")
GREP_CMDS = {"grep", "egrep", "fgrep", "rg"}
OPERATORS = {"&&", "||", "|", "|&", ";", "&"}
PARENS = {"(", ")", "{", "}"}
REDIRS = {">", ">>", "<", ">&", "&>", "<<<", ">|"}

# grep/rg flags that consume the next token as a value
VALUE_FLAGS = {
    "-e",
    "-f",
    "-m",
    "-A",
    "-B",
    "-C",
    "-d",
    "-D",
    "-g",
    "-t",
    "-T",
    "-j",
    "-M",
    "--include",
    "--exclude",
    "--exclude-dir",
    "--max-count",
    "--glob",
    "--type",
    "--type-not",
    "--context",
    "--after-context",
    "--before-context",
    "--max-depth",
    "--threads",
    "--regexp",
    "--file",
    "--max-columns",
}
# rg-only: -r is --replace and takes a value (in grep, -r is recursive)
RG_VALUE_FLAGS = VALUE_FLAGS | {"-r", "--replace"}

# tree-sitter query patterns per language; each compiled independently
# so a pattern that doesn't fit the installed grammar is skipped, not fatal
DEF_QUERIES = {
    "python": [
        "(function_definition name: (identifier) @name)",
        "(class_definition name: (identifier) @name)",
        # module-level constants only — local assignments are not definitions
        "(module (expression_statement (assignment left: (identifier) @name)))",
    ],
    "bash": [
        "(function_definition name: (word) @name)",
        "(program (variable_assignment name: (variable_name) @name))",
    ],
    "javascript": [
        "(function_declaration name: (identifier) @name)",
        "(class_declaration name: (identifier) @name)",
        "(method_definition name: (property_identifier) @name)",
        "(variable_declarator name: (identifier) @name value: (arrow_function))",
    ],
    "typescript": [
        "(function_declaration name: (identifier) @name)",
        "(class_declaration name: (type_identifier) @name)",
        "(class_declaration name: (identifier) @name)",
        "(method_definition name: (property_identifier) @name)",
        "(interface_declaration name: (type_identifier) @name)",
        "(type_alias_declaration name: (type_identifier) @name)",
        "(enum_declaration name: (identifier) @name)",
        "(variable_declarator name: (identifier) @name value: (arrow_function))",
        "(program (lexical_declaration (variable_declarator name: (identifier) @name)))",
        "(export_statement (lexical_declaration (variable_declarator name: (identifier) @name)))",
    ],
    "go": [
        "(function_declaration name: (identifier) @name)",
        "(method_declaration name: (field_identifier) @name)",
        "(type_declaration (type_spec name: (type_identifier) @name))",
    ],
    "rust": [
        "(function_item name: (identifier) @name)",
        "(struct_item name: (type_identifier) @name)",
        "(enum_item name: (type_identifier) @name)",
    ],
}
CALL_QUERIES = {
    "python": [
        "(call function: (identifier) @name)",
        "(call function: (attribute attribute: (identifier) @name))",
    ],
    "bash": [
        "(command name: (command_name (word) @name))",
    ],
    "javascript": [
        "(call_expression function: (identifier) @name)",
        "(call_expression function: (member_expression property: (property_identifier) @name))",
    ],
    "typescript": [
        "(call_expression function: (identifier) @name)",
        "(call_expression function: (member_expression property: (property_identifier) @name))",
    ],
    "go": [
        "(call_expression function: (identifier) @name)",
        "(call_expression function: (selector_expression field: (field_identifier) @name))",
    ],
    "rust": [
        "(call_expression function: (identifier) @name)",
    ],
}
# tsx is a distinct grammar (JSX-capable) that accepts the typescript queries;
# alias the QUERY SOURCE, never the parser — the typescript grammar cannot
# parse JSX and would silently drop defs in .tsx files as ERROR nodes
DEF_QUERIES["tsx"] = DEF_QUERIES["typescript"]
CALL_QUERIES["tsx"] = CALL_QUERIES["typescript"]
SUPPORTED = set(DEF_QUERIES)

MAX_FILE_BYTES = 512 * 1024
MAX_SUPPORTED_FILES_PER_REPO = 8000


def self_check():
    """Abort loudly if the tree-sitter API surface drifted.

    Every query/parse call in RepoIndex swallows exceptions per file;
    under version drift that would silently zero the indexes and print
    a confident ~0% win rate. Assert the whole path works first.
    """
    lang = tlp.get_language("python")
    tree = ts.Parser(lang).parse(b"def _gr_probe():\n    pass\n")
    q = ts.Query(lang, "(function_definition name: (identifier) @name)")
    caps = ts.QueryCursor(q).captures(tree.root_node)
    names = [n.text.decode() for n in caps.get("name", [])]
    if names != ["_gr_probe"]:
        sys.exit(f"self-check failed: tree-sitter API drift (got {names})")


# ---------------------------------------------------------------- extract


def iter_transcript_events(projects_root: Path, stats: Counter):
    """Yield (bash_calls, results) per transcript.

    bash_calls: list of dicts {id, command, cwd, ts, session}
    results: dict tool_use_id -> result text
    Also counts native Grep tool_use into stats so the Bash-only scope
    stays self-verifying (0 on this host as of 2026-06-11).
    """
    for f in sorted(projects_root.glob("*/*.jsonl")):
        calls, results = [], {}
        try:
            fh = f.open(encoding="utf-8", errors="replace")
        except OSError:
            continue
        with fh:
            for line in fh:
                try:
                    e = json.loads(line)
                except (json.JSONDecodeError, ValueError):
                    continue
                etype = e.get("type")
                msg = e.get("message") or {}
                content = msg.get("content")
                if not isinstance(content, list):
                    continue
                if etype == "assistant":
                    for c in content:
                        if not (isinstance(c, dict) and c.get("type") == "tool_use"):
                            continue
                        if c.get("name") == "Grep":
                            stats["native_grep_tool_calls"] += 1
                        elif c.get("name") == "Bash":
                            calls.append(
                                {
                                    "id": c.get("id", ""),
                                    "command": (c.get("input") or {}).get("command", ""),
                                    "cwd": e.get("cwd", ""),
                                    "ts": (e.get("timestamp") or "")[:10],
                                    "session": e.get("sessionId", f.stem),
                                }
                            )
                elif etype == "user":
                    for c in content:
                        if isinstance(c, dict) and c.get("type") == "tool_result":
                            rc = c.get("content")
                            if isinstance(rc, list):
                                text = "\n".join(
                                    x.get("text", "") for x in rc if isinstance(x, dict)
                                )
                            else:
                                text = rc if isinstance(rc, str) else ""
                            results[c.get("tool_use_id", "")] = text
        yield calls, results


def strip_redirections(tokens):
    """Drop redirection operators and their targets (e.g. 2 > /dev/null)."""
    out, i = [], 0
    while i < len(tokens):
        tok = tokens[i]
        if tok in REDIRS:
            i += 2  # skip the operator and its target
            continue
        if tok.isdigit() and i + 1 < len(tokens) and tokens[i + 1] in REDIRS:
            i += 3  # fd number, operator, target
            continue
        out.append(tok)
        i += 1
    return out


def split_segments(command):
    """Tokenize a shell command and split on operators.

    Returns list of (tokens, preceded_by_pipe). Heredoc commands are
    skipped entirely (greps inside heredoc bodies are not tool-choice
    moments). Subshell parens are dropped so `(cd X && grep ...)`
    still gets cd tracking; redirections are stripped per segment.
    """
    if "<<" in command:
        return []
    try:
        lex = shlex.shlex(command, posix=True, punctuation_chars=True)
        lex.whitespace_split = True
        tokens = list(lex)
    except ValueError:
        return []
    segments, cur, prev_op = [], [], None
    for tok in tokens:
        if tok in OPERATORS:
            if cur:
                segments.append((cur, prev_op in ("|", "|&")))
            cur, prev_op = [], tok
        elif tok in PARENS:
            continue
        else:
            cur.append(tok)
    if cur:
        segments.append((cur, prev_op in ("|", "|&")))
    return [(strip_redirections(toks), piped) for toks, piped in segments]


def parse_grep_segment(tokens):
    """Return (pattern, path_args, recursive) or None if not a grep/rg call."""
    if not tokens:
        return None
    prog = Path(tokens[0]).name
    if prog not in GREP_CMDS:
        return None
    value_flags = RG_VALUE_FLAGS if prog == "rg" else VALUE_FLAGS
    pattern, paths, recursive = None, [], prog == "rg"
    i = 1
    while i < len(tokens):
        tok = tokens[i]
        if tok in ("-e", "--regexp") and i + 1 < len(tokens):
            pattern = tokens[i + 1]
            i += 2
            continue
        if tok in value_flags and i + 1 < len(tokens):
            i += 2
            continue
        if tok.startswith("-") and tok != "-":
            # grep short-flag cluster: -rn, -R — recursive search
            if prog != "rg" and re.match(r"-[a-zA-Z]*[rR]", tok):
                recursive = True
            if tok == "--recursive":
                recursive = True
            i += 1
            continue
        if pattern is None:
            pattern = tok
        else:
            paths.append(tok)
        i += 1
    if pattern is None:
        return None
    return pattern, paths, recursive


def enclosing_repo(path: Path):
    p = path if path.is_dir() else path.parent
    for cand in (p, *p.parents):
        if (cand / ".git").exists():
            return cand
    return None


def extract_grep_calls(projects_root: Path, since: str):
    """Yield one row per identifier-shaped grep call found in transcripts."""
    stats = Counter()
    rows = []
    for calls, results in iter_transcript_events(projects_root, stats):
        for call in calls:
            if since and call["ts"] and call["ts"] < since:
                continue
            eff_cwd = Path(call["cwd"] or "/")
            cmd_row_start = len(rows)
            cmd_grep_segs = 0
            for tokens, piped in split_segments(call["command"]):
                if not tokens:
                    continue
                if tokens[0] == "cd" and len(tokens) > 1:
                    try:
                        eff_cwd = (eff_cwd / Path(tokens[1]).expanduser()).resolve()
                    except OSError:
                        pass
                    continue
                parsed = parse_grep_segment(tokens)
                if not parsed:
                    continue
                stats["grep_segments"] += 1
                cmd_grep_segs += 1
                pattern, path_args, recursive = parsed
                if piped and not path_args:
                    stats["skipped_pipe_filter"] += 1
                    continue
                if not path_args and not recursive:
                    # bare non-recursive grep with no path reads stdin
                    stats["skipped_stdin_grep"] += 1
                    continue
                if not IDENT_RE.fullmatch(pattern):
                    stats["skipped_non_identifier"] += 1
                    continue
                targets = [(eff_cwd / Path(a).expanduser()) for a in path_args] or [eff_cwd]
                try:
                    targets = [t.resolve() for t in targets]
                except OSError:
                    pass
                existing = [t for t in targets if t.exists()]
                repo = None
                for t in existing:
                    repo = enclosing_repo(t)
                    if repo:
                        break
                text = results.get(call["id"], "")
                grep_lines = len([ln for ln in text.splitlines() if ln.strip()])
                stats["identifier_greps"] += 1
                rows.append(
                    {
                        "ts": call["ts"],
                        "session": call["session"],
                        "pattern": pattern,
                        "cmd": call["command"][:200],
                        "paths": [str(t) for t in targets],
                        "repo": str(repo) if repo else None,
                        "target_state": "ok"
                        if repo
                        else ("not-a-repo" if existing else "path-gone"),
                        "grep_lines": grep_lines,
                    }
                )
            for r in rows[cmd_row_start:]:
                r["multi_grep_cmd"] = cmd_grep_segs > 1
    return rows, stats


# ----------------------------------------------------------------- replay


class RepoIndex:
    """Per-repo symbol index: one parse per supported file, defs + calls."""

    def __init__(self, root: Path, verbose=False):
        self.root = root
        self.defs = defaultdict(list)  # name -> [(relpath, line)]
        self.calls = defaultdict(list)
        self.supported_files = 0
        self.git_ok = False
        self.parsers, self.queries = {}, {}
        self._build(verbose)

    def _lang_tools(self, lang):
        if lang not in self.parsers:
            tslang = tlp.get_language(lang)
            self.parsers[lang] = ts.Parser(tslang)
            compiled = []
            for patterns in (DEF_QUERIES[lang], CALL_QUERIES[lang]):
                qs = []
                for pat in patterns:
                    try:
                        qs.append(ts.Query(tslang, pat))
                    except Exception:
                        pass
                compiled.append(qs)
            self.queries[lang] = tuple(compiled)
        return self.parsers[lang], self.queries[lang]

    def _build(self, verbose):
        try:
            out = subprocess.run(
                ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
                cwd=self.root,
                capture_output=True,
                timeout=30,
            )
            if out.returncode != 0:
                return
            files = out.stdout.decode("utf-8", "replace").split("\0")
            self.git_ok = True
        except (OSError, subprocess.TimeoutExpired):
            return
        for rel in files:
            if not rel:
                continue
            if self.supported_files >= MAX_SUPPORTED_FILES_PER_REPO:
                break
            try:
                lang = tlp.detect_language_from_path(rel)
            except Exception:
                continue
            if lang not in SUPPORTED:
                continue
            fp = self.root / rel
            try:
                if not fp.is_file() or fp.stat().st_size > MAX_FILE_BYTES:
                    continue
                src = fp.read_bytes()
            except OSError:
                continue
            parser, (qdefs, qcalls) = self._lang_tools(lang)
            try:
                tree = parser.parse(src)
            except Exception:
                continue
            self.supported_files += 1
            for qlist, store in ((qdefs, self.defs), (qcalls, self.calls)):
                for q in qlist:
                    try:
                        caps = ts.QueryCursor(q).captures(tree.root_node)
                    except Exception:
                        continue
                    for node in caps.get("name", []):
                        name = node.text.decode("utf-8", "replace")
                        store[name].append((rel, node.start_point[0] + 1))
        if verbose:
            print(
                f"  indexed {self.root} ({self.supported_files} files, {len(self.defs)} def names)",
                file=sys.stderr,
            )


def verdict(row):
    """Apply the pre-registered comparison to one replayed row.

    Registered rule: 'strictly better' = returns the definition/callers
    with materially less noise than the grep actually produced. So any
    hit (def or caller) counts; materiality = at least 3 fewer lines,
    or half the grep's output or less.
    """
    if row["repo"] is None:
        return row["target_state"]  # path-gone | not-a-repo
    if not row["git_ok"]:
        return "git-fail"
    if row["supported_files"] == 0:
        return "no-coverage"
    if row["grep_lines"] == 0:
        return "grep-empty"
    d, c, g = row["def_hits"], row["call_hits"], row["grep_lines"]
    total = d + c
    if total > 0:
        material = (g - total >= 3) or (g >= 2 * total)
        return "win" if material else "tie"
    return "loss"


# ------------------------------------------------------------------ main


def main():
    ap = argparse.ArgumentParser(
        description="Replay identifier-shaped greps from session transcripts "
        "through prototype tree-sitter find-definition/find-callers and "
        "report the win rate against the pre-registered 30% gate.",
    )
    ap.add_argument("--projects", default=str(Path.home() / ".claude/projects"))
    ap.add_argument("--since", default="")
    ap.add_argument("--rows", default="", help="write per-call JSONL here")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    self_check()
    rows, stats = extract_grep_calls(Path(args.projects), args.since)
    print(
        f"extracted: {stats['grep_segments']} grep segments, "
        f"{stats['identifier_greps']} identifier-shaped "
        f"(skipped: {stats['skipped_non_identifier']} non-identifier, "
        f"{stats['skipped_pipe_filter']} pipe-filters, "
        f"{stats['skipped_stdin_grep']} stdin-greps; "
        f"native Grep tool calls seen: {stats['native_grep_tool_calls']})",
        file=sys.stderr,
    )

    indexes = {}
    for row in rows:
        repo = row["repo"]
        if repo and repo not in indexes:
            indexes[repo] = RepoIndex(Path(repo), verbose=args.verbose)
        idx = indexes.get(repo)
        sym = row["pattern"]
        row["supported_files"] = idx.supported_files if idx else 0
        row["git_ok"] = idx.git_ok if idx else False
        row["def_hits"] = len(idx.defs.get(sym, [])) if idx else 0
        row["call_hits"] = len(idx.calls.get(sym, [])) if idx else 0
        # def_sites feed the hand-verification spot-checks in the report
        row["def_sites"] = idx.defs.get(sym, [])[:5] if idx else []
        row["verdict"] = verdict(row)

    if args.rows:
        with open(args.rows, "w", encoding="utf-8") as fh:
            for row in rows:
                fh.write(json.dumps(row) + "\n")

    def rate(rs, label):
        by = Counter(r["verdict"] for r in rs)
        decided = sum(by[v] for v in ("win", "tie", "loss", "no-coverage"))
        if decided:
            print(f"{label}: {by['win']}/{decided} = {by['win'] / decided:.0%}")
        return by

    by_verdict = Counter(r["verdict"] for r in rows)
    print(f"\nn={len(rows)} identifier-shaped grep calls; verdicts: {dict(by_verdict)}")
    rate(rows, "WIN RATE (pre-registered; gate: park if < 30%)")
    rate(
        [r for r in rows if r["verdict"] in ("win", "tie", "loss")],
        "  sensitivity: code repos only (excl. no-coverage)",
    )
    rate(
        [r for r in rows if not r.get("multi_grep_cmd")],
        "  sensitivity: single-grep commands only (clean grep_lines)",
    )
    seen, uniq = set(), []
    for r in rows:
        k = (r["repo"], r["pattern"])
        if k not in seen:
            seen.add(k)
            uniq.append(r)
    rate(uniq, "  sensitivity: unique (repo, symbol) pairs")
    defrows = [dict(r, call_hits=0) for r in rows]
    for r in defrows:
        r["verdict"] = verdict(r)
    rate(defrows, "  sensitivity: def-anchored only (callers don't count)")

    repo_counter = Counter((Path(r["repo"]).name if r["repo"] else "-", r["verdict"]) for r in rows)
    print("\nper-repo breakdown (repo, verdict, n):")
    for (repo, v), n in sorted(repo_counter.items()):
        print(f"  {repo:30s} {v:12s} {n}")


if __name__ == "__main__":
    main()
