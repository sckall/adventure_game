extends CharacterBody2D

# 骷髅敌人 - 追踪玩家
@export var hp: int = 3
@export var max_hp: int = 3
@export var detection_range: float = 250.0
@export var move_speed: float = 70.0

var player: CharacterBody2D = null
var original_color: Color
var walk_time: float = 0.0
var is_chasing: bool = false

@onready var skull = $Skull
@onready var audio = get_node("/root/AudioManager")
@onready var jaw = $Jaw
@onready var eyes = $Eyes
@onready var hurt_area = $HurtArea

func _ready():
	original_color = Color(0.9, 0.9, 0.85)
	update_appearance()

	# 查找玩家
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func update_appearance():
	skull.color = original_color
	jaw.color = original_color

func _physics_process(delta):
	# 坠落死亡检测
	if position.y > 1200:
		die()
		return
		
	walk_time += delta

	# 检测玩家距离
	if player and is_instance_valid(player):
		var dist_to_player = global_position.distance_to(player.global_position)

		if dist_to_player < detection_range:
			is_chasing = true
		elif dist_to_player > detection_range + 50:
			is_chasing = false

	# 追踪玩家
	if is_chasing and player and is_instance_valid(player):
		var dir_to_player = (player.global_position - global_position).normalized()
		velocity.x = dir_to_player.x * move_speed
	else:
		velocity.x = 0

	# 跳跃移动（每隔一段时间）
	if is_chasing and is_on_floor() and sin(walk_time * 2) > 0.95:
		velocity.y = -200

	# 应用重力
	velocity.y += 800 * delta

	move_and_slide()

	# 行走动画
	if abs(velocity.x) > 10:
		var bob = abs(sin(walk_time * 10)) * 3
		skull.position.y = -8 - bob
		jaw.position.y = 2 + bob

		# 面向移动方向
		if velocity.x > 0:
			scale.x = 1
		elif velocity.x < 0:
			scale.x = -1

func take_damage(amount: int, knockback_dir: Vector2):
	hp -= amount
	skull.color = Color(1, 1, 1)
	await get_tree().create_timer(0.1).timeout
	skull.color = original_color

	position += knockback_dir * 18

	if hp <= 0:
		die()

func die():
	audio.play_enemy_death()  # 播放敌人死亡音效

	# 骷髅散架效果
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.direction = Vector2(0, -1)
	particles.spread = 70
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 80
	particles.scale_min = 2.0
	particles.scale_max = 5.0
	particles.color = Color(0.9, 0.9, 0.85)
	particles.position = position
	get_parent().add_child(particles)

	await get_tree().create_timer(0.7).timeout
	particles.queue_free()
	queue_free()

func _on_hurt_area_body_entered(body):
	if body.name == "Player":
		body.take_damage()
