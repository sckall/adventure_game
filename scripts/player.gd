extends CharacterBody2D

# ============ 玩家 ============

signal died
signal health_changed(current, max)
signal skill_used(name)
signal enemy_killed(count)
signal skills_changed(slots)

var character_id := "warrior"

var hp := 3
var max_hp := 3

var max_speed := 240.0
var acceleration := 1400.0
var deceleration := 1800.0

var gravity := 1200.0
var fall_gravity_scale := 1.25

var jump_force := -650.0
var coyote_time := 0.10
var coyote_timer := 0.0

var jump_buffer_time := 0.12
var jump_buffer_timer := 0.0

var invincible := false
var invincible_timer := 0.0
var contact_timer := 0.0
var contact_cooldown := 0.35
var hit_stop_timer := 0.0

var attack_cooldown := 0.22
var attack_timer := 0.0
var attack_lock_timer := 0.0
var attack_range := 42.0
var facing := 1
var attack_damage := 1.0
var backstab_mult := 2.0
var hit_lunge_timer := 0.0
var hit_lunge_dir := Vector2.ZERO
var wall_slide_speed := 90.0
var wall_jump_push := 260.0
var wall_timer := 0.0
var wall_coyote := 0.12

var skill_cooldowns := {
	"primary": 0.0,
	"secondary": 0.0,
	"utility": 0.0
}
var skill_durations := {
	"primary": 0.0,
	"secondary": 0.0,
	"utility": 0.0
}
var is_spinning := false

var spin_damage_range := 60.0
var spin_damage := 999

var dash_speed := 600.0
var dash_duration := 0.15
var dash_cooldown := 1.2
var is_dashing := false
var dash_direction := Vector2.ZERO

var heal_amount := 1
var heal_cooldown := 8.0
var was_on_floor := false
var sfx_jump
var sfx_attack
var sfx_hurt
var slash_color := Color(1.0, 0.9, 0.4, 0.85)
var outline_color := Color(0.1, 0.1, 0.12)

var skill_pool = ["flight", "beam", "spike", "stealth"]
var skill_slots = ["flight", "beam", "spike"]
var is_flying := false
var fly_timer := 0.0
var stealth_timer := 0.0
var can_double_jump := false

var weapon_name := "Rusty Blade"
var weapon_rarity := "common"
var weapon_mod := ""
var weapon_damage_mult := 1.0

func _ready() -> void:
	add_to_group("player")
	_resolve_character_id()
	_apply_character_stats()
	_init_skill_slots()
	_ensure_default_input_bindings()
	_setup_visual_and_collision()
	_setup_audio()
	health_changed.emit(hp, max_hp)
	was_on_floor = is_on_floor()

func _resolve_character_id() -> void:
	var tree = get_tree()
	if tree and tree.has_meta("selected_character"):
		character_id = String(tree.get_meta("selected_character"))

func _apply_character_stats() -> void:
	match character_id:
		"warrior":
			max_hp = 4
			max_speed = 220.0
			attack_range = 52.0
			attack_cooldown = 0.35
			attack_damage = 2.0
			slash_color = Color(1.0, 0.85, 0.5, 0.9)
			outline_color = Color(0.08, 0.08, 0.1)
			can_double_jump = false
		"assassin":
			max_hp = 3
			max_speed = 280.0
			attack_range = 38.0
			attack_cooldown = 0.2
			attack_damage = 1.4
			slash_color = Color(1.0, 0.4, 0.5, 0.9)
			outline_color = Color(0.08, 0.06, 0.1)
			can_double_jump = true
		"mage":
			max_hp = 3
			max_speed = 210.0
			attack_range = 120.0
			attack_cooldown = 0.45
			attack_damage = 1.2
			slash_color = Color(0.6, 0.7, 1.0, 0.9)
			outline_color = Color(0.06, 0.08, 0.12)
			can_double_jump = false
		"priest":
			max_hp = 4
			max_speed = 210.0
			attack_range = 44.0
			attack_cooldown = 0.35
			attack_damage = 1.1
			slash_color = Color(1.0, 0.95, 0.6, 0.9)
			outline_color = Color(0.08, 0.08, 0.1)
			can_double_jump = false
		"archer":
			max_hp = 3
			max_speed = 250.0
			attack_range = 150.0
			attack_cooldown = 0.4
			attack_damage = 1.3
			slash_color = Color(0.6, 1.0, 0.7, 0.9)
			outline_color = Color(0.06, 0.09, 0.08)
			can_double_jump = true
		_:
			max_hp = 3
			max_speed = 240.0
			attack_range = 42.0
			attack_cooldown = 0.25
			attack_damage = 1.0
			slash_color = Color(1.0, 0.9, 0.4, 0.85)
			outline_color = Color(0.1, 0.1, 0.12)
			can_double_jump = false
	hp = min(hp, max_hp)

func _ensure_default_input_bindings() -> void:
	_add_key_binding("ui_left", KEY_A)
	_add_key_binding("ui_left", KEY_LEFT)
	_add_key_binding("ui_right", KEY_D)
	_add_key_binding("ui_right", KEY_RIGHT)
	_add_key_binding("ui_accept", KEY_SPACE)
	_add_key_binding("ui_accept", KEY_ENTER)
	_add_key_binding("ui_accept", KEY_KP_ENTER)
	_add_key_binding("attack", KEY_K)
	_add_mouse_binding("attack", MOUSE_BUTTON_LEFT)
	_add_key_binding("skill_primary", KEY_L)
	_add_key_binding("skill_secondary", KEY_E)
	_add_key_binding("skill_utility", KEY_Q)
	_add_key_binding("skill_cycle_1", KEY_1)
	_add_key_binding("skill_cycle_2", KEY_2)
	_add_key_binding("skill_cycle_3", KEY_3)

func _add_key_binding(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			return
	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	InputMap.action_add_event(action_name, key_event)

func _add_mouse_binding(action_name: String, button: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button:
			return
	var m := InputEventMouseButton.new()
	m.button_index = button
	InputMap.action_add_event(action_name, m)

func _setup_visual_and_collision() -> void:
	if not has_node("CollisionShape2D"):
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = Vector2(20, 28)
		collision.shape = rect
		add_child(collision)

	if not has_node("Body"):
		var body := Node2D.new()
		body.name = "Body"
		body.z_index = 10
		add_child(body)

		var palette = _get_character_palette()
		_add_outline(body, Vector2(-10, -22), Vector2(20, 30), outline_color)
		_add_part(body, "Cloak", Vector2(-8, -8), Vector2(16, 18), palette["cloak"])
		_add_part(body, "Torso", Vector2(-7, -12), Vector2(14, 14), palette["torso"])
		_add_part(body, "Head", Vector2(-6, -20), Vector2(12, 10), palette["head"])
		_add_part(body, "Visor", Vector2(-4, -16), Vector2(8, 3), palette["visor"])
		_add_part(body, "LegL", Vector2(-6, 4), Vector2(5, 10), palette["legs"])
		_add_part(body, "LegR", Vector2(1, 4), Vector2(5, 10), palette["legs"])
		_add_part(body, "Blade", Vector2(8, -8), Vector2(3, 12), palette["blade"])

func _get_character_palette() -> Dictionary:
	match character_id:
		"warrior":
			return {"cloak": Color(0.2, 0.25, 0.4), "torso": Color(0.8, 0.4, 0.25),
				"head": Color(0.95, 0.9, 0.85), "visor": Color(1.0, 0.85, 0.4),
				"legs": Color(0.25, 0.22, 0.2), "blade": Color(0.9, 0.9, 0.95)}
		"assassin":
			return {"cloak": Color(0.2, 0.1, 0.18), "torso": Color(0.85, 0.25, 0.35),
				"head": Color(0.9, 0.85, 0.9), "visor": Color(1.0, 0.7, 0.8),
				"legs": Color(0.2, 0.2, 0.25), "blade": Color(1.0, 0.85, 0.9)}
		"mage":
			return {"cloak": Color(0.2, 0.25, 0.5), "torso": Color(0.35, 0.45, 0.95),
				"head": Color(0.85, 0.9, 1.0), "visor": Color(0.8, 0.95, 1.0),
				"legs": Color(0.2, 0.24, 0.3), "blade": Color(0.7, 0.8, 1.0)}
		"priest":
			return {"cloak": Color(0.8, 0.75, 0.25), "torso": Color(0.95, 0.9, 0.35),
				"head": Color(0.98, 0.95, 0.9), "visor": Color(1.0, 0.98, 0.7),
				"legs": Color(0.3, 0.28, 0.25), "blade": Color(0.9, 0.95, 1.0)}
		"archer":
			return {"cloak": Color(0.2, 0.4, 0.2), "torso": Color(0.35, 0.85, 0.45),
				"head": Color(0.9, 0.95, 0.9), "visor": Color(0.8, 1.0, 0.85),
				"legs": Color(0.22, 0.3, 0.22), "blade": Color(0.8, 1.0, 0.9)}
		_:
			return {"cloak": Color(0.12, 0.28, 0.56), "torso": Color(0.22, 0.75, 0.95),
				"head": Color(0.82, 0.89, 0.98), "visor": Color(1.0, 0.97, 0.78),
				"legs": Color(0.18, 0.21, 0.33), "blade": Color(0.90, 0.92, 1.0)}

func _setup_audio() -> void:
	sfx_jump = _create_sfx("res://assets/audio/audio_0.ogg", -8.0)
	sfx_attack = _create_sfx("res://assets/audio/audio_1.ogg", -6.0)
	sfx_hurt = _create_sfx("res://assets/audio/audio_2.ogg", -4.0)

func _create_sfx(path: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream = _safe_load_audio(path, 1024)
	if stream == null:
		return player
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	return player

func _safe_load_audio(path: String, min_bytes: int):
	if not FileAccess.file_exists(path):
		return null
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var size = f.get_length()
	if size < min_bytes:
		return null
	return load(path)

func _add_part(parent: Node2D, name: String, top_left: Vector2, size: Vector2, color: Color) -> void:
	var sprite := Sprite2D.new()
	sprite.name = name
	sprite.centered = true
	sprite.texture = _solid_texture(int(size.x), int(size.y), color)
	sprite.position = top_left + size * 0.5
	parent.add_child(sprite)

func _add_outline(parent: Node2D, top_left: Vector2, size: Vector2, color: Color) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Outline"
	sprite.centered = true
	sprite.texture = _solid_texture(int(size.x), int(size.y), color)
	sprite.position = top_left + size * 0.5
	sprite.z_index = -1
	parent.add_child(sprite)

func _solid_texture(w: int, h: int, color: Color) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	was_on_floor = is_on_floor()

	if is_dashing:
		# 冲刺期间强制移动
		velocity.x = dash_direction.x * dash_speed
		velocity.y = 0  # 冲刺时不受重力影响
	else:
		_apply_horizontal_movement(delta)
		_apply_vertical_movement(delta)

	if hit_lunge_timer > 0.0:
		velocity += hit_lunge_dir * 180.0

	if Input.is_action_just_pressed("attack"):
		_update_facing_from_mouse()
		try_attack()
	elif Input.is_action_pressed("attack") and attack_timer <= 0.0:
		_update_facing_from_mouse()
		try_attack()
	if Input.is_action_just_pressed("skill_primary"):
		_use_skill("primary")
	if Input.is_action_just_pressed("skill_secondary"):
		_use_skill("secondary")
	if Input.is_action_just_pressed("skill_utility"):
		_use_skill("utility")
	if Input.is_action_just_pressed("skill_cycle_1"):
		_cycle_skill(0)
	if Input.is_action_just_pressed("skill_cycle_2"):
		_cycle_skill(1)
	if Input.is_action_just_pressed("skill_cycle_3"):
		_cycle_skill(2)

	_try_consume_buffered_jump()
	move_and_slide()
	_update_visual_feedback(delta)
	_check_contact_damage()

	if not was_on_floor and is_on_floor():
		_spawn_land_dust()
		# 落地时清空缓冲，避免触地反弹
		jump_buffer_timer = 0.0

	if position.y > 1200:
		die()

func _update_timers(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta
	if attack_lock_timer > 0.0:
		attack_lock_timer -= delta
	if hit_lunge_timer > 0.0:
		hit_lunge_timer -= delta
	if contact_timer > 0.0:
		contact_timer -= delta
	if wall_timer > 0.0:
		wall_timer -= delta
	if hit_stop_timer > 0.0:
		hit_stop_timer -= delta
		if hit_stop_timer <= 0.0:
			Engine.time_scale = 1.0

	# 技能冷却
	for key in skill_cooldowns:
		if skill_cooldowns[key] > 0.0:
			skill_cooldowns[key] -= delta

	# 技能持续时间
	for key in skill_durations:
		if skill_durations[key] > 0.0:
			skill_durations[key] -= delta
			if skill_durations[key] <= 0.0:
				match key:
					"primary":
						is_spinning = false
					"secondary":
						is_dashing = false

	if is_on_floor():
		coyote_timer = coyote_time
		if character_id == "assassin" or character_id == "archer":
			can_double_jump = true
	elif coyote_timer > 0.0:
		coyote_timer -= delta
	if is_on_wall_only():
		wall_timer = wall_coyote

	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			invincible = false

	if is_flying:
		fly_timer -= delta
		if fly_timer <= 0.0:
			is_flying = false

	if stealth_timer > 0.0:
		stealth_timer -= delta

func _apply_horizontal_movement(delta: float) -> void:
	if attack_lock_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		return
	var axis := Input.get_axis("ui_left", "ui_right")
	if axis > 0.01:
		facing = 1
	elif axis < -0.01:
		facing = -1

	var target_speed := axis * max_speed
	var rate := acceleration if absf(target_speed) > 0.01 else deceleration
	velocity.x = move_toward(velocity.x, target_speed, rate * delta)

func _update_facing_from_mouse() -> void:
	var mouse_global = get_global_mouse_position()
	var dir_x = mouse_global.x - global_position.x
	if absf(dir_x) > 2.0:
		facing = 1 if dir_x > 0.0 else -1

func _apply_vertical_movement(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time

	if is_flying:
		velocity.y = -120.0
	else:
		var current_gravity := gravity * (fall_gravity_scale if velocity.y > 0.0 else 1.0)
		velocity.y += current_gravity * delta
		if is_on_wall_only() and velocity.y > wall_slide_speed:
			velocity.y = wall_slide_speed

	# 松开跳跃键会进行短跳，提升操作精度
	if Input.is_action_just_released("ui_accept") and velocity.y < -120.0:
		velocity.y *= 0.58

func _try_consume_buffered_jump() -> void:
	if jump_buffer_timer <= 0.0:
		return
	if coyote_timer <= 0.0 and not is_on_floor():
		if is_on_wall_only() or wall_timer > 0.0:
			var wall_normal = get_wall_normal()
			velocity.y = jump_force * 0.95
			velocity.x = -wall_normal.x * wall_jump_push
			wall_timer = 0.0
			can_double_jump = true
			_spawn_jump_dust()
			if sfx_jump:
				sfx_jump.play()
			jump_buffer_timer = 0.0
			return
		if can_double_jump:
			velocity.y = jump_force * 0.85
			can_double_jump = false
			jump_buffer_timer = 0.0
			_spawn_jump_dust()
			if sfx_jump:
				sfx_jump.play()
		return
	velocity.y = jump_force
	can_double_jump = true
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	_spawn_jump_dust()
	if sfx_jump:
		sfx_jump.play()

func _update_visual_feedback(_delta: float) -> void:
	if not has_node("Body"):
		return

	var body := $Body
	body.scale.x = float(facing)

	var move_t := Time.get_ticks_msec() / 120.0
	var speed_ratio: float = clampf(absf(velocity.x) / max_speed, 0.0, 1.0)
	body.position.y = sin(move_t) * 0.8 * speed_ratio

	if body.has_node("LegL") and body.has_node("LegR"):
		body.get_node("LegL").position.y = 4 + sin(move_t * 1.5) * 1.8 * speed_ratio
		body.get_node("LegR").position.y = 4 + sin(move_t * 1.5 + PI) * 1.8 * speed_ratio

	# 冲刺时拉伸效果
	if is_dashing:
		body.scale.x = float(facing) * 1.3
		body.scale.y = 0.7

	# 无敌/受伤闪烁
	if invincible:
		body.modulate.a = 0.45 if int(Time.get_ticks_msec() / 70) % 2 == 0 else 1.0
	else:
		body.modulate.a = 0.45 if stealth_timer > 0.0 else 1.0

	# 旋转攻击时显示刀光
	if is_spinning:
		if body.has_node("Blade"):
			var blade := body.get_node("Blade")
			blade.modulate = Color(1.0, 0.8, 0.3, 0.8)
			blade.scale = Vector2(1.8, 1.8)
	else:
		if body.has_node("Blade"):
			body.get_node("Blade").scale = Vector2(1, 1)

func take_damage(amount := 1) -> void:
	if invincible:
		return
	hp -= amount
	invincible = true
	invincible_timer = 0.75
	_start_hit_stop(0.045, 0.12)
	_hurt_flash()
	if sfx_hurt:
		sfx_hurt.play()
	health_changed.emit(hp, max_hp)
	if hp <= 0:
		die()

func die() -> void:
	hp = max_hp
	invincible = true
	invincible_timer = 1.8
	health_changed.emit(hp, max_hp)
	died.emit()

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	health_changed.emit(hp, max_hp)

func try_attack() -> bool:
	if attack_timer > 0.0:
		return false
	attack_timer = attack_cooldown
	attack_lock_timer = _attack_lock_duration()

	var result = _character_attack()
	if result["killed"] > 0:
		enemy_killed.emit(result["killed"])
	return result["hit"]

func _attack_lock_duration() -> float:
	match character_id:
		"warrior":
			return 0.10
		"assassin":
			return 0.05
		"mage":
			return 0.08
		"archer":
			return 0.07
		_:
			return 0.08

func _use_skill(slot: String) -> void:
	if skill_cooldowns.get(slot, 0.0) > 0.0:
		return
	var skill_name = _skill_for_slot(slot)
	match skill_name:
		"flight":
			_start_flight()
		"beam":
			_start_beam()
		"spike":
			_start_spike()
		"stealth":
			_start_stealth()
		_:
			_start_spike()
	skill_used.emit(skill_name)

func _character_attack() -> Dictionary:
	match character_id:
		"warrior":
			velocity.x += 80.0 * float(facing)
			return _melee_attack(62.0, 26.0, slash_color, false, 0.0, Vector2(70 * facing, -10))
		"assassin":
			velocity.x += 160.0 * float(facing)
			return _melee_attack(38.0, 16.0, slash_color, true, backstab_mult, Vector2(20 * facing, -4))
		"mage":
			return _spawn_projectile_attack(260.0, 520.0, slash_color)
		"priest":
			var res = _melee_attack(44.0, 20.0, slash_color, false, 0.0, Vector2.ZERO)
			if res["hit"]:
				heal(1)
			return res
		"archer":
			return _line_attack(190.0, 18.0, slash_color, Vector2(25 * facing, -4))
		_:
			return _melee_attack(attack_range, 20.0, slash_color, false, 0.0, Vector2.ZERO)

func _melee_attack(range: float, width: float, color: Color, allow_backstab: bool, backstab_multiplier: float, knockback: Vector2) -> Dictionary:
	range *= weapon_damage_mult
	var dmg = attack_damage * weapon_damage_mult
	var killed := 0
	var hit_any := false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D) or not is_instance_valid(enemy):
			continue
		var delta_pos: Vector2 = enemy.global_position - global_position
		if delta_pos.length() > range:
			continue
		if not allow_backstab:
			if signf(delta_pos.x) != float(facing) and absf(delta_pos.x) > 6.0:
				continue
		if absf(delta_pos.y) > width:
			continue
		var final_dmg = dmg
		if allow_backstab and delta_pos.x * float(facing) < 0.0:
			final_dmg *= backstab_multiplier
		if _apply_damage(enemy, final_dmg, knockback):
			killed += 1
		hit_any = true
	_attack_feedback()
	_spawn_sword_slash_color(color, 1.0)
	return {"hit": hit_any, "killed": killed}

func _line_attack(range: float, width: float, color: Color, knockback: Vector2) -> Dictionary:
	range *= weapon_damage_mult
	var dmg = attack_damage * weapon_damage_mult
	var killed := 0
	var hit_any := false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D) or not is_instance_valid(enemy):
			continue
		var delta_pos: Vector2 = enemy.global_position - global_position
		if signf(delta_pos.x) != float(facing) and absf(delta_pos.x) > 6.0:
			continue
		if delta_pos.length() > range:
			continue
		if absf(delta_pos.y) > width:
			continue
		if _apply_damage(enemy, dmg, knockback):
			killed += 1
		hit_any = true
	_attack_feedback()
	_spawn_sword_slash_color(color, 1.2)
	return {"hit": hit_any, "killed": killed}

func _apply_damage(enemy: Node2D, dmg: float, knockback: Vector2) -> bool:
	var hp_val = 1.0
	if enemy.has_meta("hp"):
		hp_val = float(enemy.get_meta("hp"))
	hp_val -= dmg
	if hp_val <= 0.0:
		enemy.queue_free()
		return true
	enemy.set_meta("hp", hp_val)
	if knockback.length() > 0.0:
		if enemy.has_meta("type"):
			match String(enemy.get_meta("type")):
				"golem":
					knockback *= 0.5
				"beetle":
					knockback *= 0.8
		if enemy.has_meta("hit_knockback"):
			var existing: Vector2 = enemy.get_meta("hit_knockback")
			enemy.set_meta("hit_knockback", existing + knockback)
		else:
			enemy.set_meta("hit_knockback", knockback)
	# small hit flash
	if enemy.get_child_count() > 0:
		var child = enemy.get_child(0)
		if child is CanvasItem:
			child.modulate = Color(1.2, 1.2, 1.2)
			var t := create_tween()
			t.tween_property(child, "modulate", Color.WHITE, 0.08)
	var dir: Vector2 = (enemy.global_position - global_position).normalized()
	hit_lunge_dir = dir
	hit_lunge_timer = 0.04
	_start_hit_stop(0.03, 0.16)
	_spawn_hit_spark(enemy.global_position)
	return false

func _start_hit_stop(duration: float, slow_scale: float) -> void:
	if hit_stop_timer > 0.0:
		return
	hit_stop_timer = duration
	Engine.time_scale = clampf(slow_scale, 0.05, 1.0)

func _check_contact_damage() -> void:
	if invincible or contact_timer > 0.0:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D) or not is_instance_valid(enemy):
			continue
		var hit_radius := 18.0
		if enemy.has_meta("hit_radius"):
			hit_radius = float(enemy.get_meta("hit_radius")) + 4.0
		var dist := global_position.distance_to(enemy.global_position)
		if dist > hit_radius:
			continue
		var dmg := 1.0
		if enemy.has_meta("contact_damage"):
			dmg = float(enemy.get_meta("contact_damage"))
		take_damage(int(ceil(dmg)))
		contact_timer = contact_cooldown
		var dir: Vector2 = (global_position - enemy.global_position).normalized()
		var kb = Vector2(240.0, -140.0)
		if enemy.has_meta("contact_knockback"):
			kb = enemy.get_meta("contact_knockback")
		velocity = Vector2(dir.x * kb.x, kb.y)
		_spawn_dust(global_position + Vector2(0, 8), 6, 18, Color(0.8, 0.6, 0.6, 0.8))
		return

func _spawn_projectile_attack(range: float, speed: float, color: Color) -> Dictionary:
	var proj_script = load("res://scripts/projectile.gd")
	if proj_script == null:
		return _line_attack(range, 26.0, color, Vector2.ZERO)
	var proj := Node2D.new()
	proj.set_script(proj_script)
	proj.global_position = global_position + Vector2(10 * facing, -6)
	proj.velocity = Vector2(speed * facing, 0)
	proj.damage = attack_damage * weapon_damage_mult
	proj.lifetime = range / max(1.0, speed)
	proj.hit_radius = 14.0
	proj.color = color
	get_parent().add_child(proj)
	_attack_feedback()
	return {"hit": true, "killed": 0}

func _use_warrior_skill(slot: String) -> void:
	match slot:
		"primary":
			_start_spin_attack()
		"secondary":
			_start_guard(0.6)
		"utility":
			_start_charge()

func _use_assassin_skill(slot: String) -> void:
	match slot:
		"primary":
			_start_dash_strike()
		"secondary":
			_start_backstep()
		"utility":
			_start_smoke()

func _use_mage_skill(slot: String) -> void:
	match slot:
		"primary":
			_start_fire_bolt()
		"secondary":
			_start_frost_nova()
		"utility":
			_start_blink()

func _use_priest_skill(slot: String) -> void:
	match slot:
		"primary":
			_use_heal()
		"secondary":
			_start_guard(1.0)
		"utility":
			_start_smite()

func _use_archer_skill(slot: String) -> void:
	match slot:
		"primary":
			_start_multishot()
		"secondary":
			_start_leap()
		"utility":
			_start_piercing_shot()

func _start_guard(duration: float) -> void:
	invincible = true
	invincible_timer = duration
	skill_cooldowns["secondary"] = 1.2
	_hurt_flash()

func _start_charge() -> void:
	is_dashing = true
	skill_cooldowns["utility"] = 1.5
	skill_durations["secondary"] = 0.2
	dash_direction = Vector2(float(facing), 0)
	_spawn_sword_slash_color(Color(1.0, 0.8, 0.3, 0.9), 1.4)

func _start_dash_strike() -> void:
	is_dashing = true
	skill_cooldowns["primary"] = 0.9
	skill_durations["primary"] = 0.12
	dash_direction = Vector2(float(facing), 0)
	_melee_attack(60.0, 24.0, Color(1.0, 0.5, 0.6, 0.9), false, 0.0, Vector2.ZERO)

func _start_backstep() -> void:
	is_dashing = true
	skill_cooldowns["secondary"] = 1.2
	skill_durations["secondary"] = 0.1
	dash_direction = Vector2(-float(facing), 0)
	invincible = true
	invincible_timer = 0.2

func _start_smoke() -> void:
	skill_cooldowns["utility"] = 2.0
	invincible = true
	invincible_timer = 0.4
	_spawn_dust(global_position, 12, 28, Color(0.3, 0.3, 0.35, 0.7))

func _start_fire_bolt() -> void:
	skill_cooldowns["primary"] = 1.2
	_line_attack(200.0, 26.0, Color(1.0, 0.5, 0.2, 0.9), Vector2.ZERO)

func _start_frost_nova() -> void:
	skill_cooldowns["secondary"] = 1.5
	_melee_attack(70.0, 70.0, Color(0.6, 0.9, 1.0, 0.9), false, 0.0, Vector2.ZERO)

func _start_blink() -> void:
	skill_cooldowns["utility"] = 2.0
	global_position.x += 120.0 * float(facing)
	_spawn_dust(global_position, 10, 24, Color(0.6, 0.8, 1.0, 0.6))

func _start_smite() -> void:
	skill_cooldowns["utility"] = 1.8
	_line_attack(160.0, 20.0, Color(1.0, 1.0, 0.6, 0.9), Vector2.ZERO)

func _start_multishot() -> void:
	skill_cooldowns["primary"] = 1.0
	_line_attack(160.0, 16.0, Color(0.6, 1.0, 0.7, 0.9), Vector2.ZERO)
	_line_attack(160.0, 28.0, Color(0.6, 1.0, 0.7, 0.6), Vector2.ZERO)

func _start_leap() -> void:
	skill_cooldowns["secondary"] = 1.5
	velocity.y = jump_force * 1.2
	_spawn_jump_dust()

func _start_piercing_shot() -> void:
	skill_cooldowns["utility"] = 2.2
	_line_attack(220.0, 14.0, Color(0.4, 1.0, 0.6, 0.9), Vector2.ZERO)

func _init_skill_slots() -> void:
	if skill_slots.size() == 0:
		skill_slots = ["flight", "beam", "spike"]

func _skill_for_slot(slot: String) -> String:
	match slot:
		"primary":
			return skill_slots[0]
		"secondary":
			return skill_slots[1]
		"utility":
			return skill_slots[2]
		_:
			return "spike"

func _cycle_skill(index: int) -> void:
	if index < 0 or index >= skill_slots.size():
		return
	var current = skill_slots[index]
	var idx = skill_pool.find(current)
	if idx < 0:
		skill_slots[index] = skill_pool[0]
		skills_changed.emit(skill_slots)
		return
	var next = (idx + 1) % skill_pool.size()
	skill_slots[index] = skill_pool[next]
	skills_changed.emit(skill_slots)

func _start_flight() -> void:
	skill_cooldowns["primary"] = 2.5
	is_flying = true
	fly_timer = 1.2
	_spawn_jump_dust()

func _start_beam() -> void:
	skill_cooldowns["primary"] = 1.8
	_line_attack(220.0, 28.0, Color(0.6, 0.9, 1.0, 0.9), Vector2.ZERO)

func _start_spike() -> void:
	skill_cooldowns["primary"] = 1.6
	_melee_attack(70.0, 60.0, Color(0.6, 1.0, 0.6, 0.9), false, 0.0, Vector2.ZERO)
	_spawn_dust(global_position + Vector2(0, 10), 10, 26, Color(0.4, 0.8, 0.4, 0.8))

func _start_stealth() -> void:
	skill_cooldowns["primary"] = 3.0
	stealth_timer = 1.5

func is_stealthed() -> bool:
	return stealth_timer > 0.0

func set_weapon(weapon: Dictionary) -> void:
	weapon_name = String(weapon.get("name", "Rusty Blade"))
	weapon_rarity = String(weapon.get("rarity", "common"))
	weapon_mod = String(weapon.get("mod", ""))
	weapon_damage_mult = float(weapon.get("damage_mult", 1.0))

func _start_spin_attack() -> void:
	is_spinning = true
	skill_cooldowns["primary"] = 1.5
	skill_durations["primary"] = 0.35

	# 360度攻击周围敌人
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist <= spin_damage_range:
			_apply_damage(enemy, attack_damage * weapon_damage_mult, Vector2.ZERO)

	_attack_feedback()

	# 旋转动画
	var body := $Body
	var t := create_tween()
	t.tween_property(body, "rotation", deg_to_rad(360), 0.35).set_trans(Tween.TRANS_QUAD)
	t.tween_property(body, "rotation", 0.0, 0.01)

func _start_dash() -> void:
	is_dashing = true
	skill_cooldowns["secondary"] = dash_cooldown
	skill_durations["secondary"] = dash_duration
	dash_direction = Vector2(float(facing), 0)

	# 临时无敌
	invincible = true
	invincible_timer = dash_duration + 0.1

func _use_heal() -> void:
	if hp >= max_hp:
		return
	skill_cooldowns["utility"] = heal_cooldown
	heal(heal_amount)

	# 治疗特效
	var body := $Body
	body.modulate = Color(0.4, 1.0, 0.4)
	var t := create_tween()
	t.tween_property(body, "modulate", Color.WHITE, 0.4)

func _attack_feedback() -> void:
	if not has_node("Body"):
		return
	var body := $Body
	body.modulate = Color(1.25, 1.25, 1.25)
	var t := create_tween()
	t.tween_property(body, "modulate", Color.WHITE, 0.10)

	if body.has_node("Blade"):
		var blade := body.get_node("Blade")
		if blade is CanvasItem:
			blade.modulate = Color(1.6, 1.6, 1.6)
			t.tween_property(blade, "modulate", Color.WHITE, 0.10)
	_spawn_sword_slash()
	if sfx_attack:
		sfx_attack.play()

	# 攻击动作：只动武器，避免“挥手向下”
	if body.has_node("Blade"):
		var blade := body.get_node("Blade")
		if blade is CanvasItem:
			var swing_rot := deg_to_rad(-18.0 * float(facing))
			match character_id:
				"warrior":
					swing_rot = deg_to_rad(-22.0 * float(facing))
				"assassin":
					swing_rot = deg_to_rad(-26.0 * float(facing))
				"mage":
					swing_rot = deg_to_rad(-14.0 * float(facing))
				"archer":
					swing_rot = deg_to_rad(-18.0 * float(facing))
			var tween := create_tween()
			tween.tween_property(blade, "rotation", swing_rot, 0.05)
			tween.tween_property(blade, "rotation", 0.0, 0.08)

func _spawn_sword_slash() -> void:
	_spawn_sword_slash_color(slash_color, 1.0)

func _spawn_sword_slash_color(color: Color, scale: float) -> void:
	var container = get_parent() if get_parent() != null else self
	var base_pos = global_position + Vector2(16 * facing, -12)
	var rot = deg_to_rad(-20 * facing)
	var sizes = [Vector2(26, 4), Vector2(20, 3), Vector2(14, 2)]
	var alphas = [0.9, 0.6, 0.4]
	for i in range(sizes.size()):
		var slash := Sprite2D.new()
		slash.texture = _solid_texture(int(sizes[i].x), int(sizes[i].y), color)
		slash.centered = true
		slash.z_index = 20 + i
		slash.global_position = base_pos + Vector2(2 * i * facing, -2 * i)
		slash.rotation = rot
		slash.scale = Vector2(1.0 + 0.2 * i, 1.0) * scale
		slash.modulate.a = alphas[i]
		container.add_child(slash)
		var t := create_tween()
		t.tween_property(slash, "scale", slash.scale * Vector2(1.2, 1.1), 0.06)
		t.tween_property(slash, "modulate", Color(1, 1, 1, 0), 0.10)
		t.tween_callback(slash.queue_free)

func _hurt_flash() -> void:
	if not has_node("Body"):
		return
	var body := $Body
	body.modulate = Color(1.4, 0.6, 0.6, 1.0)
	var t := create_tween()
	t.tween_property(body, "modulate", Color.WHITE, 0.18)

func _spawn_jump_dust() -> void:
	_spawn_dust(global_position + Vector2(0, 12), 6, 18, Color(0.7, 0.7, 0.7, 0.7))

func _spawn_land_dust() -> void:
	_spawn_dust(global_position + Vector2(0, 12), 8, 22, Color(0.6, 0.6, 0.6, 0.8))

func _spawn_dust(origin: Vector2, count: int, spread: float, color: Color) -> void:
	var container = get_parent() if get_parent() != null else self
	for i in range(count):
		var p := Sprite2D.new()
		var size = 3 + randi() % 4
		p.texture = _solid_texture(size, size, color)
		p.centered = true
		p.z_index = 5
		p.global_position = origin + Vector2(randf_range(-spread, spread), randf_range(-4, 4))
		container.add_child(p)
		var t := create_tween()
		var dx = randf_range(-8, 8)
		var dy = randf_range(-8, -2)
		t.tween_property(p, "global_position", p.global_position + Vector2(dx, dy), 0.22)
		t.tween_property(p, "modulate", Color(color.r, color.g, color.b, 0.0), 0.18)
		t.tween_callback(p.queue_free)

func _spawn_hit_spark(origin: Vector2) -> void:
	var container = get_parent() if get_parent() != null else self
	for i in range(5):
		var p := Sprite2D.new()
		p.texture = _solid_texture(2, 2, Color(1.0, 0.8, 0.4, 0.9))
		p.centered = true
		p.z_index = 15
		p.global_position = origin + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		container.add_child(p)
		var t := create_tween()
		var dx = randf_range(-14, 14)
		var dy = randf_range(-12, 2)
		t.tween_property(p, "global_position", p.global_position + Vector2(dx, dy), 0.12)
		t.tween_property(p, "modulate", Color(1, 1, 1, 0), 0.12)
		t.tween_callback(p.queue_free)
