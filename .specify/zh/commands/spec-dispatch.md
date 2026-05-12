---
description: "多 Agent 派发分析：扫描功能状态，建议并行执行方案"
agent:
  id: spec-dispatch
  type: orchestrator
  order: null
  gate: null
  requires_feature: false
  writes_state: false
---

# /spec-dispatch — 多 Agent 派发分析

## 概述
扫描所有功能的状态，分析哪些工作可以并行执行，输出派发建议。

## 执行步骤

### 1. 扫描功能状态
- 列出 `.specify/specs/YYYYMMDD-NNN-*/` 下所有功能目录
- 读取每个功能的 `.feature-state.json`
- 检查 `.agent-lock` 判断是否被其他 Agent 占用

### 2. 分析可派发工作
对每个未锁定的功能，根据管线状态判断下一步：

| 当前状态 | 可派发命令 |
|---------|-----------|
| pipeline.spec.status = null | /spec-init |
| pipeline.spec.status = approved, detail = not_started | /spec-detail |
| pipeline.detail.status = approved, design = not_started | /spec-design |
| pipeline.design.status = approved, plan = not_started | /spec-plan |
| pipeline.plan.status = approved, implement = not_started | /spec-implement |
| pipeline.implement.status = approved, review = not_started | /spec-review |

### 3. 检查门禁条件
对每个可派发命令，验证其门禁条件：
- 读取对应的 `.feedback.json` 文件
- 确认 `review.verdict = "approved"`
- 检查功能目录未被锁定

### 4. 输出派发方案
```
╔══════════════════════════════════════════════════╗
║  SDD Dispatch Analysis                            ║
╚══════════════════════════════════════════════════╝

功能总数: 3
活跃 Agent: 1
可派发: 2

管线状态:
  001-user-auth    ✅ ✅ 🔄 ⬜ ⬜ ⬜  [Agent-A: spec-design]
  002-data-export  ✅ 🔄 ⬜ ⬜ ⬜ ⬜
  003-payment      🔄 ⬜ ⬜ ⬜ ⬜ ⬜

派发建议:
  [1] 002-data-export → /spec-detail
      终端: claude "/spec-detail 20260512-002-data-export"

  [2] 003-payment → (等待 spec 阶段审批)

可用并行度: 1 个新 Agent 可立即启动

批量启动:
  终端 1: claude "/spec-detail 20260512-002-data-export"
```

### 5. 可选：直接执行
如果用户确认，为每个可派发任务输出启动命令。
