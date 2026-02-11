extends CharacterBody2D

# 史莱姆配置
@export var color_name: String = "green"
@export var patrol_distance: float = 80.0
@export var hp: int = 3
@export var max_hp: int = 3
@export var detect_range: float = 400.0  # 追踪视野范围
@export var move_speed: float = 80.0
@export var knockback_force: float = 30.0

# 内部变量
var start_x: float = 0.0
var direction: int = 1
var original_color: Color
var is_tracking: bool = false
var player: Node2D = null

# 节点引用
@onready var body_rect = $Body
@onready var highlight = $Highlight
@onready var eyes_container = $EyesContainer
@onready var hurt_area = $HurtArea
@onready var health_bar = $HealthBar
@onready var audio = get_node("/root/AudioManager")

func _ready():
	start_x = position.x
	original_color = get_slime_color(color_name)
	update_appearance()
	
	# 查找玩家
	player = get_tree().get_first_node_in_group("player")

func get_slime_color(name: String) -> Color:
	var colors = {
		"green": Color(0.35, 0.85, 0.4),     # 鲜绿色史莱姆
		"blue": Color(0.35, 0.6, 0.95),      # 鲜蓝色史莱姆
		"pink": Color(0.95, 0.6, 0.8),       # 粉色史莱姆
		"yellow": Color(1.0, 0.95, 0.35),     # 黄色史莱姆
		"orange": Color(1.0, 0.65, 0.25),     # 橙色史莱姆
		"cyan": Color(0.35, 0.85, 0.85),      # 青色史莱姆
		"purple": Color(0.8, 0.45, 0.9),      # 紫色史莱姆
		"gray": Color(0.65, 0.65, 0.65),      # 灰色史莱姆
		"red": Color(0.95, 0.35, 0.35)        # 红色史莱姆
	}
	return colors.get(name, Color(0.35, 0.85, 0.4))

func update_appearance():
	body_rect.color = original_color
	highlight.color = Color(1, 1, 1, 0.3)

func _physics_process(_delta):
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
				velocity.x = move_speed
				scale.x = 1
			else:
				velocity.x = -move_speed
				scale.x = -1
		else:
			is_tracking = false
	
	if not is_tracking:
		# 巡逻移动
		velocity.x = direction * move_speed * 0.5
	
	# 应用重力
	if not is_on_floor():
		velocity.y += 500 * _delta
	
	move_and_slide()

	# 巡逻边界检查
	if not is_tracking:
		if position.x > start_x + patrol_distance:
			direction = -1
			scale.x = -1
		elif position.x < start_x - patrol_distance:
			direction = 1
			scale.x = 1

	# 跳跃动画
	if is_on_floor():
		var bounce = abs(sin(Time.get_ticks_msec() * 0.01)) * 3
		body_rect.position.y = -12 - bounce
		highlight.position.y = -10 - bounce
		eyes_container.position.y = -8 - bounce

# 玩家碰撞检测
func _on_hurt_area_body_entered(body):
	if body.name == "Player":
		body.take_damage()

# 受到伤害
func take_damage(amount: int, knockback_dir: Vector2):
	hp -= amount
	
	# 更新血条
	if health_bar:
		health_bar.value = float(hp) / float(max_hp) * 100
	
	# 受伤闪烁
	body_rect.color = Color(1, 1, 1)
	await get_tree().create_timer(0.1).timeout
	body_rect.color = original_color

	# 击退
	if knockback_dir != Vector2.ZERO:
		position += knockback_dir.normalized() * knockback_force * 0.5
	
	# 检查死亡
	if hp <= 0:
		die()

# 死亡
func die():
	audio.play_enemy_death()

	# 死亡粒子效果
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 15
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.direction = Vector2(0, -1)
	particles.spread = 60
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 80
	particles.scale_min = 3.0
	particles.scale_max = 6.0
	particles.color = original_color
	particles.position = position
	get_parent().add_child(particles)

	await get_tree().create_timer(0.6).timeout
	particles.queue_free()
	queue_free()
