---
description: "Implementation Plan + Task Breakdown (Spec-Driven Development Step 4)"
agent:
  id: spec-plan
  type: core
  order: 4
  gate: "design/*.feedback.verdict = approved"
  produces_gate: "tasks.feedback.verdict = approved"
  requires_feature: true
  writes_state: true
  output_files: [plan.html, plan.feedback.json, tasks.html, tasks.feedback.json]
  templates: [plan-template.html, tasks-template.html]
  components: [implementation-plan, triage-board, slide-deck]
---

# /spec-plan — Implementation Plan + Task Breakdown

## Prerequisites (Gate)
1. Check all `.feedback.json` files under `design/`, all `verdict` values must be `"approved"`
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

### 2. Read Upstream Documents
- `detail.html`, `detail.feedback.json`
- All design documents under `design/` and their feedback
- `.specify/templates/plan-template.html`
- `.specify/templates/tasks-template.html`

### 3. Read Component References
- `.specify/templates/components/implementation-plan.html` — Phased plan pattern
- `.specify/templates/components/triage-board.html` — Task prioritization pattern

### 4. Generate plan.html
Based on plan-template.html, generate technical implementation plan:
- Approach overview
- Phased implementation (referencing implementation-plan component: horizontal timeline + phase cards + file change list)
- Dependency graph
- Risks and mitigations

### 5. Generate tasks.html
Based on tasks-template.html, generate task list:
- Format: `- [ ] T001 [P] [US1] Description — File path`
- Phase arrangement: Setup → Infrastructure → User Stories → Testing → Wrap-up
- Parallelizable marker [P]
- Progress bar

### 6. Generate Feedback Skeleton + Update State

- Update `.feature-state.json` pipeline status
- Append event to `registry.jsonl`
- Ensure feedback server is running (run `bash .claude/hooks/start-feedback-server.sh` if not)
- **Sync to database**: `curl -s -X POST http://localhost:8421/api/sync`

### 6.1 Reactive Wait for Approval
After generating documents, enter polling mode:
- Use ScheduleWakeup to check `tasks.feedback.json` every 60-120 seconds for `review.verdict` (also check via `curl -s http://localhost:8421/api/phases/<feature_id>` for phase status)
- If `verdict` is `null`, continue waiting. Output: ⏳ Pending review: http://localhost:8421/specs/<current_feature>/tasks.html
- If `verdict` is `"approved"`:
  - Update `.feature-state.json`: set `pipeline.plan.status` to `"approved"`
  - Append `phase_approved` event to `registry.jsonl`
  - Output: ✅ Implementation plan approved. Ready for /spec-implement
  - End polling
- If `verdict` is `"rejected"`:
  - Read `review.feedback` for rejection reason
  - Modify plan.html and/or tasks.html based on feedback
  - Resubmit for approval
  - Output: 🔄 Revised based on feedback, resubmitting for approval

### 7. Output
```
✅ Implementation plan and task list generated!

📄 Implementation Plan: http://localhost:8421/specs/<current_feature>/plan.html
📄 Task List: http://localhost:8421/specs/<current_feature>/tasks.html
📋 Dashboard: http://localhost:8421

⏳ Waiting for approval... (polling tasks.feedback.json)

Next step after approval: /spec-implement
```
