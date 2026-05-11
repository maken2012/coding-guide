---
description: "执行任务实现（Spec-Driven Development 第五步）"
---

# /spec-implement — 执行实现

## 前置条件（门禁）

1. 读取 `dashboard-state.json` 获取 `current_feature`
2. 读取 `tasks.feedback.json`，检查 `review.verdict === "approved"`
3. 未通过则拒绝执行

## 执行步骤

### 1. 加载所有设计文档

读取 `spec.html`、`plan.html`、`tasks.html`、`artifacts/*`。

### 2. 逐任务执行

- 按编号顺序执行（T001 → T002 → ...）
- 遇到 `[P]` 标记的任务提示可并行
- 每完成一个任务更新 `tasks.html` 中对应 checkbox 为 `[X]`

### 3. 定期更新看板

每 3-5 个任务更新看板进度。

### 4. 完成后

```
✅ 所有任务已完成！

建议执行 /spec-review 进行代码审查
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html
```
