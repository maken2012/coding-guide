#!/bin/bash
set -e

# ============================================================
# Spec-Driven Development + HTML 可视化输出框架 — 安装脚本
# ============================================================
# 用法:
#   1. 本地安装:  ./install.sh [/path/to/target/project]
#   2. 远程安装:  bash <(curl -sL https://raw.githubusercontent.com/maken2012/coding-guide/main/install.sh)
# ============================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 确定脚本所在目录（源文件位置）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- 检测安装模式 ----

REMOTE_REPO="https://github.com/maken2012/coding-guide.git"
CLEANUP_TEMP=0

if [ ! -d "${SCRIPT_DIR}/.specify" ]; then
  # 脚本目录没有 .specify/ → 远程安装模式
  echo ""
  echo -e "${BLUE}检测到远程安装模式，正在下载框架文件...${NC}"
  TEMP_DIR="$(mktemp -d)"
  git clone --depth 1 "${REMOTE_REPO}" "${TEMP_DIR}/vibe-coding-guide" 2>/dev/null
  SOURCE_DIR="${TEMP_DIR}/vibe-coding-guide"
  CLEANUP_TEMP=1
  echo -e "${GREEN}✓ 框架文件已下载${NC}"
else
  # 脚本目录有 .specify/ → 本地安装模式
  SOURCE_DIR="${SCRIPT_DIR}"
fi

# 确定目标项目目录
if [ -n "$1" ]; then
  TARGET_DIR="$(cd "$1" && pwd)"
else
  TARGET_DIR="$(pwd)"
fi

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Spec-Driven Development Framework Installer     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "目标项目: ${GREEN}${TARGET_DIR}${NC}"
echo ""

# ---- 检查 ----

# 检查目标目录是否有 git 仓库
if [ ! -d "${TARGET_DIR}/.git" ]; then
  echo -e "${YELLOW}⚠ 目标目录没有 git 仓库，是否初始化？${NC}"
  read -p "  初始化 git? [Y/n] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    (cd "${TARGET_DIR}" && git init)
    echo -e "${GREEN}✓ Git 仓库已初始化${NC}"
  fi
fi

# 检查是否已安装
if [ -d "${TARGET_DIR}/.specify" ]; then
  echo -e "${YELLOW}⚠ 检测到已有 .specify/ 目录${NC}"
  read -p "  覆盖安装? [y/N] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}安装取消${NC}"
    if [ "${CLEANUP_TEMP}" -eq 1 ]; then
      rm -rf "${TEMP_DIR}"
    fi
    exit 0
  fi
  rm -rf "${TARGET_DIR}/.specify"
fi

# ---- 创建目录结构 ----

echo -e "${BLUE}[1/5] 创建目录结构...${NC}"

mkdir -p "${TARGET_DIR}/.specify/templates/components"
mkdir -p "${TARGET_DIR}/.specify/specs"
mkdir -p "${TARGET_DIR}/.claude/commands"
mkdir -p "${TARGET_DIR}/.claude/hooks"

echo -e "${GREEN}✓ 目录结构已创建${NC}"

# ---- 复制文件 ----

echo -e "${BLUE}[2/5] 复制模板和组件...${NC}"

# 宪章
cp "${SOURCE_DIR}/.specify/constitution.md" "${TARGET_DIR}/.specify/constitution.md"

# 文档模板
for f in "${SOURCE_DIR}/.specify/templates/"*-template.html "${SOURCE_DIR}/.specify/templates/dashboard.html"; do
  if [ -f "$f" ]; then
    cp "$f" "${TARGET_DIR}/.specify/templates/"
  fi
done

# HTML 组件
for f in "${SOURCE_DIR}/.specify/templates/components/"*.html; do
  if [ -f "$f" ]; then
    cp "$f" "${TARGET_DIR}/.specify/templates/components/"
  fi
done

TEMPLATE_COUNT=$(ls "${TARGET_DIR}/.specify/templates/"*-template.html 2>/dev/null | wc -l | tr -d ' ')
COMPONENT_COUNT=$(ls "${TARGET_DIR}/.specify/templates/components/"*.html 2>/dev/null | wc -l | tr -d ' ')

echo -e "${GREEN}✓ ${TEMPLATE_COUNT} 个模板 + ${COMPONENT_COUNT} 个组件已复制${NC}"

# ---- 复制斜杠命令 ----

echo -e "${BLUE}[3/5] 安装斜杠命令...${NC}"

# 删除旧的命令（兼容升级）
rm -f "${TARGET_DIR}/.claude/commands/spec-clarify.md" 2>/dev/null
rm -f "${TARGET_DIR}/.claude/commands/spec-tasks.md" 2>/dev/null

# 复制新命令
for f in "${SOURCE_DIR}/.claude/commands/"*.md; do
  if [ -f "$f" ]; then
    cp "$f" "${TARGET_DIR}/.claude/commands/"
  fi
done

COMMAND_COUNT=$(ls "${TARGET_DIR}/.claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
echo -e "${GREEN}✓ ${COMMAND_COUNT} 个斜杠命令已安装${NC}"

# ---- 复制 Hook 脚本 ----

echo -e "${BLUE}[4/5] 安装 Hook 脚本...${NC}"

for f in "${SOURCE_DIR}/.claude/hooks/"*.sh; do
  if [ -f "$f" ]; then
    cp "$f" "${TARGET_DIR}/.claude/hooks/"
    chmod +x "${TARGET_DIR}/.claude/hooks/$(basename "$f")"
  fi
done

echo -e "${GREEN}✓ Hook 脚本已安装${NC}"

# ---- 配置 CLAUDE.md ----

echo -e "${BLUE}[5/5] 配置 CLAUDE.md...${NC}"

CLAUDE_MD="${TARGET_DIR}/CLAUDE.md"

if [ -f "${CLAUDE_MD}" ]; then
  # 检查是否已包含 SDD 标记
  if grep -q "<!-- SDD START -->" "${CLAUDE_MD}"; then
    # 替换已有内容
    sed -i.bak '/<!-- SDD START -->/,/<!-- SDD END -->/d' "${CLAUDE_MD}"
    rm -f "${CLAUDE_MD}.bak"
  fi

  # 追加到现有文件
  {
    echo ""
    echo "<!-- SDD START -->"
    cat "${SOURCE_DIR}/CLAUDE.md"
    echo "<!-- SDD END -->"
  } >> "${CLAUDE_MD}"

  echo -e "${GREEN}✓ CLAUDE.md 已更新（追加 SDD 规则）${NC}"
else
  cp "${SOURCE_DIR}/CLAUDE.md" "${CLAUDE_MD}"
  echo -e "${GREEN}✓ CLAUDE.md 已创建${NC}"
fi

# ---- 配置 .gitignore ----

GITIGNORE="${TARGET_DIR}/.gitignore"
if [ -f "${GITIGNORE}" ]; then
  if ! grep -q ".DS_Store" "${GITIGNORE}"; then
    echo ".DS_Store" >> "${GITIGNORE}"
  fi
else
  echo ".DS_Store" > "${GITIGNORE}"
fi

# ---- 清理临时文件 ----

if [ "${CLEANUP_TEMP}" -eq 1 ]; then
  rm -rf "${TEMP_DIR}"
  echo -e "${GREEN}✓ 临时文件已清理${NC}"
fi

# ---- 完成 ----

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✓ 安装完成！                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "已安装:"
echo -e "  ${BLUE}→${NC} ${TEMPLATE_COUNT} 个文档模板   (.specify/templates/)"
echo -e "  ${BLUE}→${NC} ${COMPONENT_COUNT} 个 HTML 组件   (.specify/templates/components/)"
echo -e "  ${BLUE}→${NC} ${COMMAND_COUNT} 个斜杠命令     (.claude/commands/)"
echo -e "  ${BLUE}→${NC} 2 个 Hook 脚本       (.claude/hooks/)"
echo -e "  ${BLUE}→${NC} 1 个项目宪章         (.specify/constitution.md)"
echo -e "  ${BLUE}→${NC} 1 个项目规则         (CLAUDE.md)"
echo ""
echo -e "主线工作流:"
echo -e "  ${YELLOW}/spec-init${NC}     → 架构选型 + 高层需求"
echo -e "  ${YELLOW}/spec-detail${NC}   → 需求详述"
echo -e "  ${YELLOW}/spec-design${NC}   → 一站式设计（流程/数据/接口/UI）"
echo -e "  ${YELLOW}/spec-plan${NC}     → 实施计划 + 任务拆解"
echo -e "  ${YELLOW}/spec-implement${NC} → 开发 + 测试"
echo -e "  ${YELLOW}/spec-review${NC}   → 代码审查 + 部署方案"
echo ""
echo -e "辅助命令:"
echo -e "  ${YELLOW}/spec-explore${NC}  /spec-research /spec-report /spec-present"
echo ""
echo -e "开始使用: 在 Claude Code 中输入 ${YELLOW}/spec-init \"功能描述\"${NC}"
echo ""
