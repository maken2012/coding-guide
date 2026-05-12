---
description: "独立探索对比（辅助命令）"
agent:
  id: spec-explore
  type: auxiliary
  order: null
  gate: null
  requires_feature: true
  writes_state: false
  output_files: [exploration.html]
  templates: [exploration-template.html]
  components: [exploration-approaches, exploration-visual-designs]
---

# /spec-explore — 探索对比

独立于主线流程，用于技术选型、方案对比等探索性工作。

## 输入
探索问题：$ARGUMENTS

## 功能定向
- 如果 `$ARGUMENTS` 包含功能编号（`YYYYMMDD-NNN` 格式），定位到该功能目录
- 否则，扫描 `.specify/specs/*/` 中 `.feature-state.json`，找到当前活跃功能
- 辅助命令不更新 .feature-state.json 和 registry.jsonl

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
