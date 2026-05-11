---
description: "初始化新功能规范（Spec-Driven Development 第一步）"
---

# /spec-init — 初始化新功能规范

你正在执行 Spec-Driven Development 工作流的第一步：初始化新功能的需求规格。

## 输入

用户提供功能描述文本作为参数：$ARGUMENTS

## 执行步骤

### 1. 读取项目宪章

读取 `.specify/constitution.md`，了解项目不变量。

### 2. 生成功能编号和目录

- 扫描 `.specify/specs/` 目录，找到最大编号
- 新编号 = 最大编号 + 1（三位数，如 001、002）
- 从功能描述中提取简短英文名（kebab-case）
- 创建目录 `.specify/specs/<NNN>-<name>/`
- 创建子目录 `artifacts/` 和 `clarifications/`

### 3. 读取模板

读取 `.specify/templates/spec-template.html`，理解章节结构。

### 4. 生成 spec.html

基于模板结构生成 `.specify/specs/<NNN>-<name>/spec.html`，内容要求：

- **概述**：一句话描述功能目标
- **背景与动机（WHY）**：为什么需要这个功能，解决什么问题
- **功能需求（WHAT）**：按用户故事组织，格式：
  ```
  US1: 作为 <角色>，我想要 <行为>，以便 <目的>
  验收标准：
  - <条件1>
  - <条件2>
  ```
- **非功能需求**：性能、安全、可用性等（如适用）
- **约束与假设**：技术约束、业务约束
- 只描述 WHAT 和 WHY，不涉及 HOW

所有 CSS 内联，零外部依赖。参照 spec-template.html 的样式。

### 5. 生成反馈骨架

生成 `.specify/specs/<NNN>-<name>/spec.feedback.json`：

```json
{
  "artifact": "spec.html",
  "feature": "<NNN>-<name>",
  "phase": "spec",
  "status": "pending_review",
  "decisions": [],
  "review": { "verdict": null, "feedback": "", "timestamp": null },
  "created_at": "<当前ISO时间>",
  "updated_at": "<当前ISO时间>"
}
```

### 6. 更新看板

- 更新或创建 `.specify/specs/dashboard-state.json`：
  - 在 `features` 数组中添加新功能条目
  - 设置 `current_feature` 为新功能目录名
  - 在 `timeline` 中添加 `spec_created` 事件
- 基于 `.specify/templates/dashboard.html` 重建 `.specify/specs/dashboard.html`
  - 将 dashboard-state.json 内容嵌入 `<script type="application/json" id="dashboardState">` 标签

### 7. 输出结果

在终端输出：

```
✅ 功能规范已创建！

📄 需求规格: file:///<绝对路径>/.specify/specs/<NNN>-<name>/spec.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

下一步：
1. 在浏览器中打开 spec.html 审核需求
2. 如需澄清，执行 /spec-clarify
3. 审核通过后，执行 /spec-plan 进入方案设计
```

## 错误处理

- 如果 `.specify/constitution.md` 不存在，报错并提示先创建宪章
- 如果功能描述为空，报错并提示提供描述
- 如果目录已存在，报错并建议使用不同名称
