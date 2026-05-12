---
description: "Architecture Selection + High-Level Requirements (Spec-Driven Development Step 1)"
---

# /spec-init — Architecture Selection + High-Level Requirements

## Input
User provides a feature description text: $ARGUMENTS

## Prerequisites
- `.specify/constitution.md` exists

## Execution Steps

### 1. Read Constitution and Templates
- Read `.specify/constitution.md`
- Read `.specify/templates/spec-template.html`

### 2. Generate Feature Directory
- Scan `.specify/specs/` for today's directories (format `YYYYMMDD-NNN`), today's max sequence +1, reset to 001 each day
- Create `.specify/specs/YYYYMMDD-NNN-<name>/`

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

### 5. Update Dashboard
Update `dashboard-state.json` and `dashboard.html`.

### 6. Output
```
✅ Feature specification created!

📄 Requirements Spec: file:///<absolute-path>/.specify/specs/YYYYMMDD-NNN-<name>/spec.html
📋 Dashboard: file:///<absolute-path>/.specify/specs/dashboard.html

Next step: Run /spec-detail for detailed requirements
```
