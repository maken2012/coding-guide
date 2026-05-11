---
description: "架构选型 + 高层需求（Spec-Driven Development 第一步）"
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
- 扫描 `.specify/specs/` 最大编号，新编号 +1
- 创建 `.specify/specs/<NNN>-<name>/`

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

### 5. 更新看板
更新 `dashboard-state.json` 和 `dashboard.html`。

### 6. 输出
```
✅ 功能规范已创建！

📄 需求规格: file:///<绝对路径>/.specify/specs/<NNN>-<name>/spec.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

下一步：执行 /spec-detail 进行需求详述
```
