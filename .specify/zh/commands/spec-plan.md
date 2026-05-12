---
description: "实施计划 + 任务拆解（Spec-Driven Development 第四步）"
agent:
  id: spec-plan
  type: core
  order: 4
  gate: "design/*.feedback.verdict = approved"
  produces_gate: "tasks.feedback.verdict = approved"
  requires_feature: true
  writes_state: true
  output_files: [plan.html, plan.feedback.json, tasks.html, tasks.feedback.json]
  templates: [plan-template.html, tasks-template.html]
  components: [implementation-plan, triage-board, slide-deck]
---

# /spec-plan — 实施计划 + 任务拆解

## 前置条件（门禁）
1. 扫描 `.specify/specs/*/` 中 `.feature-state.json`，定位目标功能
2. 检查所有 design/ 下的 `.feedback.json`，`verdict` 均为 `"approved"`
3. 未通过则拒绝执行

## 功能定向
- 如果 `$ARGUMENTS` 包含功能编号（`YYYYMMDD-NNN` 格式），定位到该功能目录
- 否则，扫描 `.specify/specs/*/` 中 `.feature-state.json`，找到当前命令门禁条件满足的功能
- 如果未找到匹配功能，输出错误提示

## 执行步骤

### 1. 读取上游文档
- `detail.html`、`detail.feedback.json`
- `design/` 下所有设计文档及其 feedback
- `.specify/templates/plan-template.html`
- `.specify/templates/tasks-template.html`

### 2. 读取组件参考
- `.specify/templates/components/implementation-plan.html` — 分阶段计划模式
- `.specify/templates/components/triage-board.html` — 任务排序模式

### 3. 生成 plan.html
基于 plan-template.html 生成技术实施计划：
- 方案概述
- 分阶段实施（参照 implementation-plan 组件：水平时间线 + 阶段卡片 + 文件变更列表）
- 依赖关系图
- 风险与缓解

### 4. 生成 tasks.html
基于 tasks-template.html 生成任务清单：
- 格式：`- [ ] T001 [P] [US1] 描述 — 文件路径`
- 阶段排列：Setup → 基础设施 → 用户故事 → 测试 → 收尾
- 可并行标记 [P]
- 进度条

### 5. 生成反馈骨架 + 更新状态
- 更新 `.feature-state.json`：`pipeline.plan.status` 改为 `"pending_review"`
- 向 `.specify/specs/registry.jsonl` 追加 `phase_completed` 事件
- 运行 `.claude/hooks/refresh-dashboard.sh` 重建 dashboard.html

### 6. 输出
```
✅ 实施计划和任务清单已生成！

📄 实施计划: file:///<绝对路径>/.specify/specs/<feature_id>/plan.html
📄 任务清单: file:///<绝对路径>/.specify/specs/<feature_id>/tasks.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

请审核后执行 /spec-implement 开始实现
```
