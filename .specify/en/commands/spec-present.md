---
description: "Presentation Slides (Auxiliary Command)"
agent:
  id: spec-present
  type: auxiliary
  order: null
  gate: null
  requires_feature: true
  writes_state: false
  output_files: [presentation.html]
  templates: [presentation-template.html]
  components: [slide-deck]
---

# /spec-present — Presentation

Independent from the main workflow, used for generating presentation slides.

## Input
Presentation topic and content: $ARGUMENTS

## Feature Targeting
- If `$ARGUMENTS` contains a feature ID matching `YYYYMMDD-NNN`, target that feature directory
- Otherwise, scan `.specify/specs/*/` for a `.feature-state.json` with an active feature
- Auxiliary commands do not update .feature-state.json or registry.jsonl

## Execution Steps

### 1. Read Templates and Components
- `.specify/templates/presentation-template.html`
- `.specify/templates/components/slide-deck.html`

### 2. Generate Presentation
Generate `presentation.html` in the current feature directory:
- Arrow key navigation
- Multiple slides
- Clear visual layout

### 3. Output
```
📄 Presentation: file:///<absolute-path>/.specify/specs/<current_feature>/presentation.html
```
