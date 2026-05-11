---
description: "技术调研（辅助命令）"
---

# /spec-research — 技术调研

独立于主线流程，用于深入调研某项技术或概念。

## 输入
调研主题：$ARGUMENTS

## 执行步骤

### 1. 读取模板和组件
- `.specify/templates/research-template.html`
- `.specify/templates/components/feature-explainer.html`
- `.specify/templates/components/concept-explainer.html`
- `.specify/templates/components/code-understanding.html`

### 2. 生成调研文档
在当前功能目录下生成 `research.html`：
- 调研背景
- 技术概述（可折叠步骤 + 标签代码）
- 核心概念（交互式图解）
- 代码结构（调用链）
- 结论与建议

### 3. 输出
```
📄 调研文档: file:///<绝对路径>/.specify/specs/<current_feature>/research.html
```
