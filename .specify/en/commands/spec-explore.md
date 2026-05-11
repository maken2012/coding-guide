---
description: "Independent Exploration & Comparison (Auxiliary Command)"
---

# /spec-explore — Exploration & Comparison

Independent from the main workflow, used for technology selection, approach comparison, and other exploratory work.

## Input
Exploration question: $ARGUMENTS

## Execution Steps

### 1. Read Templates and Components
- `.specify/templates/exploration-template.html`
- `.specify/templates/components/exploration-approaches.html`
- `.specify/templates/components/exploration-visual-designs.html`

### 2. Generate Exploration Document
Generate `exploration.html` in the current feature directory:
- Problem description
- 2-4 approaches side-by-side comparison (cards + pros/cons + radio selection)
- Recommended conclusion
- Feedback mechanism

### 3. Output
```
📄 Exploration Document: file:///<absolute-path>/.specify/specs/<current_feature>/exploration.html
```
