---
description: "Development + Testing (Spec-Driven Development Step 5)"
---

# /spec-implement — Development + Testing

## Prerequisites (Gate)
1. `tasks.feedback.verdict === "approved"`
2. If not passed, refuse to execute

## Execution Steps

### 1. Load All Design Documents
Read spec, detail, design/*, plan, tasks.

### 2. Implement Task by Task
- Execute in numbered order
- After completing each task: write code + write corresponding unit tests
- Update checkbox in tasks.html to [X]
- Update dashboard every 3-5 tasks

### 3. Generate Integration Tests
After all tasks are completed, generate integration tests based on API contracts and interaction flows.

### 4. Generate Test Report
Read `.specify/templates/test-report-template.html`, generate `test-report.html`:
- Test overview (total / passed / failed / skipped)
- Coverage (CSS bar chart by module)
- Unit test results table
- Integration test results table
- Failure details (if any)

### 5. Output
```
✅ Development and testing completed!

📄 Test Report: file:///<absolute-path>/.specify/specs/<current_feature>/test-report.html
📋 Dashboard: file:///<absolute-path>/.specify/specs/dashboard.html

Next step: Run /spec-review for code review and deployment plan
```
