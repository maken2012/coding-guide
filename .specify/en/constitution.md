# Project Constitution

> Version: 1.0.0
> Last Updated: 2026-05-11

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
