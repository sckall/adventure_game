extends CharacterBody2D

# 蛇配置
@export var color_name: String = "green"
@export var hp: int = 1
@export var max_hp: int = 1
@export var detect_range: float = 200.0  # 短距离伏击
@export var move_speed: float = 120.0     # 冲刺速度快
@export var attack_cooldown: float = 2.0  # 攻击冷却
@export var knockback_force: float = 40.0

# 内部变量
var player: Node2D = null
var is_ambushing: bool = false
var can_attack: bool = true
var original_color: Color
var attack_timer: float = 0.0

# 节点引用
@onready var body = $Body
@onready var tongue = $Tongue
@onready var eyes = $Eyes
@onready var audio = get_node("/root/AudioManager")

func _ready():
	original_color = get_snake_color(color_name)
	update_appearance()
	player = get_tree().get_first_node_in_group("player")

func get_snake_color(name: String) -> Color:
	var colors = {
		"green": Color(0.3, 0.7, 0.3),       # 绿色草蛇
		"red": Color(0.8, 0.2, 0.2),         # 红色毒蛇
		"yellow": Color(0.9, 0.8, 0.2),      # 黄色蛇
		"blue": Color(0.3, 0.5, 0.9),        # 蓝色蛇
		"purple": Color(0.6, 0.3, 0.7)       # 紫色蛇
	}
	return colors.get(name, Color(0.3, 0.7, 0.3))

func update_appearance():
	body.color = original_color
	tongue.color = Color(0.9, 0.3, 0.3, 0.8)
	eyes.color = Color(1, 1, 0.3)

func _physics_process(_delta):
	# 坠落死亡检测
	if position.y > 1200:
		die()
		return
	
	# 更新玩家引用
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	
	# 更新攻击冷却
	if not can_attack:
		attack_timer -= _delta
		if attack_timer <= 0:
			can_attack = true
	
	# 伏击逻辑
	if player and is_instance_valid(player):
		var dist_to_player = position.distance_to(player.position)
		if dist_to_player < detect_range and can_attack:
			is_ambushing = true
			# 快速冲向玩家
			if player.position.x > position.x:
				velocity.x = move_speed
				scale.x = 1
			else:
				velocity.x = -move_speed
				scale.x = -1
			velocity.y = 0
		else:
			is_ambushing = false
			velocity.x = 0
	
	# 蛇形移动动画
	var wave = sin(Time.get_ticks_msec() * 0.01) * 3
	body.position.y = wave
	tongue.position.x = scale.x * 15
	tongue.visible = is_ambushing

	move_and_slide()

	# 玩家碰撞检测
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() and collision.get_collider().name == "Player":
			if is_ambushing:
				collision.get_collider().take_damage()
				can_attack = false
				attack_timer = attack_cooldown
				is_ambushing = false

# 玩家碰撞检测
func _on_body_entered(_body):
	if _body.name == "Player":
		if is_ambushing:
			_body.take_damage()

# 受到伤害
func take_damage(amount: int, knockback_dir: Vector2):
	hp -= amount
	
	# 受伤闪烁
	body.color = Color(1, 1, 1)
	await get_tree().create_timer(0.1).timeout
	body.color = original_color

	# 击退
	if knockback_dir != Vector2.ZERO:
		position += knockback_dir.normalized() * knockback_force * 8
	
	# 蜷缩动画
	scale = Vector2(0.8, 1.2)
	await get_tree().create_timer(0.15).timeout
	scale = Vector2(1, 1)
	
	if hp <= 0:
		die()

# 死亡
func die():
	audio.play_enemy_death()

	# 死亡粒子效果
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 10
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.direction = Vector2(0, -1)
	particles.spread = 45
	particles.initial_velocity_min = 25
	particles.initial_velocity_max = 50
	particles.scale_min = 2.0
	particles.scale_max = 4.0
	particles.color = original_color
	particles.position = position
	get_parent().add_child(particles)

	await get_tree().create_timer(0.5).timeout
	particles.queue_free()
	queue_free()
