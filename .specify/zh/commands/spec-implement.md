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

### 1. 编码前必读（精简上下文）

**在写任何代码之前**，读取以下必要文件建立全局理解：

| 文件 | 用途 | 必读？ |
|------|------|-------|
| `spec.html` | 理解 WHAT / WHY | ✅ 始终 |
| `tasks.html` | 知道要做什么 | ✅ 始终 |
| `plan.html` | 知道自己在哪个阶段 | ✅ 始终 |
| `detail.html` | 业务规则、异常处理 | ✅ 始终 |
| `design/flow-design.html` | 流程/时序/状态机 | 🔍 按任务需要 |
| `design/db-design.html` | 表结构、ER 关系 | 🔍 涉及数据库时 |
| `design/api-design.html` | 接口契约 | 🔍 涉及接口时 |
| `design/ui-design.html` | 组件/布局/交互 | 🔍 涉及前端时 |
| `*.feedback.json` | 用户决策记录 | 🔍 任务涉及决策项时 |

**验证**：✅ 标记的文件必须存在（且阶段已通过），否则报错终止。

### 1.1 逐任务按需加载

每开始一个任务前：
1. 读取任务描述，判断涉及哪些领域（数据/接口/前端/流程）
2. 仅加载该任务涉及的 🔍 设计文档
3. 检查对应的 feedback.json 中是否有相关决策需要遵循
4. 然后开始编码

### 2. 逐任务开发
- 按编号顺序执行
- 每完成一个任务：编写代码 + 编写对应单元测试
- 更新 tasks.html 中 checkbox 为 [X]
- 每 3-5 个任务更新状态：更新 `.feature-state.json`，追加 registry.jsonl 事件，确保反馈服务正在运行（如未运行则执行 `bash .claude/hooks/start-feedback-server.sh`）
- **Sync to database**: `curl -s -X POST http://localhost:8421/api/sync`

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
- **Sync to database**: `curl -s -X POST http://localhost:8421/api/sync`

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
