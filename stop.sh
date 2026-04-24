#!/usr/bin/env bash
# JiuwenClaw 停止脚本
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$PROJECT_ROOT/.pids"

stop_by_pidfile() {
    local name="$1"
    local pid_file="$PID_DIR/${name}.pid"
    if [[ -f "$pid_file" ]]; then
        local pid
        pid="$(cat "$pid_file")"
        if kill -0 "$pid" 2>/dev/null; then
            echo "[INFO] 停止 $name (pid=$pid)..."
            kill "$pid" 2>/dev/null || true
            local count=0
            while kill -0 "$pid" 2>/dev/null && [[ $count -lt 10 ]]; do
                sleep 0.5
                count=$((count + 1))
            done
            if kill -0 "$pid" 2>/dev/null; then
                echo "[WARN] $name 未响应，强制终止..."
                kill -9 "$pid" 2>/dev/null || true
            fi
        fi
        rm -f "$pid_file"
    fi
}

# 1. 先通过 PID 文件停止主进程
stop_by_pidfile "web"
stop_by_pidfile "app"

# 2. 清理可能残留的 jiuwenclaw 子进程（agentserver / gateway / app_web）
# 只清理属于当前项目路径的进程，避免误杀其他目录的实例
echo "[INFO] 检查并清理残留进程..."
for pattern in "jiuwenclaw.app_agentserver" "jiuwenclaw.app_gateway" "jiuwenclaw.app_web"; do
    pids="$(pgrep -f "$pattern" 2>/dev/null || true)"
    for pid in $pids; do
        # 获取进程启动时的 cwd，确认是否属于本项目
        cwd="$(lsof -a -d cwd -p "$pid" 2>/dev/null | tail -n 1 | awk '{print $NF}')"
        if [[ "$cwd" == "$PROJECT_ROOT" ]]; then
            echo "[INFO] 停止残留进程 $pattern (pid=$pid)..."
            kill "$pid" 2>/dev/null || true
            sleep 0.5
            kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
        fi
    done
done

echo "[INFO] JiuwenClaw 已停止。"
