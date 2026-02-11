extends CharacterBody2D

# 蜗牛敌人 - 移动极慢但HP很高
@export var color_name: String = "green"
@export var patrol_distance: float = 50.0
@export var hp: int = 6
@export var max_hp: int = 6
@export var detect_range: float = 300.0  # 追踪视野范围
@export var move_speed: float = 30.0
@export var knockback_force: float = 15.0

var start_x: float = 0.0
var direction: int = 1
var original_color: Color
var in_shell: bool = false
var is_tracking: bool = false
var player: Node2D = null

@onready var shell = $Shell
@onready var audio = get_node("/root/AudioManager")
@onready var body = $Body
@onready var hurt_area = $HurtArea

func _ready():
	start_x = position.x
	original_color = get_snail_color(color_name)
	update_appearance()
	
	# 查找玩家
	player = get_tree().get_first_node_in_group("player")

func get_snail_color(name: String) -> Color:
	var colors = {
		"green": Color(0.5, 0.7, 0.3),
		"pink": Color(0.8, 0.5, 0.6),
		"blue": Color(0.4, 0.5, 0.7)
	}
	return colors.get(name, Color(0.5, 0.7, 0.3))

func update_appearance():
	shell.color = Color(0.7, 0.5, 0.3)
	body.color = original_color

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
	
	var speed = 15 if not is_tracking else move_speed
	if in_shell:
		speed = 5
	
	velocity.x = direction * speed
	move_and_slide()

	# 巡逻边界
	if position.x > start_x + patrol_distance:
		direction = -1
		scale.x = -1
	elif position.x < start_x - patrol_distance:
		direction = 1
		scale.x = 1

	# 缩壳时隐藏身体
	if in_shell:
		body.visible = false
		shell.scale = Vector2(1.1, 1.1)
	else:
		body.visible = true
		shell.scale = Vector2(1, 1)

func take_damage(amount: int, knockback_dir: Vector2):
	# 缩壳时伤害减半
	if in_shell:
		amount = max(1, amount / 2)

	hp -= amount
	in_shell = true

	shell.color = Color(1, 1, 1)
	await get_tree().create_timer(0.2).timeout
	shell.color = Color(0.7, 0.5, 0.3)
	in_shell = false

	position += knockback_dir * knockback_force

	if hp <= 0:
		die()

func die():
	audio.play_enemy_death()  # 播放敌人死亡音效

	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 25
	particles.lifetime = 0.7
	particles.one_shot = true
	particles.direction = Vector2(0, -1)
	particles.spread = 60
	particles.initial_velocity_min = 25
	particles.initial_velocity_max = 60
	particles.scale_min = 3.0
	particles.scale_max = 6.0
	particles.color = Color(0.7, 0.5, 0.3)
	particles.position = position
	get_parent().add_child(particles)

	await get_tree().create_timer(0.8).timeout
	particles.queue_free()
	queue_free()

func _on_hurt_area_body_entered(_body):
	if _body.name == "Player":
		_body.take_damage()
