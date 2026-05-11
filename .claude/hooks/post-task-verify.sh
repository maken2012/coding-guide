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
