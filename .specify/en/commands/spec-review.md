---
description: "Code Review + Deployment Plan (Spec-Driven Development Step 6)"
agent:
  id: spec-review
  type: core
  order: 6
  gate: "code changes exist"
  produces_gate: null
  requires_feature: true
  writes_state: true
  output_files: [review.html, review.feedback.json, deploy-plan.html, deploy-plan.feedback.json]
  templates: [review-template.html, deploy-plan-template.html]
  components: [annotated-pr-review, pr-writeup, flowchart-diagram, feature-flags-editor]
---

# /spec-review — Review + Deployment

## Prerequisites
Code changes exist

## Feature Targeting
- If `$ARGUMENTS` contains a feature ID matching `YYYYMMDD-NNN`, target that feature directory
- Otherwise, scan `.specify/specs/*/` for a `.feature-state.json` where this command's gate condition is met
- If no matching feature found, output an error message

## Execution Steps

### 1. Locate Current Feature
- If $ARGUMENTS contains a feature ID (YYYYMMDD-NNN pattern), use that feature directory
- Otherwise, scan `.specify/specs/*/` for a `.feature-state.json` where the gate condition for THIS command is met
- Read `.feature-state.json` to get feature context

### 2. Detect Changes
Run `git diff` to identify the scope of changes.

### 3. Generate review.html
Read `review-template.html` and `annotated-pr-review.html` component:
- Review summary (Critical/High/Medium/Low counts)
- File change list
- Per-file review (with annotations, severity, suggestions, agree/disagree options)
- Action items summary

### 4. Conditionally Generate deploy-plan.html
AI determines whether deployment is involved (new configuration, database migration, new dependencies, feature flags, etc.):
- If yes → Read `deploy-plan-template.html`, generate `deploy-plan.html`
- Includes: Deployment architecture diagram, environment configuration, database migration, dependency components, initialization scripts, feature flags, rollback plan
- Referenced components: `flowchart-diagram` (deployment pipeline), `feature-flags-editor` (flag configuration)

### 5. Update State
- Update `.feature-state.json` pipeline status
- Append event to `registry.jsonl`
- Ensure feedback server is running (run `bash .claude/hooks/start-feedback-server.sh` if not)
- **Sync to database**: `curl -s -X POST http://localhost:8421/api/sync`

### 5.1 Reactive Wait for Approval
After generating review report, enter polling mode:
- Use ScheduleWakeup to check `review.feedback.json` every 60-120 seconds for `review.verdict` (also check via `curl -s http://localhost:8421/api/phases/<feature_id>` for phase status)
- If `verdict` is `null`, continue waiting. Output: ⏳ Pending review: http://localhost:8421/specs/<current_feature>/review.html
- If `verdict` is `"approved"`:
  - Update `.feature-state.json`: set `pipeline.review.status` to `"approved"`
  - Append `lifecycle_complete` event to `registry.jsonl`
  - Output: 🎉 Feature development lifecycle complete!
  - End polling
- If `verdict` is `"rejected"`:
  - Read `review.feedback` for rejection reason
  - Modify review.html and/or code based on feedback
  - Resubmit for approval
  - Output: 🔄 Revised based on feedback, resubmitting for approval

### 6. Output
```
✅ Review report generated!

📄 Review Report: http://localhost:8421/specs/<current_feature>/review.html
📄 Deployment Plan: http://localhost:8421/specs/<current_feature>/deploy-plan.html
📋 Dashboard: http://localhost:8421

⏳ Waiting for approval... (polling review.feedback.json)
```
