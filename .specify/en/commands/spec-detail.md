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
- Run `.claude/hooks/refresh-dashboard.sh`

### 5. Output
```
✅ Detailed requirements generated!

📄 Detailed Requirements: file:///<absolute-path>/.specify/specs/<current_feature>/detail.html
📋 Dashboard: file:///<absolute-path>/.specify/specs/dashboard.html

Next step: Run /spec-design for design
```
