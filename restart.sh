#!/usr/bin/env bash
# JiuwenClaw 重启脚本
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] 正在重启 JiuwenClaw..."
"$PROJECT_ROOT/stop.sh" || true
sleep 1
"$PROJECT_ROOT/start.sh"
