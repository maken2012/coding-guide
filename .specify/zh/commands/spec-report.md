---
description: "状态报告 / 事故复盘（辅助命令）"
agent:
  id: spec-report
  type: auxiliary
  order: null
  gate: null
  requires_feature: true
  writes_state: false
  output_files: [report.html]
  templates: [report-template.html]
  components: [status-report, incident-report]
---

# /spec-report — 报告

独立于主线流程，用于生成状态报告或事故复盘。

## 输入
报告类型和描述：$ARGUMENTS

## 功能定向
- 如果 `$ARGUMENTS` 包含功能编号（`YYYYMMDD-NNN` 格式），定位到该功能目录
- 否则，扫描 `.specify/specs/*/` 中 `.feature-state.json`，找到当前活跃功能
- 辅助命令不更新 .feature-state.json 和 registry.jsonl

## 执行步骤

### 1. 读取模板和组件
- `.specify/templates/report-template.html`
- `.specify/templates/components/status-report.html`
- `.specify/templates/components/incident-report.html`

### 2. AI 判断报告类型
- 如涉及 "周报"/"进度"/"状态" → 生成状态报告模式
- 如涉及 "事故"/"故障"/"复盘" → 生成事故复盘模式

### 3. 生成报告文档
在当前功能目录下生成 `report.html`。

### 4. 输出
```
📄 报告: http://localhost:8421/specs/<current_feature>/report.html
```
