---
description: "Feature Closure (Spec-Driven Development Final Command)"
agent:
  id: spec-close
  type: auxiliary
  order: null
  gate: "review.feedback.verdict = approved"
  produces_gate: null
  requires_feature: true
  writes_state: true
  output_files: [close-report.html]
  templates: [report-template.html]
  components: [status-report]
---

# /spec-close — Feature Closure

## Input
User provides a feature ID: $ARGUMENTS

## Feature Targeting
- If `$ARGUMENTS` contains a feature ID matching `YYYYMMDD-NNN`, target that feature directory
- Otherwise, scan `.specify/specs/*/` for the most recent feature with review approved

## Prerequisites
- The feature's review phase has been approved (`review.feedback.verdict = approved`)

## Execution Steps

### 1. Verify Pipeline Completeness
Read `.feature-state.json` and check:
- All started phases must be `approved`
- If any phase is not approved, list missing items and abort closure

### 2. Check Fix Records
- Read `fix-log.jsonl` if it exists
- Check for entries where `status` is not `fixed`
- If unclosed fixes exist, alert the user and abort closure

### 3. Automated Verification

#### 3.1 Code-level checks (automatic)
Based on project tech stack, detect and run available checks:

| Detection signal | Command |
|---------|---------|
| `package.json` + test script | `npm test` |
| `pytest.ini` / `conftest.py` | `pytest` |
| `go.mod` + `*_test.go` | `go test ./...` |
| `Makefile` + `test` target | `make test` |
| `Cargo.toml` + `#[test]` | `cargo test` |
| `.eslintrc*` / `eslint.config.*` | `npx eslint .` |
| `tsconfig.json` | `npx tsc --noEmit` |

Results are recorded in the closure report.

#### 3.2 Visual/Interaction checks (requires manual verification)
The following cannot be fully automated and require human confirmation:

- **Visual fidelity**: Colors, spacing, fonts, animations match design
- **Interaction quality**: Smooth operation, error state handling, edge cases
- **Business correctness**: End-to-end validation of complex workflows
- **Compatibility**: Cross-browser/device/resolution behavior

> **Exploration: Possibilities for automated visual testing**
>
> For web projects, manual visual verification can be reduced via:
> - **Playwright screenshot comparison**: `npx playwright test --update-snapshots` for baselines, then auto-compare
> - **Percy / Chromatic**: CI-integrated visual regression services
> - **Storybook + Chromatic**: Component-level visual testing
>
> However, the baseline still requires initial human confirmation of correctness.

### 4. Generate Closure Report
Generate `close-report.html` containing:
- Feature overview (name, creation time, total duration)
- Phase completion timeline
- Fix history summary (count, main issues)
- Automated verification results (passed/failed/skipped)
- Manual verification checklist (items to confirm, with checkboxes)

### 5. Update State
- Update `.feature-state.json`: set `closed_at` to current time
- Append `feature_closed` event to `registry.jsonl`
- **Sync to database**: `curl -s -X POST http://localhost:8421/api/sync`

### 6. Output
```
✅ Feature closed!

Feature: <feature name>
Duration: <N days>
Phases completed: <N/6>
Fix count: <N>
Automated checks: ✅ All passed / ⚠️ Partial / ❌ Failures

Closure report: http://localhost:8421/specs/<feature_id>/close-report.html
```
