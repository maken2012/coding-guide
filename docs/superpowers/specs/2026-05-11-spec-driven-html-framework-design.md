# Spec-Driven Development + HTML 可视化输出框架

> 设计日期：2026-05-11
> 状态：待审核

---

## 一、背景与目标

### 1.1 问题

AI 编程工具（如 Claude Code）在处理复杂项目时存在以下痛点：

- **缺乏结构化约束**：AI 容易偏离需求，遗漏边界条件，输出不可控
- **文档可读性差**：Markdown 格式的长文档难以快速理解，缺乏交互性
- **缺乏可视化反馈**：需求→设计→开发→测试的全流程中，人机协作缺少直观的审核界面
- **单人模式限制**：多 Agent 并行开发时缺少统一的进度跟踪和审核机制

### 1.2 目标

构建一套**通用、不绑定技术栈**的规范驱动开发（Spec-Driven Development）框架：

1. 所有面向人的文档以**自包含 HTML** 输出（内联 CSS/JS，零外部依赖，浏览器直接打开）
2. 面向 AI 的指令以 **Markdown** 格式存储（CLAUDE.md、斜杠命令、宪章）
3. 原生运行在 **Claude Code** 内，通过 CLAUDE.md 规则 + 斜杠命令 + hooks 实现
4. 支持**多 Agent 并行**，每个功能产出的审核反馈完全隔离
5. 提供**看板主页（Dashboard）**作为统一的审核入口和进度总览

### 1.3 设计原则

- **零构建依赖**：所有 HTML 纯手写 CSS/JS，不需要 Node/Webpack/Vite
- **不绑定技术栈**：模板无"前端框架"、"数据库类型"等预设
- **文件系统通信**：HTML 中的交互操作写入 `.feedback.json`，AI 下一轮读取
- **渐进扩展**：单人文件驱动 → 多人 Git 协作 → 团队后端服务，架构不需推倒重来

---

## 二、目录结构

```
your-project/
├── src/                              # 业务代码，不受干扰
├── package.json
├── ...
│
├── CLAUDE.md                         # 项目总控规则（AI 行为控制）
├── .specify/                         # 规范子系统（隐藏目录）
│   ├── constitution.md               # 项目宪章（不变量定义）
│   ├── templates/                    # HTML 组件模板库（提交 git）
│   │   ├── dashboard.html            # 看板主页模板
│   │   ├── spec-template.html        # 需求规格模板
│   │   ├── plan-template.html        # 技术方案模板
│   │   ├── tasks-template.html       # 任务清单模板
│   │   ├── review-template.html      # 审查报告模板
│   │   └── components/               # 20 种可复用 HTML 组件
│   │       ├── exploration-approaches.html
│   │       ├── exploration-visual-designs.html
│   │       ├── implementation-plan.html
│   │       ├── annotated-pr-review.html
│   │       ├── pr-writeup.html
│   │       ├── code-understanding.html
│   │       ├── design-system.html
│   │       ├── component-variants.html
│   │       ├── prototype-animation.html
│   │       ├── prototype-interaction.html
│   │       ├── svg-illustrations.html
│   │       ├── flowchart-diagram.html
│   │       ├── slide-deck.html
│   │       ├── feature-explainer.html
│   │       ├── concept-explainer.html
│   │       ├── status-report.html
│   │       ├── incident-report.html
│   │       ├── triage-board.html
│   │       ├── feature-flags-editor.html
│   │       └── prompt-tuner.html
│   └── specs/                        # 运行时生成的规范文档（纳入 git 版本控制）
│       ├── dashboard.html            # 看板主页（AI 自动维护）
│       ├── dashboard-state.json      # 看板全局状态
│       ├── 001-<feature-name>/       # 每个功能一个目录
│       │   ├── spec.html
│       │   ├── spec.feedback.json
│       │   ├── plan.html
│       │   ├── plan.feedback.json
│       │   ├── tasks.html
│       │   ├── tasks.feedback.json
│       │   ├── review.html           # 按需生成
│       │   ├── review.feedback.json
│       │   ├── artifacts/            # 衍生文档
│       │   │   ├── data-model.html
│       │   │   ├── data-model.feedback.json
│       │   │   ├── api-contracts.html
│       │   │   ├── api-contracts.feedback.json
│       │   │   ├── architecture.html
│       │   │   └── architecture.feedback.json
│       │   └── clarifications/       # 澄清记录
│       │       └── session-<date>.html
│       ├── 002-<feature-name>/       # 结构同上，完全隔离
│       └── ...
│
├── .claude/                          # Claude Code 原生配置
│   ├── commands/                     # 斜杠命令（MD 格式，AI 读取执行）
│   │   ├── spec-init.md
│   │   ├── spec-clarify.md
│   │   ├── spec-plan.md
│   │   ├── spec-tasks.md
│   │   ├── spec-review.md
│   │   └── spec-implement.md
│   ├── settings.json                 # hooks、权限配置
│   └── hooks/
│       ├── pre-spec-check.sh
│       └── post-task-verify.sh
│
└── .gitignore
    .DS_Store
    # 所有规范文档和反馈记录都纳入 git 版本控制（留痕追溯）
```

### 2.1 文件格式职责划分

| 角色 | 格式 | 谁读 | 例子 |
|------|------|------|------|
| 指令文件（告诉 AI 怎么做） | `.md` | Claude Code 读取执行 | `CLAUDE.md`、斜杠命令、`constitution.md` |
| 产出文件（AI 生成交付物） | `.html` | 人类浏览器打开阅读 | `spec.html`、`plan.html`、`tasks.html` |
| 反馈文件（人→AI 通信） | `.feedback.json` | AI 读取用户决策 | `spec.feedback.json`、`plan.feedback.json` |
| 模板参考（AI 模仿结构） | `.html` | AI 读取后模仿生成 | `templates/` 下所有文件 |

### 2.2 数据流向

```
用户输入 /spec-plan
    ↓
Claude Code 读取 .claude/commands/spec-plan.md（MD 指令）
    ↓
读取 templates/plan-template.html + templates/components/*（HTML 模板参考）
    ↓
读取 .specify/specs/001-xxx/spec.feedback.json（检查前置条件）
    ↓
生成 .specify/specs/001-xxx/plan.html（HTML 产出）
    ↓
生成 .specify/specs/001-xxx/plan.feedback.json（反馈骨架）
    ↓
更新 .specify/specs/dashboard.html（看板刷新）
    ↓
终端输出路径，用户浏览器打开审核
```

---

## 三、工作流阶段

### 3.1 阶段总览

| 阶段 | 命令 | 输出 | 门禁条件 |
|------|------|------|----------|
| 1. 初始化 | `/spec-init "描述"` | `spec.html` + `spec.feedback.json` | 无 |
| 2. 澄清 | `/spec-clarify` | 更新 `spec.html`（嵌入交互式问题） | `spec.feedback.json` 存在 |
| 3. 方案设计 | `/spec-plan` | `plan.html` + `artifacts/*` + `plan.feedback.json` | `spec.feedback.verdict = approved` |
| 4. 任务拆解 | `/spec-tasks` | `tasks.html` + `tasks.feedback.json` | `plan.feedback.verdict = approved` |
| 5. 执行实现 | `/spec-implement` | 代码文件 + 更新 `tasks.html` 进度 | `tasks.feedback.verdict = approved` |
| 6. 审查 | `/spec-review` | `review.html` + `review.feedback.json` | 有代码变更 |

### 3.2 阶段门禁

每个阶段只有上一阶段的 `.feedback.json` 中 `review.verdict` 为 `"approved"` 时才能启动。AI 在执行斜杠命令前必须：

1. 定位当前功能目录（读取 `dashboard-state.json` 中的 `current_feature`）
2. 检查上一阶段的 `.feedback.json` 是否存在且 `verdict = approved`
3. 门禁不通过则拒绝执行，输出提示信息

### 3.3 各阶段详细说明

#### 阶段 1：`/spec-init "功能描述"`

**输入**：用户提供的功能描述文本

**执行逻辑**：
1. 读取 `constitution.md` 获取项目不变量
2. 自动生成功能编号（扫描 `specs/` 目录，递增）
3. 创建功能目录 `specs/<NNN>-<name>/`
4. 读取 `templates/spec-template.html` 和相关组件
5. 生成 `spec.html`，内容只描述 **WHAT（做什么）** 和 **WHY（为什么）**，不涉及 HOW
6. 生成 `spec.feedback.json` 骨架
7. 更新 `dashboard.html` 和 `dashboard-state.json`
8. 终端输出：`📄 待审核: file:///.../spec.html`

#### 阶段 2：`/spec-clarify`

**输入**：无（自动分析当前 `spec.html`）

**执行逻辑**：
1. 分析 `spec.html` 中的需求，识别模糊点
2. 生成最多 5 个澄清问题，嵌入 `spec.html` 的交互区域
3. 问题类型包括：功能范围、数据模型、交互流程、非功能需求、边界条件、外部依赖、约束权衡、术语定义
4. 每个问题附带推荐选项（基于最佳实践）
5. 用户在 HTML 中选择/填写后，反馈写入 `spec.feedback.json`
6. 更新 `dashboard.html`

#### 阶段 3：`/spec-plan`

**输入**：无（读取已通过的 spec 和 clarification 反馈）

**执行逻辑**：
1. 读取 `spec.feedback.json` 确认 `verdict = approved`
2. 读取 `spec.feedback.json` 中的 `decisions` 了解用户选择
3. 读取 `constitution.md` 确保方案合规
4. 生成 `plan.html`，描述 **HOW（怎么做）**
5. 按需生成 `artifacts/` 下的衍生文档：
   - `data-model.html` — 数据模型
   - `api-contracts.html` — API 契约
   - `architecture.html` — 架构图（使用 flowchart-diagram 组件）
6. 为每个 HTML 文件生成对应的 `.feedback.json` 骨架
7. 方案中如涉及多选一决策（如架构选型、技术栈选择），嵌入交互式选项
8. 更新 `dashboard.html`

#### 阶段 4：`/spec-tasks`

**输入**：无（读取已通过的 plan）

**执行逻辑**：
1. 读取 `plan.feedback.json` 确认 `verdict = approved`
2. 读取 `plan.html` 和 `artifacts/*` 了解完整技术方案
3. 生成 `tasks.html`，格式：`- [ ] T001 [P] [US1] 描述 含文件路径`
4. 任务按阶段排列：Setup → 基础设施 → 用户故事（P1, P2...）→ 收尾
5. 标记可并行项 `[P]`
6. 每个用户故事的任务必须可独立测试
7. 生成 `tasks.feedback.json` 骨架（用户可调整优先级、拖拽排序）
8. 更新 `dashboard.html`

#### 阶段 5：`/spec-implement`

**输入**：无（读取已通过的 tasks）

**执行逻辑**：
1. 读取 `tasks.feedback.json` 确认 `verdict = approved`
2. 加载所有设计文档
3. 按任务编号顺序执行，尊重 `[P]` 并行标记
4. 每完成一个任务，更新 `tasks.html` 中对应项为 `[X]`
5. 更新 `dashboard.html` 进度

#### 阶段 6：`/spec-review`

**输入**：无（分析代码变更）

**执行逻辑**：
1. 检测自上次审查以来的代码变更
2. 生成 `review.html`，使用 annotated-pr-review 组件
3. 每个问题标注严重程度（Critical / High / Medium / Low）
4. 用户可选择：同意修改 / 不需要改（附理由）
5. 审查结果写入 `review.feedback.json`

---

## 四、看板主页（Dashboard）

### 4.1 布局

**左右分栏：左侧 25% 导航概览，右侧 75% 内容展示**

```
┌──────────────┬──────────────────────────────────────┐
│  📊 总览      │                                      │
│              │  当前焦点：001-user-auth / 技术方案     │
│  功能总数: 5  │  ─────────────────────────────────   │
│  待审核:   2  │                                      │
│  实施中:   1  │  ┌────────────────────────────────┐  │
│  已完成:   2  │  │                                │  │
│              │  │  文档详细内容展示区               │  │
│ ─────────── │  │  （可折叠章节、标签页、             │  │
│  📅 时间线    │  │   代码块、架构图等）              │  │
│              │  │                                │  │
│  05/11       │  │  内置交互：                       │  │
│  ├ 003 任务✓  │  │  [方案A] ○  [方案B] ●  [方案C] ○  │  │
│  05/10       │  │  备注: [________________]        │  │
│  ├ 001 方案●  │  │                                │  │
│  05/09       │  └────────────────────────────────┘  │
│  ├ 000 规格✓  │                                      │
│              │  [通过 ✓]  [驳回 ✗ 附反馈]            │
│ ─────────── │                                      │
│  📂 功能列表  │                                      │
│              │                                      │
│  ▸ 000-init  │                                      │
│    ✓ 已完成   │                                      │
│  ▸ 001-auth  │                                      │
│    ● 待审核   │                                      │
│  ▸ 002-pay   │                                      │
│    ○ 草稿    │                                      │
└──────────────┴──────────────────────────────────────┘
     约 25%                        约 75%
```

### 4.2 左侧面板内容

**总览区**：功能总数、待审核数、实施中数、已完成数

**时间线区**：按时间倒序展示所有操作记录（创建、审核通过、实施完成等）

**功能列表区**：所有功能的入口，每个显示当前阶段和状态

### 4.3 右侧面板内容

**内容展示区**：当前选中功能的当前阶段文档，通过 iframe 动态加载对应 `.html` 文件

**审核操作栏**：底部固定的 `[通过]` `[驳回]` 按钮，操作结果写入 `.feedback.json`

### 4.4 看板行为

1. AI 每次生成/更新文档后，自动刷新 `dashboard.html` 和 `dashboard-state.json`
2. 终端输出可直接 Cmd+点击的路径：`file:///full/path/to/.specify/specs/dashboard.html`
3. 左侧点击功能名 → 右侧加载该功能当前阶段的文档
4. 每个文档内的交互操作写入对应的 `.feedback.json`
5. 审核操作（通过/驳回）触发 `.feedback.json` 更新，AI 下次执行时读取

### 4.5 `dashboard-state.json` 结构

```json
{
  "current_feature": "001-user-auth",
  "features": [
    {
      "id": "001",
      "name": "user-auth",
      "directory": "001-user-auth",
      "current_phase": "plan",
      "status": "pending_review",
      "created_at": "2026-05-11T14:00:00Z",
      "updated_at": "2026-05-11T15:30:00Z"
    },
    {
      "id": "002",
      "name": "payment",
      "directory": "002-payment",
      "current_phase": "spec",
      "status": "draft",
      "created_at": "2026-05-11T16:00:00Z",
      "updated_at": "2026-05-11T16:00:00Z"
    }
  ],
  "timeline": [
    { "date": "2026-05-11", "feature": "001", "event": "spec_approved", "detail": "需求规格通过审核" },
    { "date": "2026-05-11", "feature": "001", "event": "plan_created", "detail": "技术方案已生成" }
  ]
}
```

---

## 五、反馈机制

### 5.1 每个 HTML 文件对应独立的 `.feedback.json`

目录结构确保并行 Agent 完全隔离：

```
.specify/specs/
├── 001-user-auth/             # Agent A 负责
│   ├── spec.html
│   ├── spec.feedback.json     # 独立反馈
│   ├── plan.html
│   ├── plan.feedback.json     # 独立反馈
│   └── artifacts/
│       ├── api-contracts.html
│       └── api-contracts.feedback.json  # 每个 artifact 也有独立反馈
├── 002-payment/               # Agent B 负责，完全隔离
│   ├── spec.html
│   └── spec.feedback.json
└── 003-notification/          # Agent C 负责，完全隔离
    ├── spec.html
    └── spec.feedback.json
```

### 5.2 `.feedback.json` 结构

```json
{
  "artifact": "plan.html",
  "feature": "001-user-auth",
  "phase": "plan",
  "status": "pending_review",
  "decisions": [
    {
      "id": "arch-choice",
      "type": "single-select",
      "options": ["微服务拆分", "单体模块化", "Serverless"],
      "selected": null,
      "note": ""
    },
    {
      "id": "db-choice",
      "type": "single-select",
      "options": ["PostgreSQL", "MySQL", "MongoDB"],
      "selected": "PostgreSQL",
      "note": "团队熟悉度高"
    },
    {
      "id": "priority-adjust",
      "type": "multi-select",
      "options": ["缓存", "消息队列", "搜索引擎", "监控"],
      "selected": ["缓存", "监控"],
      "note": "首期优先实现这两个"
    }
  ],
  "review": {
    "verdict": null,
    "feedback": "",
    "reviewer": null,
    "timestamp": null
  },
  "created_at": "2026-05-11T14:00:00Z",
  "updated_at": "2026-05-11T14:00:00Z"
}
```

### 5.3 交互类型

| 类型 | type 值 | 用途 | 组件示例 |
|------|---------|------|----------|
| 单选 | `single-select` | 方案选择、技术栈选择 | exploration-approaches |
| 多选 | `multi-select` | 优先级排序、功能范围 | triage-board |
| 文本输入 | `text-input` | 备注、补充说明 | 所有组件的备注区域 |
| 确认/驳回 | `review` | 阶段门禁通过操作 | 所有文档底部的审核栏 |
| 滑块/调参 | `slider` | 参数调节 | prototype-animation |
| 拖拽排序 | `drag-sort` | 任务优先级排列 | triage-board |

### 5.4 双通道通信

```
┌─────────────┐          ┌─────────────┐
│  Claude Code │  生成 →  │  HTML 文件    │
│  (终端)      │          │  (浏览器)     │
│             │  ← 读取   │             │
│             │  feedback │  用户交互 →  │
│             │  .json    │  写回 .json  │
└─────────────┘          └─────────────┘
```

- 用户在 HTML 中操作 → 页面 JS 将结果写入同目录 `.feedback.json`
- AI 下一轮执行 → 读取 `.feedback.json` → 根据用户决策调整行为
- 不需要任何服务端，纯文件系统通信

---

## 六、CLAUDE.md 规则

`CLAUDE.md` 是整套机制的"大脑"，控制 AI 的行为：

```markdown
# 项目规则

## 宪章
- 读取 .specify/constitution.md 并遵守所有不变量
- 任何功能规范不得违反宪章原则

## 工作流规则
- 所有面向人的文档必须以自包含 HTML 输出（内联 CSS/JS，零外部依赖）
- HTML 文档必须参照 .specify/templates/ 中对应模板的结构和样式
- 每个阶段完成后自动更新 .specify/specs/dashboard.html 和 dashboard-state.json
- 终端输出格式：📄 待审核: file:///absolute/path/to/xxx.html
- 阶段门禁：读取 .feedback.json 中 review.verdict，只有 "approved" 才进入下一阶段

## 文档生成规则
- 需求规格（spec.html）：只描述 WHAT 和 WHY，不涉及 HOW
- 技术方案（plan.html）：描述 HOW，包含架构图、数据模型、API 契约
- 任务清单（tasks.html）：格式 - [ ] T001 [P] 描述 含文件路径，按阶段排列，标记可并行项
- 审查报告（review.html）：代码级审查，带严重程度标注和修改建议

## 反馈处理规则
- 生成 HTML 时同时生成对应的 .feedback.json 骨架
- 用户在 HTML 中操作后，反馈写入 .feedback.json
- 下一轮执行前先读取 .feedback.json，按用户决策调整
- 驳回时读取 review.feedback，修改后重新提交

## 并行 Agent 规则
- 每个 Agent 只操作自己负责的功能目录
- 不读取、不修改其他功能目录下的文件
- dashboard.html 由最后完成的 Agent 统一刷新
```

---

## 七、20 种 HTML 组件库

### 7.1 组件清单

所有组件位于 `.specify/templates/components/` 下，每个是一个独立 `.html` 文件：

| # | 文件名 | 类别 | 用途 | 对应工作流阶段 |
|---|--------|------|------|----------------|
| 1 | `exploration-approaches.html` | 探索与规划 | 多方案并排对比（优缺点、推荐） | 需求澄清、方案选型 |
| 2 | `exploration-visual-designs.html` | 探索与规划 | 视觉设计方向并排渲染 | 原型设计 |
| 3 | `implementation-plan.html` | 探索与规划 | 分阶段实施计划（含依赖、文件变更、时间线） | 技术方案 |
| 4 | `annotated-pr-review.html` | 代码审查 | 带批注的 PR 审查（严重程度、跳转链接） | 代码审查 |
| 5 | `pr-writeup.html` | 代码审查 | PR 描述（动机、前后对比、文件导览） | 提交审查 |
| 6 | `code-understanding.html` | 代码审查 | 代码调用链/架构图（可折叠、可展开） | 技术调研 |
| 7 | `design-system.html` | 设计 | 设计令牌（色板、排版、间距） | UI 设计 |
| 8 | `component-variants.html` | 设计 | 组件变体矩阵（状态、尺寸、交互控制） | UI 组件开发 |
| 9 | `prototype-animation.html` | 原型 | 动效沙盒（可调时长和缓动） | 交互原型 |
| 10 | `prototype-interaction.html` | 原型 | 可交互原型（拖拽、点击流） | 交互原型 |
| 11 | `svg-illustrations.html` | 图表 | SVG 插画（可导出） | 文档插图 |
| 12 | `flowchart-diagram.html` | 图表 | 可交互流程图（点击节点查看详情） | 架构设计、部署流水线 |
| 13 | `slide-deck.html` | 演示 | 箭头键翻页演示文稿 | 方案汇报 |
| 14 | `feature-explainer.html` | 调研与学习 | 功能原理讲解（可折叠步骤、标签代码） | 技术调研 |
| 15 | `concept-explainer.html` | 调研与学习 | 概念交互讲解（如一致性哈希环） | 知识沉淀 |
| 16 | `status-report.html` | 报告 | 周报/进度报告（含时间线和内联图表） | 状态汇报 |
| 17 | `incident-report.html` | 报告 | 事故复盘（分钟级时间线、日志、行动项） | 事故处理 |
| 18 | `triage-board.html` | 编辑器 | 看板拖拽排序（导出 Markdown） | 任务排序 |
| 19 | `feature-flags-editor.html` | 编辑器 | 功能开关编辑器（依赖检查、差异导出） | 配置管理 |
| 20 | `prompt-tuner.html` | 编辑器 | 提示词调优器（左侧编辑、右侧实时预览） | 提示工程 |

### 7.2 组件统一规范

每个组件遵循以下规范：

- **自包含**：所有 CSS 内联 `<style>`，所有 JS 内联 `<script>`，零外部依赖
- **可嵌入**：提供 `<!-- SLOT:content -->` 占位符，AI 生成时替换为实际内容
- **带交互**：所有用户操作通过统一的反馈写入机制与 `.feedback.json` 对接
- **可导出**：编辑器类组件内置导出按钮，输出 Markdown/JSON

### 7.3 组件复用方式

AI 生成文档时不直接复制组件文件，而是**参照组件的结构和样式模式**生成新的 HTML：

1. 读取目标组件文件，理解其 HTML 结构、CSS 样式、JS 交互模式
2. 根据当前任务的具体内容，用相同模式生成新的 HTML
3. 保留交互机制（选择、输入、确认/驳回），替换为实际业务内容

---

## 八、斜杠命令一览

| 命令 | 阶段 | 前置条件 | 输出 |
|------|------|----------|------|
| `/spec-init "描述"` | 初始化 | 无 | `spec.html` + `spec.feedback.json` |
| `/spec-clarify` | 澄清 | `spec.feedback.json` 存在 | 更新 `spec.html` |
| `/spec-plan` | 方案设计 | `spec.feedback.verdict = approved` | `plan.html` + `artifacts/*` |
| `/spec-tasks` | 任务拆解 | `plan.feedback.verdict = approved` | `tasks.html` + `tasks.feedback.json` |
| `/spec-review` | 审查 | 有代码变更 | `review.html` + `review.feedback.json` |
| `/spec-implement` | 执行实现 | `tasks.feedback.verdict = approved` | 代码文件 + 更新 `tasks.html` |

---

## 九、未来愿景

> 以下为远期规划，不在当前实施范围内。架构设计已预留扩展空间。

### 9.1 企业框架集成

未来可通过配置层叠加公司专属框架，无需修改架构：

- **宪章层**：在 `constitution.md` 中声明公司框架为不变量
- **模板层**：在 `templates/components/` 中新增公司专属组件（如 `company-ui-patterns.html`）
- **规则层**：在 `CLAUDE.md` 中引用公司组件模板和编码规范

扩展层级：基础层（通用）→ 公司层（企业扩展）→ 项目层（具体项目），每层只关心自己的事。

### 9.2 多人团队协作

当前架构为文件驱动（单人 + 多 Agent）。未来可平滑过渡到服务驱动（多人团队）：

- 后端服务管理规范 CRUD、任务分配、审批流、依赖管理、甘特图、权限控制、通知推送
- 通过 Claude Code 的 MCP Server 机制暴露 API 给 Agent
- 斜杠命令中的文件 I/O 替换为 API 调用即可
- 数据源从 `.feedback.json` 变为 `POST /api/feedback`，看板从读本地文件变为调 API

### 9.3 演进路线

```
阶段 1（当前）：单人 + 多 Agent，文件驱动
    ↓
阶段 2：多人 Git 协作，meta.json 定义角色和负责人
    ↓
阶段 3：后端服务驱动，团队共享看板，完整权限和通知体系
```

---

## 十、实施计划概要

本设计文档审核通过后，实施分为以下步骤：

1. **搭建目录骨架** — 创建 `.specify/`、`.claude/commands/` 等目录结构
2. **编写 CLAUDE.md** — 项目总控规则
3. **编写 constitution.md** — 项目宪章
4. **开发 20 个 HTML 组件模板** — 从 Thariq 的开源仓库提取并适配
5. **开发看板主页模板** — dashboard.html（左右分栏布局）
6. **编写 6 个斜杠命令** — spec-init、spec-clarify、spec-plan、spec-tasks、spec-review、spec-implement
7. **编写 hooks 脚本** — pre-spec-check.sh、post-task-verify.sh
8. **端到端测试** — 用一个真实功能走完整工作流
9. **版本控制** — 所有规范文档和反馈记录纳入 git，确保审批留痕

---

## 附录：灵感来源

- **GitHub Spec-Kit**（github/spec-kit）：Spec-Driven Development 工作流引擎，提供了阶段门禁、质量检查、宪章机制等成熟模式
- **OpenSpec**（Fission-AI/OpenSpec）：轻量级规范驱动工具，提供了 Delta Specs、Given/When/Then 场景等概念
- **HTML Effectiveness**（thariqs.github.io/html-effectiveness/）：证明了 HTML 作为 AI 编程输出格式在 17/20 场景下优于 Markdown，提供了 20 种可复用的 HTML 组件模式
