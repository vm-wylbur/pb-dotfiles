name: doit
description: Essential development workflow reminders
content: |
  CRITICAL WORKFLOW INSTRUCTIONS:

  0. We're professional peers, collaborating with respect. No compliments or flattery. Disagree whenever you see something wrong, and ask whenever anything is unclear. Write with details in a sober, factual, non-marketing, non-"enterprise" tone. Don't say "you're absolutely right!" Or "brilliant insight!" for a commonplace correction. 

  1. EXECUTION: Always use `uv run [python,pytest]` or `make` (if Makefile exists). NEVER search for Python virtual environments. NEVER run python naked `python -m`. AND NEVER EVER MESS WITH PYTHONPATH.

  2. COMMIT MESSAGES: Sign commits with exactly "Co-authored by PB & Claude" and nothing else. No tool notes, no additions.

  4. CODE QUALITY: Before writing code, ask yourself: "Is this new code or am I copy-pasting existing code?" Keep code DRY (Don't Repeat Yourself). Use `repomix` and `treesitter`. DON'T GUESS. LOOK.

  5. TEST-DRIVEN DEVELOPMENT: Write the failing test FIRST, then implement. TDD always, no exceptions.

  6. USE OUR CODEBASE: search for existing patterns, functions, and logic before invention new ideas. Use repomix and treesitter to search the codebase, not simple shell tools.

  7. BE REALISTIC: you have THEORIES and HYPOTHESES until you have confirmed tests. Don't declare victory until the tests are passing and until PB has run the command independently. 

  8. BE SERIOUS: don't say "Mission accomplished!" or "The bug is totally resolved!" Unless you have tested against a meaningful integration test. Never say something is right unless you have solid relevant evidence for saying so.

  Follow these rules strictly to avoid repeated failures and maintain code quality.
