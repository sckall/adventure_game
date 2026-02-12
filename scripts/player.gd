extends CharacterBody2D

# ============ 玩家(像素地牢风格) ============

signal died
signal health_changed(current, max)

var hp := 4
var max_hp := 4

var max_speed := 190.0
var acceleration := 1050.0
var deceleration := 1200.0
var jump_force := -370.0
var gravity := 980.0
var fall_gravity_scale := 1.28

var coyote_time := 0.10
var coyote_timer := 0.0
var jump_buffer_time := 0.12
var jump_buffer_timer := 0.0

var invincible := false
var invincible_timer := 0.0

var attack_cooldown := 0.22
var attack_timer := 0.0
var attack_range := 42.0
var facing := 1

func _ready() -> void:
	add_to_group("player")
	_setup_visual_and_collision()
	health_changed.emit(hp, max_hp)

func _setup_visual_and_collision() -> void:
	if not has_node("CollisionShape2D"):
		var collision := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(20, 28)
		collision.shape = rect
		add_child(collision)

	if not has_node("Body"):
		var body := ColorRect.new()
		body.name = "Body"
		body.size = Vector2(18, 26)
		body.position = Vector2(-9, -13)
		body.color = Color(0.22, 0.75, 0.95)
		add_child(body)

		var visor := ColorRect.new()
		visor.name = "Visor"
		visor.size = Vector2(12, 5)
		visor.position = Vector2(3, 5)
		visor.color = Color(0.95, 0.98, 1.0)
		body.add_child(visor)

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_apply_horizontal_movement(delta)
	_apply_vertical_movement(delta)
	_try_consume_buffered_jump()
	move_and_slide()
	_update_visual_feedback(delta)

	if position.y > 1200:
		die()

func _update_timers(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	if is_on_floor():
		coyote_timer = coyote_time
	elif coyote_timer > 0.0:
		coyote_timer -= delta

	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false

func _apply_horizontal_movement(delta: float) -> void:
	var axis := Input.get_axis("ui_left", "ui_right")
	if axis > 0.01:
		facing = 1
	elif axis < -0.01:
		facing = -1

	var target_speed := axis * max_speed
	var rate := acceleration if absf(target_speed) > 0.01 else deceleration
	velocity.x = move_toward(velocity.x, target_speed, rate * delta)

func _apply_vertical_movement(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time

	var current_gravity := gravity * (fall_gravity_scale if velocity.y > 0.0 else 1.0)
	velocity.y += current_gravity * delta

	# 松开跳跃键会进行短跳，提升操作精度
	if Input.is_action_just_released("ui_accept") and velocity.y < -120.0:
		velocity.y *= 0.58

func _try_consume_buffered_jump() -> void:
	if jump_buffer_timer <= 0.0:
		return
	if coyote_timer <= 0.0 and not is_on_floor():
		return
	velocity.y = jump_force
	jump_buffer_timer = 0.0
	coyote_timer = 0.0

func _update_visual_feedback(_delta: float) -> void:
	if not has_node("Body"):
		return

	if invincible:
		$Body.modulate.a = 0.45 if int(Time.get_ticks_msec() / 70) % 2 == 0 else 1.0
	else:
		$Body.modulate.a = 1.0

func take_damage(amount := 1) -> void:
	if invincible:
		return
	hp -= amount
	invincible = true
	invincible_timer = 0.75
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
	return true
