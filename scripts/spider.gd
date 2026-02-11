extends CharacterBody2D

# 蜘蛛配置
@export var color_name: String = "black"
@export var hp: int = 2
@export var max_hp: int = 2
@export var detect_range: float = 350.0  # 追踪视野范围
@export var move_speed: float = 100.0
@export var drop_speed: float = 150.0    # 下落速度
@export var climb_speed: float = 80.0    # 爬行速度
@export var knockback_force: float = 20.0

# 内部变量
var player: Node2D = null
var is_tracking: bool = false
var is_dropping: bool = false
var original_color: Color
var on_ceiling: bool = true  # 是否在天花板

# 节点引用
@onready var body = $Body
@onready var legs = $Legs
@onready var audio = get_node("/root/AudioManager")

func _ready():
	original_color = get_spider_color(color_name)
	update_appearance()
	player = get_tree().get_first_node_in_group("player")

func get_spider_color(name: String) -> Color:
	var colors = {
		"black": Color(0.1, 0.1, 0.1),       # 黑色蜘蛛
		"brown": Color(0.45, 0.25, 0.1),     # 棕色蜘蛛
		"red": Color(0.7, 0.15, 0.15),       # 红色毒蜘蛛
		"purple": Color(0.45, 0.2, 0.55)     # 紫色蜘蛛
	}
	return colors.get(name, Color(0.1, 0.1, 0.1))

func update_appearance():
	body.color = original_color
	legs.color = Color(original_color.r * 0.7, original_color.g * 0.7, original_color.b * 0.7, 1.0)

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
			# 玩家在下方则下落，在上方则爬行
			if player.position.y > position.y:
				is_dropping = true
				velocity.y = drop_speed
			else:
				is_dropping = false
				velocity.y = 0
				# 向玩家水平移动
				if player.position.x > position.x:
					velocity.x = climb_speed
					scale.x = 1
				else:
					velocity.x = -climb_speed
					scale.x = -1
		else:
			is_tracking = false
			is_dropping = false
			velocity.x = 0
	
	# 腿部动画
	var leg_offset = sin(Time.get_ticks_msec() * 0.02) * 2
	legs.position.x = leg_offset

	move_and_slide()

	# 玩家碰撞检测
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() and collision.get_collider().name == "Player":
			collision.get_collider().take_damage()

# 玩家碰撞检测
func _on_body_entered(_body):
	if _body.name == "Player":
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
		position += knockback_dir.normalized() * knockback_force * 5
	
	# 惊吓动画
	scale = Vector2(1.3, 0.7)
	await get_tree().create_timer(0.1).timeout
	scale = Vector2(1, 1)
	
	if hp <= 0:
		die()

# 死亡
func die():
	audio.play_enemy_death()

	# 死亡粒子效果
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 12
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.direction = Vector2(0, -1)
	particles.spread = 90
	particles.initial_velocity_min = 20
	particles.initial_velocity_max = 60
	particles.scale_min = 2.0
	particles.scale_max = 5.0
	particles.color = original_color
	particles.position = position
	get_parent().add_child(particles)

	await get_tree().create_timer(0.5).timeout
	particles.queue_free()
	queue_free()
