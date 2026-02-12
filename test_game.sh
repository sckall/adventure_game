#!/bin/bash

# 自动测试脚本 - 每次修改后运行
echo "🚀 启动游戏测试..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
/Volumes/SSD/app/Godot.app/Contents/MacOS/Godot --path "$SCRIPT_DIR" &

echo "✅ 游戏已启动"
