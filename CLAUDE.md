# 项目规则

## 宪章
- 读取 .specify/constitution.md 并遵守所有不变量
- 任何功能规范不得违反宪章原则

## 工作流总览

主线 6 步 + 辅助 4 步。每个主线命令根据项目上下文**动态决定**生成哪些子文档。

### 主线流程

```
/spec-init → /spec-detail → /spec-design → /spec-plan → /spec-implement → /spec-review
架构选型      需求详述       一站式设计     计划+任务     开发+测试       审查+部署
```

### 辅助命令（独立于主线）

```
/spec-explore   → 独立探索对比
/spec-research  → 技术调研
/spec-report    → 状态报告 / 事故复盘
/spec-present   → 演示文稿
```

---

## 主线命令 → 模板 → 组件映射

### /spec-init（架构选型 + 高层需求）

**门禁**：无

**动态产出逻辑**：
- 始终生成：`spec.html`
- 如涉及架构决策：内嵌架构对比（引用 `exploration-approaches` 组件模式）
- 如涉及技术栈选型：内嵌技术选型对比
- 如涉及部署架构：生成 `arch-diagram.html`（引用 `flowchart-diagram` 组件模式）

**引用组件**：
- `exploration-approaches` — 架构方案对比
- `exploration-visual-designs` — 视觉方向对比（前端项目）
- `flowchart-diagram` — 系统架构图
- `spec-template` — 需求规格骨架

**产出文件**：
```
specs/<NNN>-<name>/
├── spec.html                    # 必生成
├── spec.feedback.json           # 必生成
└── arch-diagram.html            # 按需（架构图）
    arch-diagram.feedback.json
```

### /spec-detail（需求详述）

**门禁**：`spec.feedback.verdict = approved`

**动态产出逻辑**：
- 始终生成：`detail.html`（输入输出、交互流程、业务规则、异常处理）
- 如有前端交互：内嵌交互流程图（引用 `flowchart-diagram`）
- 如有复杂业务逻辑：内嵌时序图 / 状态机图
- 如有多方案需求：内嵌方案对比（引用 `exploration-approaches`）

**引用组件**：
- `flowchart-diagram` — 业务流程图、时序图、状态机
- `exploration-approaches` — 需求方案对比
- `feature-explainer` — 复杂功能原理说明

**产出文件**：
```
specs/<NNN>-<name>/
├── detail.html                  # 必生成
├── detail.feedback.json         # 必生成
└── (按需内嵌在 detail.html 中)
```

### /spec-design（一站式设计）

**门禁**：`detail.feedback.verdict = approved`

**动态产出逻辑**：AI 分析项目类型，自动决定生成哪些设计文档：

| 项目类型 | 生成的设计文档 | 跳过的 |
|---------|--------------|-------|
| 全栈项目 | flow + db + api + ui | 无 |
| 纯后端 API | flow + db + api | ui |
| 纯前端 SPA | flow + ui | db, api |
| 数据/ETL | flow + db | api, ui |
| CLI 工具 | flow | db, api, ui |

**引用组件**：
- `flow-design` 子文档 → `flowchart-diagram`（流程图）、`svg-illustrations`（示意图）
- `db-design` 子文档 → `code-understanding`（ER关系图模式）
- `api-design` 子文档 → `feature-explainer`（标签式代码展示）
- `ui-design` 子文档 → `design-system`（设计令牌）、`component-variants`（组件矩阵）、`prototype-animation`（动效）、`prototype-interaction`（交互原型）

**产出文件**：
```
specs/<NNN>-<name>/
├── design/
│   ├── flow-design.html         # 业务流程/时序图
│   ├── flow-design.feedback.json
│   ├── db-design.html           # 数据表设计（按需）
│   ├── db-design.feedback.json
│   ├── api-design.html          # 接口契约（按需）
│   ├── api-design.feedback.json
│   ├── ui-design.html           # UI/UX 设计（按需）
│   └── ui-design.feedback.json
```

### /spec-plan（计划 + 任务拆解）

**门禁**：`design/*.feedback.verdict = approved`（所有已生成的设计文档都通过）

**动态产出逻辑**：
- 始终生成：`plan.html` + `tasks.html`
- 计划中按需内嵌依赖关系图（引用 `implementation-plan` 组件模式）
- 任务中按需内嵌优先级排序（引用 `triage-board` 组件模式）

**引用组件**：
- `implementation-plan` — 分阶段计划 + 依赖关系
- `triage-board` — 任务优先级拖拽排序
- `slide-deck` — 如需向团队展示计划

**产出文件**：
```
specs/<NNN>-<name>/
├── plan.html                    # 必生成
├── plan.feedback.json
├── tasks.html                   # 必生成
└── tasks.feedback.json
```

### /spec-implement（开发 + 测试）

**门禁**：`tasks.feedback.verdict = approved`

**动态产出逻辑**：
- 按任务编号顺序编码
- 每个任务完成后自动生成对应单元测试
- 所有任务完成后生成集成测试
- 生成测试报告

**引用组件**：
- `status-report` — 测试报告中的进度展示
- `annotated-pr-review` — 测试覆盖率审查

**产出文件**：
```
specs/<NNN>-<name>/
├── (代码文件)
├── test-report.html             # 测试报告
└── test-report.feedback.json
```

### /spec-review（审查 + 部署）

**门禁**：有代码变更

**动态产出逻辑**：
- 始终生成：`review.html`（代码审查）
- 如涉及部署：生成 `deploy-plan.html`（配置、数据库迁移、初始化、依赖组件）
- 如涉及功能开关：内嵌 `feature-flags-editor` 组件模式

**引用组件**：
- `annotated-pr-review` — 带批注的代码审查
- `pr-writeup` — 变更摘要
- `flowchart-diagram` — 部署流水线图
- `feature-flags-editor` — 功能开关配置

**产出文件**：
```
specs/<NNN>-<name>/
├── review.html                  # 必生成
├── review.feedback.json
├── deploy-plan.html             # 按需
└── deploy-plan.feedback.json
```

---

## 辅助命令 → 模板 → 组件映射

### /spec-explore（独立探索对比）
- 模板：`exploration-template.html`
- 组件：`exploration-approaches`、`exploration-visual-designs`
- 产出：`exploration.html`

### /spec-research（技术调研）
- 模板：`research-template.html`
- 组件：`feature-explainer`、`concept-explainer`、`code-understanding`
- 产出：`research.html`

### /spec-report（状态报告 / 事故复盘）
- 模板：`report-template.html`
- 组件：`status-report`（周报）、`incident-report`（事故复盘）
- 产出：`report.html`

### /spec-present（演示文稿）
- 模板：`presentation-template.html`
- 组件：`slide-deck`
- 产出：`presentation.html`

---

## 通用规则

### 文档生成规则
- 所有面向人的文档必须以自包含 HTML 输出（内联 CSS/JS，零外部依赖）
- HTML 必须参照 .specify/templates/ 中对应模板的结构和样式
- 每个阶段完成后更新 .feature-state.json 并确保反馈服务正在运行（bash .claude/hooks/start-feedback-server.sh），dashboard 通过 http://localhost:8421 实时查询 SQLite 数据库
- **状态同步**：写入 .feature-state.json、.feedback.json 或 registry.jsonl 后，必须主动通知服务器同步：`curl -s -X POST http://localhost:8421/api/sync`（同步是幂等全量对账，每次调用扫描所有文件，失败后重试自然覆盖之前未同步的数据）
- 终端输出格式：📄 待审核: http://localhost:8421/specs/<feature_id>/xxx.html
- 生成待审核 HTML 后自动执行 `open http://localhost:8421` 在浏览器中打开 dashboard，用户可在 dashboard 中审核所有文档
- 阶段门禁：读取 .feedback.json 中 review.verdict，只有 "approved" 才进入下一阶段

### 反馈处理规则
- 生成 HTML 时同时生成对应的 .feedback.json 骨架
- 用户在 HTML 中操作后，反馈写入 .feedback.json
- 下一轮执行前先读取 .feedback.json，按用户决策调整
- 驳回时读取 review.feedback，修改后重新提交

### 并行 Agent 规则
- 每个 Agent 只操作自己负责的功能目录
- 不读取、不修改其他功能目录下的文件
- dashboard.html 由最后完成的 Agent 确保反馈服务正在运行，dashboard 自动刷新

### HTML 组件使用规则
- 读取 .specify/templates/components/ 下的组件文件作为结构和样式参考
- 不直接复制组件文件，而是模仿其 HTML 结构、CSS 样式、JS 交互模式
- 所有用户操作通过统一的反馈机制（saveFeedback 函数）对接 .feedback.json
- 每个组件提供 SLOT:content 占位符用于内容替换

### .feedback.json 结构规范
每个反馈文件必须包含以下结构：
{
  "artifact": "文件名.html",
  "feature": "功能目录名",
  "phase": "spec|detail|design|plan|implement|review",
  "status": "pending_review",
  "decisions": [
    { "id": "决策ID", "type": "single-select|multi-select|text-input|review", "options": [...], "selected": null, "note": "" }
  ],
  "review": { "verdict": null, "feedback": "", "timestamp": null },
  "created_at": "ISO时间",
  "updated_at": "ISO时间"
}

### 看板 dashboard.html 维护规则
- Dashboard 由 feedback-server.py 提供（http://localhost:8421），动态查询 SQLite 数据库
- 左侧 25%：总览统计 + 时间线 + 功能列表（含决策折叠摘要）
- 右侧 75%：当前选中功能的当前阶段文档（通过 iframe 加载）或已通过状态卡片
- 底部：通过/驳回审核按钮（已通过的功能隐藏审核栏）
- 每次生成或更新任何规范文档后，确保反馈服务正在运行，dashboard 自动展示最新数据
