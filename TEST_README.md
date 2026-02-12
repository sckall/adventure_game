# ============ 游戏测试说明 ============

## 测试步骤

### 1. 在Godot中打开项目
```
路径: /Users/guojiong/Desktop/0.1编程项目/【合集】游戏/chui_adventure
```

### 2. 检查主场景
确保 `scenes/main.tscn` 是主场景

### 3. 运行测试
按 F5 或点击 ▶️ 运行

### 4. 查看输出
- 按 `Ctrl+Shift+V` 打开输出面板
- 应该看到:
```
=== 游戏启动测试 ===
随机武器: xxx
随机护甲: xxx
随机药水: xxx
=== 测试完成 ===
```

## 如果有错误

### 常见错误和修复

1. **"Invalid token" / 语法错误"**
   → 检查缩进（用空格，不用Tab）
   → GDScript对缩进敏感

2. **"Function not found"**
   → 函数名拼写错误
   → 检查括号和参数

3. **"Node not found"**
   → 场景中没有对应节点
   → 检查节点名称

## 简化方案

如果代码还是报错，用最简单的方式测试：

```gdscript
# test.gd - 最小测试
extends Node2D

func _ready():
    print("Hello!")
```

## 下一步

确认基本功能能运行后，再逐步添加复杂功能。
