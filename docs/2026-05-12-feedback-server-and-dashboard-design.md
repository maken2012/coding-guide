# Feedback Server + Dashboard 改进设计

**日期：** 2026-05-12
**状态：** Draft

## 背景

SDD 框架当前存在以下问题：

1. **反馈无法自动写入** — `saveFeedback()` 只能弹"另存为"对话框或复制剪贴板，无法直接写入 `.feedback.json`
2. **时区不一致** — 模板用 UTC（`toISOString()`），脚本透传原始字符串无转换，出现 UTC/UTC+8 混乱
3. **审批决策未在看板展示** — 审批后只标记状态，用户选的具体方案内容不显示
4. **已通过阶段仍显示审核栏** — 已审批通过的看板不应再加载 iframe 和审核按钮

## 定位

本次改进将 SDD 框架从"零依赖纯模板"升级为**微型管理系统**。引入 Python HTTP 服务 + SQLite 存储层，实现：

- 浏览器反馈自动回写
- 结构化数据存储
- Dashboard / Timeline 动态查库，实时展示

## 架构

```
                          浏览器
                            │
              ┌─────────────┼─────────────┐
              │             │             │
        dashboard.html  timeline.html  spec.html (等模板)
              │             │             │
        fetch API      fetch API    POST /api/feedback
              │             │             │
              └─────────────┼─────────────┘
                            │
                ┌───────────▼───────────┐
                │  feedback-server.py   │ ← Python 标准库 HTTP Server
                │  (localhost:8421)     │
                └───┬───────────┬───────┘
                    │           │
            写 .feedback.json   写 SQLite (sdd.db)
            (Agent 兼容)        (唯一数据源)
```

**核心变化：** dashboard.html 和 timeline.html 变为动态 SPA，通过 fetch API 直接查库，不再依赖 refresh-dashboard.sh 重建静态文件。

## 设计详情

### 1. SQLite 数据层

**文件：** `.specify/specs/sdd.db`

```sql
CREATE TABLE features (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  current_phase TEXT,
  status TEXT DEFAULT 'draft',
  created_at TEXT,
  updated_at TEXT
);

CREATE TABLE phases (
  feature_id TEXT,
  phase TEXT,
  status TEXT DEFAULT 'draft',
  artifact_path TEXT,
  updated_at TEXT,
  PRIMARY KEY (feature_id, phase)
);

CREATE TABLE decisions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  feature_id TEXT,
  phase TEXT,
  decision_key TEXT,
  decision_value TEXT,
  created_at TEXT
);

CREATE TABLE timeline (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  feature_id TEXT,
  event_type TEXT,
  description TEXT,
  created_at TEXT
);
```

**时区策略：** 所有时间字段统一使用本地时区 `YYYY-MM-DD HH:MM:SS`，由 feedback-server.py 通过 `datetime.now().strftime('%Y-%m-%d %H:%M:%S')` 生成。

**兼容策略：** JSON 文件（`.feature-state.json`、`.feedback.json`）继续保留作为 Agent 读写接口。feedback-server.py 双写 JSON + SQLite。Agent 命令无需修改。

### 2. Feedback Server

**文件：** `.claude/hooks/feedback-server.py`

纯 Python 标准库（http.server + sqlite3），零外部依赖。

#### API 列表

| 方法 | 路径 | 功能 |
|------|------|------|
| GET | `/` | 重定向到 `/specs/dashboard.html` |
| GET | `/timeline` | 返回 `/specs/timeline.html` |
| GET | `/specs/<path>` | 提供静态文件 |
| GET | `/api/features` | 所有功能列表 + 当前状态 |
| GET | `/api/phases/{feature_id}` | 该功能各阶段状态 |
| GET | `/api/decisions/{feature_id}` | 该功能所有决策 |
| GET | `/api/timeline?limit=10` | 最近 N 条时间线 |
| GET | `/api/timeline?page=1&per_page=50&feature_id=xxx` | 分页时间线（可按功能筛选） |
| POST | `/api/feedback` | 提交反馈 → 双写 JSON + SQLite |

#### POST /api/feedback 请求体

```json
{
  "feature_id": "20260512-001-monitor",
  "phase": "spec",
  "verdict": "approved",
  "feedback": "看起来不错",
  "decisions": {
    "architecture": "microservice",
    "tech_stack": "vue3"
  },
  "timestamp": "2026-05-12 16:30:00"
}
```

#### 安全约束（路径沙箱）

所有文件操作必须限制在项目 `.specify/specs/` 目录内，防止路径穿越攻击。

**Feature ID 校验：**
- 必须匹配正则：`^\d{8}-\d{3}-[a-zA-Z0-9_-]+$`（如 `20260512-001-monitor`）
- 拒绝包含 `..`、`/`、`\`、空字符的输入
- 拒绝绝对路径或非预期格式

**Phase 校验：**
- 必须是枚举值之一：`spec`、`detail`、`design`、`plan`、`implement`、`review`

**Verdict 校验：**
- 必须是枚举值之一：`approved`、`rejected`

**文件写入路径构建：**
```python
# 先校验 feature_id 格式
if not re.match(r'^\d{8}-\d{3}-[a-zA-Z0-9_-]+$', feature_id):
    return 400, '{"error": "invalid feature_id"}'

# 用 os.path.realpath 解析真实路径，再验证是否在沙箱内
target_dir = os.path.realpath(os.path.join(SPECS_ROOT, feature_id))
if not target_dir.startswith(os.path.realpath(SPECS_ROOT)):
    return 403, '{"error": "path traversal denied"}'

# 只允许写入 .feedback.json 和 .feature-state.json
allowed_files = {'.feedback.json', '.feature-state.json'}
filename = f'{phase}.feedback.json'
if filename not in allowed_files and not filename.endswith('.feedback.json'):
    return 403, '{"error": "file type denied"}'
```

**静态文件读取：**
- GET `/specs/<path>` 同样校验 realpath 必须在 SPECS_ROOT 内
- 拒绝符号链接指向沙箱外的文件

#### 处理逻辑

1. 校验 feature_id、phase、verdict 格式（见安全约束）
2. 构建路径并验证在沙箱内
3. 写入/更新对应 `.feedback.json`（仅允许 `{phase}.feedback.json`）
4. 写入 SQLite：
   - `decisions` 表 — 每个决策项一行（先删旧值再插入）
   - `timeline` 表 — 新增一条审批事件
   - `phases` 表 — 更新阶段状态
   - `features` 表 — 更新 current_phase 和 status
5. 返回 `{ "ok": true }`

#### 启动方式

```bash
python3 .claude/hooks/feedback-server.py
python3 .claude/hooks/feedback-server.py --port 8421 --root /path/to/project/.specify/specs
```

启动时自动初始化 SQLite 数据库（如不存在则建表）。从现有 `.feature-state.json` 和 `.feedback.json` 迁移历史数据到 SQLite。

### 3. 模板 saveFeedback 改造

所有阶段模板（spec、detail、plan、review 等）中的 `saveFeedback()` 和 `submitVerdict()` 改为：

**saveFeedback：** 优先 POST 到 feedback-server，失败降级到 File System Access API / 剪贴板。

**submitVerdict：**
- `timestamp` 改为 `new Date().toLocaleString('sv-SE')`（本地时间）
- 增加 `feature_id` 字段（从 URL 参数 `?feature_id=xxx` 或 `<meta name="feature-id">` 读取）

### 4. Dashboard 改造（动态 SPA）

**文件：** `.specify/zh/templates/dashboard.html`、`.specify/en/templates/dashboard.html`

**核心变化：** 移除内嵌 `<script type="application/json" id="dashboardState">` 静态数据，改为页面加载时通过 fetch API 拉取。

#### 数据加载

```javascript
// 页面加载时
async function init() {
  var features = await fetch('/api/features').then(r => r.json());
  var timeline = await fetch('/api/timeline?limit=10').then(r => r.json());
  renderFeatureList(features);
  renderTimeline(timeline);
}
```

#### 功能列表渲染

点击功能时：

1. `fetch('/api/phases/' + featureId)` → 获取各阶段状态
2. `fetch('/api/decisions/' + featureId)` → 获取决策内容
3. 根据阶段状态决定展示方式：
   - **approved** → 隐藏 iframe，显示"已通过 ✓"状态卡片 + 决策折叠摘要
   - **pending_review / rejected** → 加载 iframe + 审核栏

#### 决策折叠摘要

每个功能卡片下方新增可折叠区域，展示各阶段决策：

```
▼ 决策记录 (3)
  架构方案: 微服务        ✓
  技术栈: Vue3            ✓
  视觉方向: 简约科技风    ✓
```

已通过阶段绿色 ✓，未通过灰色。点击卡片展开/折叠。

#### 审核栏控制

- approved 阶段 → 不加载 iframe，不显示审核栏
- pending_review / rejected → 加载 iframe + 审核栏

#### 时间线摘要

左侧底部显示最近 10 条 + "查看完整时间线 →" 链接指向 `/timeline`。

### 5. 独立时间线页面

**文件：** `.specify/zh/templates/timeline.html`、`.specify/en/templates/timeline.html`

**功能：**

- 全屏时间线视图，通过 `fetch('/api/timeline?page=1')` 动态加载
- 左侧功能筛选栏（点击过滤特定功能的时间线）
- 每条事件：时间戳、功能名称、事件类型图标（started 蓝 / approved 绿 / rejected 红 / feedback 灰）、描述
- 分页：每页 50 条，底部"加载更多"按钮（fetch 下一页追加）

### 6. 时区统一

**统一规则：本地时区，YYYY-MM-DD HH:MM:SS 格式**

| 组件 | 当前 | 改为 |
|------|------|------|
| 模板 submitVerdict | `new Date().toISOString()` (UTC) | `new Date().toLocaleString('sv-SE')` (本地) |
| feedback-server.py | N/A | `datetime.now().strftime('%Y-%m-%d %H:%M:%S')` |
| dashboard / timeline | 静态注入 | API 返回，直接展示 |
| Agent 命令 | `date '+%Y-%m-%dT%H:%M:%S'` | 不改（feedback-server 会转换） |

### 7. install.sh 集成

新增：
- 复制 `feedback-server.py` 到 `.claude/hooks/`
- 安装完成后打印：`python3 .claude/hooks/feedback-server.py`

### 8. 废弃 refresh-dashboard.sh

dashboard.html 改为动态查库后，refresh-dashboard.sh 不再需要用于看板渲染。保留文件但标记为 deprecated，用于 Agent 命令中需要手动刷新的场景（如有）。

## 改动文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `.claude/hooks/feedback-server.py` | 新增 | HTTP 服务 + SQLite + API |
| `.specify/zh/templates/dashboard.html` | 重写 | 动态 SPA，fetch API 查库 |
| `.specify/en/templates/dashboard.html` | 重写 | 同上英文版 |
| `.specify/zh/templates/timeline.html` | 新增 | 独立时间线页面 |
| `.specify/en/templates/timeline.html` | 新增 | 同上英文版 |
| `.specify/zh/templates/spec-template.html` | 修改 | saveFeedback POST + 时区 |
| `.specify/en/templates/spec-template.html` | 修改 | 同上 |
| `.specify/zh/templates/detail-template.html` | 修改 | saveFeedback POST + 时区 |
| `.specify/en/templates/detail-template.html` | 修改 | 同上 |
| `.specify/zh/templates/plan-template.html` | 修改 | saveFeedback POST + 时区 |
| `.specify/en/templates/plan-template.html` | 修改 | 同上 |
| `.specify/zh/templates/review-template.html` | 修改 | saveFeedback POST + 时区 |
| `.specify/en/templates/review-template.html` | 修改 | 同上 |
| `install.sh` | 修改 | 集成 feedback-server |

## 不做的事情

- 不修改 Agent 命令（spec-init 等仍读写 JSON 文件）
- 不修改 constitution.md
- 不添加用户认证（本地开发工具）
- 不做 WebSocket 实时推送（刷新页面即可）
- 不删除 refresh-dashboard.sh（标记 deprecated）
