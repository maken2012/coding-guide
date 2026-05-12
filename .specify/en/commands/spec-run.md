---
description: "Feature Full Lifecycle Manager: Auto-advance through all 6 phases, wait for approval then continue to next phase"
agent:
  id: spec-run
  type: lifecycle
  order: null
  gate: null
  requires_feature: false
  writes_state: true
---

# /spec-run — Feature Full Lifecycle Manager

## Overview
Automatically manages the complete lifecycle of a feature from /spec-init through /spec-review. The Agent generates documents at each phase, waits for user approval, and auto-advances to the next phase upon detecting approval.

## Input
- `/spec-run "feature description"` — Create a new feature and run through the full lifecycle
- `/spec-run YYYYMMDD-NNN-<name>` — Take over an existing feature and resume from the current phase

## Execution Flow

### 0. Initialization
- Generate a unique session ID (format: `sess-<8 random characters>`)
- If the argument is a new feature description:
  - Create feature directory (`YYYYMMDD-NNN-<name>`)
  - Initialize `.feature-state.json`
  - Append `feature_created` event to `registry.jsonl`
  - Start from phase 1 (spec)
- If the argument is an existing feature ID:
  - Read `.feature-state.json` and find the current phase
  - Resume execution from that phase

### 1. Phase Execution Loop
Execute the following phases in order, waiting for approval after each phase:

```
Phase 1: /spec-init logic → Generate spec.html → Wait for approval
Phase 2: /spec-detail logic → Generate detail.html → Wait for approval
Phase 3: /spec-design logic → Generate design/*.html → Wait for all approvals
Phase 4: /spec-plan logic → Generate plan.html + tasks.html → Wait for approval
Phase 5: /spec-implement logic → Code + tests → Wait for approval
Phase 6: /spec-review logic → Review + deployment plan → Wait for approval
```

### 2. Reactive Wait (Common to All Phases)
After generating documents, enter polling mode:
- Use ScheduleWakeup to check the corresponding `.feedback.json` every 60-120 seconds for `review.verdict` (also check via `curl -s http://localhost:8421/api/phases/<feature_id>` for phase status)
- `null` → Continue waiting. Output: ⏳ Phase N/6 pending approval: http://localhost:8421/specs/<feature_id>/xxx.html
- `"approved"` → Update `.feature-state.json`, append `phase_approved` event, advance to next phase
- `"rejected"` → Read feedback, revise documents, resubmit and wait

### 3. Phase Transitions
- At the start of each phase, update `.feature-state.json`: set the corresponding phase status to `"in_progress"`
- After each phase is approved, update: set the corresponding phase status to `"approved"`
- Append `phase_started` and `phase_completed` events to `registry.jsonl`
- Ensure feedback server is running (run `bash .claude/hooks/start-feedback-server.sh` if not)
- **Sync to database**: `curl -s -X POST http://localhost:8421/api/sync`

### 4. Lifecycle Complete
When phase 6 (review) is approved:
- Update `.feature-state.json`: set `pipeline.review.status` to `"approved"`
- Append `lifecycle_complete` event to `registry.jsonl`
- Ensure feedback server is running (run `bash .claude/hooks/start-feedback-server.sh` if not)
- **Sync to database**: `curl -s -X POST http://localhost:8421/api/sync`
- Output completion summary

### 5. Output
```
🎉 Feature lifecycle complete!

Feature: 20260512-001-user-auth
Duration: X hours Y minutes
Phases completed:
  ✅ spec      → spec.html
  ✅ detail    → detail.html
  ✅ design    → flow-design.html, db-design.html, api-design.html
  ✅ plan      → plan.html, tasks.html
  ✅ implement → test-report.html
  ✅ review    → review.html, deploy-plan.html

📋 Dashboard: http://localhost:8421
```

## Reference Files
For detailed execution logic of each phase, refer to the corresponding command files:
- Phase 1: Execution steps in `.claude/commands/spec-init.md`
- Phase 2: Execution steps in `.claude/commands/spec-detail.md`
- Phase 3: Execution steps in `.claude/commands/spec-design.md`
- Phase 4: Execution steps in `.claude/commands/spec-plan.md`
- Phase 5: Execution steps in `.claude/commands/spec-implement.md`
- Phase 6: Execution steps in `.claude/commands/spec-review.md`
