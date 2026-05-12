#!/bin/bash
set -e

# ============================================================
# Spec-Driven Development Framework — Installer
# ============================================================
# Usage:
#   1. Local:    ./install.sh [/path/to/project]
#   2. Remote:   curl -sL https://raw.githubusercontent.com/maken2012/coding-guide/main/install.sh | bash -s -- --lang zh -y
#      (or download first: curl -sL URL -o install.sh && bash install.sh)
#   Options:
#     --lang zh   Force Chinese (default)
#     --lang en   Force English
#     -y, --yes   Skip all interactive prompts
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_REPO="https://github.com/maken2012/coding-guide.git"
CLEANUP_TEMP=0
LANG_OPT=""

# ---- Parse arguments ----

TARGET_ARG=""
AUTO_YES=0
for arg in "$@"; do
  case "$arg" in
    --lang)
      shift
      LANG_OPT="$1"
      ;;
    --lang=*)
      LANG_OPT="${arg#*=}"
      ;;
    -y|--yes)
      AUTO_YES=1
      ;;
    *)
      TARGET_ARG="$arg"
      ;;
  esac
done

# ---- Detect language ----

if [ -z "${LANG_OPT}" ]; then
  # Auto-detect from system locale
  if echo "${LANG:-}" "${LC_ALL:-}" | grep -qi "zh"; then
    LANG_OPT="zh"
  else
    LANG_OPT="en"
  fi
fi

if [ "${LANG_OPT}" != "zh" ] && [ "${LANG_OPT}" != "en" ]; then
  echo -e "${RED}Error: --lang must be 'zh' or 'en'${NC}"
  exit 1
fi

# ---- Detect install mode ----

if [ ! -d "${SCRIPT_DIR}/.specify" ]; then
  echo ""
  echo -e "${BLUE}Remote install detected, downloading framework...${NC}"
  TEMP_DIR="$(mktemp -d)"
  git clone --depth 1 "${REMOTE_REPO}" "${TEMP_DIR}/vibe-coding-guide"
  SOURCE_DIR="${TEMP_DIR}/vibe-coding-guide"
  CLEANUP_TEMP=1
  echo -e "${GREEN}✓ Framework downloaded${NC}"
else
  SOURCE_DIR="${SCRIPT_DIR}"
fi

# ---- Language-dependent messages ----

if [ "${LANG_OPT}" = "zh" ]; then
  MSG_TARGET="目标项目"
  MSG_NO_GIT="⚠ 目标目录没有 git 仓库，是否初始化？"
  MSG_INIT_GIT="  初始化 git? [Y/n] "
  MSG_GIT_DONE="✓ Git 仓库已初始化"
  MSG_EXISTS="⚠ 检测到已有 .specify/ 目录"
  MSG_OVERWRITE="  覆盖安装? [y/N] "
  MSG_CANCEL="安装取消"
  MSG_DIR="创建目录结构..."
  MSG_DIR_DONE="✓ 目录结构已创建"
  MSG_COPY="复制模板和组件..."
  MSG_COPY_DONE="✓ %s 个模板 + %s 个组件已复制"
  MSG_CMD="安装斜杠命令..."
  MSG_CMD_DONE="✓ %s 个斜杠命令已安装"
  MSG_HOOK="安装 Hook 脚本..."
  MSG_HOOK_DONE="✓ Hook 脚本已安装"
  MSG_CLAUDE="配置 CLAUDE.md..."
  MSG_CLAUDE_APPEND="✓ CLAUDE.md 已更新（追加 SDD 规则）"
  MSG_CLAUDE_CREATE="✓ CLAUDE.md 已创建"
  MSG_CLEANUP="✓ 临时文件已清理"
  MSG_DONE="✓ 安装完成！"
  MSG_INSTALLED="已安装:"
  MSG_TEMPLATES="个文档模板"
  MSG_COMPONENTS="个 HTML 组件"
  MSG_COMMANDS="个斜杠命令"
  MSG_HOOKS="个 Hook 脚本"
  MSG_CONST="个项目宪章"
  MSG_RULES="个项目规则"
  MSG_WORKFLOW="主线工作流:"
  MSG_AUX="辅助命令:"
  MSG_START="开始使用: 在 Claude Code 中输入"
  W1="架构选型 + 高层需求"
  W2="需求详述"
  W3="一站式设计（流程/数据/接口/UI）"
  W4="实施计划 + 任务拆解"
  W5="开发 + 测试"
  W6="代码审查 + 部署方案"
else
  MSG_TARGET="Target project"
  MSG_NO_GIT="⚠ Target directory has no git repo. Initialize?"
  MSG_INIT_GIT="  Init git? [Y/n] "
  MSG_GIT_DONE="✓ Git repo initialized"
  MSG_EXISTS="⚠ Existing .specify/ directory detected"
  MSG_OVERWRITE="  Overwrite? [y/N] "
  MSG_CANCEL="Install cancelled"
  MSG_DIR="Creating directory structure..."
  MSG_DIR_DONE="✓ Directory structure created"
  MSG_COPY="Copying templates and components..."
  MSG_COPY_DONE="✓ %s templates + %s components copied"
  MSG_CMD="Installing slash commands..."
  MSG_CMD_DONE="✓ %s slash commands installed"
  MSG_HOOK="Installing hook scripts..."
  MSG_HOOK_DONE="✓ Hook scripts installed"
  MSG_CLAUDE="Configuring CLAUDE.md..."
  MSG_CLAUDE_APPEND="✓ CLAUDE.md updated (SDD rules appended)"
  MSG_CLAUDE_CREATE="✓ CLAUDE.md created"
  MSG_CLEANUP="✓ Temp files cleaned up"
  MSG_DONE="✓ Install complete!"
  MSG_INSTALLED="Installed:"
  MSG_TEMPLATES="document templates"
  MSG_COMPONENTS="HTML components"
  MSG_COMMANDS="slash commands"
  MSG_HOOKS="hook scripts"
  MSG_CONST="project constitution"
  MSG_RULES="project rules"
  MSG_WORKFLOW="Main workflow:"
  MSG_AUX="Auxiliary commands:"
  MSG_START="Get started: type"
  W1="Architecture + High-level Requirements"
  W2="Requirement Details"
  W3="All-in-One Design (Flow/Data/API/UI)"
  W4="Implementation Plan + Task Breakdown"
  W5="Development + Testing"
  W6="Code Review + Deployment"
fi

# ---- Determine target directory ----

if [ -n "${TARGET_ARG}" ]; then
  TARGET_DIR="$(cd "${TARGET_ARG}" && pwd)"
else
  TARGET_DIR="$(pwd)"
fi

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Spec-Driven Development Framework Installer     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${MSG_TARGET}: ${GREEN}${TARGET_DIR}${NC}"
echo -e "Language: ${GREEN}${LANG_OPT}${NC}"
echo ""

# ---- Checks ----

if [ ! -d "${TARGET_DIR}/.git" ]; then
  echo -e "${YELLOW}${MSG_NO_GIT}${NC}"
  if [ "${AUTO_YES}" -eq 1 ]; then
    REPLY="y"
    echo "  y (auto)"
  else
    read -p "${MSG_INIT_GIT}" -n 1 -r
    echo ""
  fi
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    (cd "${TARGET_DIR}" && git init)
    echo -e "${GREEN}${MSG_GIT_DONE}${NC}"
  fi
fi

if [ -d "${TARGET_DIR}/.specify" ]; then
  echo -e "${YELLOW}${MSG_EXISTS}${NC}"
  if [ "${AUTO_YES}" -eq 1 ]; then
    REPLY="y"
    echo "  y (auto)"
  else
    read -p "${MSG_OVERWRITE}" -n 1 -r
    echo ""
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}${MSG_CANCEL}${NC}"
    if [ "${CLEANUP_TEMP}" -eq 1 ]; then
      rm -rf "${TEMP_DIR}"
    fi
    exit 0
  fi
  rm -rf "${TARGET_DIR}/.specify"
fi

# ---- Create directories ----

echo -e "${BLUE}[1/5] ${MSG_DIR}${NC}"

mkdir -p "${TARGET_DIR}/.specify/templates/components"
mkdir -p "${TARGET_DIR}/.specify/specs"
mkdir -p "${TARGET_DIR}/.claude/commands"
mkdir -p "${TARGET_DIR}/.claude/hooks"

echo -e "${GREEN}${MSG_DIR_DONE}${NC}"

# ---- Copy templates and components ----

echo -e "${BLUE}[2/5] ${MSG_COPY}${NC}"

LANG_SOURCE="${SOURCE_DIR}/.specify/${LANG_OPT}"

# Constitution
cp "${LANG_SOURCE}/constitution.md" "${TARGET_DIR}/.specify/constitution.md"

# Document templates
for f in "${LANG_SOURCE}/templates/"*-template.html "${LANG_SOURCE}/templates/dashboard.html"; do
  if [ -f "$f" ]; then
    cp "$f" "${TARGET_DIR}/.specify/templates/"
  fi
done

# HTML components
for f in "${LANG_SOURCE}/templates/components/"*.html; do
  if [ -f "$f" ]; then
    cp "$f" "${TARGET_DIR}/.specify/templates/components/"
  fi
done

TEMPLATE_COUNT=$(ls "${TARGET_DIR}/.specify/templates/"*-template.html 2>/dev/null | wc -l | tr -d ' ')
COMPONENT_COUNT=$(ls "${TARGET_DIR}/.specify/templates/components/"*.html 2>/dev/null | wc -l | tr -d ' ')

printf "  ${GREEN}${MSG_COPY_DONE}${NC}\n" "${TEMPLATE_COUNT}" "${COMPONENT_COUNT}"

# ---- Copy slash commands ----

echo -e "${BLUE}[3/5] ${MSG_CMD}${NC}"

# Remove old commands (upgrade compat)
rm -f "${TARGET_DIR}/.claude/commands/spec-clarify.md" 2>/dev/null
rm -f "${TARGET_DIR}/.claude/commands/spec-tasks.md" 2>/dev/null

# Copy new commands
for f in "${LANG_SOURCE}/commands/"*.md; do
  if [ -f "$f" ]; then
    cp "$f" "${TARGET_DIR}/.claude/commands/"
  fi
done

COMMAND_COUNT=$(ls "${TARGET_DIR}/.claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
printf "  ${GREEN}${MSG_CMD_DONE}${NC}\n" "${COMMAND_COUNT}"

# ---- Copy hook scripts ----

echo -e "${BLUE}[4/5] ${MSG_HOOK}${NC}"

for f in "${SOURCE_DIR}/.claude/hooks/"*.sh; do
  if [ -f "$f" ]; then
    cp "$f" "${TARGET_DIR}/.claude/hooks/"
    chmod +x "${TARGET_DIR}/.claude/hooks/$(basename "$f")"
  fi
done

echo -e "${GREEN}${MSG_HOOK_DONE}${NC}"

# ---- Configure CLAUDE.md (append-only) ----

echo -e "${BLUE}[5/5] ${MSG_CLAUDE}${NC}"

CLAUDE_MD="${TARGET_DIR}/CLAUDE.md"
RULES_FILE="${LANG_SOURCE}/claude-rules.md"

if [ -f "${CLAUDE_MD}" ]; then
  # Remove old SDD section if present
  if grep -q "<!-- SDD START -->" "${CLAUDE_MD}"; then
    sed -i.bak '/<!-- SDD START -->/,/<!-- SDD END -->/d' "${CLAUDE_MD}"
    rm -f "${CLAUDE_MD}.bak"
  fi

  # Append SDD rules to existing file
  {
    echo ""
    echo "<!-- SDD START -->"
    cat "${RULES_FILE}"
    echo "<!-- SDD END -->"
  } >> "${CLAUDE_MD}"

  echo -e "${GREEN}${MSG_CLAUDE_APPEND}${NC}"
else
  # No existing CLAUDE.md — create new one with SDD rules only
  {
    echo "<!-- SDD START -->"
    cat "${RULES_FILE}"
    echo "<!-- SDD END -->"
  } > "${CLAUDE_MD}"

  echo -e "${GREEN}${MSG_CLAUDE_CREATE}${NC}"
fi

# ---- Configure .gitignore ----

GITIGNORE="${TARGET_DIR}/.gitignore"
if [ -f "${GITIGNORE}" ]; then
  if ! grep -q ".DS_Store" "${GITIGNORE}"; then
    echo ".DS_Store" >> "${GITIGNORE}"
  fi
else
  echo ".DS_Store" > "${GITIGNORE}"
fi

# ---- Cleanup ----

if [ "${CLEANUP_TEMP}" -eq 1 ]; then
  rm -rf "${TEMP_DIR}"
  echo -e "${GREEN}${MSG_CLEANUP}${NC}"
fi

# ---- Done ----

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ${MSG_DONE}                            ${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${MSG_INSTALLED}"
echo -e "  ${BLUE}→${NC} ${TEMPLATE_COUNT} ${MSG_TEMPLATES}   (.specify/templates/)"
echo -e "  ${BLUE}→${NC} ${COMPONENT_COUNT} ${MSG_COMPONENTS}   (.specify/templates/components/)"
echo -e "  ${BLUE}→${NC} ${COMMAND_COUNT} ${MSG_COMMANDS}     (.claude/commands/)"
echo -e "  ${BLUE}→${NC} 2 ${MSG_HOOKS}       (.claude/hooks/)"
echo -e "  ${BLUE}→${NC} 1 ${MSG_CONST}         (.specify/constitution.md)"
echo -e "  ${BLUE}→${NC} 1 ${MSG_RULES}         (CLAUDE.md)"
echo ""
echo -e "${MSG_WORKFLOW}"
echo -e "  ${YELLOW}/spec-init${NC}     → ${W1}"
echo -e "  ${YELLOW}/spec-detail${NC}   → ${W2}"
echo -e "  ${YELLOW}/spec-design${NC}   → ${W3}"
echo -e "  ${YELLOW}/spec-plan${NC}     → ${W4}"
echo -e "  ${YELLOW}/spec-implement${NC} → ${W5}"
echo -e "  ${YELLOW}/spec-review${NC}   → ${W6}"
echo ""
echo -e "${MSG_AUX}"
echo -e "  ${YELLOW}/spec-explore${NC}  /spec-research /spec-report /spec-present"
echo ""
echo -e "${MSG_START} ${YELLOW}/spec-init \"feature description\"${NC}"
echo ""
