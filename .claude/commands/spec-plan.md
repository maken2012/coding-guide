---
description: "设计技术方案（Spec-Driven Development 第三步）"
---

# /spec-plan — 技术方案设计

## 前置条件（门禁）

1. 读取 `.specify/specs/dashboard-state.json` 获取 `current_feature`
2. 读取 `.specify/specs/<current_feature>/spec.feedback.json`
3. 检查 `review.verdict === "approved"`
4. 如果不是 "approved"，拒绝执行并输出：❌ 门禁未通过：需求规格尚未审核通过

## 执行步骤

### 1. 读取所有上游文档

- `.specify/constitution.md`
- `.specify/specs/<current_feature>/spec.html`
- `.specify/specs/<current_feature>/spec.feedback.json`
- `.specify/templates/plan-template.html`
- `.specify/templates/components/` 下相关组件

### 2. 生成 plan.html

基于 plan-template.html 结构生成，内容包含：
- 方案概述
- 架构设计（使用 flowchart-diagram 组件模式的 SVG）
- 数据模型
- API 契约（标签页切换）
- 技术选型（使用 exploration-approaches 组件模式，嵌入 data-decision 交互）
- 分阶段实施计划
- 风险与缓解

### 3. 按需生成 artifacts

在 `artifacts/` 下生成衍生文档（每个都是自包含 HTML）：
- `data-model.html`
- `api-contracts.html`
- `architecture.html`

每个衍生文档生成对应的 `.feedback.json` 骨架。

### 4. 生成反馈骨架 + 更新看板

### 5. 输出结果

```
✅ 技术方案已生成！

📄 技术方案: file:///<绝对路径>/.specify/specs/<current_feature>/plan.html
📎 衍生文档: file:///<绝对路径>/.specify/specs/<current_feature>/artifacts/
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

请在浏览器中审核方案后提交反馈，然后执行 /spec-tasks
```
