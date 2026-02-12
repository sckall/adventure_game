# 代码健壮性指南

## 核心原则

### 1. 避免空引用
```gdscript
# 错误做法
var item = items[0]  # 可能越界
item.do_something()  # item可能是null

# 正确做法
if items.size() > 0:
    var item = items[0]
    if item:
        item.do_something()
```

### 2. 默认值保护
```gdscript
# 错误做法
var hp = player.hp  # player可能是null

# 正确做法
var hp = 0
if player and player.has_method("get_hp"):
    hp = player.get_hp()
```

### 3. 安全的属性访问
```gdscript
# 使用get_stat代替直接访问
func get_stat(stat_name: String, default = 0):
    if has_method("get"):
        return get(stat_name, default)
    return default
```

### 4. 清晰的错误提示
```gdscript
# 错误做法
print("error")

# 正确做法
print("警告: 找不到道具 %s" % item_id)
```

## 检查清单

写代码前检查：

- [ ] 所有变量有初始化值吗？
- [ ] 所有数组访问有边界检查吗？
- [ ] 所有节点引用有null检查吗？
- [ ] 所有方法调用有存在检查吗？
- [ ] 错误信息清晰吗？

## 测试方法

### 最小化测试
```gdscript
func test_minimal():
    print("Test: 开始")
    # 只测最核心功能
    print("Test: 结束")
```

### 完整测试
```gdscript
func test_full():
    # 测试所有分支
    test_normal_case()
    test_edge_case()
    test_error_case()
```

## 常见错误

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| 空引用 | 节点不存在 | 使用`is_instance_valid()` |
| 数组越界 | 索引超出范围 | 检查`size()` |
| 语法错误 | 缩进/括号 | 用Godot编辑器检查 |
| 类型错误 | 错误的类型 | 添加类型注解 |

## GDScript健壮技巧

```gdscript
# 1. 使用类型注解
var hp: int = 10
var speed: float = 200.0
var target: Node = null

# 2. 安全的方法调用
if target and target.has_method("take_damage"):
    target.take_damage(10)

# 3. 默认值
var damage: int = 1
damage = enemy.get("damage", 1)  # 如果不存在则用1

# 4. 安全的属性获取
var value = get("property", default_value)

# 5. 检查节点是否有效
if is_instance_valid(my_node):
    my_node.do_something()
```

## 文件结构

```
scripts/
├── items/
│   └── RobustItemSystem.gd    # 健壮版道具
├── enemies/
│   └── RobustEnemySystem.gd  # 健壮版敌人
├── player/
│   └── RobustPlayer.gd       # 健壮版玩家
└── RobustTest.gd           # 测试脚本
```
