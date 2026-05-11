---
description: "对当前功能需求进行澄清（Spec-Driven Development 第二步）"
---

# /spec-clarify — 需求澄清

你正在执行 Spec-Driven Development 工作流的第二步：对需求规格进行澄清。

## 前置条件

- `.specify/specs/dashboard-state.json` 存在且 `current_feature` 有值
- 对应功能目录下 `spec.feedback.json` 存在

## 执行步骤

### 1. 定位当前功能

读取 `.specify/specs/dashboard-state.json` 获取 `current_feature`。

### 2. 读取现有 spec

读取 `.specify/specs/<current_feature>/spec.html`，分析需求内容。

### 3. 生成澄清问题

分析 spec 中的模糊点，生成最多 5 个澄清问题。问题分类（按需选择）：

- **功能范围与行为**：边界条件、异常流程
- **数据模型**：实体、字段、关系
- **交互与 UX 流程**：用户操作路径
- **非功能质量属性**：性能目标、安全要求
- **集成与外部依赖**：第三方系统、API
- **边界条件与失败处理**：错误场景、降级策略
- **约束与权衡**：技术限制、优先级取舍
- **术语定义**：领域概念澄清

### 4. 更新 spec.html

在 spec.html 底部（审核栏之前）插入澄清区域，每个问题包含：
- 问题标题和描述
- 单选选项（含推荐标记 ✨）
- 补充说明输入框
- `data-decision` 和 `data-type="single-select"` 属性

### 5. 更新反馈骨架

更新 `spec.feedback.json`，在 `decisions` 数组中添加澄清问题的条目。

### 6. 更新看板

更新 `dashboard-state.json` 和 `dashboard.html`。

### 7. 输出结果

```
✅ 澄清问题已生成！

📄 更新的规格: file:///<绝对路径>/.specify/specs/<current_feature>/spec.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

请在浏览器中回答澄清问题后提交反馈，然后执行 /spec-plan
```
