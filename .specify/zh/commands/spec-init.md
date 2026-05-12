---
description: "架构选型 + 高层需求（Spec-Driven Development 第一步）"
agent:
  id: spec-init
  type: core
  order: 1
  gate: null
  produces_gate: "spec.feedback.verdict = approved"
  requires_feature: false
  writes_state: true
  output_files: [spec.html, spec.feedback.json, arch-diagram.html]
  templates: [spec-template.html]
  components: [exploration-approaches, exploration-visual-designs, flowchart-diagram]
---

# /spec-init — 架构选型 + 高层需求

## 输入
用户提供功能描述文本：$ARGUMENTS

## 前置条件
- `.specify/constitution.md` 存在

## 执行步骤

### 1. 读取宪章和模板
- 读取 `.specify/constitution.md`
- 读取 `.specify/templates/spec-template.html`

### 2. 生成功能目录
- 扫描 `.specify/specs/` 中当日目录（格式 `YYYYMMDD-NNN`），当日最大序号 +1，每日从 001 开始
- 创建 `.specify/specs/YYYYMMDD-NNN-<name>/`

### 2.1 初始化功能状态
在功能目录内创建 `.feature-state.json`：
```json
{
  "id": "YYYYMMDD-NNN-<name>",
  "name": "<功能名称>",
  "created_at": "<ISO时间>",
  "pipeline": {
    "spec": { "status": "in_progress", "artifact": "spec.html" },
    "detail": { "status": "not_started" },
    "design": { "status": "not_started" },
    "plan": { "status": "not_started" },
    "implement": { "status": "not_started" },
    "review": { "status": "not_started" }
  },
  "agent_session": null,
  "agent_since": null
}
```

向 `.specify/specs/registry.jsonl` 追加事件（如不存在则创建）：
```
{"ts":"<ISO时间>","event":"feature_created","feature":"YYYYMMDD-NNN-<name>","agent":"spec-init"}
```

### 3. 动态生成 spec.html
读取 `spec-template.html` 作为骨架。根据功能描述**智能判断**是否需要以下子内容：

**始终包含**：
- 概述（WHAT）
- 背景与动机（WHY）
- 功能需求（按用户故事组织）
- 非功能需求
- 约束与假设

**按需包含**（AI 判断项目类型后决定）：
- 如涉及架构决策 → 内嵌架构方案对比（参照 `exploration-approaches.html` 组件模式，3列卡片 + radio + 推荐）
- 如涉及技术栈选型 → 内嵌技术选型对比（同上模式）
- 如涉及部署架构 → 额外生成 `arch-diagram.html`（参照 `flowchart-diagram.html` 组件模式）
- 如为前端项目且需视觉方向 → 内嵌视觉方向对比（参照 `exploration-visual-designs.html` 组件模式）

引用的组件文件（读取作为结构和样式参考）：
- `.specify/templates/components/exploration-approaches.html`
- `.specify/templates/components/exploration-visual-designs.html`
- `.specify/templates/components/flowchart-diagram.html`

### 4. 生成反馈骨架
为每个生成的 HTML 文件生成对应的 `.feedback.json`。

### 5. 更新状态
- 更新 `.feature-state.json`：`pipeline.spec.status` 改为 `"pending_review"`
- 向 `registry.jsonl` 追加 `phase_completed` 事件
- 运行 `.claude/hooks/refresh-dashboard.sh` 重建 dashboard.html

### 5.1 反应式等待审批
生成文档后，进入轮询等待模式：
- 使用 ScheduleWakeup 每 60-120 秒检查 `spec.feedback.json` 中 `review.verdict` 的值
- 如果 `verdict` 为 `null`，继续等待，输出：⏳ 等待审批: file:///.../spec.html
- 如果 `verdict` 为 `"approved"`：
  - 更新 `.feature-state.json`：`pipeline.spec.status` 改为 `"approved"`
  - 向 `registry.jsonl` 追加 `phase_approved` 事件
  - 输出：✅ 需求规格已通过，可执行 /spec-detail 进行需求详述
  - 结束轮询
- 如果 `verdict` 为 `"rejected"`：
  - 读取 `review.feedback` 获取驳回原因
  - 根据反馈修改 spec.html
  - 重新提交等待审批
  - 输出：🔄 已根据反馈修改，重新提交审批

### 6. 输出
```
✅ 功能规范已创建！

📄 需求规格: file:///<绝对路径>/.specify/specs/YYYYMMDD-NNN-<name>/spec.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

请在浏览器中审核 spec.html，批准后将自动进入下一步
```
