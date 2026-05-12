---
description: "All-in-One Design (Spec-Driven Development Step 3)"
agent:
  id: spec-design
  type: core
  order: 3
  gate: "detail.feedback.verdict = approved"
  produces_gate: "design/*.feedback.verdict = approved"
  requires_feature: true
  writes_state: true
  output_files: [design/flow-design.html, design/db-design.html, design/api-design.html, design/ui-design.html]
  templates: [flow-design-template.html, db-design-template.html, api-design-template.html, ui-design-template.html]
  components: [flowchart-diagram, svg-illustrations, code-understanding, feature-explainer, design-system, component-variants, prototype-animation, prototype-interaction]
---

# /spec-design — All-in-One Design

## Prerequisites (Gate)
`detail.feedback.verdict === "approved"`

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
- All design-related templates and components

### 3. Analyze Project Type, Decide Which Design Documents to Generate

| Project Type | Generate | Skip |
|---------|------|------|
| Full-Stack Project | flow + db + api + ui | None |
| Backend-only API | flow + db + api | ui |
| Frontend-only SPA | flow + ui | db, api |
| Data/ETL | flow + db | api, ui |
| CLI Tool | flow | db, api, ui |

### 4. Create design/ Directory
Create `.specify/specs/<current_feature>/design/`

### 5. Generate Design Documents One by One

**flow-design.html** (always generated):
- Read `flow-design-template.html` + `flowchart-diagram.html` component
- Business flow diagrams, sequence diagrams, state machines

**db-design.html** (generated when database is involved):
- Read `db-design-template.html` + `code-understanding.html` component (ER diagram mode)
- Data table design, indexes, constraints, migration strategy

**api-design.html** (generated when backend is involved):
- Read `api-design-template.html` + `feature-explainer.html` component (tabbed code mode)
- Interface contracts, request/response formats, error codes

**ui-design.html** (generated when frontend is involved):
- Read `ui-design-template.html`
- Reference `design-system.html` (design tokens), `component-variants.html` (component matrix)
- Reference `prototype-animation.html`, `prototype-interaction.html` (if prototypes are needed)
- Design tokens, page structure, component specifications, interaction specifications

Each document generates a corresponding `.feedback.json`.

### 6. Update State
- Update `.feature-state.json` pipeline status
- Append event to `registry.jsonl`
- Run `.claude/hooks/refresh-dashboard.sh`

### 6.1 Reactive Wait for Approval
After generating documents, enter polling mode for ALL design feedback files:
- Use ScheduleWakeup to check each feedback file under `design/` (flow-design.feedback.json, db-design.feedback.json, api-design.feedback.json, ui-design.feedback.json — only those that were generated) every 60-120 seconds for `review.verdict`
- If any `verdict` is `null`, continue waiting. Output: ⏳ Pending review on: <list of unapproved design docs>
- If all `verdict`s are `"approved"`:
  - Update `.feature-state.json`: set `pipeline.design.status` to `"approved"`
  - Append `phase_approved` event to `registry.jsonl`
  - Output: ✅ All design documents approved. Ready for /spec-plan
  - End polling
- If any `verdict` is `"rejected"`:
  - Read `review.feedback` for rejection reasons on rejected docs
  - Modify corresponding HTML files based on feedback
  - Resubmit for approval
  - Output: 🔄 Revised <rejected doc names> based on feedback, resubmitting for approval

### 7. Output
```
✅ Design documents generated!

📄 Flow Design: file:///<absolute-path>/.specify/specs/<current_feature>/design/flow-design.html
📄 Data Design: file:///<absolute-path>/.specify/specs/<current_feature>/design/db-design.html
📄 API Design: file:///<absolute-path>/.specify/specs/<current_feature>/design/api-design.html
📄 UI Design: file:///<absolute-path>/.specify/specs/<current_feature>/design/ui-design.html
📋 Dashboard: file:///<absolute-path>/.specify/specs/dashboard.html

⏳ Waiting for approval on all design documents... (polling design/*.feedback.json)

Next step after all approved: /spec-plan
```
