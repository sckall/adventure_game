extends CharacterBody2D

# ============ 健壮版玩家系统 ============
# 核心原则：
# 1. 避免空引用
# 2. 安全的属性访问
# 3. 清晰的状态管理
# 4. 默认值保护

signal died
signal health_changed(current: int, max: int)

# 玩家状态
enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	FALL,
	DASH,
	ATTACK,
	HURT,
	DEAD
}

# ============ 基础属性 ============
var state: int = PlayerState.IDLE

# 生命值（默认值保护）
var hp: int = 3
var max_hp: int = 3

# 移动属性
var move_speed: float = 200.0
var jump_force: float = -500.0
var gravity: float = 980.0
var velocity_y: float = 0.0

# 状态标记
var is_on_ground: bool = false
var is_invincible: bool = false
var is_alive: bool = true

# 计时器
var invincible_timer: float = 0.0
var attack_timer: float = 0.0

# 方向
var facing_right: bool = true

# ============ 初始化 ============
func _ready():
	# 确保有碰撞体
	if not has_node("CollisionShape2D"):
		var shape = CollisionShape2D.new()
		shape.shape = CapsuleShape2D.new()
		shape.position = Vector2(0, -16)
		add_child(shape)
	
	print("Player: 初始化完成 HP:%d" % hp)

func _physics_process(delta: _ready():
	if not is_alive:
		return
	
	_process_timers(delta)
	_process_movement(delta)
	_process_actions(delta)
	
	# 限制速度
	velocity.x = clampf(velocity.x, -move_speed, move_speed)

# ============ 计时器处理 ============
func _process_timers(delta: float):
	# 无敌时间
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false
	
	# 攻击冷却
	if attack_timer > 0:
		attack_timer -= delta

# ============ 移动处理 ============
func _process_movement(delta: float):
	# 获取输入
	var input_dir = _get_input_direction()
	
	# 应用速度
	velocity.x = input_dir * move_speed
	
	# 重力
	velocity_y += gravity * delta
	
	# 落地检测（简化版）
	if position.y > 1000:
		# 掉出地图
		die()
		return
	
	# 移动
	move_and_slide()
	
	# 简单落地检测
	if position.y >= 500 and velocity_y > 0:
		velocity_y = 0
		position.y = 500
		is_on_ground = true
	else:
		is_on_ground = false
	
	# 更新状态
	_update_state()

# ============ 输入处理 ============
func _get_input_direction() -> float:
	var left = Input.is_action_pressed("move_left")
	var right = Input.is_action_pressed("move_right")
	
	if left and not right:
		return -1.0
	elif right and not left:
		return 1.0
	return 0.0

func _process_actions(delta: float):
	# 跳跃
	if Input.is_action_just_pressed("jump") and is_on_ground:
		jump()
	
	# 攻击
	if Input.is_action_just_pressed("attack"):
		attack()
	
	# 技能1
	if Input.is_action_just_pressed("skill_1"):
		use_skill_1()

# ============ 动作 ============
func jump():
	if is_on_ground:
		velocity_y = jump_force
		is_on_ground = false
		print("Player: 跳跃")

func attack():
	if attack_timer > 0:
		return
	
	attack_timer = 0.5
	_change_state(PlayerState.ATTACK)
	print("Player: 攻击")
	
	# 创建攻击判定（简化版）
	_create_attack_area()

func use_skill_1():
	print("Player: 使用技能1")

# ============ 受伤处理 ============
func take_damage(amount: int = 1) -> bool:
	if is_invincible or not is_alive:
		return false
	
	hp -= amount
	
	# 发送信号
	health_changed.emit(hp, max_hp)
	
	if hp <= 0:
		die()
	else:
		_start_invincible(1.0)  # 1秒无敌
		_change_state(PlayerState.HURT)
		print("Player: 受伤 HP剩余:%d" % hp)
	
	return true

func die():
	if not is_alive:
		return
	
	is_alive = false
	_change_state(PlayerState.DEAD)
	died.emit()
	print("Player: 死亡")

func heal(amount: int = 1):
	hp = min(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)
	print("Player: 回血 HP:%d/%d" % [hp, max_hp])

# ============ 无敌时间 ============
func _start_invincible(duration: float):
	is_invincible = true
	invincible_timer = duration
	print("Player: 无敌开始 (%.1f秒)" % duration)

# ============ 状态管理 ============
func _change_state(new_state: int):
	if state == PlayerState.DEAD:
		return
	
	state = new_state
	# 状态变化可以添加动画等

func _update_state():
	if not is_alive:
		state = PlayerState.DEAD
		return
	
	if state == PlayerState.HURT:
		return
	
	if state == PlayerState.ATTACK:
		if attack_timer <= 0:
			_change_state(PlayerState.IDLE)
		return
	
	if is_on_ground:
		if absf(velocity.x) > 10:
			_change_state(PlayerState.WALK)
		else:
			_change_state(PlayerState.IDLE)
	else:
		if velocity_y < 0:
			_change_state(PlayerState.JUMP)
		else:
			_change_state(PlayerState.FALL)

# ============ 攻击判定 ============
func _create_attack_area():
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(60, 40)
	area.add_child(shape)
	
	# 攻击方向
	var offset = Vector2(40, 0)
	if not facing_right:
		offset.x = -40
	shape.position = offset
	
	add_child(area)
	
	# 0.1秒后移除
	await get_tree().create_timer(0.1).timeout
	area.queue_free()

# ============ 实用方法 ============
func get_facing_direction() -> Vector2:
	return Vector2(1, 0) if facing_right else Vector2(-1, 0)

func is_facing_right() -> bool:
	return facing_right

func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(hp) / float(max_hp)

# 安全获取属性
func get_stat(stat_name: String, default = 0):
	match stat_name:
		"speed": return move_speed
		"jump": return jump_force
		"gravity": return gravity
		"hp": return hp
		"max_hp": return max_hp
		_: return default

# 设置属性（带验证）
func set_stat(stat_name: String, value):
	match stat_name:
		"speed":
			move_speed = maxf(value, 50.0)
		"jump":
			jump_force = value
		"gravity":
			gravity = maxf(value, 100.0)
		"hp":
			hp = maxi(value, 0)
		"max_hp":
			max_hp = maxi(value, 1)

# ============ 调试信息 ============
func debug_info() -> String:
	return "Player [%s] HP:%d/%d 状态:%s" % [
		"存活" if is_alive else "死亡",
		hp, max_hp,
		PlayerState.keys()[state]
	]

func _to_string() -> String:
	return "[Player:%s HP:%d/%d]" % [str(is_alive), hp, max_hp]
