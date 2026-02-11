extends CharacterBody2D

# 蝙蝠敌人 - 飞行怪
@export var color_name: String = "purple"
@export var fly_range: float = 100.0
@export var hp: int = 2
@export var max_hp: int = 2
@export var detect_range: float = 500.0  # 追踪视野范围
@export var fly_speed: float = 80.0
@export var knockback_force: float = 20.0

var start_y: float = 0.0
var direction: int = 1
var original_color: Color
var fly_time: float = 0.0
var is_tracking: bool = false
var player: Node2D = null

@onready var body = $Body
@onready var wing_left = $WingLeft
@onready var wing_right = $WingRight
@onready var health_bar = $HealthBar
@onready var audio = get_node("/root/AudioManager")

func _ready():
	start_y = position.y
	original_color = get_bat_color(color_name)
	update_appearance()
	
	# 查找玩家
	player = get_tree().get_first_node_in_group("player")

func get_bat_color(_name: String) -> Color:
	var colors = {
		"red": Color(0.9, 0.3, 0.3),
		"purple": Color(0.7, 0.3, 0.8),
		"blue": Color(0.3, 0.5, 0.9)
	}
	return colors.get(_name, Color(0.7, 0.3, 0.8))

func update_appearance():
	body.color = original_color
	wing_left.color = original_color
	wing_right.color = original_color

func _physics_process(delta):
	fly_time += delta
	
	# 坠落检测（蝙蝠不会坠落，但可以检测是否飞出边界）
	if position.y < -100 or position.y > 1300:
		die()
		return
	
	# 更新玩家引用
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	
	# 追踪逻辑
	if player and is_instance_valid(player):
		var dist_to_player = position.distance_to(player.position)
		if dist_to_player < detect_range:
			is_tracking = true
			# 向玩家移动
			var dir_to_player = (player.position - position).normalized()
			velocity.x = dir_to_player.x * fly_speed
			velocity.y = dir_to_player.y * fly_speed
			
			# 翻转朝向
			if dir_to_player.x > 0:
				scale.x = 1
			else:
				scale.x = -1
		else:
			is_tracking = false
	
	if not is_tracking:
		# 巡逻飞行
		velocity.x = direction * fly_speed * 0.6
		velocity.y = sin(fly_time * 3) * 40

	# 翅膀扇动动画
	var wing_flap = abs(sin(fly_time * 15)) * 8
	wing_left.position.y = -4 - wing_flap
	wing_right.position.y = -4 - wing_flap

	move_and_slide()

	# 巡逻边界检查
	if not is_tracking:
		if position.x > start_y + fly_range:
			direction = -1
			scale.x = -1
		elif position.x < start_y - fly_range:
			direction = 1
			scale.x = 1

func take_damage(_amount: int, knockback_dir: Vector2):
	hp -= 1
	
	# 更新血条
	if health_bar:
		health_bar.value = float(hp) / float(max_hp) * 100
	
	body.color = Color(1, 1, 1)
	await get_tree().create_timer(0.1).timeout
	body.color = original_color

	# 击退
	if knockback_dir != Vector2.ZERO:
		position += knockback_dir.normalized() * knockback_force * 0.3

	if hp <= 0:
		die()

func die():
	audio.play_enemy_death()

	# 死亡效果
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 10
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.direction = Vector2(0, -1)
	particles.spread = 50
	particles.initial_velocity_min = 40
	particles.initial_velocity_max = 70
	particles.scale_min = 2.0
	particles.scale_max = 4.0
	particles.color = original_color
	particles.position = position
	get_parent().add_child(particles)

	await get_tree().create_timer(0.5).timeout
	particles.queue_free()
	queue_free()

func _on_hurt_area_body_entered(_body):
	if _body.name == "Player":
		_body.take_damage()
