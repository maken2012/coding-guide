---
description: "Technical Research (Auxiliary Command)"
---

# /spec-research — Technical Research

Independent from the main workflow, used for in-depth research on a specific technology or concept.

## Input
Research topic: $ARGUMENTS

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
📄 Research Document: file:///<absolute-path>/.specify/specs/<current_feature>/research.html
```
