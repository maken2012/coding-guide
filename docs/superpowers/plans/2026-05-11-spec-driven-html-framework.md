# Spec-Driven Development + HTML 可视化输出框架 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Claude Code 内构建一套通用的规范驱动开发框架，所有面向人的文档以自包含 HTML 输出。

**Architecture:** `.specify/` 存放规范子系统（隐藏目录），`.claude/` 存放 Claude Code 原生配置，`CLAUDE.md` 作为总控。6 个斜杠命令驱动 init → clarify → plan → tasks → implement → review 工作流。每个阶段生成 HTML 产出和 `.feedback.json` 反馈骨架，看板主页汇聚所有状态。

**Tech Stack:** 纯 HTML/CSS/JS（零构建依赖）、Claude Code 斜杠命令（Markdown）、Bash hooks

**对应设计文档:** `docs/superpowers/specs/2026-05-11-spec-driven-html-framework-design.md`

---

## 文件清单

实施完成后的完整文件树：

```
vibe-coding-guide/
├── .gitignore
├── CLAUDE.md
├── .specify/
│   ├── constitution.md
│   └── templates/
│       ├── dashboard.html
│       ├── spec-template.html
│       ├── plan-template.html
│       ├── tasks-template.html
│       ├── review-template.html
│       └── components/
│           ├── exploration-approaches.html
│           ├── exploration-visual-designs.html
│           ├── implementation-plan.html
│           ├── annotated-pr-review.html
│           ├── pr-writeup.html
│           ├── code-understanding.html
│           ├── design-system.html
│           ├── component-variants.html
│           ├── prototype-animation.html
│           ├── prototype-interaction.html
│           ├── svg-illustrations.html
│           ├── flowchart-diagram.html
│           ├── slide-deck.html
│           ├── feature-explainer.html
│           ├── concept-explainer.html
│           ├── status-report.html
│           ├── incident-report.html
│           ├── triage-board.html
│           ├── feature-flags-editor.html
│           └── prompt-tuner.html
├── .claude/
│   ├── settings.json
│   ├── commands/
│   │   ├── spec-init.md
│   │   ├── spec-clarify.md
│   │   ├── spec-plan.md
│   │   ├── spec-tasks.md
│   │   ├── spec-review.md
│   │   └── spec-implement.md
│   └── hooks/
│       ├── pre-spec-check.sh
│       └── post-task-verify.sh
└── docs/
    └── superpowers/
        ├── specs/2026-05-11-spec-driven-html-framework-design.md
        └── plans/2026-05-11-spec-driven-html-framework.md
```

共 **36 个文件**（含已有的 2 个设计文档）。

---

## Task 1: 项目初始化与目录骨架

**Files:**
- Create: `.gitignore`
- Create: `.claude/settings.json`
- Create: 目录结构

- [ ] **Step 1: 初始化 Git 仓库**

```bash
cd /Users/shun/Documents/person-project/vibe-conding-guide
git init
```

Expected: `Initialized empty Git repository`

- [ ] **Step 2: 创建目录结构**

```bash
mkdir -p .specify/templates/components
mkdir -p .specify/specs
mkdir -p .claude/commands
mkdir -p .claude/hooks
```

Expected: 所有目录创建成功

- [ ] **Step 3: 创建 `.gitignore`**

所有规范文档和反馈记录都纳入 git 版本控制（留痕追溯），只忽略系统临时文件：

```gitignore
# macOS
.DS_Store
```

- [ ] **Step 4: 创建 `.claude/settings.json`**

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(ls *)",
      "Bash(mkdir *)",
      "Bash(cat *)"
    ]
  }
}
```

- [ ] **Step 5: 验证目录结构**

```bash
find . -not -path './.git/*' -not -path './.git' | sort
```

Expected: 显示所有创建的目录和文件

- [ ] **Step 6: 提交**

```bash
git add -A
git commit -m "chore: init project with directory structure and gitignore"
```

---

## Task 2: 编写 constitution.md

**Files:**
- Create: `.specify/constitution.md`

- [ ] **Step 1: 创建宪章文件**

```markdown
# 项目宪章

> 版本: 1.0.0
> 最后更新: 2026-05-11

## 核心原则

### 文档优先
- 所有功能必须先有 spec.html 再有代码
- 需求规格只描述 WHAT 和 WHY，技术方案只描述 HOW
- 每个阶段必须通过审核才能进入下一阶段

### 质量门禁
- 需求规格必须可测试：每条需求都有明确的验收标准
- 技术方案必须包含错误处理和边界条件
- 任务清单中每个任务必须可独立验证

### HTML 输出规范
- 所有面向人的文档必须是自包含 HTML（内联 CSS/JS，零外部依赖）
- HTML 必须参照 templates/ 中对应模板的结构
- 交互组件必须包含反馈机制（可写入 .feedback.json）

### 并行隔离
- 每个功能目录独立，互不干扰
- Agent 只操作自己负责的功能目录
- 看板由最后完成的 Agent 统一刷新

### 不可变量
- 宪章变更需要明确的版本号记录
- 已通过的审核不可回退（只能通过新审核覆盖）
- 生成代码必须通过 spec-review 审查才能视为完成
```

- [ ] **Step 2: 提交**

```bash
git add .specify/constitution.md
git commit -m "feat: add project constitution"
```

---

## Task 3: 编写 CLAUDE.md

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: 创建项目总控规则**

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

## HTML 组件使用规则
- 读取 .specify/templates/components/ 下的组件文件作为结构和样式参考
- 不直接复制组件文件，而是模仿其 HTML 结构、CSS 样式、JS 交互模式
- 所有用户操作通过统一的反馈机制（saveFeedback 函数）对接 .feedback.json
- 每个组件提供 SLOT:content 占位符用于内容替换

## .feedback.json 结构规范
每个反馈文件必须包含以下结构：
```json
{
  "artifact": "文件名.html",
  "feature": "功能目录名",
  "phase": "spec|plan|tasks|review",
  "status": "pending_review",
  "decisions": [
    { "id": "决策ID", "type": "single-select|multi-select|text-input|review", "options": [...], "selected": null, "note": "" }
  ],
  "review": { "verdict": null, "feedback": "", "timestamp": null },
  "created_at": "ISO时间",
  "updated_at": "ISO时间"
}
```

## 看板 dashboard.html 维护规则
- 读取 .specify/specs/dashboard-state.json 获取全局状态
- 左侧 25%：总览统计 + 时间线 + 功能列表
- 右侧 75%：当前选中功能的当前阶段文档（通过 iframe 加载）
- 底部：通过/驳回审核按钮
- 每次生成或更新任何规范文档后，必须重建 dashboard.html
```

- [ ] **Step 2: 提交**

```bash
git add CLAUDE.md
git commit -m "feat: add CLAUDE.md project rules"
```

---

## Task 4: 开发共享反馈机制与 HTML 基础模板

**Files:**
- Create: `.specify/templates/components/exploration-approaches.html`（作为参考实现）

此任务创建第一个完整的 HTML 组件，同时确立所有后续组件共享的模式：

1. **反馈写入 JS** — saveFeedback() 函数
2. **SLOT 占位符** — `<!-- SLOT:content -->` 模式
3. **审核按钮** — 通过/驳回标准 UI
4. **通用 CSS 变量** — 颜色、间距、字体

- [ ] **Step 1: 从 Thariq 仓库获取原始 HTML**

```bash
cd /Users/shun/Documents/person-project/vibe-conding-guide
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/01-exploration-code-approaches.html -o /tmp/01-original.html
```

Expected: 文件下载成功

- [ ] **Step 2: 创建参考实现组件**

基于原始 HTML，做以下适配：
- 移除 "Birchline" 品牌标识，替换为通用占位
- 添加 `<style>` 中的 CSS 变量定义（统一色彩体系）
- 添加 `<!-- SLOT:content -->` 占位符
- 内嵌 `saveFeedback()` 函数（File System Access API + 剪贴板降级）
- 添加底部审核按钮栏（通过/驳回）
- 添加 `initFeedback()` 函数（从同目录 .feedback.json 恢复状态）

关键共享代码片段（将内嵌到每个组件中）：

```html
<!-- ===== 反馈机制（每个组件必须包含）===== -->
<style>
  /* 审核按钮栏 */
  .review-bar { position: fixed; bottom: 0; left: 0; right: 0; background: var(--surface); border-top: 1px solid var(--border); padding: 16px 24px; display: flex; gap: 12px; align-items: center; z-index: 100; }
  .btn-approve { background: #16a34a; color: white; border: none; padding: 8px 20px; border-radius: 6px; cursor: pointer; font-size: 14px; }
  .btn-reject { background: #dc2626; color: white; border: none; padding: 8px 20px; border-radius: 6px; cursor: pointer; font-size: 14px; }
  .btn-approve:hover { background: #15803d; }
  .btn-reject:hover { background: #b91c1c; }
  .feedback-input { flex: 1; padding: 8px 12px; border: 1px solid var(--border); border-radius: 6px; font-size: 14px; }
  .toast { position: fixed; top: 20px; right: 20px; padding: 12px 20px; border-radius: 8px; color: white; z-index: 200; animation: fadeIn 0.3s; }
  .toast-success { background: #16a34a; }
  .toast-info { background: #2563eb; }
  @keyframes fadeIn { from { opacity: 0; transform: translateY(-10px); } to { opacity: 1; transform: translateY(0); } }
</style>

<div class="review-bar" id="reviewBar">
  <button class="btn-approve" onclick="submitVerdict('approved')">通过 ✓</button>
  <button class="btn-reject" onclick="submitVerdict('rejected')">驳回 ✗</button>
  <input class="feedback-input" id="feedbackInput" placeholder="输入审核意见（驳回时必填）..." />
</div>

<script>
/* ===== 反馈机制核心函数 ===== */
const FEEDBACK_FILE = document.currentScript?.getAttribute('data-feedback') || location.pathname.replace('.html', '.feedback.json');

function collectDecisions() {
  const decisions = [];
  document.querySelectorAll('[data-decision]').forEach(el => {
    const id = el.getAttribute('data-decision');
    const type = el.getAttribute('data-type') || 'single-select';
    if (type === 'single-select') {
      const checked = el.querySelector('input[type="radio"]:checked');
      decisions.push({ id, type, selected: checked ? checked.value : null, note: '' });
    } else if (type === 'multi-select') {
      const checked = [...el.querySelectorAll('input[type="checkbox"]:checked')].map(i => i.value);
      decisions.push({ id, type, selected: checked, note: '' });
    } else if (type === 'text-input') {
      decisions.push({ id, type, selected: null, note: el.querySelector('input,textarea')?.value || '' });
    }
  });
  return decisions;
}

async function saveFeedback(data) {
  const json = JSON.stringify(data, null, 2);
  if (window.showSaveFilePicker) {
    try {
      const handle = await window.showSaveFilePicker({ suggestedName: FEEDBACK_FILE.split('/').pop(), types: [{ description: 'JSON', accept: { 'application/json': ['.json'] } }] });
      const writable = await handle.createWritable();
      await writable.write(json);
      await writable.close();
      showToast('反馈已保存', 'success');
      return;
    } catch (e) { if (e.name === 'AbortError') return; }
  }
  await navigator.clipboard.writeText(json);
  showToast('JSON 已复制到剪贴板，请粘贴保存为 ' + FEEDBACK_FILE.split('/').pop(), 'info');
}

function submitVerdict(verdict) {
  if (verdict === 'rejected' && !document.getElementById('feedbackInput').value.trim()) {
    showToast('驳回时必须填写审核意见', 'info'); return;
  }
  const feedback = collectDecisions();
  const data = {
    artifact: location.pathname.split('/').pop(),
    feature: location.pathname.split('/').filter(s => s.match(/^\d{3}-/)).pop() || '',
    phase: document.querySelector('meta[name="phase"]')?.content || '',
    status: verdict === 'approved' ? 'approved' : 'rejected',
    decisions: feedback,
    review: { verdict, feedback: document.getElementById('feedbackInput').value.trim(), timestamp: new Date().toISOString() },
    created_at: document.querySelector('meta[name="created"]')?.content || new Date().toISOString(),
    updated_at: new Date().toISOString()
  };
  saveFeedback(data);
}

function showToast(msg, type) {
  const t = document.createElement('div');
  t.className = 'toast toast-' + type;
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => t.remove(), 3000);
}
</script>
```

- [ ] **Step 3: 浏览器验证**

用浏览器打开 `.specify/templates/components/exploration-approaches.html`，确认：
- 页面正常渲染
- 审核按钮栏在底部固定显示
- 点击"通过"弹出保存/复制提示
- 点击"驳回"（无意见）弹出提示要求填写

- [ ] **Step 4: 提交**

```bash
git add .specify/templates/components/exploration-approaches.html
git commit -m "feat: add exploration-approaches component with shared feedback mechanism"
```

---

## Task 5: 适配探索与规划类组件（2 个）

**Files:**
- Create: `.specify/templates/components/exploration-visual-designs.html`
- Create: `.specify/templates/components/implementation-plan.html`

- [ ] **Step 1: 获取原始文件**

```bash
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/02-exploration-visual-designs.html -o /tmp/02-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/16-implementation-plan.html -o /tmp/16-original.html
```

- [ ] **Step 2: 适配 exploration-visual-designs.html**

从原始文件适配：
- 替换品牌为通用占位
- 添加 Task 4 中的共享反馈机制（CSS + JS）
- 添加 `<!-- SLOT:content -->` 占位符
- 添加 `<meta name="phase" content="spec">`
- 添加 `data-decision` 属性到各设计选项

- [ ] **Step 3: 适配 implementation-plan.html**

从原始文件适配：
- 替换品牌为通用占位
- 添加共享反馈机制
- 添加 `<meta name="phase" content="plan">`
- 阶段依赖关系区域添加 `data-decision` 属性

- [ ] **Step 4: 浏览器验证**

分别打开两个 HTML 文件，确认渲染和反馈机制正常。

- [ ] **Step 5: 提交**

```bash
git add .specify/templates/components/exploration-visual-designs.html .specify/templates/components/implementation-plan.html
git commit -m "feat: add exploration and planning components"
```

---

## Task 6: 适配代码审查类组件（3 个）

**Files:**
- Create: `.specify/templates/components/annotated-pr-review.html`
- Create: `.specify/templates/components/pr-writeup.html`
- Create: `.specify/templates/components/code-understanding.html`

- [ ] **Step 1: 获取原始文件**

```bash
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/03-code-review-pr.html -o /tmp/03-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/17-pr-writeup.html -o /tmp/17-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/04-code-understanding.html -o /tmp/04-original.html
```

- [ ] **Step 2: 适配 annotated-pr-review.html**

- 添加共享反馈机制
- 每个 diff 批注添加严重程度单选（Critical/High/Medium/Low）和同意/不同意选项
- 添加 `<meta name="phase" content="review">`

- [ ] **Step 3: 适配 pr-writeup.html**

- 添加共享反馈机制
- 添加 `<meta name="phase" content="review">`

- [ ] **Step 4: 适配 code-understanding.html**

- 添加共享反馈机制
- 添加 `<meta name="phase" content="plan">`

- [ ] **Step 5: 浏览器验证 + 提交**

```bash
git add .specify/templates/components/annotated-pr-review.html .specify/templates/components/pr-writeup.html .specify/templates/components/code-understanding.html
git commit -m "feat: add code review components"
```

---

## Task 7: 适配设计与原型类组件（4 个）

**Files:**
- Create: `.specify/templates/components/design-system.html`
- Create: `.specify/templates/components/component-variants.html`
- Create: `.specify/templates/components/prototype-animation.html`
- Create: `.specify/templates/components/prototype-interaction.html`

- [ ] **Step 1: 获取原始文件**

```bash
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/05-design-system.html -o /tmp/05-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/06-component-variants.html -o /tmp/06-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/07-prototype-animation.html -o /tmp/07-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/08-prototype-interaction.html -o /tmp/08-original.html
```

- [ ] **Step 2: 逐个适配（通用模式）**

每个组件执行相同的适配步骤：
1. 替换 "Birchline" 品牌为通用占位
2. 添加 Task 4 的共享反馈机制（CSS + JS）
3. 添加 `<!-- SLOT:content -->` 占位符
4. 添加 `data-decision` 属性到交互选项
5. 添加 `<meta name="phase">` 标签

design-system 和 component-variants 添加 `phase="spec"`。
prototype-animation 添加滑块 `data-type="slider"` 的 decision 支持。
prototype-interaction 添加 `phase="plan"`。

- [ ] **Step 3: 浏览器验证 + 提交**

```bash
git add .specify/templates/components/design-system.html .specify/templates/components/component-variants.html .specify/templates/components/prototype-animation.html .specify/templates/components/prototype-interaction.html
git commit -m "feat: add design and prototyping components"
```

---

## Task 8: 适配图表、演示、调研、报告类组件（7 个）

**Files:**
- Create: `.specify/templates/components/svg-illustrations.html`
- Create: `.specify/templates/components/flowchart-diagram.html`
- Create: `.specify/templates/components/slide-deck.html`
- Create: `.specify/templates/components/feature-explainer.html`
- Create: `.specify/templates/components/concept-explainer.html`
- Create: `.specify/templates/components/status-report.html`
- Create: `.specify/templates/components/incident-report.html`

- [ ] **Step 1: 获取原始文件**

```bash
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/10-svg-illustrations.html -o /tmp/10-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/13-flowchart-diagram.html -o /tmp/13-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/09-slide-deck.html -o /tmp/09-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/14-research-feature-explainer.html -o /tmp/14-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/15-research-concept-explainer.html -o /tmp/15-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/11-status-report.html -o /tmp/11-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/12-incident-report.html -o /tmp/12-original.html
```

- [ ] **Step 2: 逐个适配**

每个组件执行相同的适配步骤（替换品牌、添加反馈机制、SLOT 占位符、meta phase）。

phase 分配：
- svg-illustrations: `phase="plan"`
- flowchart-diagram: `phase="plan"`
- slide-deck: `phase="plan"`
- feature-explainer: `phase="plan"`
- concept-explainer: `phase="plan"`
- status-report: `phase="review"`
- incident-report: `phase="review"`

- [ ] **Step 3: 浏览器验证 + 提交**

```bash
git add .specify/templates/components/
git commit -m "feat: add diagram, presentation, research, and report components"
```

---

## Task 9: 适配编辑器类组件（3 个）

**Files:**
- Create: `.specify/templates/components/triage-board.html`
- Create: `.specify/templates/components/feature-flags-editor.html`
- Create: `.specify/templates/components/prompt-tuner.html`

- [ ] **Step 1: 获取原始文件**

```bash
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/18-editor-triage-board.html -o /tmp/18-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/19-editor-feature-flags.html -o /tmp/19-original.html
curl -sL https://raw.githubusercontent.com/ThariqS/html-effectiveness/main/20-editor-prompt-tuner.html -o /tmp/20-original.html
```

- [ ] **Step 2: 逐个适配**

除了通用适配步骤外，编辑器类组件还需额外处理：
- triage-board: 导出功能保留，导出结果同时触发 saveFeedback
- feature-flags-editor: 差异导出功能保留，添加 feedback 保存
- prompt-tuner: 实时预览功能保留，添加 feedback 保存

- [ ] **Step 3: 浏览器验证 + 提交**

```bash
git add .specify/templates/components/triage-board.html .specify/templates/components/feature-flags-editor.html .specify/templates/components/prompt-tuner.html
git commit -m "feat: add editor components (triage, flags, prompt tuner)"
```

---

## Task 10: 开发看板主页模板

**Files:**
- Create: `.specify/templates/dashboard.html`

这是整个系统的核心入口，左 25% 导航 + 右 75% 内容。

- [ ] **Step 1: 创建 dashboard.html**

完整的自包含 HTML，包含：

**CSS 部分：**
- CSS 变量（色彩体系：`--bg`, `--surface`, `--border`, `--text`, `--primary`, `--success`, `--danger`）
- 左侧面板样式（固定宽度 280px，背景 `--surface`，可滚动）
- 右侧内容区样式（flex: 1，iframe 占满）
- 统计卡片样式
- 时间线样式（竖线 + 节点）
- 功能列表项样式（带状态徽章）
- 审核按钮栏样式（底部固定）

**HTML 结构：**
- `<body>` 为 flex 横向布局
- 左侧 `<aside>` 包含：
  - 统计区（功能总数、待审核、实施中、已完成）
  - 分割线
  - 时间线区（从 `dashboard-state.json` 读取）
  - 分割线
  - 功能列表区（点击切换右侧内容）
- 右侧 `<main>` 包含：
  - `<iframe id="contentFrame">` 加载当前选中的 HTML 文档
  - 审核操作栏（通过/驳回按钮）

**JS 部分：**
- `loadDashboardState()` — 读取同目录 `dashboard-state.json`
- `renderStats()` — 渲染统计数字
- `renderTimeline()` — 渲染时间线
- `renderFeatureList()` — 渲染功能列表，绑定点击事件
- `loadContent(htmlPath)` — 右侧 iframe 加载指定 HTML
- `submitVerdict()` — 调用 iframe 内的反馈机制（postMessage 通信）
- `init()` — 页面加载时初始化

由于 `file://` 协议下无法 fetch 本地 JSON，采用以下方案：
- dashboard.html 内嵌一个 `<script type="application/json" id="dashboardState">` 标签
- AI 更新看板时，替换该 script 标签内的 JSON 内容
- JS 读取 `JSON.parse(document.getElementById('dashboardState').textContent)`

- [ ] **Step 2: 浏览器验证**

打开 dashboard.html，确认左右布局正确，统计区/时间线/功能列表渲染正常。

- [ ] **Step 3: 提交**

```bash
git add .specify/templates/dashboard.html
git commit -m "feat: add dashboard template with left-nav right-content layout"
```

---

## Task 11: 开发文档模板（4 个）

**Files:**
- Create: `.specify/templates/spec-template.html`
- Create: `.specify/templates/plan-template.html`
- Create: `.specify/templates/tasks-template.html`
- Create: `.specify/templates/review-template.html`

每个模板都是自包含 HTML，定义了该类文档的章节结构和样式。

- [ ] **Step 1: 创建 spec-template.html（需求规格模板）**

章节结构：
- 页头：功能名称、编号、创建日期、阶段徽章
- 概述：一句话描述
- 背景与动机（WHY）
- 功能需求（WHAT）：按用户故事组织，每个故事有验收标准
- 非功能需求：性能、安全、可用性等
- 约束与假设
- 澄清区域（`/spec-clarify` 后嵌入交互式问题）
- 底部审核栏

包含共享反馈机制。`<meta name="phase" content="spec">`。

- [ ] **Step 2: 创建 plan-template.html（技术方案模板）**

章节结构：
- 页头：功能名称、编号、关联的 spec 链接
- 方案概述
- 架构设计（引用 flowchart-diagram 组件模式）
- 数据模型（引用 data-model 组件模式）
- API 契约（标签页切换：REST/GraphQL）
- 技术选型（引用 exploration-approaches 组件模式的多选交互）
- 分阶段实施计划（引用 implementation-plan 组件模式）
- 风险与缓解
- 底部审核栏

包含共享反馈机制。`<meta name="phase" content="plan">`。

- [ ] **Step 3: 创建 tasks-template.html（任务清单模板）**

章节结构：
- 页头：功能名称、关联的 plan 链接
- 任务总览（进度条）
- 按阶段分组的任务列表：
  - Setup
  - 基础设施
  - 用户故事 P1
  - 用户故事 P2
  - 收尾
- 每个任务：`T001 [P] [US1] 描述 — 文件路径`
- 可勾选的 checkbox
- 底部审核栏

包含共享反馈机制。`<meta name="phase" content="tasks">`。

- [ ] **Step 4: 创建 review-template.html（审查报告模板）**

章节结构：
- 页头：功能名称、审查范围
- 审查摘要（通过/警告/错误 计数）
- 文件变更列表
- 逐文件审查（引用 annotated-pr-review 组件模式）
- 每个问题：严重程度、位置描述、建议修改、同意/不同意选项
- 行动项汇总
- 底部审核栏

包含共享反馈机制。`<meta name="phase" content="review">`。

- [ ] **Step 5: 浏览器验证 + 提交**

```bash
git add .specify/templates/spec-template.html .specify/templates/plan-template.html .specify/templates/tasks-template.html .specify/templates/review-template.html
git commit -m "feat: add spec, plan, tasks, review document templates"
```

---

## Task 12: 编写斜杠命令 — spec-init

**Files:**
- Create: `.claude/commands/spec-init.md`

- [ ] **Step 1: 创建 spec-init 命令**

```markdown
---
description: "初始化新功能规范（Spec-Driven Development 第一步）"
---

# /spec-init — 初始化新功能规范

你正在执行 Spec-Driven Development 工作流的第一步：初始化新功能的需求规格。

## 输入

用户提供功能描述文本作为参数：$ARGUMENTS

## 执行步骤

### 1. 读取项目宪章

读取 `.specify/constitution.md`，了解项目不变量。

### 2. 生成功能编号和目录

- 扫描 `.specify/specs/` 目录，找到最大编号
- 新编号 = 最大编号 + 1（三位数，如 001、002）
- 从功能描述中提取简短英文名（kebab-case）
- 创建目录 `.specify/specs/<NNN>-<name>/`
- 创建子目录 `artifacts/` 和 `clarifications/`

### 3. 读取模板

读取 `.specify/templates/spec-template.html`，理解章节结构。

### 4. 生成 spec.html

基于模板结构生成 `.specify/specs/<NNN>-<name>/spec.html`，内容要求：

- **概述**：一句话描述功能目标
- **背景与动机（WHY）**：为什么需要这个功能，解决什么问题
- **功能需求（WHAT）**：按用户故事组织，格式：
  ```
  US1: 作为 <角色>，我想要 <行为>，以便 <目的>
  验收标准：
  - <条件1>
  - <条件2>
  ```
- **非功能需求**：性能、安全、可用性等（如适用）
- **约束与假设**：技术约束、业务约束
- 只描述 WHAT 和 WHY，不涉及 HOW

所有 CSS 内联，零外部依赖。参照 spec-template.html 的样式。

### 5. 生成反馈骨架

生成 `.specify/specs/<NNN>-<name>/spec.feedback.json`：

```json
{
  "artifact": "spec.html",
  "feature": "<NNN>-<name>",
  "phase": "spec",
  "status": "pending_review",
  "decisions": [],
  "review": { "verdict": null, "feedback": "", "timestamp": null },
  "created_at": "<当前ISO时间>",
  "updated_at": "<当前ISO时间>"
}
```

### 6. 更新看板

- 更新或创建 `.specify/specs/dashboard-state.json`：
  - 在 `features` 数组中添加新功能条目
  - 设置 `current_feature` 为新功能目录名
  - 在 `timeline` 中添加 `spec_created` 事件
- 基于 `.specify/templates/dashboard.html` 重建 `.specify/specs/dashboard.html`
  - 将 dashboard-state.json 内容嵌入 `<script type="application/json" id="dashboardState">` 标签

### 7. 输出结果

在终端输出：

```
✅ 功能规范已创建！

📄 需求规格: file:///<绝对路径>/.specify/specs/<NNN>-<name>/spec.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

下一步：
1. 在浏览器中打开 spec.html 审核需求
2. 如需澄清，执行 /spec-clarify
3. 审核通过后，执行 /spec-plan 进入方案设计
```

## 错误处理

- 如果 `.specify/constitution.md` 不存在，报错并提示先创建宪章
- 如果功能描述为空，报错并提示提供描述
- 如果目录已存在，报错并建议使用不同名称
```

- [ ] **Step 2: 提交**

```bash
git add .claude/commands/spec-init.md
git commit -m "feat: add /spec-init slash command"
```

---

## Task 13: 编写斜杠命令 — spec-clarify

**Files:**
- Create: `.claude/commands/spec-clarify.md`

- [ ] **Step 1: 创建 spec-clarify 命令**

```markdown
---
description: "对当前功能需求进行澄清（Spec-Driven Development 第二步）"
---

# /spec-clarify — 需求澄清

你正在执行 Spec-Driven Development 工作流的第二步：对需求规格进行澄清。

## 前置条件

- `.specify/specs/dashboard-state.json` 存在且 `current_feature` 有值
- 对应功能目录下 `spec.feedback.json` 存在

## 执行步骤

### 1. 定位当前功能

读取 `.specify/specs/dashboard-state.json` 获取 `current_feature`。

### 2. 读取现有 spec

读取 `.specify/specs/<current_feature>/spec.html`，分析需求内容。

### 3. 生成澄清问题

分析 spec 中的模糊点，生成最多 5 个澄清问题。问题分类（按需选择）：

- **功能范围与行为**：边界条件、异常流程
- **数据模型**：实体、字段、关系
- **交互与 UX 流程**：用户操作路径
- **非功能质量属性**：性能目标、安全要求
- **集成与外部依赖**：第三方系统、API
- **边界条件与失败处理**：错误场景、降级策略
- **约束与权衡**：技术限制、优先级取舍
- **术语定义**：领域概念澄清

### 4. 更新 spec.html

在 spec.html 底部（审核栏之前）插入澄清区域，每个问题：

```html
<div class="clarification-block" data-decision="clarify-<N>" data-type="single-select">
  <h4>Q<N>: <问题标题></h4>
  <p><问题描述></p>
  <div class="options">
    <label><input type="radio" name="clarify-<N>" value="<推荐选项>"> <推荐选项> ✨ 推荐</label>
    <label><input type="radio" name="clarify-<N>" value="<选项B>"> <选项B></label>
    <label><input type="radio" name="clarify-<N>" value="<选项C>"> <选项C></label>
  </div>
  <input type="text" placeholder="补充说明（可选）..." />
</div>
```

每个问题附带推荐选项（基于最佳实践，标注 ✨）。

### 5. 更新反馈骨架

更新 `spec.feedback.json`，在 `decisions` 数组中添加澄清问题的条目。

### 6. 更新看板

- 在 `dashboard-state.json` 的 timeline 中添加 `clarify_created` 事件
- 重建 `dashboard.html`

### 7. 输出结果

```
✅ 澄清问题已生成！

📄 更新的规格: file:///<绝对路径>/.specify/specs/<current_feature>/spec.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

请在浏览器中回答澄清问题后提交反馈，然后执行 /spec-plan
```
```

- [ ] **Step 2: 提交**

```bash
git add .claude/commands/spec-clarify.md
git commit -m "feat: add /spec-clarify slash command"
```

---

## Task 14: 编写斜杠命令 — spec-plan

**Files:**
- Create: `.claude/commands/spec-plan.md`

- [ ] **Step 1: 创建 spec-plan 命令**

```markdown
---
description: "设计技术方案（Spec-Driven Development 第三步）"
---

# /spec-plan — 技术方案设计

你正在执行 Spec-Driven Development 工作流的第三步：设计技术方案。

## 前置条件（门禁）

1. 读取 `.specify/specs/dashboard-state.json` 获取 `current_feature`
2. 读取 `.specify/specs/<current_feature>/spec.feedback.json`
3. 检查 `review.verdict === "approved"`
4. 如果不是 "approved"，拒绝执行并输出：

```
❌ 门禁未通过：需求规格尚未审核通过
请先在浏览器中审核 spec.html 并点击"通过"
```

## 执行步骤

### 1. 读取所有上游文档

- `.specify/constitution.md`
- `.specify/specs/<current_feature>/spec.html`
- `.specify/specs/<current_feature>/spec.feedback.json`（特别是 decisions，了解用户选择）
- `.specify/templates/plan-template.html`
- `.specify/templates/components/` 下相关组件（flowchart-diagram、implementation-plan、exploration-approaches 等）

### 2. 生成 plan.html

基于 plan-template.html 结构生成，内容要求：

- **方案概述**：整体技术方案的一句话概括
- **架构设计**：系统架构图（使用 flowchart-diagram 组件模式的 SVG）
- **数据模型**：实体、字段、关系、索引（如适用）
- **API 契约**：端点、请求/响应格式（标签页切换展示）
- **技术选型**：涉及选择的部分使用 exploration-approaches 组件模式，嵌入 `data-decision` 交互
- **分阶段实施计划**：使用 implementation-plan 组件模式
- **风险与缓解**：识别技术风险并提供缓解方案

所有 CSS 内联，零外部依赖。

### 3. 按需生成 artifacts

根据方案复杂度，在 `artifacts/` 下生成衍生文档（每个都是自包含 HTML）：

- `data-model.html` — 详细数据模型图
- `api-contracts.html` — API 契约详情
- `architecture.html` — 架构图

每个衍生文档生成对应的 `.feedback.json` 骨架。

plan.html 中通过链接引用这些 artifacts。

### 4. 生成反馈骨架

生成 `plan.feedback.json`，decisions 包含技术选型中的交互选项。

### 5. 更新看板

- 更新 `dashboard-state.json`：phase 改为 "plan"，status 改为 "pending_review"
- 添加 `plan_created` 时间线条目
- 重建 `dashboard.html`

### 6. 输出结果

```
✅ 技术方案已生成！

📄 技术方案: file:///<绝对路径>/.specify/specs/<current_feature>/plan.html
📎 衍生文档: file:///<绝对路径>/.specify/specs/<current_feature>/artifacts/
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

请在浏览器中审核方案后提交反馈，然后执行 /spec-tasks
```
```

- [ ] **Step 2: 提交**

```bash
git add .claude/commands/spec-plan.md
git commit -m "feat: add /spec-plan slash command"
```

---

## Task 15: 编写斜杠命令 — spec-tasks

**Files:**
- Create: `.claude/commands/spec-tasks.md`

- [ ] **Step 1: 创建 spec-tasks 命令**

```markdown
---
description: "拆解实施任务（Spec-Driven Development 第四步）"
---

# /spec-tasks — 任务拆解

## 前置条件（门禁）

1. 读取 `dashboard-state.json` 获取 `current_feature`
2. 读取 `plan.feedback.json`，检查 `review.verdict === "approved"`
3. 未通过则拒绝执行

## 执行步骤

### 1. 读取所有上游文档

- `plan.html`、`plan.feedback.json`
- `artifacts/` 下所有衍生文档
- `.specify/templates/tasks-template.html`

### 2. 生成 tasks.html

格式要求：
- 任务编号：`T001`、`T002`...（三位数递增）
- 可并行标记：`[P]` 表示可与其他 [P] 任务并行执行
- 用户故事关联：`[US1]`、`[US2]` 关联到 spec 中的用户故事
- 文件路径：每个任务注明涉及的文件路径

阶段排列：
1. **Setup** — 项目结构、配置、依赖安装
2. **基础设施** — 数据库迁移、基础服务
3. **用户故事 P1** — 高优先级功能
4. **用户故事 P2** — 中优先级功能
5. **收尾** — 测试、文档、优化

每个任务使用可勾选的 checkbox，初始为未勾选。

### 3. 生成反馈骨架

`tasks.feedback.json` 的 decisions 包含任务优先级调整选项。

### 4. 更新看板

- phase 改为 "tasks"，status 改为 "pending_review"
- 添加 `tasks_created` 时间线条目
- 重建 dashboard.html

### 5. 输出结果

```
✅ 任务清单已生成！

📄 任务清单: file:///<绝对路径>/.specify/specs/<current_feature>/tasks.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

请审核任务清单后提交反馈，然后执行 /spec-implement 开始实现
```
```

- [ ] **Step 2: 提交**

```bash
git add .claude/commands/spec-tasks.md
git commit -m "feat: add /spec-tasks slash command"
```

---

## Task 16: 编写斜杠命令 — spec-implement 和 spec-review

**Files:**
- Create: `.claude/commands/spec-implement.md`
- Create: `.claude/commands/spec-review.md`

- [ ] **Step 1: 创建 spec-implement 命令**

```markdown
---
description: "执行任务实现（Spec-Driven Development 第五步）"
---

# /spec-implement — 执行实现

## 前置条件（门禁）

1. 读取 `dashboard-state.json` 获取 `current_feature`
2. 读取 `tasks.feedback.json`，检查 `review.verdict === "approved"`
3. 未通过则拒绝执行

## 执行步骤

### 1. 加载所有设计文档

读取 `spec.html`、`plan.html`、`tasks.html`、`artifacts/*`，了解完整上下文。

### 2. 逐任务执行

- 按任务编号顺序执行（T001 → T002 → ...）
- 遇到 `[P]` 标记的任务，提示用户可以并行启动多个 Agent
- 每完成一个任务：
  - 实际编写/修改代码文件
  - 更新 `tasks.html` 中对应 checkbox 为 `[X]`
  - 更新 `tasks.feedback.json` 的 `updated_at`

### 3. 定期更新看板

每完成 3-5 个任务后，更新看板显示进度。

### 4. 完成后

全部任务完成后：
- 更新 `dashboard-state.json`：status 改为 "implementation_complete"
- 输出：

```
✅ 所有任务已完成！

建议执行 /spec-review 进行代码审查
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html
```
```

- [ ] **Step 2: 创建 spec-review 命令**

```markdown
---
description: "代码审查（Spec-Driven Development 第六步）"
---

# /spec-review — 代码审查

## 前置条件

- 当前功能有代码变更（通过 git diff 或文件时间戳检测）

## 执行步骤

### 1. 检测代码变更

运行 `git diff` 或比较文件修改时间，识别自上次审查以来的代码变更。

### 2. 生成 review.html

基于 `review-template.html` 和 `annotated-pr-review` 组件模式生成：

- **审查摘要**：通过/警告/错误 计数
- **文件变更列表**：每个变更文件概览
- **逐文件审查**：
  - 代码差异展示
  - 每个问题标注严重程度：🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Low
  - 问题描述和修改建议
  - 每个问题附带"同意修改"/"不需修改"单选 + 备注
- **行动项汇总**

### 3. 生成反馈骨架

`review.feedback.json` 的 decisions 包含每个审查问题的判断选项。

### 4. 更新看板

- phase 改为 "review"，status 改为 "pending_review"
- 添加 `review_created` 时间线条目
- 重建 dashboard.html

### 5. 输出结果

```
✅ 审查报告已生成！

📄 审查报告: file:///<绝对路径>/.specify/specs/<current_feature>/review.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

请在浏览器中审核后提交反馈
```
```

- [ ] **Step 3: 提交**

```bash
git add .claude/commands/spec-implement.md .claude/commands/spec-review.md
git commit -m "feat: add /spec-implement and /spec-review slash commands"
```

---

## Task 17: 编写 Hook 脚本

**Files:**
- Create: `.claude/hooks/pre-spec-check.sh`
- Create: `.claude/hooks/post-task-verify.sh`

- [ ] **Step 1: 创建 pre-spec-check.sh**

规范生成前校验脚本，检查项目基础设施是否就绪：

```bash
#!/bin/bash
# pre-spec-check.sh — 规范生成前校验
set -e

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SPECIFY_DIR="$PROJECT_ROOT/.specify"

# 检查 .specify 目录存在
if [ ! -d "$SPECIFY_DIR" ]; then
  echo "ERROR: .specify/ 目录不存在，请先初始化项目"
  exit 1
fi

# 检查 constitution.md 存在
if [ ! -f "$SPECIFY_DIR/constitution.md" ]; then
  echo "ERROR: constitution.md 不存在，请先创建项目宪章"
  exit 1
fi

# 检查 templates 目录存在
if [ ! -d "$SPECIFY_DIR/templates" ]; then
  echo "ERROR: templates/ 目录不存在"
  exit 1
fi

echo "OK: 项目基础设施校验通过"
```

- [ ] **Step 2: 创建 post-task-verify.sh**

任务完成后验证脚本，检查产出文件完整性：

```bash
#!/bin/bash
# post-task-verify.sh — 任务完成后验证
set -e

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SPECIFY_DIR="$PROJECT_ROOT/.specify"
SPECS_DIR="$SPECIFY_DIR/specs"

# 检查 dashboard-state.json 是否是合法 JSON
if [ -f "$SPECS_DIR/dashboard-state.json" ]; then
  python3 -c "import json; json.load(open('$SPECS_DIR/dashboard-state.json'))" 2>/dev/null || {
    echo "WARNING: dashboard-state.json 格式异常"
  }
fi

# 检查当前功能的 feedback.json 格式
STATE=$(cat "$SPECS_DIR/dashboard-state.json" 2>/dev/null)
if [ -n "$STATE" ]; then
  FEATURE=$(echo "$STATE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('current_feature',''))" 2>/dev/null)
  if [ -n "$FEATURE" ] && [ -d "$SPECS_DIR/$FEATURE" ]; then
    for fb in "$SPECS_DIR/$FEATURE/"*.feedback.json; do
      if [ -f "$fb" ]; then
        python3 -c "import json; json.load(open('$fb'))" 2>/dev/null || {
          echo "WARNING: $(basename $fb) 格式异常"
        }
      fi
    done
  fi
fi

echo "OK: 产出文件验证完成"
```

- [ ] **Step 3: 添加执行权限 + 提交**

```bash
chmod +x .claude/hooks/pre-spec-check.sh .claude/hooks/post-task-verify.sh
git add .claude/hooks/
git commit -m "feat: add pre-spec-check and post-task-verify hook scripts"
```

---

## Task 18: 端到端验证

**Files:**
- 无新文件，验证已有文件

- [ ] **Step 1: 验证文件完整性**

```bash
cd /Users/shun/Documents/person-project/vibe-conding-guide
echo "=== 检查文件数量 ==="
find .specify/ .claude/ CLAUDE.md -type f | wc -l
echo "=== 检查组件数量 ==="
ls .specify/templates/components/ | wc -l
echo "=== 检查命令数量 ==="
ls .claude/commands/ | wc -l
```

Expected: 文件 36+，组件 20，命令 6

- [ ] **Step 2: 浏览器验证 dashboard.html**

打开 `.specify/templates/dashboard.html`，确认：
- 左右布局正确
- 左侧统计、时间线、功能列表区域渲染正常
- 右侧内容区空白（无数据时显示占位）

- [ ] **Step 3: 浏览器抽检 3 个组件**

随机打开 3 个组件 HTML，确认：
- 页面正常渲染（CSS 生效）
- 底部审核按钮栏显示
- 点击"通过"/"驳回"有反馈提示

- [ ] **Step 4: 验证斜杠命令可用**

在 Claude Code 中测试 `/spec-init` 命令是否被识别（不需要完整执行，确认命令加载即可）。

- [ ] **Step 5: 最终提交**

```bash
git add -A
git commit -m "chore: complete spec-driven development framework setup"
```

---

## 自检清单

### 规格覆盖

| 设计文档章节 | 对应任务 |
|---|---|
| 一、背景与目标 | 贯穿所有任务 |
| 二、目录结构 | Task 1 |
| 三、工作流阶段（6 个命令） | Task 12-16 |
| 四、看板主页 | Task 10 |
| 五、反馈机制 | Task 4（共享机制） |
| 六、CLAUDE.md 规则 | Task 3 |
| 七、20 种 HTML 组件 | Task 4-9 |
| 八、斜杠命令 | Task 12-16 |
| 九、未来愿景 | 不在实施范围内 |
| 附录 | 不需要实施 |

### 占位符扫描

无 TBD、TODO、待定内容。所有步骤包含具体操作指令。

### 类型一致性

- 所有 `.feedback.json` 结构一致（artifact/feature/phase/status/decisions/review/created_at/updated_at）
- 所有 HTML 组件共享同一套反馈机制（saveFeedback/collectDecisions/submitVerdict）
- 所有斜杠命令使用相同的门禁检查逻辑（读 dashboard-state.json → 读 feedback.json → 检查 verdict）
