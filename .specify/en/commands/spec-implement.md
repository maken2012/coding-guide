---
description: "Development + Testing (Spec-Driven Development Step 5)"
agent:
  id: spec-implement
  type: core
  order: 5
  gate: "tasks.feedback.verdict = approved"
  produces_gate: null
  requires_feature: true
  writes_state: true
  output_files: [test-report.html, test-report.feedback.json]
  templates: [test-report-template.html]
  components: [status-report, annotated-pr-review]
---

# /spec-implement — Development + Testing

## Prerequisites (Gate)
1. `tasks.feedback.verdict === "approved"`
2. If not passed, refuse to execute

## Feature Targeting
- If `$ARGUMENTS` contains a feature ID matching `YYYYMMDD-NNN`, target that feature directory
- Otherwise, scan `.specify/specs/*/` for a `.feature-state.json` where this command's gate condition is met
- If no matching feature found, output an error message

## Execution Steps

### 1. Locate Current Feature
- If $ARGUMENTS contains a feature ID (YYYYMMDD-NNN pattern), use that feature directory
- Otherwise, scan `.specify/specs/*/` for a `.feature-state.json` where the gate condition for THIS command is met
- Read `.feature-state.json` to get feature context

### 2. Load All Design Documents
Read spec, detail, design/*, plan, tasks.

### 3. Implement Task by Task
- Execute in numbered order
- After completing each task: write code + write corresponding unit tests
- Update checkbox in tasks.html to [X]
- Update `.feature-state.json` pipeline status every 3-5 tasks
- Append event to `registry.jsonl` every 3-5 tasks
- Run `.claude/hooks/refresh-dashboard.sh` every 3-5 tasks

### 4. Generate Integration Tests
After all tasks are completed, generate integration tests based on API contracts and interaction flows.

### 5. Generate Test Report
Read `.specify/templates/test-report-template.html`, generate `test-report.html`:
- Test overview (total / passed / failed / skipped)
- Coverage (CSS bar chart by module)
- Unit test results table
- Integration test results table
- Failure details (if any)

### 5.1 Reactive Wait for Approval
After generating test report, enter polling mode:
- Use ScheduleWakeup to check `test-report.feedback.json` every 60-120 seconds for `review.verdict`
- If `verdict` is `null`, continue waiting. Output: ⏳ Pending review: file:///.../test-report.html
- If `verdict` is `"approved"`:
  - Update `.feature-state.json`: set `pipeline.implement.status` to `"approved"`
  - Append `phase_approved` event to `registry.jsonl`
  - Output: ✅ Implementation approved. Ready for /spec-review
  - End polling
- If `verdict` is `"rejected"`:
  - Read `review.feedback` for rejection reason
  - Fix code/tests based on feedback, regenerate test-report.html
  - Resubmit for approval
  - Output: 🔄 Revised based on feedback, resubmitting for approval

### 6. Output
```
✅ Development and testing completed!

📄 Test Report: file:///<absolute-path>/.specify/specs/<current_feature>/test-report.html
📋 Dashboard: file:///<absolute-path>/.specify/specs/dashboard.html

⏳ Waiting for approval... (polling test-report.feedback.json)

Next step after approval: /spec-review
```
