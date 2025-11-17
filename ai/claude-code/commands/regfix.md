name: regfix
description: guidelines for fixing the scottools monitoring system output
content: |
  Guiderail: Fix Assessment Protocol

  Before any fix implementation, ALWAYS ask:

  1. Data vs Logic Issue?
  - Prompt: "Is this a data classification problem or a logic problem?"
  - Data issues: Wrong categories, missing patterns, incorrect mappings
  - Logic issues: Broken algorithms, missing conditions, faulty calculations
  - If you think it's a logic issue, think twice! Maybe it is, but if it's a special case, it's probably not special.

  2. Source of Truth Analysis
  - Prompt: "Where does this classification/behavior originate?"
  - Database-driven: Look for config tables, pattern matching, lookup tables
  - Code-driven: Look for hardcoded logic, algorithms, business rules

  3. Evidence-Based Assessment
  - Prompt: "What evidence shows this is code vs database?"
  - Check for: "DATABASE-DRIVEN", lookup functions, cache loading
  - Check for: hardcoded patterns, switch statements, algorithmic logic

  4. Impact Scope Analysis
  - Prompt: "Does this affect all similar items or just specific ones?"
  - Database fix: Usually affects categories/patterns (all GPU metrics)
  - Code fix: Usually affects behavior/logic (calculation methods)

  5. Workflow
  - Get new fixes - the user will give these in natural language
  - Check existing JSON - what's the last run? From /tmp/scott_validation_final.json
  - Make tests - Create YAML tests that verify the % formatting                                                                                           │ │
  - Run validation to see tests fail `uv run python tests/run_validation_tests.py` IN BACKGROUND with the correct json
  - Make fixes - Update database metric types or formatting logic                                                                                         │ │
  - Run validation - Check if tests pass                                                                                                                  │ │
  - If tests fail, redo fixes; if tests pass, end

6. Test Infrastructure
  - Don't reinvent anything! use these tools
  - remember `uv run pytest|python` don't run naked python
│ - `tests/run_validation_tests.py` - Comprehensive regression tests with diagnostic functions                                                              │ │
│ - `tests/validation_fixes.yml` - YAML-based test definitions with JSONPath assertions                                                                     │ │
│ - Diagnostic pattern testing - The excellent `diagnose_search_patterns()` function                                                                        │ │
│ - `ValidationTestRunner` class - YAML/JSON test framework

Systematic Assessment Prompt:

  STOP: Before implementing any fix, answer these questions:
  - Where is the source of truth for this behavior?
  - Is this a data/configuration issue or a code logic issue?
  - What evidence indicates database vs code fix?
  - Would this fix affect similar items consistently?

  Only proceed after explicitly answering all four questions.
