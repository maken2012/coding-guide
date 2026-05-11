---
description: "Implementation Plan + Task Breakdown (Spec-Driven Development Step 4)"
---

# /spec-plan — Implementation Plan + Task Breakdown

## Prerequisites (Gate)
1. Read `dashboard-state.json` to get `current_feature`
2. Check all `.feedback.json` files under `design/`, all `verdict` values must be `"approved"`
3. If not passed, refuse to execute

## Execution Steps

### 1. Read Upstream Documents
- `detail.html`, `detail.feedback.json`
- All design documents under `design/` and their feedback
- `.specify/templates/plan-template.html`
- `.specify/templates/tasks-template.html`

### 2. Read Component References
- `.specify/templates/components/implementation-plan.html` — Phased plan pattern
- `.specify/templates/components/triage-board.html` — Task prioritization pattern

### 3. Generate plan.html
Based on plan-template.html, generate technical implementation plan:
- Approach overview
- Phased implementation (referencing implementation-plan component: horizontal timeline + phase cards + file change list)
- Dependency graph
- Risks and mitigations

### 4. Generate tasks.html
Based on tasks-template.html, generate task list:
- Format: `- [ ] T001 [P] [US1] Description — File path`
- Phase arrangement: Setup → Infrastructure → User Stories → Testing → Wrap-up
- Parallelizable marker [P]
- Progress bar

### 5. Generate Feedback Skeleton + Update Dashboard

### 6. Output
```
✅ Implementation plan and task list generated!

📄 Implementation Plan: file:///<absolute-path>/.specify/specs/<current_feature>/plan.html
📄 Task List: file:///<absolute-path>/.specify/specs/<current_feature>/tasks.html
📋 Dashboard: file:///<absolute-path>/.specify/specs/dashboard.html

Please review, then run /spec-implement to start implementation
```
