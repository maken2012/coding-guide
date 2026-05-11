---
description: "Detailed Requirements (Spec-Driven Development Step 2)"
---

# /spec-detail — Detailed Requirements

## Prerequisites (Gate)
`spec.feedback.verdict === "approved"`

## Execution Steps

### 1. Locate Current Feature
Read `dashboard-state.json` to get `current_feature`.

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

### 4. Generate Feedback Skeleton + Update Dashboard

### 5. Output
```
✅ Detailed requirements generated!

📄 Detailed Requirements: file:///<absolute-path>/.specify/specs/<current_feature>/detail.html
📋 Dashboard: file:///<absolute-path>/.specify/specs/dashboard.html

Next step: Run /spec-design for design
```
