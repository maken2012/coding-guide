---
description: "Bug Fix Tracking (Spec-Driven Development Fix Command)"
agent:
  id: spec-fix
  type: auxiliary
  order: null
  gate: "implement.status != not_started"
  produces_gate: null
  requires_feature: true
  writes_state: true
  output_files: [fix-log.jsonl, fix-plan.html]
  templates: []
  components: [status-report, annotated-pr-review]
---

# /spec-fix — Bug Fix Tracking

## Input
User provides a feature ID and issue description: $ARGUMENTS

If `$ARGUMENTS` starts with `--plan`, force planning mode (see below).

## Feature Targeting
- If `$ARGUMENTS` contains a feature ID matching `YYYYMMDD-NNN`, target that feature directory
- Otherwise, scan `.specify/specs/*/` for the most recent feature in implement or later stage

## Prerequisites
- The feature's implement or review phase has started

## Execution Steps

### 1. Diagnose and Classify

- Read `.feature-state.json` to understand current state
- Read `spec.html` and `detail.html` for original requirements
- Locate affected files and code based on issue description
- Analyze root cause (requirement gap / implementation error / edge case miss / environment issue)
- **Assess complexity** to determine fix path:

| Signal | Level | Path |
|--------|-------|------|
| 1-2 files changed, no cascading impact | Simple | Quick fix |
| 3+ files, or cross-module | Medium | Planned fix |
| Data migration / architecture change / perf regression | Complex | Planned fix |
| User specified `--plan` | Any | Planned fix |

### 2A. Quick Fix (simple issues)

Skip directly to step 3 to implement.

### 2B. Planned Fix (medium/complex issues)

Generate `fix-plan.html` with the following sections:

#### 2B.1 Problem Description
- Symptom (what the user sees)
- Root cause (why it happens)
- Impact scope (which features/modules are affected)

#### 2B.2 Fix Strategy
- Fix approach (at least 2 options compared, with recommendation)
- File list with modification summary per file
- Risk assessment (potential side effects of the fix)
- Rollback plan (if the fix introduces new issues)

#### 2B.3 Verification Plan
- Fix-point tests
- Regression test scope (ensure fix doesn't break other features)
- Manual verification checklist

#### 2B.4 Wait for Approval

After generating the fix plan, enter wait-for-approval mode:
- Output: 📄 Fix plan pending review: http://localhost:8421/specs/<feature_id>/fix-plan.html
- Wait for user to confirm the plan (via fix-plan.html or verbally)
- After confirmation, proceed to step 3

### 3. Implement Fix

- Follow the plan from fix-plan.html (or diagnosis results for quick fixes)
- Modify code or documentation
- Run relevant tests to verify the fix
- Run regression tests (if applicable)
- If no tests exist, write minimal tests for the fix point

### 4. Record Fix Log
Append to `fix-log.jsonl` in the feature directory (create if not exists):
```json
{"id":1,"ts":"<server time>","issue":"<description>","severity":"<simple|medium|complex>","phase":"<occurred phase>","root_cause":"<root cause>","files_changed":["path1","path2"],"fix_summary":"<summary>","has_plan":true,"tests":["<test command>"],"regression":"<regression test result>","status":"fixed"}
```

ID = existing line count + 1.

### 5. Update State
- Update `.feature-state.json`: increment `fix_count`, set `last_fix` to current time
- Ensure feedback server is running (`bash .claude/hooks/start-feedback-server.sh`)
- **Sync to database**: `curl -s -X POST http://localhost:8421/api/sync`

### 6. Output
```
🔧 Fix archived!

Feature: <feature name>
Fix #<N>: <issue description>
Severity: Simple / Medium / Complex
Root cause: <root cause analysis>
Files: <file list>
Tests: <result>
Regression: <regression test result>

Fix log: .specify/specs/<feature_id>/fix-log.jsonl
```
