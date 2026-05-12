---
description: "Detailed Requirements (Spec-Driven Development Step 2)"
agent:
  id: spec-detail
  type: core
  order: 2
  gate: "spec.feedback.verdict = approved"
  produces_gate: "detail.feedback.verdict = approved"
  requires_feature: true
  writes_state: true
  output_files: [detail.html, detail.feedback.json]
  templates: [detail-template.html]
  components: [flowchart-diagram, exploration-approaches, feature-explainer]
---

# /spec-detail — Detailed Requirements

## Prerequisites (Gate)
`spec.feedback.verdict === "approved"`

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
- `spec.html`, `spec.feedback.json`
- `.specify/templates/detail-template.html`
- `.specify/templates/components/flowchart-diagram.html` (flowchart reference)
- `.specify/templates/components/exploration-approaches.html` (approach comparison reference)

### 3. Generate detail.html
Based on detail-template.html, including:
- **Input/Output Definitions**: Table format — Field Name / Type / Required / Description
- **Interaction Flow**: Automatically generate flowchart based on project type (referencing flowchart-diagram component pattern)
- **Business Rules**: Condition → Action format rule list
- **Exception Handling**: Error Code / Scenario / Response / Retry Strategy table
- **Constraints**: Technical constraints, business constraints

AI intelligently decides based on project type:
- Has frontend interactions? → Generate interaction flowchart
- Has complex business logic? → Generate sequence diagram / state machine
- Has multiple approach requirements? → Embed approach comparison

### 4. Generate Feedback Skeleton + Update State

- Update `.feature-state.json` pipeline status
- Append event to `registry.jsonl`
- Ensure feedback server is running (run `bash .claude/hooks/start-feedback-server.sh` if not)

### 4.1 Reactive Wait for Approval
After generating documents, enter polling mode:
- Use ScheduleWakeup to check `detail.feedback.json` every 60-120 seconds for `review.verdict` (also check via `curl -s http://localhost:8421/api/phases/<feature_id>` for phase status)
- If `verdict` is `null`, continue waiting. Output: ⏳ Pending review: http://localhost:8421/specs/<current_feature>/detail.html
- If `verdict` is `"approved"`:
  - Update `.feature-state.json`: set `pipeline.detail.status` to `"approved"`
  - Append `phase_approved` event to `registry.jsonl`
  - Output: ✅ Detailed requirements approved. Ready for /spec-design
  - End polling
- If `verdict` is `"rejected"`:
  - Read `review.feedback` for rejection reason
  - Modify detail.html based on feedback
  - Resubmit for approval
  - Output: 🔄 Revised based on feedback, resubmitting for approval

### 5. Output
```
✅ Detailed requirements generated!

📄 Detailed Requirements: http://localhost:8421/specs/<current_feature>/detail.html
📋 Dashboard: http://localhost:8421

⏳ Waiting for approval... (polling detail.feedback.json)

Next step after approval: /spec-design
```
