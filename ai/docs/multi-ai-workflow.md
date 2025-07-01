<!--
Author: PB and Claude
Date: Mon 30 Jun 2025
License: (c) HRDAG, 2025, GPL-2 or newer

------
dotfiles/ai/docs/multi-ai-workflow.md
-->

# Multi-AI Workflow Integration

**Purpose**: Guidelines for coordinating multiple AI agents on complex projects.

**Usage**: Reference this document for projects using multiple AI agents with specialized roles.

---

## Agent Roles

### Specialized AI Functions
- **Dev-Claude**: Requirements analysis, human interface, GitHub issue management
- **Dev-Gemini**: Heavy implementation work, large task execution  
- **QA-Claude**: Black box testing, CLI tool validation
- **CI-Claude**: Unit tests, integration tests, automated testing

### Agent Coordination Patterns
- Use shared memory system for context preservation
- Store decisions and approaches for other agents to reference
- Coordinate through GitHub issues for complex workflows
- Maintain consistent behavior standards across all agents

### Workflow Examples
1. **Dev-Claude** translates vague requests → specific GitHub issues
2. **Dev-Gemini** picks up issues and implements
3. **QA-Claude** reviews PRs, files bugs, suggests improvements
4. **CI-Claude** runs full test suite, catches regressions
5. **Memory system** maintains context across all interactions

---

**Import this document in project-specific CLAUDE.md files when using multi-AI workflows.**