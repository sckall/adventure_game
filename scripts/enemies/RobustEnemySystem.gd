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

# 敌人基类
class_name EnemyBase extends Node

var type: int = EnemyType.SLIME
var state: int = EnemyState.IDLE
var hp: int = 1
var max_hp: int = 1
var damage: int = 1
var speed: float = 50.0
var level: int = 1
var target: Node = null
var is_alive: bool = true

# 状态计时器
var state_timer: float = 0.0

func _ready():
	_init_enemy()

func _init_enemy():
	# 默认值保护
	if hp <= 0:
		hp = 1
	if max_hp <= 0:
		max_hp = hp
	
	# 根据类型设置属性
	_setup_by_type()

func _setup_by_type():
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

# 设置目标
func set_target(new_target: Node):
	target = new_target

# 受伤
func take_damage(amount: int) -> bool:
	if not is_alive:
		return false
	
	hp -= amount
	_change_state(EnemyState.HURT)
	
	if hp <= 0:
		die()
		return true
	
	return true

# 死亡
func die():
	is_alive = hp <= 0
	_change_state(EnemyState.DEAD)
	print("敌人死亡: %s" % name)

# 改变状态
func _change_state(new_state: int):
	state = new_state
	state_timer = 0.0

# 更新
func update(delta: float):
	if not is_alive:
		return
	
	state_timer += delta
	
	match state:
		EnemyState.IDLE:
			_update_idle(delta)
		EnemyState.CHASE:
			_update_chase(delta)
		EnemyState.ATTACK:
			_update_attack(delta)
		EnemyState.HURT:
			_update_hurt(delta)
		EnemyState.DEAD:
			_update_dead(delta)

func _update_idle(delta: float):
	# 寻找目标
	if is_instance_valid(target):
		var dist = _get_distance_to_target()
		if dist < 300:  # 发现范围
			_change_state(EnemyState.CHASE)
	elif state_timer > 2.0:  # 待机2秒后随机移动
		_change_state(EnemyState.CHASE)

func _update_chase(delta: float):
	if not is_instance_valid(target):
		_change_state(EnemyState.IDLE)
		return
	
	var dist = _get_distance_to_target()
	
	if dist > 500:
		# 目标太远，放弃
		_change_state(EnemyState.IDLE)
	elif dist < 50:
		# 足够近，攻击
		_change_state(EnemyState.ATTACK)
	else:
		# 移动向目标
		_move_toward_target(delta)

func _update_attack(delta: float):
	if not is_instance_valid(target):
		_change_state(EnemyState.IDLE)
		return
	
	var dist = _get_distance_to_target()
	if dist > 60:
		_change_state(EnemyState.CHASE)
	elif state_timer > 1.0:
		# 攻击间隔
		_attack_target()
		_change_state(EnemyState.CHASE)

func _update_hurt(delta: float):
	if state_timer > 0.2:
		_change_state(EnemyState.IDLE)

func _update_dead(delta: float):
	pass

func _move_toward_target(delta: float):
	if not is_instance_valid(target):
		return
	
	var dir = (target.global_position - global_position).normalized()
	global_position += dir * speed * delta

func _get_distance_to_target() -> float:
	if not is_instance_valid(target):
		return 9999.0
	return global_position.distance_to(target.global_position)

func _attack_target():
	if is_instance_valid(target):
		print("%s 攻击! 伤害: %d" % [name, damage])
		# 调用目标的受伤方法
		if target.has_method("take_damage"):
			target.take_damage(damage)

# 获取状态名称
func get_state_name() -> String:
	return EnemyState.keys()[state]

# 获取类型名称
func get_type_name() -> String:
	return EnemyType.keys()[type]

# 安全打印
func debug_info() -> String:
	return "%s [%s] HP:%d/%d Lv.%d" % [name, get_state_name(), hp, max_hp, level]

# ============ 敌人生成器 ============
class_name EnemySpawner extends Node

var spawn_points: Array = []

func _ready():
	print("EnemySpawner: 启动")

# 生成敌人
func spawn_enemy(enemy_type: int, spawn_pos: Vector2, _level: int = 1) -> EnemyBase:
	var enemy = EnemyBase.new()
	enemy.type = enemy_type
	enemy.level = _level
	enemy.position = spawn_pos
	add_child(enemy)
	
	print("生成敌人: %s 在 %s" % [enemy.get_type_name(), str(spawn_pos)])
	return enemy

# 批量生成
func spawn_enemies(enemy_type: int, count: int, area_rect: Rect2, _level: int = 1) -> Array:
	var enemies = []
	for i in range(count):
		var pos = Vector2(
			randf_range(area_rect.position.x, area_rect.position.x + area_rect.size.x),
			randf_range(area_rect.position.y, area_rect.position.y + area_rect.size.y)
		)
		enemies.append(spawn_enemy(enemy_type, pos, _level))
	return enemies

# 生成随机类型敌人
func spawn_random_enemy(spawn_pos: Vector2, _level: int = 1) -> EnemyBase:
	var types = [
		EnemyType.SLIME, EnemyType.BAT, 
		EnemyType.HEDGEHOG, EnemyType.SNAIL
	]
	var t = types.pick_random()
	return spawn_enemy(t, spawn_pos, _level)

# ============ 敌人管理器 ============
class_name EnemyManager extends Node

var enemies: Array = []
var spawner: EnemySpawner

func _ready():
	spawner = EnemySpawner.new()
	add_child(spawner)
	print("EnemyManager: 启动")

# 添加敌人
func add_enemy(enemy: EnemyBase):
	if enemy:
		enemies.append(enemy)
		print("敌人列表: %d 个" % enemies.size())

# 移除敌人
func remove_enemy(enemy: EnemyBase):
	enemies.erase(enemy)
	print("敌人列表: %d 个" % enemies.size())

# 更新所有敌人
func update_all(delta: float):
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			enemy.update(delta)

# 检查是否全部死亡
func all_dead() -> bool:
	for enemy in enemies:
		if enemy.is_alive:
			return false
	return true

# 获取存活敌人数量
func get_alive_count() -> int:
	var count = 0
	for enemy in enemies:
		if enemy.is_alive:
			count += 1
	return count

# 安全获取敌人
func get_enemy(index: int) -> EnemyBase:
	if index >= 0 and index < enemies.size():
		return enemies[index]
	return null

# 清空所有敌人
func clear_all():
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	print("敌人已清空")
