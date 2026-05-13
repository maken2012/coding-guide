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
  output_files: [fix-log.jsonl]
  templates: []
  components: [status-report, annotated-pr-review]
---

# /spec-fix — Bug Fix Tracking

## Input
User provides a feature ID and issue description: $ARGUMENTS

## Feature Targeting
- If `$ARGUMENTS` contains a feature ID matching `YYYYMMDD-NNN`, target that feature directory
- Otherwise, scan `.specify/specs/*/` for the most recent feature in implement or later stage

## Prerequisites
- The feature's implement or review phase has started

## Execution Steps

### 1. Read Context
- Read `.feature-state.json` to understand current state
- Read relevant phase documents (spec.html, detail.html, design/) for original requirements
- Analyze the user's issue description

### 2. Diagnose and Locate
- Locate affected files and code based on issue description
- Analyze root cause (requirement gap / implementation error / edge case miss / environment issue)

### 3. Implement Fix
- Modify code or documentation
- Run relevant tests to verify the fix
- If no tests exist, write minimal tests for the fix point

### 4. Record Fix Log
Append to `fix-log.jsonl` in the feature directory (create if not exists):
```json
{"id":1,"ts":"<server time>","issue":"<description>","phase":"<occurred phase>","root_cause":"<root cause>","files_changed":["path1","path2"],"fix_summary":"<summary>","tests":["<test command>"],"status":"fixed"}
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
Root cause: <root cause analysis>
Files: <file list>
Tests: <result>

Fix log: .specify/specs/<feature_id>/fix-log.jsonl
```
