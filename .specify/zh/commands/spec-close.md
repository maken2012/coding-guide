---
description: "需求关闭（Spec-Driven Development 终止指令）"
agent:
  id: spec-close
  type: auxiliary
  order: null
  gate: "review.feedback.verdict = approved"
  produces_gate: null
  requires_feature: true
  writes_state: true
  output_files: [close-report.html]
  templates: [report-template.html]
  components: [status-report]
---

# /spec-close — 需求关闭

## 输入
用户提供功能 ID：$ARGUMENTS

## 功能定位
- 如果 `$ARGUMENTS` 包含功能 ID（匹配 `YYYYMMDD-NNN`），定位该功能目录
- 否则，扫描 `.specify/specs/*/` 查找最近一个 review 已通过的功能

## 前置条件
- 该功能的 review 阶段已通过（`review.feedback.verdict = approved`）

## 执行步骤

### 1. 验证管道完整性
读取 `.feature-state.json`，检查：
- 所有已开始的阶段必须为 `approved`
- 如有未通过的阶段，列出缺失项并终止关闭

### 2. 检查修复记录
- 读取 `fix-log.jsonl`（如存在）
- 检查是否有 `status` 不是 `fixed` 的条目
- 如有未关闭的修复，提示用户并终止关闭

### 3. 自动化验证

#### 3.1 代码级检查（自动执行）
根据项目技术栈，自动检测并运行可用的检查：

| 检测信号 | 执行命令 |
|---------|---------|
| `package.json` + test script | `npm test` |
| `pytest.ini` / `conftest.py` | `pytest` |
| `go.mod` + `*_test.go` | `go test ./...` |
| `Makefile` + `test` target | `make test` |
| `Cargo.toml` + `#[test]` | `cargo test` |
| `.eslintrc*` / `eslint.config.*` | `npx eslint .` |
| `tsconfig.json` | `npx tsc --noEmit` |

检查结果记录到关闭报告。

#### 3.2 视觉/交互检查（需要人工）
以下场景当前无法完全自动化，需要人工确认：

- **视觉还原度**：颜色、间距、字体、动画是否与设计一致
- **交互体验**：操作流畅度、异常状态处理、边界场景
- **业务正确性**：复杂业务流程的端到端验证
- **兼容性**：不同浏览器/设备/分辨率的表现

> **探索：自动化视觉测试的可能性**
>
> 对于 Web 项目，可以通过以下方式减少人工视觉验证：
> - **Playwright 截图对比**：`npx playwright test --update-snapshots` 生成基准图，后续自动对比
> - **Percy / Chromatic**：CI 集成的视觉回归服务
> - **Storybook + Chromatic**：组件级视觉测试
>
> 但首次仍需人工确认基准图正确性。

### 4. 生成关闭报告
生成 `close-report.html`，包含：
- 需求概述（名称、创建时间、总耗时）
- 各阶段完成时间线
- 修复历史摘要（次数、主要问题）
- 自动化验证结果（通过/失败/跳过）
- 人工验证清单（待确认项，带 checkbox）

### 5. 更新状态
- 更新 `.feature-state.json`：设置 `closed_at` 为当前时间
- 向 `registry.jsonl` 追加 `feature_closed` 事件
- 运行 `.claude/hooks/refresh-dashboard.sh` 重建 dashboard

### 6. 输出
```
✅ 需求已关闭！

功能: <功能名称>
持续时间: <N天>
阶段完成: <N/6>
修复次数: <N次>
自动化验证: ✅ 全部通过 / ⚠️ 部分通过 / ❌ 有失败

关闭报告: file:///<绝对路径>/.specify/specs/<feature_id>/close-report.html
```
