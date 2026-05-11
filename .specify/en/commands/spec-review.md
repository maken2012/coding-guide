---
description: "Code Review + Deployment Plan (Spec-Driven Development Step 6)"
---

# /spec-review — Review + Deployment

## Prerequisites
Code changes exist

## Execution Steps

### 1. Detect Changes
Run `git diff` to identify the scope of changes.

### 2. Generate review.html
Read `review-template.html` and `annotated-pr-review.html` component:
- Review summary (Critical/High/Medium/Low counts)
- File change list
- Per-file review (with annotations, severity, suggestions, agree/disagree options)
- Action items summary

### 3. Conditionally Generate deploy-plan.html
AI determines whether deployment is involved (new configuration, database migration, new dependencies, feature flags, etc.):
- If yes → Read `deploy-plan-template.html`, generate `deploy-plan.html`
- Includes: Deployment architecture diagram, environment configuration, database migration, dependency components, initialization scripts, feature flags, rollback plan
- Referenced components: `flowchart-diagram` (deployment pipeline), `feature-flags-editor` (flag configuration)

### 4. Update Dashboard

### 5. Output
```
✅ Review report generated!

📄 Review Report: file:///<absolute-path>/.specify/specs/<current_feature>/review.html
📄 Deployment Plan: file:///<absolute-path>/.specify/specs/<current_feature>/deploy-plan.html
📋 Dashboard: file:///<absolute-path>/.specify/specs/dashboard.html
```
