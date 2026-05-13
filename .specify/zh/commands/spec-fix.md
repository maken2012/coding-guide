---
description: "Bug 修复跟踪（Spec-Driven Development 修复指令）"
agent:
  id: spec-fix
  type: auxiliary
  order: null
  gate: "implement.status != not_started"
  produces_gate: null
  requires_feature: true
  writes_state: true
  output_files: [fix-log.jsonl, fix-plan.html]
  templates: []
  components: [status-report, annotated-pr-review]
---

# /spec-fix — Bug 修复跟踪

## 输入
用户提供功能 ID 和问题描述：$ARGUMENTS

如果 `$ARGUMENTS` 以 `--plan` 开头，强制使用规划模式（见下方）。

## 功能定位
- 如果 `$ARGUMENTS` 包含功能 ID（匹配 `YYYYMMDD-NNN`），定位该功能目录
- 否则，扫描 `.specify/specs/*/` 查找最近一个在 implement 或之后阶段的功能

## 前置条件
- 该功能的 implement 或 review 阶段已开始

## 执行步骤

### 1. 诊断与定级

- 读取 `.feature-state.json` 了解当前状态
- 读取 `spec.html` 和 `detail.html` 了解原始需求
- 根据问题描述定位受影响的文件和代码
- 分析根因（需求偏差 / 实现错误 / 边界遗漏 / 环境问题）
- **评估复杂度**，决定走快速修复还是规划修复：

| 信号 | 级别 | 路径 |
|------|------|------|
| 改 1-2 个文件，无连锁影响 | 简单 | 快速修复 |
| 改 3+ 个文件，或跨模块 | 中等 | 规划修复 |
| 涉及数据迁移 / 架构变更 / 性能回退 | 复杂 | 规划修复 |
| 用户指定 `--plan` | 任意 | 规划修复 |

### 2A. 快速修复（简单问题）

直接跳到步骤 3 实施。

### 2B. 规划修复（中/复杂问题）

生成 `fix-plan.html`，包含以下章节：

#### 2B.1 问题描述
- 现象（用户看到什么）
- 根因（为什么发生）
- 影响范围（哪些功能/模块受影响）

#### 2B.2 修复方案
- 修复策略（至少 2 种方案对比，推荐其中一种）
- 涉及文件列表及每个文件的修改概要
- 风险评估（修改可能引发的副作用）
- 回滚方案（如果修复引入新问题）

#### 2B.3 验证计划
- 修复点测试
- 回归测试范围（确保修复不影响其他功能）
- 手动验证清单

#### 2B.4 等待审批

生成修复方案后，进入等待审批模式：
- 输出：📄 修复方案待审核: http://localhost:8421/specs/<feature_id>/fix-plan.html
- 等待用户在 fix-plan.html 中确认方案（或直接口头确认）
- 确认后进入步骤 3 实施

### 3. 实施修复

- 按 fix-plan.html 的方案（快速修复则按诊断结果直接修复）
- 修改代码或文档
- 运行相关测试验证修复
- 运行回归测试（如有）
- 如无测试，为修复点编写最小测试

### 4. 记录修复日志
在功能目录下追加 `fix-log.jsonl`（如不存在则创建）：
```json
{"id":1,"ts":"<服务器时间>","issue":"<问题描述>","severity":"<simple|medium|complex>","phase":"<发生阶段>","root_cause":"<根因>","files_changed":["path1","path2"],"fix_summary":"<修复摘要>","has_plan":true,"tests":["<测试命令>"],"regression":"<回归测试结果>","status":"fixed"}
```

序号 = 文件中已有行数 + 1。

### 5. 更新状态
- 更新 `.feature-state.json`：`fix_count` +1，`last_fix` 记录最新修复时间
- 确保反馈服务正在运行（`bash .claude/hooks/start-feedback-server.sh`）
- **同步到数据库**：`curl -s -X POST http://localhost:8421/api/sync`

### 6. 输出
```
🔧 修复已归档！

功能: <功能名称>
修复 #<N>: <问题描述>
级别: 简单 / 中等 / 复杂
根因: <根因分析>
修改: <文件列表>
测试: <结果>
回归: <回归测试结果>

修复日志: .specify/specs/<feature_id>/fix-log.jsonl
```
