extends CharacterBody2D

# ============ 玩家(像素地牢风格) ============

signal died
signal health_changed(current, max)

var hp := 4
var max_hp := 4
var speed := 180.0
var jump_force := -360.0
var gravity := 900.0
var invincible := false
var invincible_timer := 0.0
var attack_cooldown := 0.25
var attack_timer := 0.0
var attack_range := 40.0
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
	velocity.y += gravity * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * speed
	if velocity.x > 0.01:
		facing = 1
	elif velocity.x < -0.01:
		facing = -1

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()

	if attack_timer > 0.0:
		attack_timer -= delta

	if invincible:
		invincible_timer -= delta
		if has_node("Body"):
			$Body.modulate.a = 0.45 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		if invincible_timer <= 0:
			invincible = false
			if has_node("Body"):
				$Body.modulate.a = 1.0

	if position.y > 1200:
		die()

func take_damage(amount := 1) -> void:
	if invincible:
		return
	hp -= amount
	invincible = true
	invincible_timer = 0.8
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
