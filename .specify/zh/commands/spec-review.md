---
description: "代码审查 + 部署方案（Spec-Driven Development 第六步）"
---

# /spec-review — 审查 + 部署

## 前置条件
有代码变更

## 执行步骤

### 1. 检测变更
运行 `git diff` 识别变更范围。

### 2. 生成 review.html
读取 `review-template.html` 和 `annotated-pr-review.html` 组件：
- 审查摘要（Critical/High/Medium/Low 计数）
- 文件变更列表
- 逐文件审查（带批注、严重程度、建议、同意/不同意选项）
- 行动项汇总

### 3. 按需生成 deploy-plan.html
AI 判断是否涉及部署（有新配置、数据库迁移、新依赖、功能开关等）：
- 如是 → 读取 `deploy-plan-template.html`，生成 `deploy-plan.html`
- 包含：部署架构图、环境配置、数据库迁移、依赖组件、初始化脚本、功能开关、回滚方案
- 引用组件：`flowchart-diagram`（部署流水线）、`feature-flags-editor`（开关配置）

### 4. 更新看板

### 5. 输出
```
✅ 审查报告已生成！

📄 审查报告: file:///<绝对路径>/.specify/specs/<current_feature>/review.html
📄 部署方案: file:///<绝对路径>/.specify/specs/<current_feature>/deploy-plan.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html
```
