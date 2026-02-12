extends Area2D

# ============ 道具拾取物 ============

var item_data: Dictionary = {}
var float_offset: float = 0.0

@onready var rect = $ColorRect
@onready var glow = $Glow

func setup(data: Dictionary):
	item_data = data
	
	# 设置颜色
	rect.color = _get_rarity_color()
	glow.color = _get_rarity_color()
	
	# 添加标签
	var label = Label.new()
	label.name = "Label"
	label.text = item_data.name
	label.add_theme_font_size_override("font_size", 12)
	label.position = Vector2(-30, 25)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

func _ready():
	# 碰撞
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15
	collision.shape = shape
	add_child(collision)
	
	# 可视
	rect = ColorRect.new()
	rect.size = Vector2(24, 24)
	rect.position = Vector2(-12, -12)
	add_child(rect)
	
	glow = ColorRect.new()
	glow.size = Vector2(32, 32)
	glow.position = Vector2(-16, -16)
	glow.modulate.a = 0.3
	glow.z_index = -1
	add_child(glow)
	
	body_entered.connect(_on_body_entered)
	
	# 漂浮动画
	_create_float_anim()

func _get_rarity_color() -> Color:
	match item_data.rarity:
		1: return Color(0.5, 0.5, 0.5)  # 灰
		2: return Color(0.3, 0.8, 0.3)  # 绿
		3: return Color(0.3, 0.5, 0.9)  # 蓝
		4: return Color(0.7, 0.4, 0.9)  # 紫
		_: return Color(1.0, 0.8, 0.2)  # 金

func _create_float_anim():
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", -3, 1.0).from(0.0)
	tween.parallel().tween_property(self, "modulate:a", 0.7, 1.0).from(1.0)

func _on_body_entered(body: Node2D):
	if body.name == "Player":
		_apply_effect(body)
		_pickup_effect(body)
		queue_free()

func _apply_effect(player):
	var item_sys = player.get_node_or_null("ItemSystem")
	if item_sys:
		item_sys.add_item(item_data)
	
	# 显示浮动文字
	_show_pickup_text(player)

func _show_pickup_text(player):
	var label = Label.new()
	label.text = item_data.name
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", _get_rarity_color())
	label.position = player.position + Vector2(-25, -50)
	label.z_index = 100
	player.get_parent().add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", player.position.y - 80, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free).set_delay(0.5)

func _pickup_effect(player):
	# 粒子效果
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 8
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.direction = Vector2(0, -1)
	particles.spread = 45
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 60
	particles.color = _get_rarity_color()
	particles.position = position
	player.get_parent().add_child(particles)
	
	await get_tree().create_timer(0.6).timeout
	particles.queue_free()
