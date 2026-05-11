---
description: "需求详述（Spec-Driven Development 第二步）"
---

# /spec-detail — 需求详述

## 前置条件（门禁）
`spec.feedback.verdict === "approved"`

## 执行步骤

### 1. 定位当前功能
读取 `dashboard-state.json` 获取 `current_feature`。

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

### 4. 生成反馈骨架 + 更新看板

### 5. 输出
```
✅ 需求详述已生成！

📄 需求详述: file:///<绝对路径>/.specify/specs/<current_feature>/detail.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

下一步：执行 /spec-design 进行设计
```
