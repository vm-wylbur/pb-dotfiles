# Look at Test Results & Auto-Fix

The test run is complete. Please analyze the recent test results and **automatically implement all fixes you identify**.

## What to do:
1. **Analyze recent logs** in `~/var/log/dsg-testing-*.jsonl` (focus on last 30 minutes)
2. **Identify all issues** from JSON structured logs and error patterns  
3. **Implement fixes immediately** - don't just suggest them, make the changes
4. **Report what you fixed** and any remaining issues

## Your response should include:

### ✅ Working Scenarios
List scenarios that completed successfully

### 🔧 Fixes Applied
For each fix you made:
- What was broken
- Which files you changed  
- What the fix does
- Expected impact

### ❌ Remaining Issues (if any)
Only include issues you **cannot** fix automatically:
- Scenarios still failing after your fixes
- Infrastructure/environment problems requiring manual intervention
- Issues needing user decisions

### 📋 Ready for Next Test
Recommend specific test command to validate your fixes

## Auto-fix Guidelines:
- **Fix all code issues immediately**: missing parameters, wrong paths, syntax errors
- **Update configuration files**: fix paths, variables, command references
- **Don't ask permission**: just implement obvious fixes for clear programming errors
- **Skip only**: infrastructure setup, user environment config, or ambiguous requirements

## Response format:
Lead with what you fixed, not what you found. If everything is working after your fixes, say so and suggest the next test cycle.

Focus on implemented solutions, not analysis. Show file changes made, not problems identified.