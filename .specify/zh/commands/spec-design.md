---
description: "一站式设计（Spec-Driven Development 第三步）"
agent:
  id: spec-design
  type: core
  order: 3
  gate: "detail.feedback.verdict = approved"
  produces_gate: "design/*.feedback.verdict = approved"
  requires_feature: true
  writes_state: true
  output_files: [design/flow-design.html, design/db-design.html, design/api-design.html, design/ui-design.html]
  templates: [flow-design-template.html, db-design-template.html, api-design-template.html, ui-design-template.html]
  components: [flowchart-diagram, svg-illustrations, code-understanding, feature-explainer, design-system, component-variants, prototype-animation, prototype-interaction]
---

# /spec-design — 一站式设计

## 前置条件（门禁）
`detail.feedback.verdict === "approved"`

## 功能定向
- 如果 `$ARGUMENTS` 包含功能编号（`YYYYMMDD-NNN` 格式），定位到该功能目录
- 否则，扫描 `.specify/specs/*/` 中 `.feature-state.json`，找到当前命令门禁条件满足的功能
- 如果未找到匹配功能，输出错误提示

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
创建 `.specify/specs/<feature_id>/design/`

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

### 5. 更新状态
- 更新 `.feature-state.json`：`pipeline.design.status` 改为 `"pending_review"`
- 向 `.specify/specs/registry.jsonl` 追加 `phase_completed` 事件
- 确保反馈服务正在运行（如未运行则执行 `bash .claude/hooks/start-feedback-server.sh`）

### 5.1 反应式等待审批
生成文档后，进入轮询等待模式：
- 使用 ScheduleWakeup 每 60-120 秒检查 **所有已生成**的设计反馈文件中 `review.verdict` 的值（同时可通过 `curl -s http://localhost:8421/api/phases/<feature_id>` 获取阶段状态）
- 需检查的文件：`design/flow-design.feedback.json`、`design/db-design.feedback.json`（如生成）、`design/api-design.feedback.json`（如生成）、`design/ui-design.feedback.json`（如生成）
- 如果任何文件的 `verdict` 为 `null`，继续等待，输出：⏳ 等待审批: http://localhost:8421/specs/<feature_id>/design/（列出未审批文件）
- 如果所有文件的 `verdict` 均为 `"approved"`：
  - 更新 `.feature-state.json`：`pipeline.design.status` 改为 `"approved"`
  - 向 `registry.jsonl` 追加 `phase_approved` 事件
  - 输出：✅ 所有设计文档已通过，可执行 /spec-plan 进行计划拆解
  - 结束轮询
- 如果任何文件的 `verdict` 为 `"rejected"`：
  - 读取对应 `review.feedback` 获取驳回原因
  - 根据反馈修改被驳回的设计文档
  - 重新提交等待审批
  - 输出：🔄 已根据反馈修改，重新提交审批

### 6. 输出
```
✅ 设计文档已生成！

📄 流程设计: http://localhost:8421/specs/<feature_id>/design/flow-design.html
📄 数据设计: http://localhost:8421/specs/<feature_id>/design/db-design.html
📄 接口设计: http://localhost:8421/specs/<feature_id>/design/api-design.html
📄 UI设计:   http://localhost:8421/specs/<feature_id>/design/ui-design.html
📋 看板主页: http://localhost:8421

请在浏览器中逐个审核设计文档，全部批准后将自动进入下一步
```
