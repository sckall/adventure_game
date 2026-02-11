extends CharacterBody2D
class_name AIBoss

# ============ AI BOSS - 自适应战斗系统 ============
# 分析玩家移动模式、预测跳跃时机、调整攻击策略

# ============ Boss状态 ============
enum State {
	IDLE,           # 待机
	PATROL,         # 巡逻
	CHASE,          # 追逐
	ATTACK,         # 攻击
	ENRAGED,        # 狂暴模式（低血量）
	STUNNED         # 被击晕
}

var current_state = State.IDLE

# ============ Boss属性 ============
@export var boss_name: String = "暗影领主"
@export var max_hp: int = 20
@export var hp: int = 20
@export var phase_2_threshold: float = 0.5  # 血量低于50%进入第二阶段
@export var enraged_threshold: float = 0.25  # 血量低于25%进入狂暴模式

# ============ 移动属性 ============
var base_speed: float = 120.0
var chase_speed: float = 180.0
var enraged_speed: float = 280.0
var current_speed: float = 120.0

# ============ AI学习系统 ============
# 玩家行为分析数据
var player_behavior_data = {
	# 移动偏好 (0-1, 左右偏好)
	"left_move_count": 0,
	"right_move_count": 0,

	# 跳跃频率
	"jump_count": 0,
	"total_time": 0.0,

	# 攻击时机偏好
	"attack_when_close": 0,    # 近距离攻击次数
	"attack_when_far": 0,      # 远距离攻击次数

	# 躲避偏好
	"dodge_left_count": 0,
	"dodge_right_count": 0,

	# 最常停留位置区域
	"position_zones": {},      # 将地图分区，统计玩家常在区域

	# 跳跃时机统计
	"jump_after_damage": 0,    # 受伤后立即跳跃次数
	"jump_near_edge": 0,       # 靠近边缘时跳跃次数
}

# 预测系统
var predicted_player_pos: Vector2 = Vector2.ZERO
var prediction_confidence: float = 0.0  # 0-1，预测置信度

# ============ 攻击模式 ============
enum AttackPattern {
	MELEE_SWIPE,        # 近战横扫
	PROJECTILE,         # 发射弹幕
	CHARGE_ATTACK,      # 冲撞攻击
	DIRECTIONAL_BURST,  # 定向爆发
	TELEPORT_STRIKE,    # 传送打击
	SHOCKWAVE,          # 震地波
	ENRAGED_FLURRY      # 狂暴连击
}

var available_attacks = []
var current_attack_cooldown = 0.0
var attack_pattern_weights = {
	AttackPattern.MELEE_SWIPE: 1.0,
	AttackPattern.PROJECTILE: 1.0,
	AttackPattern.CHARGE_ATTACK: 0.8,
	AttackPattern.DIRECTIONAL_BURST: 0.6,
	AttackPattern.TELEPORT_STRIKE: 0.4,
	AttackPattern.SHOCKWAVE: 0.3,
	AttackPattern.ENRAGED_FLURRY: 0.0  # 仅狂暴模式
}

# ============ 战斗阶段 ============
enum CombatPhase {
	PHASE_1,  # 正常模式
	PHASE_2,  # 血量<50%
	PHASE_3   # 狂暴模式
}

var current_phase = CombatPhase.PHASE_1

# ============ 节点引用 ============
var player: Node2D
@onready var g = get_node("/root/Global")
@onready var body = $Body
@onready var audio = get_node("/root/AudioManager")
@onready var eye_left = $EyeLeft
@onready var eye_right = $EyeRight
@onready var eye_glow = $EyeGlow
@onready var hurt_area = $HurtArea
@onready var attack_area = $AttackArea
@onready var warning_indicator = $WarningIndicator

# ============ 视觉效果 ============
var original_color: Color
var phase_2_color: Color = Color(1.0, 0.4, 0.2)  # 橙红色
var enraged_color: Color = Color(1.0, 0.1, 0.1)   # 深红色

# ============ 内部变量 ============
var state_timer = 0.0
var attack_animation_timer = 0.0
var is_attacking = false
var stun_timer = 0.0
var patrol_start_x: float = 0.0
var patrol_direction: int = 1
var behavior_analysis_timer = 0.0

# ============ 信号 ============
signal boss_defeated()
signal phase_changed(phase: int)
signal attack_launched(attack_type: int)
signal boss_intro_requested()  # 请求显示Boss预告
signal stats_updated(stats: Dictionary)  # 统计数据更新
signal ai_learning_updated(preference: String, accuracy: float, attack: String)  # AI学习数据更新

# ============ 初始化 ============
func _ready():
	# 查找玩家
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("../Player")

	# 设置颜色
	original_color = Color(0.4, 0.2, 0.6)  # 深紫色
	update_boss_color()

	# 初始化攻击模式
	available_attacks = [
		AttackPattern.MELEE_SWIPE,
		AttackPattern.PROJECTILE,
		AttackPattern.CHARGE_ATTACK
	]

	# 设置巡逻起点
	patrol_start_x = position.x

	# 连接信号
	if hurt_area:
		hurt_area.body_entered.connect(_on_hurt_area_body_entered)
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	# 请求显示Boss预告
	boss_intro_requested.emit()

	print("AI Boss '", boss_name, "' 已生成！准备战斗...")

# ============ 主循环 ============
func _physics_process(delta):
	state_timer += delta
	behavior_analysis_timer += delta

	# 分析玩家行为（每0.5秒）
	if behavior_analysis_timer >= 0.5:
		analyze_player_behavior()
		behavior_analysis_timer = 0.0

	# 更新状态机
	match current_state:
		State.IDLE:
			process_idle(delta)
		State.PATROL:
			process_patrol(delta)
		State.CHASE:
			process_chase(delta)
		State.ATTACK:
			process_attack(delta)
		State.ENRAGED:
			process_enraged(delta)
		State.STUNNED:
			process_stunned(delta)

	# 更新冷却
	if current_attack_cooldown > 0:
		current_attack_cooldown -= delta

	# 更新视觉
	update_visuals(delta)

	# 应用移动
	move_and_slide()

# ============ 状态处理 ============

func process_idle(delta):
	# 检测玩家距离
	if player and is_instance_valid(player):
		var dist = position.distance_to(player.position)
		if dist < 400:  # 发现玩家
			current_state = State.CHASE
		elif dist < 600:
			current_state = State.PATROL
	else:
		# 没有玩家时巡逻
		if state_timer > 2.0:
			current_state = State.PATROL
			state_timer = 0

func process_patrol(delta):
	# 巡逻移动
	velocity.x = patrol_direction * base_speed * 0.5

	# 检测玩家
	if player and is_instance_valid(player):
		var dist = position.distance_to(player.position)
		if dist < 400:
			current_state = State.CHASE
			state_timer = 0
			return

	# 巡逻边界检测
	var patrol_range = 150
	if position.x > patrol_start_x + patrol_range:
		patrol_direction = -1
		scale.x = -abs(scale.x)
	elif position.x < patrol_start_x - patrol_range:
		patrol_direction = 1
		scale.x = abs(scale.x)

func process_chase(delta):
	if not player or not is_instance_valid(player):
		current_state = State.PATROL
		return

	# 计算到玩家的方向
	var dir_to_player = (player.position - position).normalized()
	var dist = position.distance_to(player.position)

	# 更新预测位置
	update_player_prediction()

	# 根据预测调整移动
	if prediction_confidence > 0.6:
		# 高置信度时，预测拦截
		var intercept_dir = (predicted_player_pos - position).normalized()
		velocity.x = intercept_dir.x * current_speed
	else:
		# 低置信度时，直接追踪
		velocity.x = dir_to_player.x * current_speed

	# 面向玩家
	if dir_to_player.x > 0:
		scale.x = abs(scale.x)
	else:
		scale.x = -abs(scale.x)

	# 攻击判断
	if dist < 150 and current_attack_cooldown <= 0:
		start_attack(select_best_attack())
	elif dist > 600:
		current_state = State.PATROL

func process_attack(delta):
	attack_animation_timer -= delta

	# 攻击动画期间减速
	velocity.x = 0

	if attack_animation_timer <= 0 and not is_attacking:
		current_state = State.CHASE
		state_timer = 0

func process_enraged(delta):
	if not player or not is_instance_valid(player):
		current_state = State.PATROL
		return

	# 狂暴模式：更快、更激进
	var dir_to_player = (player.position - position).normalized()
	var dist = position.distance_to(player.position)

	# 更快的移动
	velocity.x = dir_to_player.x * enraged_speed

	# 面向玩家
	if dir_to_player.x > 0:
		scale.x = abs(scale.x)
	else:
		scale.x = -abs(scale.x)

	# 频繁攻击
	if dist < 200 and current_attack_cooldown <= 0:
		# 狂暴模式优先使用连击
		start_attack(AttackPattern.ENRAGED_FLURRY)

func process_stunned(delta):
	stun_timer -= delta
	velocity = Vector2.ZERO

	if stun_timer <= 0:
		# 根据血量恢复状态
		var hp_percent = float(hp) / max_hp
		if hp_percent <= enraged_threshold:
			current_state = State.ENRAGED
		else:
			current_state = State.CHASE

# ============ AI学习系统 ============

func analyze_player_behavior():
	if not player or not is_instance_valid(player):
		return

	# 获取玩家速度
	var player_vel = player.velocity if player.has_method("get") else Vector2.ZERO
	if "velocity" in player:
		player_vel = player.velocity

	# 统计移动方向偏好
	if player_vel.x < -10:
		player_behavior_data["left_move_count"] += 1
	elif player_vel.x > 10:
		player_behavior_data["right_move_count"] += 1

	# 统计跳跃（通过检测y方向速度变化）
	if player_vel.y < -100:
		player_behavior_data["jump_count"] += 1

	# 统计位置区域
	var zone_x = int(player.position.x / 100) * 100
	var zone_key = str(zone_x)
	if zone_key in player_behavior_data["position_zones"]:
		player_behavior_data["position_zones"][zone_key] += 1
	else:
		player_behavior_data["position_zones"][zone_key] = 1

	player_behavior_data["total_time"] += 0.5

	# 根据收集的数据调整攻击权重
	adapt_attack_patterns()

func update_player_prediction():
	if not player or not is_instance_valid(player):
		prediction_confidence = 0
		return

	var player_vel = player.velocity if "velocity" in player else Vector2.ZERO
	var time_ahead = 0.5  # 预测0.5秒后的位置

	# 基础预测：基于当前速度
	predicted_player_pos = player.position + player_vel * time_ahead

	# 高级预测：基于玩家习惯
	var total_moves = player_behavior_data["left_move_count"] + player_behavior_data["right_move_count"]
	if total_moves > 10:  # 有足够数据时
		# 预测玩家会偏向某个方向
		var left_ratio = float(player_behavior_data["left_move_count"]) / total_moves
		var bias = 0
		if left_ratio > 0.6:
			bias = -50  # 偏向左
		elif left_ratio < 0.4:
			bias = 50   # 偏向右

		predicted_player_pos.x += bias
		prediction_confidence = 0.7
	else:
		prediction_confidence = 0.4

	# 如果玩家靠近边缘，预测会跳跃
	if is_near_edge(player.position):
		predicted_player_pos.y -= 150  # 预测跳跃
		prediction_confidence += 0.2

func is_near_edge(pos: Vector2) -> bool:
	# 简单的边缘检测（假设地图宽度约4000）
	return pos.x < 200 or pos.x > 3800

func adapt_attack_patterns():
	# 根据玩家习惯调整攻击权重

	var total_moves = player_behavior_data["left_move_count"] + player_behavior_data["right_move_count"]
	if total_moves > 20:
		var left_ratio = float(player_behavior_data["left_move_count"]) / total_moves

		# 如果玩家偏好某个方向，增加定向攻击权重
		if left_ratio > 0.7 or left_ratio < 0.3:
			attack_pattern_weights[AttackPattern.DIRECTIONAL_BURST] = 1.2
			# 发送AI学习更新信号
			var pref_text = "偏好向%s移动" % ("左" if left_ratio > 0.7 else "右")
			ai_learning_updated.emit(pref_text, prediction_confidence, "定向爆发")
		else:
			attack_pattern_weights[AttackPattern.DIRECTIONAL_BURST] = 0.6

	# 如果玩家频繁跳跃，增加震地波权重
	if player_behavior_data["jump_count"] > 10:
		var jump_rate = player_behavior_data["jump_count"] / max(player_behavior_data["total_time"], 1.0)
		if jump_rate > 2.0:  # 每秒跳跃超过2次
			attack_pattern_weights[AttackPattern.SHOCKWAVE] = 1.5
			ai_learning_updated.emit("频繁跳跃", prediction_confidence, "震地波")

# ============ 攻击系统 ============

func select_best_attack() -> AttackPattern:
	# 计算每个攻击的权重得分
	var best_attack = AttackPattern.MELEE_SWIPE
	var best_score = -1.0

	for attack in available_attacks:
		var base_weight = attack_pattern_weights.get(attack, 1.0)

		# 距离修正
		var dist = position.distance_to(player.position) if player else 999
		var distance_modifier = 1.0

		match attack:
			AttackPattern.MELEE_SWIPE:
				distance_modifier = 2.0 if dist < 120 else (1.0 if dist < 200 else 0.3)
			AttackPattern.PROJECTILE:
				distance_modifier = 1.5 if dist > 150 else (1.0 if dist > 100 else 0.5)
			AttackPattern.CHARGE_ATTACK:
				distance_modifier = 1.3 if dist > 200 else 0.8
			AttackPattern.SHOCKWAVE:
				# 如果玩家频繁跳跃，提高震地波权重
				var jump_rate = player_behavior_data["jump_count"] / max(player_behavior_data["total_time"], 1.0)
				distance_modifier = 2.0 if jump_rate > 1.5 else 1.0

		var score = base_weight * distance_modifier

		# 添加随机性
		score += randf() * 0.3

		if score > best_score:
			best_score = score
			best_attack = attack

	return best_attack

func start_attack(attack_type: AttackPattern):
	if is_attacking:
		return

	is_attacking = true
	current_state = State.ATTACK
	attack_animation_timer = 0.8

	# 执行攻击
	match attack_type:
		AttackPattern.MELEE_SWIPE:
			perform_melee_swipe()
		AttackPattern.PROJECTILE:
			perform_projectile_attack()
		AttackPattern.CHARGE_ATTACK:
			perform_charge_attack()
		AttackPattern.DIRECTIONAL_BURST:
			perform_directional_burst()
		AttackPattern.TELEPORT_STRIKE:
			perform_teleport_strike()
		AttackPattern.SHOCKWAVE:
			perform_shockwave()
		AttackPattern.ENRAGED_FLURRY:
			perform_enraged_flurry()

	attack_launched.emit(attack_type)

	# 设置冷却
	var base_cooldown = 1.5
	if current_phase == CombatPhase.PHASE_2:
		base_cooldown = 1.2
	elif current_phase == CombatPhase.PHASE_3:
		base_cooldown = 0.8
	current_attack_cooldown = base_cooldown + randf() * 0.5

# ============ 具体攻击实现 ============

func perform_melee_swipe():
	# 近战横扫
	audio.play_attack()

	var swipe_area = Area2D.new()
	swipe_area.position = position + Vector2(facing_direction() * 40, 0)

	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 60
	swipe_area.add_child(shape)

	# 可视化
	var visual = ColorRect.new()
	visual.size = Vector2(100, 80)
	visual.position = Vector2(-50, -40)
	visual.color = Color(1, 0.3, 0.3, 0.5)
	visual.z_index = 5
	swipe_area.add_child(visual)

	swipe_area.body_entered.connect(func(b): _on_attack_hit(b, swipe_area, 2))
	get_parent().add_child(swipe_area)

	# 动画效果
	var tween = create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): swipe_area.queue_free())

	is_attacking = false

func perform_projectile_attack():
	# 发射弹幕
	audio.play_attack()

	var projectile_count = 3 if current_phase == CombatPhase.PHASE_1 else 5
	for i in range(projectile_count):
		await get_tree().create_timer(0.15).timeout
		fire_projectile(i, projectile_count)

	is_attacking = false

func fire_projectile(index: int, total: int):
	if not player or not is_instance_valid(player):
		return

	var proj = Area2D.new()
	proj.position = position

	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 12
	proj.add_child(shape)

	var visual = ColorRect.new()
	visual.size = Vector2(24, 24)
	visual.position = Vector2(-12, -12)
	visual.color = Color(0.8, 0.2, 1, 0.9)
	proj.add_child(visual)

	# 计算方向（带预测）
	var base_dir = (player.position - position).normalized()
	var spread_angle = 0.3  # 扩散角度
	var angle_offset = (float(index) - float(total - 1) / 2.0) * spread_angle

	# 旋转方向
	var dir = base_dir.rotated(angle_offset)

	proj.body_entered.connect(func(b): _on_attack_hit(b, proj, 1))
	get_parent().add_child(proj)

	# 发射
	var tween = create_tween()
	var target_pos = position + dir * 600
	tween.tween_property(proj, "position", target_pos, 1.5)
	tween.tween_callback(func(): proj.queue_free())

func perform_charge_attack():
	# 冲撞攻击
	audio.play_attack()

	var charge_dir = facing_direction()
	velocity.x = charge_dir * 400

	await get_tree().create_timer(0.5).timeout
	velocity = Vector2.ZERO

	is_attacking = false

func perform_directional_burst():
	# 定向爆发（根据玩家移动偏好）
	audio.play_attack()

	var player_left_pref = player_behavior_data["left_move_count"] > player_behavior_data["right_move_count"]
	var burst_dir = -1 if player_left_pref else 1

	for i in range(5):
		var proj = Area2D.new()
		proj.position = position + Vector2(burst_dir * 30, 0)

		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = 10
		proj.add_child(shape)

		var visual = ColorRect.new()
		visual.size = Vector2(20, 20)
		visual.position = Vector2(-10, -10)
		visual.color = Color(1, 0.5, 0, 0.9)
		proj.add_child(visual)

		proj.body_entered.connect(func(b): _on_attack_hit(b, proj, 1))
		get_parent().add_child(proj)

		var tween = create_tween()
		tween.tween_property(proj, "position", proj.position + Vector2(burst_dir * 400, -50 + i * 25), 1.0)
		tween.tween_callback(func(): proj.queue_free())

	is_attacking = false

func perform_teleport_strike():
	# 传送打击
	if not player or not is_instance_valid(player):
		is_attacking = false
		return

	# 传送特效
	var teleport_effect = CPUParticles2D.new()
	teleport_effect.position = position
	teleport_effect.emitting = true
	teleport_effect.amount = 20
	teleport_effect.lifetime = 0.5
	teleport_effect.one_shot = true
	teleport_effect.color = Color(0.5, 0.2, 0.8, 1)
	get_parent().add_child(teleport_effect)

	# 传送到玩家附近
	var teleport_offset = Vector2(-80 if randf() < 0.5 else 80, -50)
	var old_pos = position
	position = player.position + teleport_offset

	# 新位置特效
	var arrival_effect = teleport_effect.duplicate()
	arrival_effect.position = position
	get_parent().add_child(arrival_effect)

	# 立即攻击
	await get_tree().create_timer(0.2).timeout
	perform_melee_swipe()

	# 清理
	await get_tree().create_timer(0.5).timeout
	teleport_effect.queue_free()
	arrival_effect.queue_free()

func perform_shockwave():
	# 震地波
	audio.play_attack()

	# 震地视觉效果
	var wave = ColorRect.new()
	wave.size = Vector2(300, 30)
	wave.position = Vector2(-150, 20)
	wave.color = Color(1, 0.8, 0.2, 0.7)
	wave.z_index = 3
	add_child(wave)

	# 扩散动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(wave, "size:x", 500, 0.5)
	tween.tween_property(wave, "position:x", -250, 0.5)
	tween.tween_property(wave, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): wave.queue_free())

	# 伤害检测（延迟）
	await get_tree().create_timer(0.2).timeout
	if player and is_instance_valid(player):
		var dist = abs(player.position.x - position.x)
		if dist < 250 and abs(player.position.y - position.y) < 100:
			_on_attack_hit(player, null, 2)

	is_attacking = false

func perform_enraged_flurry():
	# 狂暴连击
	audio.play_attack()

	for i in range(5):
		await get_tree().create_timer(0.15).timeout

		var swipe = Area2D.new()
		swipe.position = position + Vector2(facing_direction() * (30 + i * 10), 0)

		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = 50
		swipe.add_child(shape)

		var visual = ColorRect.new()
		visual.size = Vector2(80, 60)
		visual.position = Vector2(-40, -30)
		visual.color = Color(1, 0, 0, 0.7)
		visual.z_index = 5
		swipe.add_child(visual)

		swipe.body_entered.connect(func(b): _on_attack_hit(b, swipe, 1))
		get_parent().add_child(swipe)

		var tween = create_tween()
		tween.tween_property(visual, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func(): swipe.queue_free())

	is_attacking = false

# ============ 攻击命中处理 ============

func _on_attack_hit(body, area, damage):
	if body == player and is_instance_valid(player):
		if player.has_method("take_damage"):
			player.take_damage()

	# 清理攻击区域
	if area and is_instance_valid(area):
		area.queue_free()

# ============ 受伤处理 ============


func _on_attack_area_body_entered(body):
	pass

func _on_hurt_area_body_entered(_body):
	if _body == player:
		# 玩家攻击Boss
		take_damage(1)

		# 记录玩家攻击时机
		var dist = position.distance_to(player.position)
		if dist < 150:
			player_behavior_data["attack_when_close"] += 1
		else:
			player_behavior_data["attack_when_far"] += 1

func take_damage(amount: int):
	if current_state == State.STUNNED:
		return

	hp -= amount
	audio.play_hurt()

	# 发送受伤统计信号
	stats_updated.emit({"damage_dealt": amount, "boss_current_hp": hp})

	# 受伤闪烁
	body.color = Color(1, 1, 1)
	await get_tree().create_timer(0.1).timeout
	body.color = get_current_color()

	# 检查阶段变化
	var hp_percent = float(hp) / max_hp
	update_combat_phase(hp_percent)

	# 发送Boss血量更新
	stats_updated.emit({"boss_hp_percent": hp_percent * 100})

	# 检查死亡
	if hp <= 0:
		die()
	elif current_state != State.ENRAGED:
		# 短暂晕眩（狂暴模式不会晕眩）
		stun_timer = 0.3
		current_state = State.STUNNED

func update_combat_phase(hp_percent: float):
	var old_phase = current_phase

	if hp_percent <= enraged_threshold:
		current_phase = CombatPhase.PHASE_3
		current_speed = enraged_speed
		current_state = State.ENRAGED
		enter_enraged_mode()
	elif hp_percent <= phase_2_threshold:
		current_phase = CombatPhase.PHASE_2
		current_speed = chase_speed
		enter_phase_2()

	if old_phase != current_phase:
		phase_changed.emit(int(current_phase))

func enter_phase_2():
	print("Boss进入第二阶段！")
	update_boss_color()

	# 解锁新攻击
	if not AttackPattern.DIRECTIONAL_BURST in available_attacks:
		available_attacks.append(AttackPattern.DIRECTIONAL_BURST)
	if not AttackPattern.SHOCKWAVE in available_attacks:
		available_attacks.append(AttackPattern.SHOCKWAVE)

func enter_enraged_mode():
	print("Boss进入狂暴模式！")
	update_boss_color()

	# 解锁所有攻击
	if not AttackPattern.TELEPORT_STRIKE in available_attacks:
		available_attacks.append(AttackPattern.TELEPORT_STRIKE)

	# 提高移动速度
	current_speed = enraged_speed

# ============ 死亡处理 ============

func die():
	print("Boss '", boss_name, "' 被击败！")
	audio.play_enemy_death()

	# 死亡粒子效果
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 50
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.direction = Vector2(0, -1)
	particles.spread = 90
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 150
	particles.scale_min = 5.0
	particles.scale_max = 10.0
	particles.color = get_current_color()
	particles.position = position
	get_parent().add_child(particles)

	# 显示死亡文字
	var death_label = Label.new()
	death_label.text = "BOSS 击败!"
	death_label.position = position + Vector2(-100, -100)
	death_label.add_theme_font_size_override("font_size", 48)
	death_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	death_label.z_index = 200
	get_parent().add_child(death_label)

	# 奖励：蘑菇和经验值
	g.total_mushrooms += 100

	# 动画清理
	await get_tree().create_timer(1.5).timeout
	particles.queue_free()
	death_label.queue_free()
	boss_defeated.emit()
	queue_free()

# ============ 辅助函数 ============

func facing_direction() -> int:
	return 1 if scale.x > 0 else -1

func get_current_color() -> Color:
	match current_phase:
		CombatPhase.PHASE_2:
			return phase_2_color
		CombatPhase.PHASE_3:
			return enraged_color
		_:
			return original_color

func update_boss_color():
	var target_color = get_current_color()
	body.color = target_color

	if eye_glow:
		match current_phase:
			CombatPhase.PHASE_2:
				eye_glow.color = Color(1, 0.6, 0.2)
			CombatPhase.PHASE_3:
				eye_glow.color = Color(1, 0.2, 0.2)

func update_visuals(delta):
	# 眼睛跟随玩家
	if player and is_instance_valid(player):
		var look_dir = (player.position - position).normalized()
		eye_left.position.x = -15 + look_dir.x * 3
		eye_right.position.x = 5 + look_dir.x * 3

		# 瞳孔
		if has_node("PupilLeft") and has_node("PupilRight"):
			$PupilLeft.position.x = -14 + look_dir.x * 5
			$PupilRight.position.x = 6 + look_dir.x * 5

	# 呼吸效果
	var breath = sin(Time.get_ticks_msec() * 0.003) * 2
	body.scale.y = 1.0 + breath * 0.05

# ============ Debug/调试 ============

func get_behavior_summary() -> Dictionary:
	return {
		"move_preference": "left" if player_behavior_data["left_move_count"] > player_behavior_data["right_move_count"] else "right",
		"jump_frequency": player_behavior_data["jump_count"],
		"prediction_confidence": prediction_confidence,
		"current_phase": current_phase
	}
