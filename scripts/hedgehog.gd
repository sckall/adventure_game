extends CharacterBody2D

# 刺猬敌人 - 带刺，触碰受伤但移动缓慢
@export var color_name: String = "orange"
@export var patrol_distance: float = 60.0
@export var hp: int = 4
@export var max_hp: int = 4
@export var detect_range: float = 350.0  # 追踪视野范围
@export var move_speed: float = 50.0
@export var knockback_force: float = 25.0

var start_x: float = 0.0
var direction: int = 1
var original_color: Color
var is_rolling: bool = false
var is_tracking: bool = false
var player: Node2D = null

@onready var body = $Body
@onready var audio = get_node("/root/AudioManager")
@onready var spikes = $Spikes
@onready var hurt_area = $HurtArea

func _ready():
	start_x = position.x
	original_color = get_hedgehog_color(color_name)
	update_appearance()
	
	# 查找玩家
	player = get_tree().get_first_node_in_group("player")

func get_hedgehog_color(name: String) -> Color:
	var colors = {
		"orange": Color(0.9, 0.6, 0.3),
		"brown": Color(0.6, 0.4, 0.2),
		"gray": Color(0.5, 0.5, 0.5)
	}
	return colors.get(name, Color(0.9, 0.6, 0.3))

func update_appearance():
	body.color = original_color
	spikes.color = Color(0.3, 0.3, 0.3, 0.8)

func _physics_process(delta):
	# 坠落死亡检测
	if position.y > 1200:
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
			if player.position.x > position.x:
				direction = 1
			else:
				direction = -1
		else:
			is_tracking = false
	
	var speed = 30 if not is_tracking else move_speed
	if is_rolling:
		speed = 50
	
	velocity.x = direction * speed
	move_and_slide()

	# 巡逻边界
	if position.x > start_x + patrol_distance:
		direction = -1
		scale.x = -1
	elif position.x < start_x - patrol_distance:
		direction = 1
		scale.x = 1

	# 受到攻击时缩成球
	if is_rolling:
		body.scale = Vector2(0.8, 0.8)
		spikes.scale = Vector2(1.2, 1.2)
	else:
		body.scale = Vector2(1, 1)
		spikes.scale = Vector2(1, 1)

func take_damage(amount: int, knockback_dir: Vector2):
	hp -= amount
	is_rolling = true

	body.color = Color(1, 1, 1)
	await get_tree().create_timer(0.15).timeout
	body.color = original_color
	is_rolling = false

	position += knockback_dir * knockback_force * 0.5

	if hp <= 0:
		die()

func die():
	audio.play_enemy_death()  # 播放敌人死亡音效

	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 18
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.direction = Vector2(0, -1)
	particles.spread = 55
	particles.initial_velocity_min = 35
	particles.initial_velocity_max = 75
	particles.scale_min = 2.5
	particles.scale_max = 5.0
	particles.color = original_color
	particles.position = position
	get_parent().add_child(particles)

	await get_tree().create_timer(0.6).timeout
	particles.queue_free()
	queue_free()

func _on_hurt_area_body_entered(_body):
	if _body.name == "Player":
		_body.take_damage()
