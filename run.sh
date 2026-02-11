#!/bin/bash
# 运行 Chui的冒险 游戏
# Godot 可执行文件路径
GODOT="/Volumes/SSD/app/Godot.app/Contents/MacOS/Godot"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"$GODOT" --path "$SCRIPT_DIR" .
