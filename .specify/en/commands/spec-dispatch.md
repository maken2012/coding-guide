---
description: "Multi-Agent Dispatch Analyzer: scan feature states and suggest parallel execution plans"
agent:
  id: spec-dispatch
  type: orchestrator
  order: null
  gate: null
  requires_feature: false
  writes_state: false
---

# /spec-dispatch — Multi-Agent Dispatch Analyzer

## Overview
Scan the status of all features, analyze which work can be executed in parallel, and output dispatch recommendations.

## Execution Steps

### 1. Scan Feature States
- List all feature directories under `.specify/specs/YYYYMMDD-NNN-*/`
- Read each feature's `.feature-state.json`
- Check `.agent-lock` to determine if occupied by another Agent

### 2. Analyze Dispatchable Work
For each unlocked feature, determine the next step based on pipeline status:

| Current Status | Dispatchable Command |
|---------------|---------------------|
| pipeline.spec.status = null | /spec-init |
| pipeline.spec.status = approved, detail = not_started | /spec-detail |
| pipeline.detail.status = approved, design = not_started | /spec-design |
| pipeline.design.status = approved, plan = not_started | /spec-plan |
| pipeline.plan.status = approved, implement = not_started | /spec-implement |
| pipeline.implement.status = approved, review = not_started | /spec-review |

### 3. Check Gate Conditions
For each dispatchable command, verify its gate conditions:
- Read the corresponding `.feedback.json` file
- Confirm `review.verdict = "approved"`
- Check that the feature directory is not locked

### 4. Output Dispatch Plan
```
╔══════════════════════════════════════════════════╗
║  SDD Dispatch Analysis                            ║
╚══════════════════════════════════════════════════╝

Total features: 3
Active Agents: 1
Dispatchable: 2

Pipeline status:
  001-user-auth    ✅ ✅ 🔄 ⬜ ⬜ ⬜  [Agent-A: spec-design]
  002-data-export  ✅ 🔄 ⬜ ⬜ ⬜ ⬜
  003-payment      🔄 ⬜ ⬜ ⬜ ⬜ ⬜

Dispatch recommendations:
  [1] 002-data-export → /spec-detail
      Terminal: claude "/spec-detail 20260512-002-data-export"

  [2] 003-payment → (waiting for spec phase approval)

Available parallelism: 1 new Agent can start immediately

Batch launch:
  Terminal 1: claude "/spec-detail 20260512-002-data-export"
```

### 5. Optional: Direct Execution
If the user confirms, output the launch command for each dispatchable task.
