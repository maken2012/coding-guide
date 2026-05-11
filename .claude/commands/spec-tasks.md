---
description: "拆解实施任务（Spec-Driven Development 第四步）"
---

# /spec-tasks — 任务拆解

## 前置条件（门禁）

1. 读取 `dashboard-state.json` 获取 `current_feature`
2. 读取 `plan.feedback.json`，检查 `review.verdict === "approved"`
3. 未通过则拒绝执行

## 执行步骤

### 1. 读取所有上游文档

读取 `plan.html`、`plan.feedback.json`、`artifacts/*`、`tasks-template.html`。

### 2. 生成 tasks.html

格式：`- [ ] T001 [P] [US1] 描述 — 文件路径`

阶段排列：Setup → 基础设施 → 用户故事 P1 → 用户故事 P2 → 收尾

每个任务使用可勾选的 checkbox。

### 3. 生成反馈骨架 + 更新看板

### 4. 输出结果

```
✅ 任务清单已生成！

📄 任务清单: file:///<绝对路径>/.specify/specs/<current_feature>/tasks.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

请审核任务清单后提交反馈，然后执行 /spec-implement 开始实现
```
