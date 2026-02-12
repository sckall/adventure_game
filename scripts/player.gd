extends Node2D

# ============ 玩家 ============

signal died
signal health_changed(current, max)

var hp = 3
var max_hp = 3
var speed = 200.0
var jump_force = -400.0
var gravity = 800.0
var velocity = Vector2.ZERO
var is_on_ground = false
var invincible = false
var invincible_timer = 0.0

func _ready():
	add_to_group("player")

func _physics_process(delta):
	# 重力
	velocity.y += gravity * delta
	
	# 左右移动
	var input_x = Input.get_axis("ui_left", "ui_right")
	velocity.x = input_x * speed
	
	# 跳跃
	if Input.is_action_just_pressed("ui_accept") and is_on_ground:
		velocity.y = jump_force
		is_on_ground = false
	
	# 应用移动
	move_and_slide()
	
	# 检测地面
	is_on_ground = false
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_normal().y > 0.5:
			is_on_ground = true
	
	# 无敌计时
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false
	
	# 掉落死亡
	if position.y > 1000:
		die()

func take_damage():
	if invincible:
		return
	hp -= 1
	invincible = true
	invincible_timer = 1.0
	health_changed.emit(hp, max_hp)
	
	if hp <= 0:
		die()

func die():
	hp = max_hp
	position = Vector2(100, 500)
	invincible = true
	invincible_timer = 2.0
	died.emit()

func heal(amount):
	hp = min(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)
