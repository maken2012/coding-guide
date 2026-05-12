---
description: "Architecture Selection + High-Level Requirements (Spec-Driven Development Step 1)"
agent:
  id: spec-init
  type: core
  order: 1
  gate: null
  produces_gate: "spec.feedback.verdict = approved"
  requires_feature: false
  writes_state: true
  output_files: [spec.html, spec.feedback.json, arch-diagram.html]
  templates: [spec-template.html]
  components: [exploration-approaches, exploration-visual-designs, flowchart-diagram]
---

# /spec-init — Architecture Selection + High-Level Requirements

## Input
User provides a feature description text: $ARGUMENTS

## Feature Targeting
- If `$ARGUMENTS` contains a feature ID matching `YYYYMMDD-NNN`, target that feature directory
- Otherwise, scan `.specify/specs/*/` for a `.feature-state.json` where this command's gate condition is met
- If no matching feature found, output an error message

## Prerequisites
- `.specify/constitution.md` exists

## Execution Steps

### 1. Read Constitution and Templates
- Read `.specify/constitution.md`
- Read `.specify/templates/spec-template.html`

### 2. Generate Feature Directory
- Scan `.specify/specs/` for today's directories (format `YYYYMMDD-NNN`), today's max sequence +1, reset to 001 each day
- Create `.specify/specs/YYYYMMDD-NNN-<name>/`

### 2.1 Initialize Feature State
Create `.feature-state.json` in the feature directory:
```json
{
  "id": "YYYYMMDD-NNN-<name>",
  "name": "<feature name>",
  "created_at": "<ISO timestamp>",
  "pipeline": {
    "spec": { "status": "in_progress", "artifact": "spec.html" },
    "detail": { "status": "not_started" },
    "design": { "status": "not_started" },
    "plan": { "status": "not_started" },
    "implement": { "status": "not_started" },
    "review": { "status": "not_started" }
  },
  "agent_session": null,
  "agent_since": null
}
```

Append an event to `.specify/specs/registry.jsonl` (create if not exists):
```
{"ts":"<ISO timestamp>","event":"feature_created","feature":"YYYYMMDD-NNN-<name>","agent":"spec-init"}
```

### 3. Dynamically Generate spec.html
Read `spec-template.html` as the skeleton. Based on the feature description, **intelligently determine** whether the following sub-content is needed:

**Always included**:
- Overview (WHAT)
- Background and Motivation (WHY)
- Functional Requirements (organized by user stories)
- Non-Functional Requirements
- Constraints and Assumptions

**Included as needed** (AI determines based on project type):
- If architecture decisions are involved → Embed architecture approach comparison (referencing `exploration-approaches.html` component pattern: 3-column cards + radio + recommendation)
- If tech stack selection is involved → Embed tech selection comparison (same pattern as above)
- If deployment architecture is involved → Additionally generate `arch-diagram.html` (referencing `flowchart-diagram.html` component pattern)
- If it is a frontend project requiring visual direction → Embed visual design comparison (referencing `exploration-visual-designs.html` component pattern)

Referenced component files (read as structure and style reference):
- `.specify/templates/components/exploration-approaches.html`
- `.specify/templates/components/exploration-visual-designs.html`
- `.specify/templates/components/flowchart-diagram.html`

### 4. Generate Feedback Skeleton
For each generated HTML file, generate a corresponding `.feedback.json`.

### 5. Update State
- Update `.feature-state.json` pipeline status
- Append event to `registry.jsonl`
- Run `.claude/hooks/refresh-dashboard.sh`

### 5.1 Reactive Wait for Approval
After generating documents, enter polling mode:
- Use ScheduleWakeup to check `spec.feedback.json` every 60-120 seconds for `review.verdict`
- If `verdict` is `null`, continue waiting. Output: ⏳ Pending review: file:///.../spec.html
- If `verdict` is `"approved"`:
  - Update `.feature-state.json`: set `pipeline.spec.status` to `"approved"`
  - Append `phase_approved` event to `registry.jsonl`
  - Output: ✅ Requirements spec approved. Ready for /spec-detail
  - End polling
- If `verdict` is `"rejected"`:
  - Read `review.feedback` for rejection reason
  - Modify spec.html based on feedback
  - Resubmit for approval
  - Output: 🔄 Revised based on feedback, resubmitting for approval

### 6. Output
```
✅ Feature specification created!

📄 Requirements Spec: file:///<absolute-path>/.specify/specs/YYYYMMDD-NNN-<name>/spec.html
📋 Dashboard: file:///<absolute-path>/.specify/specs/dashboard.html

⏳ Waiting for approval... (polling spec.feedback.json)

Next step after approval: /spec-detail
```
