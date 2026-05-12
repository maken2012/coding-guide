# Spec-Driven Development Framework — Claude Code 规格驱动开发框架

将规格驱动开发与自包含 HTML 可视化输出相结合，让 AI 编程更可靠、可审查。

---

## 这是什么？

- 一个 Claude Code 框架，强制执行规格驱动开发工作流
- 所有人类阅读的文档都是自包含 HTML（内联 CSS/JS，零外部依赖）
- 阶段门禁：每个阶段必须审核通过才能进入下一阶段
- 支持多 Agent 并行开发，独立反馈文件互不干扰
- 所有文档和反馈文件通过 git 追踪，完整审计链
- 灵感来源：GitHub 的 spec-kit、Fission-AI 的 OpenSpec、Thariq 的 20 个 HTML 有效性演示

---

## 快速开始

### 远程安装（一行命令）

```bash
bash <(curl -sL https://raw.githubusercontent.com/maken2012/coding-guide/main/install.sh)
```

### 本地安装

```bash
git clone https://github.com/maken2012/coding-guide.git
cd your-project
./coding-guide/install.sh
```

### 语言选项

```bash
# 强制英文
bash install.sh --lang en

# 强制中文（默认）
bash install.sh --lang zh
```

---

## 主线工作流（6 步）

```
/spec-init → /spec-detail → /spec-design → /spec-plan → /spec-implement → /spec-review
架构选型      需求详述       一站式设计     计划+任务     开发+测试       审查+部署
```

| 阶段 | 命令 | 说明 | 产出 |
|------|------|------|------|
| 架构选型 | `/spec-init` | 高层需求定义与架构决策 | `spec.html` |
| 需求详述 | `/spec-detail` | 输入输出、交互流程、业务规则、异常处理 | `detail.html` |
| 一站式设计 | `/spec-design` | 根据项目类型自动生成所需设计文档 | `design/` 目录 |
| 计划与任务 | `/spec-plan` | 分阶段实施计划与任务拆解 | `plan.html` + `tasks.html` |
| 开发与测试 | `/spec-implement` | 按任务顺序编码，自动生成测试 | 代码文件 + `test-report.html` |
| 审查与部署 | `/spec-review` | 代码审查与部署计划 | `review.html` + `deploy-plan.html` |

每个命令读取上一阶段的反馈文件，只有 `verdict: "approved"` 才能进入下一阶段。

**LTS 1.1 快捷方式：** 使用 `/spec-run <功能名>` 自动推进全部 6 个阶段，或使用 `/spec-dispatch` 分析功能状态并获取并行 Agent 命令。详见[多 Agent 并行（LTS 1.1）](#多-agent-并行lts-11)。

## 辅助命令（独立于主线）

```
/spec-explore   → 独立探索对比
/spec-research  → 技术调研
/spec-report    → 状态报告 / 事故复盘
/spec-present   → 演示文稿
```

---

## 工作原理

1. 每个斜杠命令生成自包含 HTML 文档
2. 用户在浏览器中审阅 HTML，通过交互式反馈批准/驳回
3. 反馈保存到 `.feedback.json`（每个 HTML 文档一个）
4. 只有批准的文档才能进入下一阶段
5. Dashboard 提供所有功能及其当前阶段的概览

---

## 项目结构（安装后）

```
.specify/
├── constitution.md          # 项目宪章
├── specs/                   # 运行时规范文件
│   └── <功能>/
│       ├── spec.html + .feedback.json
│       ├── detail.html + .feedback.json
│       ├── design/
│       ├── plan.html, tasks.html
│       └── review.html
└── templates/               # 文档模板
    ├── dashboard.html
    ├── *-template.html      # 15 个模板
    └── components/          # 20 个可复用组件

.claude/
├── commands/                # 10 个斜杠命令
└── hooks/                   # 验证钩子
```

---

## 核心特性

- **阶段门禁工作流** — 不可跳过阶段，确保每一步都经过审核
- **自包含 HTML 输出** — 离线可用，支持 `file://` 协议，零外部依赖
- **交互式反馈** — 浏览器中直接批准/驳回/微调，无需离开文档
- **多 Agent 并行** — 每个功能独立反馈文件，互不干扰
- **Git 追踪审计链** — 规格、反馈全部纳入 git 版本管理，完整可追溯
- **20 个 HTML 组件** — 流程图、ER 图、代码审查、幻灯片等开箱即用
- **中英双语支持** — 安装时可选择语言，模板和命令均支持中英文
- **多 Agent 并行（LTS 1.1）** — 使用 `/spec-run` 自动推进全部阶段，或使用 `/spec-dispatch` 启动并行 Agent 同时开发多个功能

---

## HTML 组件（20 个）

| 组件 | 说明 |
|------|------|
| `exploration-approaches` | 方案对比 |
| `exploration-visual-designs` | 视觉方向对比 |
| `implementation-plan` | 分阶段实施计划 |
| `annotated-pr-review` | 带批注的代码审查 |
| `pr-writeup` | 变更摘要 |
| `code-understanding` | 代码理解 / ER 图 |
| `design-system` | 设计系统与设计令牌 |
| `component-variants` | 组件矩阵 |
| `prototype-animation` | 动效原型 |
| `prototype-interaction` | 交互原型 |
| `svg-illustrations` | SVG 插图 |
| `flowchart-diagram` | 流程图 |
| `slide-deck` | 幻灯片 |
| `feature-explainer` | 功能原理说明 |
| `concept-explainer` | 概念解释 |
| `status-report` | 状态报告 |
| `incident-report` | 事故报告 |
| `triage-board` | 优先级排序 |
| `feature-flags-editor` | 功能开关配置 |
| `prompt-tuner` | 提示词调优 |

---

## 反馈机制

1. 每个 HTML 文档底部有交互式审核栏
2. 用户可批准/驳回、添加备注、做出选择
3. 通过 File System Access API（Chrome/Edge）保存反馈，剪贴板兜底
4. AI 在进入下一阶段前读取 `.feedback.json`
5. 阶段门禁：只有 `verdict: "approved"` 才能推进

### .feedback.json 结构示例

```json
{
  "artifact": "spec.html",
  "feature": "my-feature",
  "phase": "spec",
  "status": "pending_review",
  "decisions": [
    {
      "id": "arch-choice",
      "type": "single-select",
      "options": ["monolith", "microservice", "serverless"],
      "selected": null,
      "note": ""
    }
  ],
  "review": {
    "verdict": null,
    "feedback": "",
    "timestamp": null
  },
  "created_at": "2026-05-12T10:00:00Z",
  "updated_at": "2026-05-12T10:00:00Z"
}
```

---

## 多 Agent 并行（LTS 1.1）

同时运行多个 Claude Code 会话，每个管理一个功能的完整生命周期。

### /spec-run — 自动化生命周期

一条命令管理整个 6 阶段管线，每次审批后自动推进：

```bash
/spec-run "用户认证模块"
```

Agent 生成 spec.html → 等待你审批 → 自动执行 spec-detail → 等待 → ... 直到 spec-review。你只需在浏览器中点击审批按钮。

### /spec-dispatch — 并行 Agent 分析器

扫描所有功能状态，获取并行执行建议：

```bash
/spec-dispatch
```

输出显示每个功能处于哪个阶段、哪些被活跃 Agent 占用、以及启动新 Agent 的终端命令。

### 多 Agent 工作流

```
终端 1: /spec-run "用户认证"        # Agent-A 管理 001
终端 2: /spec-run "数据导出"        # Agent-B 管理 002
终端 3: /spec-run "支付集成"        # Agent-C 管理 003
```

每个 Agent 独立操作自己的功能目录，功能锁防止冲突。

### 新架构

- `.feature-state.json` — 每个功能独立的管线状态（替代集中式 dashboard-state.json）
- `.agent-lock` — 原子功能锁，60 分钟过期
- `registry.jsonl` — 追加式事件日志，跨 Agent 可观测
- 反应式轮询 — Agent 检测 .feedback.json 审批结果，自动推进

---

## 环境要求

- **Claude Code CLI**（或 Claude 桌面版 / VS Code 扩展）
- **Git**
- **现代浏览器**（推荐 Chrome / Edge，支持 File System Access API）

---

## 许可证

MIT License

---

## 链接

- GitHub: https://github.com/maken2012/coding-guide
- [English Documentation](README.md)
