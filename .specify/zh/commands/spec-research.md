---
description: "技术调研（辅助命令）"
agent:
  id: spec-research
  type: auxiliary
  order: null
  gate: null
  requires_feature: true
  writes_state: false
  output_files: [research.html]
  templates: [research-template.html]
  components: [feature-explainer, concept-explainer, code-understanding]
---

# /spec-research — 技术调研

独立于主线流程，用于深入调研某项技术或概念。

## 输入
调研主题：$ARGUMENTS

## 功能定向
- 如果 `$ARGUMENTS` 包含功能编号（`YYYYMMDD-NNN` 格式），定位到该功能目录
- 否则，扫描 `.specify/specs/*/` 中 `.feature-state.json`，找到当前活跃功能
- 辅助命令不更新 .feature-state.json 和 registry.jsonl

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
