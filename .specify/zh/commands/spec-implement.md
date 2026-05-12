---
description: "开发实现 + 测试（Spec-Driven Development 第五步）"
agent:
  id: spec-implement
  type: core
  order: 5
  gate: "tasks.feedback.verdict = approved"
  produces_gate: null
  requires_feature: true
  writes_state: true
  output_files: [test-report.html, test-report.feedback.json]
  templates: [test-report-template.html]
  components: [status-report, annotated-pr-review]
---

# /spec-implement — 开发 + 测试

## 前置条件（门禁）
1. `tasks.feedback.verdict === "approved"`
2. 未通过则拒绝执行

## 功能定向
- 如果 `$ARGUMENTS` 包含功能编号（`YYYYMMDD-NNN` 格式），定位到该功能目录
- 否则，扫描 `.specify/specs/*/` 中 `.feature-state.json`，找到当前命令门禁条件满足的功能
- 如果未找到匹配功能，输出错误提示

## 执行步骤

### 1. 加载所有设计文档
读取 spec、detail、design/*、plan、tasks。

### 2. 逐任务开发
- 按编号顺序执行
- 每完成一个任务：编写代码 + 编写对应单元测试
- 更新 tasks.html 中 checkbox 为 [X]
- 每 3-5 个任务更新状态：更新 `.feature-state.json`，追加 registry.jsonl 事件，确保反馈服务正在运行（如未运行则执行 `bash .claude/hooks/start-feedback-server.sh`）

### 3. 生成集成测试
所有任务完成后，根据 API 契约和交互流程生成集成测试。

### 4. 生成测试报告
读取 `.specify/templates/test-report-template.html`，生成 `test-report.html`：
- 测试概览（总数/通过/失败/跳过）
- 覆盖率（按模块的 CSS 柱状图）
- 单元测试结果表
- 集成测试结果表
- 失败详情（如有）

### 5. 更新状态
- 更新 `.feature-state.json`：`pipeline.implement.status` 改为 `"pending_review"`
- 向 `.specify/specs/registry.jsonl` 追加 `phase_completed` 事件
- 确保反馈服务正在运行（如未运行则执行 `bash .claude/hooks/start-feedback-server.sh`）

### 5.1 反应式等待审批
生成文档后，进入轮询等待模式：
- 使用 ScheduleWakeup 每 60-120 秒检查 `test-report.feedback.json` 中 `review.verdict` 的值（同时可通过 `curl -s http://localhost:8421/api/phases/<feature_id>` 获取阶段状态）
- 如果 `verdict` 为 `null`，继续等待，输出：⏳ 等待审批: http://localhost:8421/specs/<feature_id>/test-report.html
- 如果 `verdict` 为 `"approved"`：
  - 更新 `.feature-state.json`：`pipeline.implement.status` 改为 `"approved"`
  - 向 `registry.jsonl` 追加 `phase_approved` 事件
  - 输出：✅ 测试报告已通过，可执行 /spec-review 进行代码审查
  - 结束轮询
- 如果 `verdict` 为 `"rejected"`：
  - 读取 `review.feedback` 获取驳回原因
  - 根据反馈修复测试或代码
  - 重新生成 test-report.html
  - 重新提交等待审批
  - 输出：🔄 已根据反馈修改，重新提交审批

### 6. 输出
```
✅ 开发和测试已完成！

📄 测试报告: http://localhost:8421/specs/<feature_id>/test-report.html
📋 看板主页: http://localhost:8421

请在浏览器中审核测试报告，批准后将自动进入下一步
```
