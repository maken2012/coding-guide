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
- 每 3-5 个任务更新状态：更新 `.feature-state.json`，追加 registry.jsonl 事件，运行 `.claude/hooks/refresh-dashboard.sh`

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
- 运行 `.claude/hooks/refresh-dashboard.sh` 重建 dashboard.html

### 6. 输出
```
✅ 开发和测试已完成！

📄 测试报告: file:///<绝对路径>/.specify/specs/<feature_id>/test-report.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

下一步：执行 /spec-review 进行代码审查和部署方案
```
