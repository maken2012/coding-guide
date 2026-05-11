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
