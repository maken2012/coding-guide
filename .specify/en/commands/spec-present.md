---
description: "Presentation Slides (Auxiliary Command)"
---

# /spec-present — Presentation

Independent from the main workflow, used for generating presentation slides.

## Input
Presentation topic and content: $ARGUMENTS

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
