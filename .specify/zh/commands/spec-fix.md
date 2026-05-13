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
  output_files: [fix-log.jsonl]
  templates: []
  components: [status-report, annotated-pr-review]
---

# /spec-fix — Bug 修复跟踪

## 输入
用户提供功能 ID 和问题描述：$ARGUMENTS

## 功能定位
- 如果 `$ARGUMENTS` 包含功能 ID（匹配 `YYYYMMDD-NNN`），定位该功能目录
- 否则，扫描 `.specify/specs/*/` 查找最近一个在 implement 或之后阶段的功能

## 前置条件
- 该功能的 implement 或 review 阶段已开始

## 执行步骤

### 1. 读取上下文
- 读取 `.feature-state.json` 了解当前状态
- 读取相关阶段的 spec.html / detail.html / design/ 了解原始需求
- 分析用户描述的问题

### 2. 诊断与定位
- 根据问题描述定位受影响的文件和代码
- 分析根因（需求偏差 / 实现错误 / 边界遗漏 / 环境问题）

### 3. 实施修复
- 修改代码或文档
- 运行相关测试验证修复
- 如无测试，为修复点编写最小测试

### 4. 记录修复日志
在功能目录下追加 `fix-log.jsonl`（如不存在则创建）：
```json
{"id":1,"ts":"<服务器时间>","issue":"<问题描述>","phase":"<发生阶段>","root_cause":"<根因>","files_changed":["path1","path2"],"fix_summary":"<修复摘要>","tests":["<测试命令>"],"status":"fixed"}
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
根因: <根因分析>
修改: <文件列表>
测试: <结果>

修复日志: .specify/specs/<feature_id>/fix-log.jsonl
```
