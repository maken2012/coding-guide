---
description: "一站式设计（Spec-Driven Development 第三步）"
---

# /spec-design — 一站式设计

## 前置条件（门禁）
`detail.feedback.verdict === "approved"`

## 执行步骤

### 1. 读取上游文档
- `detail.html`、`detail.feedback.json`
- 所有 design 相关模板和组件

### 2. 分析项目类型，决定生成哪些设计文档

| 项目类型 | 生成 | 跳过 |
|---------|------|------|
| 全栈项目 | flow + db + api + ui | 无 |
| 纯后端 API | flow + db + api | ui |
| 纯前端 SPA | flow + ui | db, api |
| 数据/ETL | flow + db | api, ui |
| CLI 工具 | flow | db, api, ui |

### 3. 创建 design/ 目录
创建 `.specify/specs/<current_feature>/design/`

### 4. 逐个生成设计文档

**flow-design.html**（始终生成）：
- 读取 `flow-design-template.html` + `flowchart-diagram.html` 组件
- 业务流程图、时序图、状态机

**db-design.html**（有数据库时生成）：
- 读取 `db-design-template.html` + `code-understanding.html` 组件（ER图模式）
- 数据表设计、索引、约束、迁移策略

**api-design.html**（有后端时生成）：
- 读取 `api-design-template.html` + `feature-explainer.html` 组件（标签代码模式）
- 接口契约、请求/响应格式、错误码

**ui-design.html**（有前端时生成）：
- 读取 `ui-design-template.html`
- 引用 `design-system.html`（设计令牌）、`component-variants.html`（组件矩阵）
- 引用 `prototype-animation.html`、`prototype-interaction.html`（如需原型）
- 设计令牌、页面结构、组件规范、交互规范

每个文档生成对应 `.feedback.json`。

### 5. 更新看板

### 6. 输出
```
✅ 设计文档已生成！

📄 流程设计: file:///<绝对路径>/.specify/specs/<current_feature>/design/flow-design.html
📄 数据设计: file:///<绝对路径>/.specify/specs/<current_feature>/design/db-design.html
📄 接口设计: file:///<绝对路径>/.specify/specs/<current_feature>/design/api-design.html
📄 UI设计:   file:///<绝对路径>/.specify/specs/<current_feature>/design/ui-design.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

请逐个审核设计文档后，执行 /spec-plan
```
