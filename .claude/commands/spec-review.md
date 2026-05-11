---
description: "代码审查（Spec-Driven Development 第六步）"
---

# /spec-review — 代码审查

## 前置条件

- 当前功能有代码变更（通过 git diff 检测）

## 执行步骤

### 1. 检测代码变更

运行 `git diff` 识别变更。

### 2. 生成 review.html

基于 `review-template.html` 和 `annotated-pr-review` 组件模式生成：
- 审查摘要（通过/警告/错误计数）
- 文件变更列表
- 逐文件审查（每问题标注严重程度 + 建议修改 + 同意/不同意选项）
- 行动项汇总

### 3. 生成反馈骨架 + 更新看板

### 4. 输出结果

```
✅ 审查报告已生成！

📄 审查报告: file:///<绝对路径>/.specify/specs/<current_feature>/review.html
📋 看板主页: file:///<绝对路径>/.specify/specs/dashboard.html

请在浏览器中审核后提交反馈
```
