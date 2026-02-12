#!/bin/bash

# ============ 自动测试推送脚本 ============
# 放在游戏项目根目录运行
# 用法: ./auto_commit_and_test.sh

GAME_PATH="/Users/guojiong/Desktop/0.1编程项目/【合集】游戏/chui_adventure"
GODOT="/Volumes/SSD/app/Godot.app/Contents/MacOS/Godot"
LOG_FILE="$GAME_PATH/auto_test.log"

echo "========================================" | tee -a $LOG_FILE
echo "  自动测试推送脚本" | tee -a $LOG_FILE
echo "  $(date)" | tee -a $LOG_FILE
echo "========================================" | tee -a $LOG_FILE

# 1. 检查Git状态
echo "" | tee -a $LOG_FILE
echo "检查代码变化..." | tee -a $LOG_FILE
cd "$GAME_PATH"

# 检查是否有变化
if git status --porcelain | grep -q .; then
    echo "发现代码变化，准备提交..." | tee -a $LOG_FILE
    
    # 获取修改信息
    CHANGES=$(git status --porcelain | head -10)
    echo "修改的文件:" | tee -a $LOG_FILE
    echo "$CHANGES" | tee -a $LOG_FILE
    
    # 询问提交信息
    echo "" | tee -a $LOG_FILE
    read -p "输入提交信息: " COMMIT_MSG
    if [ -z "$COMMIT_MSG" ]; then
        COMMIT_MSG="Auto update: $(date '+%Y-%m-%d %H:%M')"
    fi
    
    # 2. 提交
    echo "" | tee -a $LOG_FILE
    echo "提交代码..." | tee -a $LOG_FILE
    git add -A
    git commit -m "$COMMIT_MSG" >> $LOG_FILE 2>&1
    
    # 3. 推送到GitHub
    echo "推送到GitHub..." | tee -a $LOG_FILE
    if git push origin main >> $LOG_FILE 2>&1; then
        echo "✓ 推送成功!" | tee -a $LOG_FILE
    else
        echo "✗ 推送失败: 检查网络或权限" | tee -a $LOG_FILE
        echo "错误信息:" | tee -a $LOG_FILE
        git push origin main 2>&1 | tee -a $LOG_FILE
        exit 1
    fi
else
    echo "没有检测到代码变化" | tee -a $LOG_FILE
fi

# 4. 启动Godot测试
echo "" | tee -a $LOG_FILE
echo "启动Godot测试..." | tee -a $LOG_FILE

# 关闭之前的Godot实例
pkill -f "Godot.*chui_adventure" 2>/dev/null
sleep 1

# 启动Godot（无头模式检查语法）
echo "检查语法..." | tee -a $LOG_FILE
"$GODOT" --path "$GAME_PATH" --quiet --headless 2>&1 | head -30 | tee -a $LOG_FILE

# 检查结果
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "" | tee -a $LOG_FILE
    echo "✓ Godot启动成功!" | tee -a $LOG_FILE
else
    echo "" | tee -a $LOG_FILE
    echo "✗ Godot启动失败! 查看上面的错误信息" | tee -a $LOG_FILE
    echo "完整日志: $LOG_FILE" | tee -a $LOG_FILE
fi

echo "" | tee -a $LOG_FILE
echo "完成! $(date)" | tee -a $LOG_FILE
