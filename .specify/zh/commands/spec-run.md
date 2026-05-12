---
description: "功能全生命周期管理：自动推进 6 个阶段，等待审批后自动进入下一阶段"
agent:
  id: spec-run
  type: lifecycle
  order: null
  gate: null
  requires_feature: false
  writes_state: true
---

# /spec-run — 功能全生命周期管理

## 概述
自动管理一个功能从 /spec-init 到 /spec-review 的完整生命周期。Agent 在每个阶段生成文档后等待用户审批，检测到 approval 后自动推进到下一阶段。

## 输入
- `/spec-run "功能描述"` — 创建新功能并走完全生命周期
- `/spec-run YYYYMMDD-NNN-<name>` — 接管已有功能，从当前阶段继续

## 执行流程

### 0. 初始化
- 生成唯一 session ID（格式：`sess-<8位随机字符>`）
- 如果参数是新功能描述：
  - 创建功能目录（`YYYYMMDD-NNN-<name>`）
  - 初始化 `.feature-state.json`
  - 向 `registry.jsonl` 追加 `feature_created` 事件
  - 从阶段 1 (spec) 开始
- 如果参数是已有功能编号：
  - 读取 `.feature-state.json`，找到当前阶段
  - 从该阶段继续执行

### 1. 阶段执行循环
按顺序执行以下阶段，每个阶段完成后等待审批：

```
阶段 1: /spec-init 逻辑 → 生成 spec.html → 等待审批
阶段 2: /spec-detail 逻辑 → 生成 detail.html → 等待审批
阶段 3: /spec-design 逻辑 → 生成 design/*.html → 等待所有审批
阶段 4: /spec-plan 逻辑 → 生成 plan.html + tasks.html → 等待审批
阶段 5: /spec-implement 逻辑 → 编码 + 测试 → 等待审批
阶段 6: /spec-review 逻辑 → 审查 + 部署方案 → 等待审批
```

### 2. 反应式等待（每个阶段通用）
生成文档后进入轮询模式：
- 使用 ScheduleWakeup 每 60-120 秒检查对应 `.feedback.json` 的 `review.verdict`（同时可通过 `curl -s http://localhost:8421/api/phases/<feature_id>` 获取阶段状态）
- `null` → 继续等待，输出：⏳ 阶段 N/6 等待审批: http://localhost:8421/specs/<feature_id>/xxx.html
- `"approved"` → 更新 `.feature-state.json`，追加 `phase_approved` 事件，进入下一阶段
- `"rejected"` → 读取反馈，修改文档，重新提交等待

### 3. 阶段转换
- 每个阶段开始时更新 `.feature-state.json`：对应 phase status = `"in_progress"`
- 每个阶段审批后更新：对应 phase status = `"approved"`
- 向 `registry.jsonl` 追加 `phase_started` 和 `phase_completed` 事件
- 确保反馈服务正在运行（如未运行则执行 `bash .claude/hooks/start-feedback-server.sh`）
- **Sync to database**: `curl -s -X POST http://localhost:8421/api/sync`

### 4. 生命周期完成
当阶段 6 (review) 审批通过后：
- 更新 `.feature-state.json`：`pipeline.review.status` = `"approved"`
- 向 `registry.jsonl` 追加 `lifecycle_complete` 事件
- 确保反馈服务正在运行（如未运行则执行 `bash .claude/hooks/start-feedback-server.sh`）
- **Sync to database**: `curl -s -X POST http://localhost:8421/api/sync`
- 输出完成总结

### 5. 输出
```
🎉 功能生命周期完成！

功能: 20260512-001-user-auth
耗时: X 小时 Y 分钟
阶段完成:
  ✅ spec      → spec.html
  ✅ detail    → detail.html
  ✅ design    → flow-design.html, db-design.html, api-design.html
  ✅ plan      → plan.html, tasks.html
  ✅ implement → test-report.html
  ✅ review    → review.html, deploy-plan.html

📋 Dashboard: http://localhost:8421
```

## 参考文件
每个阶段的详细执行逻辑，参照对应命令文件：
- 阶段 1: `.claude/commands/spec-init.md` 中的执行步骤
- 阶段 2: `.claude/commands/spec-detail.md` 中的执行步骤
- 阶段 3: `.claude/commands/spec-design.md` 中的执行步骤
- 阶段 4: `.claude/commands/spec-plan.md` 中的执行步骤
- 阶段 5: `.claude/commands/spec-implement.md` 中的执行步骤
- 阶段 6: `.claude/commands/spec-review.md` 中的执行步骤
