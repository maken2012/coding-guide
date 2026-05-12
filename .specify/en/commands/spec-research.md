---
description: "Technical Research (Auxiliary Command)"
agent:
  id: spec-research
  type: auxiliary
  order: null
  gate: null
  requires_feature: true
  writes_state: false
  output_files: [research.html]
  templates: [research-template.html]
  components: [feature-explainer, concept-explainer, code-understanding]
---

# /spec-research — Technical Research

Independent from the main workflow, used for in-depth research on a specific technology or concept.

## Input
Research topic: $ARGUMENTS

## Feature Targeting
- If `$ARGUMENTS` contains a feature ID matching `YYYYMMDD-NNN`, target that feature directory
- Otherwise, scan `.specify/specs/*/` for a `.feature-state.json` with an active feature
- Auxiliary commands do not update .feature-state.json or registry.jsonl

## Execution Steps

### 1. Read Templates and Components
- `.specify/templates/research-template.html`
- `.specify/templates/components/feature-explainer.html`
- `.specify/templates/components/concept-explainer.html`
- `.specify/templates/components/code-understanding.html`

### 2. Generate Research Document
Generate `research.html` in the current feature directory:
- Research background
- Technology overview (collapsible steps + tabbed code)
- Core concepts (interactive diagrams)
- Code structure (call chains)
- Conclusions and recommendations

### 3. Output
```
📄 Research Document: http://localhost:8421/specs/<current_feature>/research.html
```
