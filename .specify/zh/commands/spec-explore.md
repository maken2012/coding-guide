---
description: "独立探索对比（辅助命令）"
---

# /spec-explore — 探索对比

独立于主线流程，用于技术选型、方案对比等探索性工作。

## 输入
探索问题：$ARGUMENTS

## 执行步骤

### 1. 读取模板和组件
- `.specify/templates/exploration-template.html`
- `.specify/templates/components/exploration-approaches.html`
- `.specify/templates/components/exploration-visual-designs.html`

### 2. 生成探索文档
在当前功能目录下生成 `exploration.html`：
- 问题描述
- 2-4 个方案并排对比（卡片 + 优缺点 + radio 选择）
- 推荐结论
- 反馈机制

### 3. 输出
```
📄 探索文档: file:///<绝对路径>/.specify/specs/<current_feature>/exploration.html
```
