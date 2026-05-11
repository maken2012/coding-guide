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

## 看板 dashboard.html 维护规则
- 读取 .specify/specs/dashboard-state.json 获取全局状态
- 左侧 25%：总览统计 + 时间线 + 功能列表
- 右侧 75%：当前选中功能的当前阶段文档（通过 iframe 加载）
- 底部：通过/驳回审核按钮
- 每次生成或更新任何规范文档后，必须重建 dashboard.html
