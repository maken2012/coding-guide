---
description: "Status Report / Incident Post-Mortem (Auxiliary Command)"
agent:
  id: spec-report
  type: auxiliary
  order: null
  gate: null
  requires_feature: true
  writes_state: false
  output_files: [report.html]
  templates: [report-template.html]
  components: [status-report, incident-report]
---

# /spec-report — Report

Independent from the main workflow, used for generating status reports or incident post-mortems.

## Input
Report type and description: $ARGUMENTS

## Feature Targeting
- If `$ARGUMENTS` contains a feature ID matching `YYYYMMDD-NNN`, target that feature directory
- Otherwise, scan `.specify/specs/*/` for a `.feature-state.json` with an active feature
- Auxiliary commands do not update .feature-state.json or registry.jsonl

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
