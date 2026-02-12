extends Node

# ============ 健壮版敌人系统 ============
# 核心原则：
# 1. 避免空引用
# 2. 简单的状态机
# 3. 默认值保护
# 4. 清晰的调试信息

# 敌人类型枚举
enum EnemyType {
	SLIME,      # 史莱姆
	BAT,        # 蝙蝠
	HEDGEHOG,   # 刺猬
	SNAIL,      # 蜗牛
	SNAKE,      # 蛇
	SPIDER,     # 蜘蛛
	SKELETON,   # 骷髅
	BOSS        # Boss
}

# 敌人状态
enum EnemyState {
	IDLE,       # 待机
	CHASE,      # 追逐
	ATTACK,     # 攻击
	HURT,       # 受伤
	DEAD        # 死亡
}

# 敌人数数据（纯数据类）
class_name EnemyData:
	var type: int = EnemyType.SLIME
	var hp: int = 1
	var max_hp: int = 1
	var damage: int = 1
	var speed: float = 50.0
	var level: int = 1
	var name: String = "敌人"
	
	func _init(_type: int = EnemyType.SLIME, _level: int = 1):
		type = _type
		level = _level
		_setup()
	
	func _setup():
		match type:
			EnemyType.SLIME:
				name = "史莱姆"
				hp = 2 + level
				damage = 1
				speed = 40.0
			EnemyType.BAT:
				name = "蝙蝠"
				hp = 1 + level
				damage = 1
				speed = 80.0
			EnemyType.HEDGEHOG:
				name = "刺猬"
				hp = 4 + level
				damage = 2
				speed = 30.0
			EnemyType.SNAIL:
				name = "蜗牛"
				hp = 6 + level
				damage = 1
				speed = 20.0
			EnemyType.SNAKE:
				name = "蛇"
				hp = 2 + level
				damage = 2
				speed = 70.0
			EnemyType.SPIDER:
				name = "蜘蛛"
				hp = 3 + level
				damage = 2
				speed = 60.0
			EnemyType.SKELETON:
				name = "骷髅"
				hp = 5 + level * 2
				damage = 3
				speed = 45.0
			EnemyType.BOSS:
				name = "Boss"
				hp = 20 + level * 10
				damage = 5
				speed = 50.0

# 敌人生成器（挂载到节点上使用）
class_name EnemySpawner extends Node

func spawn_enemy(enemy_type: int, spawn_pos: Vector2, _level: int = 1) -> Node2D:
	var enemy = Node2D.new()
	enemy.name = "Enemy"
	enemy.position = spawn_pos
	
	# 添加数据
	var data = EnemyData.new(enemy_type, _level)
	enemy.set_meta("data", data)
	
	# 添加碰撞
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 16
	area.add_child(shape)
	enemy.add_child(area)
	
	# 添加身体
	var body = ColorRect.new()
	body.size = Vector2(32, 32)
	body.position = Vector2(-16, -16)
	
	match enemy_type:
		EnemyType.SLIME: body.color = Color(0.3, 0.8, 0.3)
		EnemyType.BAT: 
			body.size = Vector2(24, 16)
			body.color = Color(0.5, 0.3, 0.6)
		EnemyType.HEDGEHOG: body.color = Color(0.6, 0.5, 0.3)
		EnemyType.SKELETON: body.color = Color(0.9, 0.9, 0.9)
		_: body.color = Color(0.8, 0.3, 0.3)
	
	enemy.add_child(body)
	
	return enemy

func spawn_random_enemy(spawn_pos: Vector2, _level: int = 1) -> Node2D:
	var types = [EnemyType.SLIME, EnemyType.BAT, EnemyType.HEDGEHOG, EnemyType.SNAIL]
	return spawn_enemy(types.pick_random(), spawn_pos, _level)

# 敌人生成管理器
class_name EnemyManager extends Node

var enemy_list: Array = []

func add_enemy(enemy: Node2D):
	if enemy:
		enemy_list.append(enemy)

func remove_enemy(enemy: Node2D):
	enemy_list.erase(enemy)

func get_alive_count() -> int:
	var count = 0
	for e in enemy_list:
		if is_instance_valid(e):
			var data = e.get_meta("data") as EnemyData
			if data and data.hp > 0:
				count += 1
	return count

func all_dead() -> bool:
	return get_alive_count() == 0

func clear_all():
	for e in enemy_list:
		if is_instance_valid(e):
			e.queue_free()
	enemy_list.clear()

func update_all(delta: float):
	for e in enemy_list:
		if is_instance_valid(e):
			# 简单AI：向玩家移动
			var player = get_tree().get_first_node_in_group("player")
			if player:
				var dir = (player.global_position - e.global_position).normalized()
				e.global_position += dir * 50.0 * delta
