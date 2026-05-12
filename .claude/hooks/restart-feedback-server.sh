#!/bin/bash
# restart-feedback-server.sh — Stop then start the feedback server

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$SCRIPT_DIR/stop-feedback-server.sh"
sleep 1
bash "$SCRIPT_DIR/start-feedback-server.sh"
