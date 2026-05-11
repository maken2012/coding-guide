---
description: "Status Report / Incident Post-Mortem (Auxiliary Command)"
---

# /spec-report — Report

Independent from the main workflow, used for generating status reports or incident post-mortems.

## Input
Report type and description: $ARGUMENTS

## Execution Steps

### 1. Read Templates and Components
- `.specify/templates/report-template.html`
- `.specify/templates/components/status-report.html`
- `.specify/templates/components/incident-report.html`

### 2. AI Determines Report Type
- If related to "weekly report" / "progress" / "status" → Generate status report mode
- If related to "incident" / "outage" / "post-mortem" → Generate incident post-mortem mode

### 3. Generate Report Document
Generate `report.html` in the current feature directory.

### 4. Output
```
📄 Report: file:///<absolute-path>/.specify/specs/<current_feature>/report.html
```
