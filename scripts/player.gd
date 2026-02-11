extends CharacterBody2D

# 玩家死亡信号
signal player_died()

var g: Node = null
var char_info: Dictionary = {}

var move_speed: float = 280.0
var move_accel: float = 1500.0
var move_friction: float = 1200.0
var jump_force: float = -700.0
var gravity: float = 1400.0

var can_coyote_jump: bool = false
var coyote_timer: float = 0.0
const COYOTE_TIME: float = 0.1

var can_jump_buffer: bool = false
var jump_buffer_timer: float = 0.0
const JUMP_BUFFER_TIME: float = 0.1

var can_double_jump: bool = true

# 跳跃蓄力相关
var is_jump_holding: bool = false
var jump_hold_time: float = 0.0
const JUMP_HOLD_MAX_TIME: float = 0.2  # 最大蓄力时间
const JUMP_GRAVITY_MULTIPLIER: float = 0.3  # 按住时重力减小到30%

var can_dash: bool = true
var is_dashing: bool = false
var dash_speed: float = 600.0
var dash_duration: float = 0.15
var dash_timer: float = 0.0
var dash_cooldown: float = 1.0
var dash_cooldown_timer: float = 0.0

var can_float: bool = true
var is_floating: bool = false
var float_duration: float = 1.5
var float_timer: float = 0.0
var float_cooldown: float = 3.0
var float_cooldown_timer: float = 0.0
var float_gravity: float = 300.0

var can_fireball: bool = true
var fireball_cooldown: float = 0.8
var fireball_cooldown_timer: float = 0.0

# 受伤无敌时间
var invincible: bool = false
var invincible_duration: float = 1.0
var invincible_timer: float = 0.0

var hp: int = 3
var max_hp: int = 3
var can_heal: bool = true
var heal_cooldown: float = 10.0
var heal_cooldown_timer: float = 0.0

var is_shielded: bool = false
var shield_duration: float = 2.0
var shield_timer: float = 0.0
var shield_cooldown: float = 8.0
var shield_cooldown_timer: float = 0.0

var can_grapple: bool = true
var grapple_cooldown: float = 2.0
var grapple_cooldown_timer: float = 0.0
var is_grappling: bool = false
var grapple_target: Vector2 = Vector2.ZERO
var grapple_speed: float = 800.0

# 新技能变量
var can_ground_slam: bool = true
var ground_slam_cooldown: float = 3.0
var ground_slam_cooldown_timer: float = 0.0

var can_ice_spike: bool = true
var ice_spike_cooldown: float = 4.0
var ice_spike_cooldown_timer: float = 0.0

var can_holy_shield: bool = true
var holy_shield_duration: float = 3.0
var holy_shield_timer: float = 0.0
var holy_shield_cooldown: float = 12.0
var holy_shield_cooldown_timer: float = 0.0

var can_piercing_shot: bool = true
var piercing_shot_cooldown: float = 5.0
var piercing_shot_cooldown_timer: float = 0.0

var can_slow_arrow: bool = true
var slow_arrow_cooldown: float = 1.5
var slow_arrow_cooldown_timer: float = 0.0

var was_on_floor: bool = false
var facing_right: bool = true
var facing_direction: int = 1

@onready var body_rect: ColorRect = $Body
@onready var audio = get_node("/root/AudioManager")
@onready var eye_left: ColorRect = $Eyes/EyeL
@onready var eye_right: ColorRect = $Eyes/EyeR
@onready var pupil_left: ColorRect = $Eyes/PupilL
@onready var pupil_right: ColorRect = $Eyes/PupilR
@onready var dust: CPUParticles2D = $Dust
@onready var cooldown_label: Label = $Cooldown
@onready var blush_left: ColorRect = $BlushL
@onready var blush_right: ColorRect = $BlushR

func _ready() -> void:
	g = get_node("/root/Global")
	char_info = g.get_character_info(g.selected_character)

	# 应用基础属性 + 升级加成
	move_speed = char_info.get("speed", 280) + g.get_upgrade_bonus("speed")
	jump_force = char_info.get("jump_force", -420.0) - g.get_upgrade_bonus("jump")
	max_hp = int(char_info.get("hp", 3) + g.get_upgrade_bonus("hp"))
	hp = max_hp

	print("Player", "角色初始化: %s, HP: %d, 速度: %f" % [g.selected_character, hp, move_speed])

	# 简单初始化
	body_rect.position = Vector2.ZERO
	$Eyes.position = Vector2.ZERO
	update_body_color()

func update_body_color() -> void:
	var char_color: Color = char_info.get("color", Color(0.2, 0.6, 1))
	body_rect.color = char_color

func _physics_process(delta):
	if is_dashing:
		process_dash(delta)
	elif is_grappling:
		process_grapple(delta)
	else:
		process_movement(delta)
	
	process_skills(delta)
	process_cooldowns(delta)
	update_eyes()
	update_ui()

func process_movement(delta):
	var was_floor = was_on_floor
	
	if is_on_floor():
		coyote_timer = 0.0
		can_coyote_jump = true
	else:
		coyote_timer += delta
		if coyote_timer >= COYOTE_TIME:
			can_coyote_jump = false
	
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
		if jump_buffer_timer <= 0:
			can_jump_buffer = false

	var input_axis = Input.get_axis("move_left", "move_right")
	
	if input_axis != 0:
		velocity.x = move_toward(velocity.x, input_axis * move_speed, move_accel * delta)
		if input_axis > 0:
			facing_right = true
			facing_direction = 1
		else:
			facing_right = false
			facing_direction = -1
	else:
		velocity.x = move_toward(velocity.x, 0, move_friction * delta)
	
	if is_floating:
		velocity.y += float_gravity * delta
	else:
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("jump"):
		can_jump_buffer = true
		jump_buffer_timer = JUMP_BUFFER_TIME

	if can_jump_buffer and (is_on_floor() or can_coyote_jump):
		perform_jump()

	# 跳跃蓄力机制：按住跳跃键时减小重力，跳得更高
	if Input.is_action_pressed("jump") and velocity.y < 0 and is_jump_holding:
		jump_hold_time += delta
		# 按住时应用减小的重力
		velocity.y += gravity * JUMP_GRAVITY_MULTIPLIER * delta
	else:
		# 松开跳跃键时，立即下落
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y = velocity.y * 0.3
			is_jump_holding = false
			jump_hold_time = 0
		# 上升到最高点时重置
		if velocity.y >= 0:
			is_jump_holding = false
			jump_hold_time = 0

	move_and_slide()
	
	was_on_floor = is_on_floor()
	
	if not was_floor and is_on_floor():
		land_squash()
	
	if position.y > 1100:
		respawn()

func process_dash(delta):
	dash_timer -= delta
	if dash_timer <= 0:
		is_dashing = false
		velocity.x = 0

func perform_dash():
	if can_dash and not is_dashing:
		is_dashing = true
		can_dash = false
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		velocity.x = facing_direction * dash_speed
		jump_squash()

func process_grapple(delta):
	var dir = (grapple_target - position).normalized()
	velocity = dir * grapple_speed
	move_and_slide()
	
	if position.distance_to(grapple_target) < 30 or not is_instance_valid(get_last_slide_collision()):
		is_grappling = false

func perform_grapple():
	if can_grapple and not is_grappling:
		var cast_length = 400
		var query = PhysicsRayQueryParameters2D.create(position, position + Vector2(facing_direction * cast_length, 0))
		var result = get_world_2d().direct_space_state.intersect_ray(query)
		
		if result:
			is_grappling = true
			can_grapple = false
			grapple_cooldown_timer = grapple_cooldown
			grapple_target = result.position
			jump_squash()

func process_skills(delta):
	var skills = char_info.get("skills", [])
	
	if "double_jump" in skills:
		if Input.is_action_just_pressed("jump") and not is_on_floor() and can_double_jump:
			perform_double_jump()
	
	if "dash" in skills:
		if Input.is_action_just_pressed("interact"):
			perform_dash()
	
	if "float" in skills:
		if Input.is_action_pressed("interact") and not is_on_floor() and float_timer > 0:
			is_floating = true
			if Input.is_action_just_released("interact"):
				is_floating = false
				float_timer = 0

	if "fireball" in skills:
		if Input.is_action_just_pressed("attack"):
			shoot_fireball()

	# 新技能输入处理
	if "ground_slam" in skills:
		if Input.is_action_just_pressed("attack"):
			perform_ground_slam()

	if "ice_spike" in skills:
		if Input.is_action_just_pressed("attack"):
			shoot_ice_spike()

	if "holy_shield" in skills:
		if Input.is_action_just_pressed("interact"):
			activate_holy_shield()

	if "piercing_shot" in skills:
		if Input.is_action_just_pressed("attack"):
			shoot_piercing_shot()
	
	if "heal" in skills:
		if Input.is_action_just_pressed("interact"):
			perform_heal()
	
	if "shield" in skills:
		if Input.is_action_just_pressed("jump") and not is_on_floor():
			activate_shield()
	
	if "grapple" in skills:
		if Input.is_action_just_pressed("interact"):
			perform_grapple()
	
	if "slow_arrow" in skills:
		if Input.is_action_just_pressed("attack"):
			shoot_slow_arrow()

func process_cooldowns(delta):
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	if is_floating:
		float_timer -= delta
		if float_timer <= 0:
			is_floating = false
	
	if float_cooldown_timer > 0:
		float_cooldown_timer -= delta
	else:
		float_timer = float_duration
	
	if fireball_cooldown_timer > 0:
		fireball_cooldown_timer -= delta
	
	if heal_cooldown_timer > 0:
		heal_cooldown_timer -= delta
	
	if shield_cooldown_timer > 0:
		shield_cooldown_timer -= delta
	if shield_timer > 0:
		shield_timer -= delta
		if shield_timer <= 0:
			is_shielded = false
	
	if grapple_cooldown_timer > 0:
		grapple_cooldown_timer -= delta
	
	if slow_arrow_cooldown_timer > 0:
		slow_arrow_cooldown_timer -= delta

	# 新技能冷却
	if ground_slam_cooldown_timer > 0:
		ground_slam_cooldown_timer -= delta

	if ice_spike_cooldown_timer > 0:
		ice_spike_cooldown_timer -= delta

	if holy_shield_cooldown_timer > 0:
		holy_shield_cooldown_timer -= delta

	if piercing_shot_cooldown_timer > 0:
		piercing_shot_cooldown_timer -= delta

func perform_jump():
	if piercing_shot_cooldown_timer > 0:
		piercing_shot_cooldown_timer -= delta
	
	# 无敌时间倒计时
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false

	velocity.y = jump_force
	can_jump_buffer = false
	can_coyote_jump = false
	can_double_jump = true
	is_jump_holding = true
	jump_hold_time = 0
	jump_squash()
	audio.play_jump()  # 播放跳跃音效

func perform_double_jump():
	velocity.y = jump_force * 0.9
	can_double_jump = false
	jump_squash()
	audio.play_jump()  # 播放跳跃音效

func shoot_fireball():
	if fireball_cooldown_timer <= 0:
		fireball_cooldown_timer = fireball_cooldown
		audio.play_attack()  # 播放攻击音效

		var fireball = Area2D.new()
		fireball.position = position

		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = 10
		fireball.add_child(shape)

		var rect = ColorRect.new()
		rect.size = Vector2(20, 20)
		rect.position = Vector2(-10, -10)
		rect.color = Color(1, 0.5, 0.2)
		fireball.add_child(rect)

		fireball.body_entered.connect(_on_fireball_hit)
		get_parent().add_child(fireball)

		var tween = create_tween()
		tween.tween_property(fireball, "position:x", position.x + facing_direction * 500, 1.5)
		tween.tween_callback(func(): fireball.queue_free())

func _on_fireball_hit(body):
	if body.has_meta("type") and body.get_meta("type") == "slime":
		damage_enemy(body, 2)  # 火球术造成2点伤害

func perform_heal():
	if heal_cooldown_timer <= 0 and hp < max_hp:
		hp = min(hp + 1, max_hp)
		heal_cooldown_timer = heal_cooldown
		update_body_color()

func activate_shield():
	if shield_cooldown_timer <= 0:
		is_shielded = true
		shield_timer = shield_duration
		shield_cooldown_timer = shield_cooldown
		body_rect.modulate = Color(1, 1, 0.5, 0.7)

func shoot_slow_arrow():
	if slow_arrow_cooldown_timer <= 0:
		slow_arrow_cooldown_timer = slow_arrow_cooldown
		audio.play_attack()  # 播放攻击音效

		var arrow = Area2D.new()
		arrow.position = position

		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = 8
		arrow.add_child(shape)

		var rect = ColorRect.new()
		rect.size = Vector2(16, 8)
		rect.position = Vector2(-8, -4)
		rect.color = Color(0.5, 0.8, 1)
		arrow.add_child(rect)

		arrow.body_entered.connect(_on_arrow_hit)
		get_parent().add_child(arrow)

		var tween = create_tween()
		tween.tween_property(arrow, "position:x", position.x + facing_direction * 400, 1.2)
		tween.tween_callback(func(): arrow.queue_free())

func _on_arrow_hit(body):
	if body.has_meta("type") and body.get_meta("type") == "slime":
		damage_enemy(body, 1)  # 箭造成1点伤害

# 对敌人造成伤害
func damage_enemy(enemy, base_damage):
	# 应用攻击力升级加成
	var total_damage = base_damage + g.get_upgrade_bonus("damage")
	var final_damage = int(total_damage)  # 转为整数

	# 显示伤害数字
	spawn_damage_number(enemy.position, final_damage)

	# 击退方向
	var knockback_dir = (enemy.position - position).normalized()

	# 如果敌人有 take_damage 方法，使用它
	if enemy.has_method("take_damage"):
		enemy.take_damage(final_damage, knockback_dir)
		return

	# 兼容旧的元数据方式
	if not enemy.has_meta("hp"):
		return

	var current_hp = enemy.get_meta("hp")

	# 减少HP
	current_hp -= final_damage
	enemy.set_meta("hp", current_hp)

	# 击退效果
	enemy.position += knockback_dir * 20

	# 受伤闪烁效果
	if enemy.get_child_count() > 1:
		var rect = enemy.get_child(1)
		var original_color = rect.color
		rect.color = Color(1, 1, 1)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(rect):
			rect.color = original_color

	# 检查死亡
	if current_hp <= 0:
		spawn_collect_effect(enemy.position)
		enemy.queue_free()

# 显示伤害数字
func spawn_damage_number(pos, damage):
	var label = Label.new()
	label.text = str(damage)
	label.position = pos + Vector2(-20, -40)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	label.z_index = 100
	get_parent().add_child(label)

	# 飘字动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 80, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func(): label.queue_free()).set_delay(0.8)

func jump_squash():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 只做挤压拉伸，位置保持固定
	tween.tween_property(body_rect, "scale", Vector2(1.2, 0.8), 0.08)
	tween.chain().tween_property(body_rect, "scale", Vector2(1, 1), 0.15)

func land_squash():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 只做挤压拉伸，位置保持固定
	tween.tween_property(body_rect, "scale", Vector2(1.15, 0.85), 0.06)
	tween.chain().tween_property(body_rect, "scale", Vector2(1, 1), 0.12)

	dust.emitting = true
	dust.position = Vector2(0, 22)

func update_eyes():
	var eye_offset = 3 if facing_right else -3

	# 更新眼睛背景位置（白眼）
	eye_left.position.x = -8 + eye_offset
	eye_right.position.x = 4 + eye_offset

	# 更新瞳孔位置
	pupil_left.position.x = -6 + eye_offset
	pupil_right.position.x = 6 + eye_offset

	# 更新腮红位置（对称，不随朝向改变）
	# 腮红是装饰性的，不需要跟随朝向

func update_ui():
	if cooldown_label:
		var skills = char_info.get("skills", [])
		var text = ""
		
		if "dash" in skills:
			var d = "O" if dash_cooldown_timer <= 0 else "X"
			text += d + " Dash "
		
		if "float" in skills:
			var f = "O" if float_cooldown_timer <= 0 else "X"
			text += f + " Float "
		
		if "fireball" in skills:
			var fb = "O" if fireball_cooldown_timer <= 0 else "X"
			text += fb + " Attack(K) "
		
		if "heal" in skills:
			var h = "O" if heal_cooldown_timer <= 0 else "X"
			text += h + " Heal "
		
		if "shield" in skills:
			var s = "O" if shield_cooldown_timer <= 0 else "X"
			text += s + " Shield "

		if "holy_shield" in skills:
			var hs = "O" if holy_shield_cooldown_timer <= 0 else "X"
			text += hs + " 圣盾 "

		if "ground_slam" in skills:
			var gs = "O" if ground_slam_cooldown_timer <= 0 else "X"
			text += gs + " 震地 "

		if "ice_spike" in skills:
			var ice_spike_status = "O" if ice_spike_cooldown_timer <= 0 else "X"
			text += ice_spike_status + " 冰冻 "

		if "piercing_shot" in skills:
			var ps = "O" if piercing_shot_cooldown_timer <= 0 else "X"
			text += ps + " 穿透 "
		
		if "grapple" in skills:
			var g = "O" if grapple_cooldown_timer <= 0 else "X"
			text += g + " Grapple "
		
		if "slow_arrow" in skills:
			var sa = "O" if slow_arrow_cooldown_timer <= 0 else "X"
			text += sa + " Attack(K) "
		
		text += " HP:" + str(hp)
		cooldown_label.text = text

func spawn_collect_effect(pos):
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 12
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.direction = Vector2(0, -1)
	particles.spread = 45
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.scale_min = 3.0
	particles.scale_max = 6.0
	particles.color = Color(1, 0.9, 0.3, 1)
	particles.position = pos
	get_parent().add_child(particles)
	
	await get_tree().create_timer(0.5).timeout
	particles.queue_free()

# ============ 新技能函数 ============

# 震地猛击（战士）
func perform_ground_slam():
	if ground_slam_cooldown_timer <= 0 and is_on_floor():
		audio.play_attack()  # 播放攻击音效
		ground_slam_cooldown_timer = ground_slam_cooldown
		can_ground_slam = false

		# 范围震地效果
		var slam_radius = 80
		var targets = get_tree().get_nodes_in_group("enemies")
		for target in targets:
			if target and is_instance_valid(target):
				var dist = global_position.distance_to(target.global_position)
				if dist < slam_radius:
					target.take_damage()

		# 震屏特效
		var screen_shake = create_tween()
		screen_shake.set_parallel(true)
		screen_shake.tween_property(self, "position:x", 20, 0.05)
		screen_shake.tween_property(self, "position:x", -20, 0.05)
		screen_shake.tween_property(self, "position:x", 0, 0.05)

		# 击退
		velocity.x = -facing_direction * 300
		jump_squash()

		await get_tree().create_timer(0.2).timeout
		can_ground_slam = true

# 冰冻术（法师）- 召成冰柱冻结敌人
func shoot_ice_spike():
	if ice_spike_cooldown_timer <= 0:
		ice_spike_cooldown_timer = ice_spike_cooldown
		audio.play_attack()  # 播放攻击音效

		var ice_spike = Area2D.new()
		ice_spike.position = position + Vector2(facing_direction * 30, -10)

		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = 25
		ice_spike.add_child(shape)

		var sprite = ColorRect.new()
		sprite.size = Vector2(50, 50)
		sprite.position = Vector2(-25, -25)
		sprite.color = Color(0.6, 0.9, 1, 0.6)
		ice_spike.add_child(sprite)

		ice_spike.body_entered.connect(_on_ice_spike_body_entered)
		get_parent().add_child(ice_spike)

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(ice_spike, "modulate:a", 0, 0.5)
		tween.tween_property(ice_spike, "scale", Vector2(3, 0.01), 0.5)
		tween.tween_callback(func(): ice_spike.queue_free())

		await get_tree().create_timer(ice_spike_cooldown).timeout
		can_ice_spike = true

func _on_ice_spike_body_entered(body):
	if body.has_meta("type") and body.get_meta("type") == "slime":
		body.velocity.x = 0
		body.take_damage()

# 圣光护盾（牧师）- 范围内玩家持续回血
func activate_holy_shield():
	if holy_shield_cooldown_timer <= 0:
		holy_shield_cooldown_timer = holy_shield_cooldown

	is_shielded = true

	var aura = ColorRect.new()
	aura.size = Vector2(150, 150)
	aura.position = Vector2(-75, -75)
	aura.color = Color(1, 1, 0.8, 0.3)
	aura.z_index = -1
	add_child(aura)

	await get_tree().create_timer(holy_shield_duration).timeout
	is_shielded = false
	aura.queue_free()

# 穿透箭（射手）- 高伤害射击
func shoot_piercing_shot():
	if piercing_shot_cooldown_timer <= 0:
		piercing_shot_cooldown_timer = piercing_shot_cooldown
		audio.play_attack()  # 播放攻击音效

		var arrow = Area2D.new()
		arrow.position = position + Vector2(facing_direction * 30, 0)
		arrow.set_meta("piercing", true)

		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = 8
		arrow.add_child(shape)

		var sprite = ColorRect.new()
		sprite.size = Vector2(30, 12)
		sprite.position = Vector2(-15, -6)
		sprite.color = Color(1, 0.9, 0.3, 1)
		arrow.add_child(sprite)

		arrow.body_entered.connect(_on_arrow_body_entered)
		get_parent().add_child(arrow)

		var tween = create_tween()
		tween.tween_property(arrow, "position:x", position.x + facing_direction * 500, 0.4)

		await get_tree().create_timer(piercing_shot_cooldown).timeout
		can_piercing_shot = true

func _on_arrow_body_entered(body):
	if body.has_meta("type") and body.get_meta("type") == "slime":
		body.take_damage()
		body.queue_free()

func respawn():
	position = Vector2(150, 530)
	velocity = Vector2.ZERO
	_reset_body_parts()
	is_dashing = false
	is_grappling = false
	is_floating = false
	is_shielded = false

func _reset_body_parts():
	# 重置身体所有变形
	body_rect.scale = Vector2(1, 1)
	body_rect.position = Vector2.ZERO

func take_damage():
	if is_shielded or invincible:
		return
	
	# 设置无敌时间
	invincible = true
	invincible_timer = invincible_duration
	
	_reset_body_parts()  # 重置之前的变形
	
	hp -= 1
	audio.play_hurt()  # 播放受伤音效

	# 受伤闪烁效果
	body_rect.color = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	body_rect.color = char_info.get("color", Color(0.2, 0.6, 1))

	if hp <= 0:
		# 发送玩家死亡信号
		player_died.emit()
		respawn()
		hp = max_hp
	update_body_color()

func _on_area_2d_body_entered(collider):
	if collider.name == "Exit":
		get_parent()._on_player_reached_exit()
	
	# 检查是否是敌人（只有敌人造成伤害）
	if (collider.is_in_group("enemies") or collider.has_meta("type")) and not invincible:
		take_damage()

func _on_area_2d_body_entered(collider):
	if collider.name == "Exit":
		get_parent()._on_player_reached_exit()
	
	if collider.has_meta("type") and collider.get_meta("type") == "slime":
		take_damage()

# 玩家攻击区域碰撞 - 对敌人造成伤害
func _on_body_entered(body):
	if body.is_in_group("enemies") or body.has_meta("type"):
		var damage = 1
		var knockback = Vector2(facing_direction * 200, -100)
		
		if body.has_method("take_damage"):
			body.take_damage(damage, knockback)
		
		# 播放攻击命中音效
		audio.play_attack()
