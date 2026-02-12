# 🎮 GodotBT 行为树系统

## 安装

1. 复制 `addons/godot_bt` 到你的项目 `addons` 文件夹
2. 在 Godot 中启用插件: `项目设置` → `插件` → 启用 `GodotBT`

## 自定义节点

### 任务 (Tasks)
- `BTPatrol` - 巡逻任务
- `BTChase` - 追逐玩家
- `BTAttack` - 攻击玩家
- `BTWaitIdle` - 空闲等待

### 条件 (Conditions)
- `BTPlayerInRange` - 检测玩家是否在范围内

## 使用方法

### 1. 为敌人添加行为树

```gdscript
extends CharacterBody2D

@export var behavior_tree: BehaviorTree
var blackboard: Blackboard
var ctx: BTContext

func _ready():
    blackboard = Blackboard.new()
    player = get_tree().get_first_node_in_group("player")
    
    if behavior_tree:
        ctx = behavior_tree.create_context(self, blackboard)
    
    blackboard.set_value("player", player)
    blackboard.set_value("detect_range", 400.0)

func _physics_process(delta):
    if is_instance_valid(behavior_tree) and ctx:
        behavior_tree.tick(ctx, delta)
```

### 2. 敌人AI逻辑

```
BTSelector (SlimeAI)
├── BTSequence (ChaseSequence)
│   ├── BTPlayerInRange (PlayerDetected) [检测玩家]
│   ├── BTChase (Chase) [追逐玩家]
│   └── BTAttack (Attack) [攻击玩家]
└── BTWaitIdle (Idle) [空闲等待]
```

## 节点属性

### BTPlayerInRange
- `detect_range`: 检测范围（默认400像素）

### BTChase
- `speed`: 追逐速度（默认120）
- `stop_distance`: 停止距离（默认50）

### BTAttack
- `damage`: 伤害值（默认1）
- `attack_cooldown`: 攻击冷却（默认1秒）

### BTWaitIdle
- `min_time`: 最短等待时间（默认1秒）
- `max_time`: 最长等待时间（默认3秒）
