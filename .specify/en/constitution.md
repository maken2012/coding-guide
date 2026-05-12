# Project Constitution

> Version: 1.1.0
> Last Updated: 2026-05-12

## Core Principles

### Documentation First
- Every feature must have a spec.html before any code is written
- Requirement specifications describe only WHAT and WHY; technical solutions describe only HOW
- Each phase must pass review before proceeding to the next phase

### Quality Gates
- Requirement specifications must be testable: every requirement has clear acceptance criteria
- Technical solutions must include error handling and boundary conditions
- Every task in the task list must be independently verifiable

### HTML Output Standards
- All human-facing documents must be self-contained HTML (inline CSS/JS, zero external dependencies)
- HTML must follow the structure of the corresponding template in templates/
- Interactive components must include a feedback mechanism (writable to .feedback.json)

### Parallel Isolation
- Each feature directory is independent and does not interfere with others
- Agents only operate within their assigned feature directory
- The dashboard is refreshed by the last agent to complete

### Invariants
- Constitution changes require an explicit version number record
- Approved reviews cannot be rolled back (only overridden by a new review)
- Generated code must pass spec-review to be considered complete

### Reactive Agent Protocol
- Each feature directory owns its `.feature-state.json` as the single source of truth for that feature's pipeline state
- Feature locking (`.agent-lock`) ensures at most one agent operates on a feature at any time
- `registry.jsonl` event log records all state changes for cross-agent observability
- Direct modification of `dashboard-state.json` (deprecated) is prohibited; state is distributed across feature directories
