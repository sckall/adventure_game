#!/bin/bash

# GitHub推送脚本
cd "/Users/guojiong/Desktop/0.1编程项目/【合集】游戏/chui_adventure"

# 设置凭证存储
git config credential.helper store

# 推送到GitHub
echo "正在推送到GitHub..."
git push -u origin main

echo "推送完成！"
