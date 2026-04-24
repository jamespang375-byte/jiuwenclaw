#!/usr/bin/env bash
# JiuwenClaw 一键启动脚本（前后台）
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$PROJECT_ROOT/.pids"
mkdir -p "$PID_DIR"

# 查找合适的 Python 解释器（优先 3.11，项目要求 >=3.11,<3.14）
# 同时验证必要依赖（dotenv, jiuwenclaw）是否已安装
PYTHON_CMD=""
for py in python3.11 python3.12 python3.13 python3; do
    if command -v "$py" &>/dev/null; then
        ver="$($py -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)"
        if [[ "$ver" == "3.11" || "$ver" == "3.12" || "$ver" == "3.13" ]]; then
            if $py -c "from dotenv import load_dotenv; import jiuwenclaw" 2>/dev/null; then
                PYTHON_CMD="$py"
                break
            fi
        fi
    fi
done

# 如果都没找到已安装依赖的 Python，退而求其次找一个兼容版本并尝试安装
if [[ -z "$PYTHON_CMD" ]]; then
    for py in python3.11 python3.12 python3.13 python3; do
        if command -v "$py" &>/dev/null; then
            ver="$($py -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)"
            if [[ "$ver" == "3.11" || "$ver" == "3.12" || "$ver" == "3.13" ]]; then
                PYTHON_CMD="$py"
                break
            fi
        fi
    done
fi

if [[ -z "$PYTHON_CMD" ]]; then
    echo "[ERROR] 未找到兼容的 Python 版本（需要 3.11-3.13），请安装后重试。"
    exit 1
fi

echo "[INFO] 使用 Python: $PYTHON_CMD (version $($PYTHON_CMD --version))"

# 检查并安装 Python 依赖（如未安装）
if ! $PYTHON_CMD -c "from dotenv import load_dotenv; import jiuwenclaw" 2>/dev/null; then
    echo "[INFO] 正在安装 Python 依赖..."
    cd "$PROJECT_ROOT"
    $PYTHON_CMD -m pip install -e ".[desktop]"
fi

# 检查前端构建产物
DIST_DIR="$PROJECT_ROOT/jiuwenclaw/web/dist"
if [[ ! -d "$DIST_DIR" ]]; then
    echo "[INFO] 前端构建产物不存在，正在构建..."
    cd "$PROJECT_ROOT/jiuwenclaw/web"
    if [[ ! -d node_modules ]]; then
        npm install --cache /tmp/npm-cache
    fi
    npm run build
fi

# 如果已有运行中的实例，先停止
if [[ -f "$PID_DIR/app.pid" ]] || [[ -f "$PID_DIR/web.pid" ]]; then
    echo "[INFO] 检测到已有运行实例，先执行停止..."
    "$PROJECT_ROOT/stop.sh" || true
    sleep 1
fi

LOG_DIR="$HOME/.jiuwenclaw/logs"
mkdir -p "$LOG_DIR"

# 启动后台服务（AgentServer + Gateway）
echo "[INFO] 启动后台服务（AgentServer + Gateway）..."
cd "$PROJECT_ROOT"
nohup "$PYTHON_CMD" -m jiuwenclaw.app > "$LOG_DIR/app.log" 2>&1 &
echo $! > "$PID_DIR/app.pid"
sleep 2

# 检查后台服务是否启动成功
if ! kill -0 "$(cat "$PID_DIR/app.pid")" 2>/dev/null; then
    echo "[ERROR] 后台服务启动失败，请查看日志: $LOG_DIR/app.log"
    rm -f "$PID_DIR/app.pid"
    exit 1
fi

# 启动前台 Web 服务（使用小众端口避免冲突）
WEB_PORT=27384
echo "[INFO] 启动前台 Web 服务（端口 $WEB_PORT）..."
nohup "$PYTHON_CMD" -m jiuwenclaw.app_web --dist "$DIST_DIR" --host 0.0.0.0 --port "$WEB_PORT" > "$LOG_DIR/web.log" 2>&1 &
echo $! > "$PID_DIR/web.pid"
sleep 1

# 检查前台服务是否启动成功
if ! kill -0 "$(cat "$PID_DIR/web.pid")" 2>/dev/null; then
    echo "[ERROR] 前台 Web 服务启动失败，请查看日志: $LOG_DIR/web.log"
    rm -f "$PID_DIR/web.pid"
    "$PROJECT_ROOT/stop.sh" || true
    exit 1
fi

echo ""
echo "========================================"
echo "  JiuwenClaw 启动成功！"
echo "========================================"
echo "  Web 界面: http://localhost:$WEB_PORT"
echo "  后台日志: $LOG_DIR/app.log"
echo "  前台日志: $LOG_DIR/web.log"
echo "========================================"
echo ""
echo "[TIP] 使用 ./stop.sh 停止服务，./restart.sh 重启服务。"
