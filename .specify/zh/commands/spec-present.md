---
description: "演示文稿（辅助命令）"
agent:
  id: spec-present
  type: auxiliary
  order: null
  gate: null
  requires_feature: true
  writes_state: false
  output_files: [presentation.html]
  templates: [presentation-template.html]
  components: [slide-deck]
---

# /spec-present — 演示文稿

独立于主线流程，用于生成演示文稿。

## 输入
演示主题和内容：$ARGUMENTS

## 功能定向
- 如果 `$ARGUMENTS` 包含功能编号（`YYYYMMDD-NNN` 格式），定位到该功能目录
- 否则，扫描 `.specify/specs/*/` 中 `.feature-state.json`，找到当前活跃功能
- 辅助命令不更新 .feature-state.json 和 registry.jsonl

## 执行步骤

### 1. 读取模板和组件
- `.specify/templates/presentation-template.html`
- `.specify/templates/components/slide-deck.html`

### 2. 生成演示文稿
在当前功能目录下生成 `presentation.html`：
- 箭头键翻页
- 多张幻灯片
- 清晰的视觉排版

### 3. 输出
```
📄 演示文稿: file:///<绝对路径>/.specify/specs/<current_feature>/presentation.html
```
