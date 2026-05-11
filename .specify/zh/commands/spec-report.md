---
description: "状态报告 / 事故复盘（辅助命令）"
---

# /spec-report — 报告

独立于主线流程，用于生成状态报告或事故复盘。

## 输入
报告类型和描述：$ARGUMENTS

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
📄 报告: file:///<绝对路径>/.specify/specs/<current_feature>/report.html
```
