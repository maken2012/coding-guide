---
description: "代码审查 + 部署方案（Spec-Driven Development 第六步）"
agent:
  id: spec-review
  type: core
  order: 6
  gate: "code changes exist"
  produces_gate: null
  requires_feature: true
  writes_state: true
  output_files: [review.html, review.feedback.json, deploy-plan.html, deploy-plan.feedback.json]
  templates: [review-template.html, deploy-plan-template.html]
  components: [annotated-pr-review, pr-writeup, flowchart-diagram, feature-flags-editor]
---

# /spec-review — 审查 + 部署

## 前置条件
有代码变更

## 功能定向
- 如果 `$ARGUMENTS` 包含功能编号（`YYYYMMDD-NNN` 格式），定位到该功能目录
- 否则，扫描 `.specify/specs/*/` 中 `.feature-state.json`，找到当前命令门禁条件满足的功能
- 如果未找到匹配功能，输出错误提示

## 执行步骤

### 1. 检测变更
运行 `git diff` 识别变更范围。

### 2. 生成 review.html
读取 `review-template.html` 和 `annotated-pr-review.html` 组件：
- 审查摘要（Critical/High/Medium/Low 计数）
- 文件变更列表
- 逐文件审查（带批注、严重程度、建议、同意/不同意选项）
- 行动项汇总

### 3. 按需生成 deploy-plan.html
AI 判断是否涉及部署（有新配置、数据库迁移、新依赖、功能开关等）：
- 如是 → 读取 `deploy-plan-template.html`，生成 `deploy-plan.html`
- 包含：部署架构图、环境配置、数据库迁移、依赖组件、初始化脚本、功能开关、回滚方案
- 引用组件：`flowchart-diagram`（部署流水线）、`feature-flags-editor`（开关配置）

### 4. 更新状态
- 更新 `.feature-state.json`：`pipeline.review.status` 改为 `"pending_review"`
- 向 `.specify/specs/registry.jsonl` 追加 `phase_completed` 事件
- 确保反馈服务正在运行（如未运行则执行 `bash .claude/hooks/start-feedback-server.sh`）

### 4.1 反应式等待审批
生成文档后，进入轮询等待模式：
- 使用 ScheduleWakeup 每 60-120 秒检查 `review.feedback.json` 中 `review.verdict` 的值（同时可通过 `curl -s http://localhost:8421/api/phases/<feature_id>` 获取阶段状态）
- 如果 `verdict` 为 `null`，继续等待，输出：⏳ 等待审批: http://localhost:8421/specs/<feature_id>/review.html
- 如果 `verdict` 为 `"approved"`：
  - 更新 `.feature-state.json`：`pipeline.review.status` 改为 `"approved"`
  - 向 `registry.jsonl` 追加 `phase_approved` 事件
  - 向 `registry.jsonl` 追加 `lifecycle_complete` 事件
  - 输出：🎉 功能开发生命周期完成！
  - 结束轮询
- 如果 `verdict` 为 `"rejected"`：
  - 读取 `review.feedback` 获取驳回原因
  - 根据反馈修改代码或 review.html
  - 重新提交等待审批
  - 输出：🔄 已根据反馈修改，重新提交审批

### 5. 输出
```
✅ 审查报告已生成！

📄 审查报告: http://localhost:8421/specs/<feature_id>/review.html
📄 部署方案: http://localhost:8421/specs/<feature_id>/deploy-plan.html
📋 看板主页: http://localhost:8421

请在浏览器中审核审查报告，批准后将自动完成功能生命周期
```
