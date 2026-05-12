---
description: "需求详述（Spec-Driven Development 第二步）"
agent:
  id: spec-detail
  type: core
  order: 2
  gate: "spec.feedback.verdict = approved"
  produces_gate: "detail.feedback.verdict = approved"
  requires_feature: true
  writes_state: true
  output_files: [detail.html, detail.feedback.json]
  templates: [detail-template.html]
  components: [flowchart-diagram, exploration-approaches, feature-explainer]
---

# /spec-detail — 需求详述

## 前置条件（门禁）
`spec.feedback.verdict === "approved"`

## 功能定向
- 如果 `$ARGUMENTS` 包含功能编号（`YYYYMMDD-NNN` 格式），定位到该功能目录
- 否则，扫描 `.specify/specs/*/` 中 `.feature-state.json`，找到当前命令门禁条件满足的功能
- 如果未找到匹配功能，输出错误提示

## 执行步骤

### 1. 定位当前功能
扫描 `.specify/specs/*/` 中 `.feature-state.json`，找到门禁条件满足的功能。

### 2. 读取上游文档
- `spec.html`、`spec.feedback.json`
- `.specify/templates/detail-template.html`
- `.specify/templates/components/flowchart-diagram.html`（流程图参考）
- `.specify/templates/components/exploration-approaches.html`（方案对比参考）

### 3. 生成 detail.html
基于 detail-template.html，包含：
- **输入输出定义**：表格格式 — 字段名 / 类型 / 必填 / 说明
- **交互流程**：根据项目类型自动生成流程图（参照 flowchart-diagram 组件模式）
- **业务规则**：条件 → 动作 格式的规则列表
- **异常处理**：错误码 / 场景 / 响应 / 重试策略 表格
- **约束条件**：技术约束、业务约束

AI 根据项目类型智能决定：
- 有前端交互？→ 生成交互流程图
- 有复杂业务逻辑？→ 生成时序图/状态机
- 有多方案需求？→ 内嵌方案对比

### 4. 生成反馈骨架 + 更新状态
- 更新 `.feature-state.json`：`pipeline.detail.status` 改为 `"pending_review"`
- 向 `.specify/specs/registry.jsonl` 追加 `phase_completed` 事件
- 确保反馈服务正在运行（如未运行则执行 `bash .claude/hooks/start-feedback-server.sh`）

### 4.1 反应式等待审批
生成文档后，进入轮询等待模式：
- 使用 ScheduleWakeup 每 60-120 秒检查 `detail.feedback.json` 中 `review.verdict` 的值（同时可通过 `curl -s http://localhost:8421/api/phases/<feature_id>` 获取阶段状态）
- 如果 `verdict` 为 `null`，继续等待，输出：⏳ 等待审批: http://localhost:8421/specs/<feature_id>/detail.html
- 如果 `verdict` 为 `"approved"`：
  - 更新 `.feature-state.json`：`pipeline.detail.status` 改为 `"approved"`
  - 向 `registry.jsonl` 追加 `phase_approved` 事件
  - 输出：✅ 需求详述已通过，可执行 /spec-design 进行设计
  - 结束轮询
- 如果 `verdict` 为 `"rejected"`：
  - 读取 `review.feedback` 获取驳回原因
  - 根据反馈修改 detail.html
  - 重新提交等待审批
  - 输出：🔄 已根据反馈修改，重新提交审批

### 5. 输出
```
✅ 需求详述已生成！

📄 需求详述: http://localhost:8421/specs/<feature_id>/detail.html
📋 看板主页: http://localhost:8421

请在浏览器中审核 detail.html，批准后将自动进入下一步
```
