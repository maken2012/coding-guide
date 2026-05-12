## Constitution
- Read .specify/constitution.md and comply with all invariants
- No feature specification may violate constitution principles

## Workflow Overview

Main pipeline has 6 steps + 4 auxiliary commands. Each main pipeline command **dynamically determines** which sub-documents to generate based on project context.

### Main Pipeline

```
/spec-init → /spec-detail → /spec-design → /spec-plan → /spec-implement → /spec-review
Architecture     Detailed        One-stop        Plan +         Development     Review +
Selection        Requirements    Design          Tasks          + Testing        Deployment
```

### Auxiliary Commands (independent of main pipeline)

```
/spec-explore   → Independent exploration and comparison
/spec-research  → Technical research
/spec-report    → Status report / Incident postmortem
/spec-present   → Presentation slides
```

---

## Main Pipeline Commands → Templates → Component Mapping

### /spec-init (Architecture Selection + High-Level Requirements)

**Gate**: None

**Dynamic Output Logic**:
- Always generate: `spec.html`
- If architecture decisions are involved: embed architecture comparison (using `exploration-approaches` component pattern)
- If tech stack selection is involved: embed tech stack comparison
- If deployment architecture is involved: generate `arch-diagram.html` (using `flowchart-diagram` component pattern)

**Referenced Components**:
- `exploration-approaches` — Architecture approach comparison
- `exploration-visual-designs` — Visual direction comparison (frontend projects)
- `flowchart-diagram` — System architecture diagram
- `spec-template` — Requirement specification skeleton

**Output Files**:
```
specs/YYYYMMDD-NNN-<name>/
├── spec.html                    # Always generated
├── spec.feedback.json           # Always generated
└── arch-diagram.html            # On-demand (architecture diagram)
    arch-diagram.feedback.json
```

### /spec-detail (Detailed Requirements)

**Gate**: `spec.feedback.verdict = approved`

**Dynamic Output Logic**:
- Always generate: `detail.html` (inputs/outputs, interaction flows, business rules, exception handling)
- If frontend interactions exist: embed interaction flow diagram (using `flowchart-diagram`)
- If complex business logic exists: embed sequence diagram / state machine diagram
- If multiple approaches are needed: embed approach comparison (using `exploration-approaches`)

**Referenced Components**:
- `flowchart-diagram` — Business flow diagrams, sequence diagrams, state machines
- `exploration-approaches` — Requirement approach comparison
- `feature-explainer` — Complex feature principle explanation

**Output Files**:
```
specs/YYYYMMDD-NNN-<name>/
├── detail.html                  # Always generated
├── detail.feedback.json         # Always generated
└── (embedded on-demand within detail.html)
```

### /spec-design (One-Stop Design)

**Gate**: `detail.feedback.verdict = approved`

**Dynamic Output Logic**: AI analyzes project type and automatically determines which design documents to generate:

| Project Type | Design Documents Generated | Skipped |
|-------------|---------------------------|---------|
| Full-stack project | flow + db + api + ui | None |
| Backend-only API | flow + db + api | ui |
| Frontend-only SPA | flow + ui | db, api |
| Data / ETL | flow + db | api, ui |
| CLI tool | flow | db, api, ui |

**Referenced Components**:
- `flow-design` sub-document → `flowchart-diagram` (flowcharts), `svg-illustrations` (illustrations)
- `db-design` sub-document → `code-understanding` (ER diagram mode)
- `api-design` sub-document → `feature-explainer` (tabbed code display)
- `ui-design` sub-document → `design-system` (design tokens), `component-variants` (component matrix), `prototype-animation` (animations), `prototype-interaction` (interactive prototypes)

**Output Files**:
```
specs/YYYYMMDD-NNN-<name>/
├── design/
│   ├── flow-design.html         # Business flow / sequence diagrams
│   ├── flow-design.feedback.json
│   ├── db-design.html           # Database table design (on-demand)
│   ├── db-design.feedback.json
│   ├── api-design.html          # API contract (on-demand)
│   ├── api-design.feedback.json
│   ├── ui-design.html           # UI/UX design (on-demand)
│   └── ui-design.feedback.json
```

### /spec-plan (Plan + Task Breakdown)

**Gate**: `design/*.feedback.verdict = approved` (all generated design documents have passed)

**Dynamic Output Logic**:
- Always generate: `plan.html` + `tasks.html`
- Embed dependency diagram in plan on-demand (using `implementation-plan` component pattern)
- Embed priority ranking in tasks on-demand (using `triage-board` component pattern)

**Referenced Components**:
- `implementation-plan` — Phased plan + dependencies
- `triage-board` — Task priority drag-and-drop ranking
- `slide-deck` — If presenting the plan to the team

**Output Files**:
```
specs/YYYYMMDD-NNN-<name>/
├── plan.html                    # Always generated
├── plan.feedback.json
├── tasks.html                   # Always generated
└── tasks.feedback.json
```

### /spec-implement (Development + Testing)

**Gate**: `tasks.feedback.verdict = approved`

**Dynamic Output Logic**:
- Code in task number order
- Automatically generate corresponding unit tests after each task is completed
- Generate integration tests after all tasks are completed
- Generate test report

**Referenced Components**:
- `status-report` — Progress display in test reports
- `annotated-pr-review` — Test coverage review

**Output Files**:
```
specs/YYYYMMDD-NNN-<name>/
├── (code files)
├── test-report.html             # Test report
└── test-report.feedback.json
```

### /spec-review (Review + Deployment)

**Gate**: Code changes exist

**Dynamic Output Logic**:
- Always generate: `review.html` (code review)
- If deployment is involved: generate `deploy-plan.html` (configuration, database migrations, initialization, dependencies)
- If feature flags are involved: embed `feature-flags-editor` component pattern

**Referenced Components**:
- `annotated-pr-review` — Annotated code review
- `pr-writeup` — Change summary
- `flowchart-diagram` — Deployment pipeline diagram
- `feature-flags-editor` — Feature flag configuration

**Output Files**:
```
specs/YYYYMMDD-NNN-<name>/
├── review.html                  # Always generated
├── review.feedback.json
├── deploy-plan.html             # On-demand
└── deploy-plan.feedback.json
```

---

## Auxiliary Commands → Templates → Component Mapping

### /spec-explore (Independent Exploration and Comparison)
- Template: `exploration-template.html`
- Components: `exploration-approaches`, `exploration-visual-designs`
- Output: `exploration.html`

### /spec-research (Technical Research)
- Template: `research-template.html`
- Components: `feature-explainer`, `concept-explainer`, `code-understanding`
- Output: `research.html`

### /spec-report (Status Report / Incident Postmortem)
- Template: `report-template.html`
- Components: `status-report` (weekly report), `incident-report` (incident postmortem)
- Output: `report.html`

### /spec-present (Presentation Slides)
- Template: `presentation-template.html`
- Components: `slide-deck`
- Output: `presentation.html`

---

## General Rules

### Document Generation Rules
- All human-facing documents must be output as self-contained HTML (inline CSS/JS, zero external dependencies)
- HTML must follow the structure and styles of the corresponding template in .specify/templates/
- Automatically update dashboard.html and dashboard-state.json after each phase is completed
- Terminal output format: 📄 Pending review: file:///absolute/path/to/xxx.html
- Phase gate: read review.verdict from .feedback.json; only "approved" allows proceeding to the next phase

### Feedback Handling Rules
- Generate the corresponding .feedback.json skeleton alongside each HTML file
- After the user interacts with the HTML, feedback is written to .feedback.json
- Read .feedback.json before the next execution round and adjust based on user decisions
- On rejection, read review.feedback, modify, and resubmit

### Parallel Agent Rules
- Each agent only operates within its assigned feature directory
- Do not read or modify files in other feature directories
- dashboard.html is refreshed by the last agent to complete

### HTML Component Usage Rules
- Read component files under .specify/templates/components/ as structural and style references
- Do not copy component files directly; instead, replicate their HTML structure, CSS styles, and JS interaction patterns
- All user interactions connect to .feedback.json through a unified feedback mechanism (saveFeedback function)
- Each component provides a SLOT:content placeholder for content replacement

### .feedback.json Structure Specification
Each feedback file must contain the following structure:
{
  "artifact": "filename.html",
  "feature": "feature directory name",
  "phase": "spec|detail|design|plan|implement|review",
  "status": "pending_review",
  "decisions": [
    { "id": "decision ID", "type": "single-select|multi-select|text-input|review", "options": [...], "selected": null, "note": "" }
  ],
  "review": { "verdict": null, "feedback": "", "timestamp": null },
  "created_at": "ISO timestamp",
  "updated_at": "ISO timestamp"
}

### Dashboard dashboard.html Maintenance Rules
- Read .specify/specs/dashboard-state.json to get global state
- Left 25%: overview statistics + timeline + feature list
- Right 75%: current phase document of the selected feature (loaded via iframe)
- Bottom: approve/reject review buttons
- dashboard.html must be rebuilt every time any specification document is generated or updated
