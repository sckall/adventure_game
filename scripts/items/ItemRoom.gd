extends Area2D

# ============ 以撒风格道具房 ============
# 生成随机道具供玩家拾取

signal item_picked(item_data)

@export var item_count: int = 1  # 道具房里的道具数量
@export var reroll_enabled: bool = false  # 是否可以重置

var database: ItemDatabase
var spawned_items: Array = []

func _ready():
	database = get_node("/root/ItemDatabase")
	
	# 添加碰撞
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(200, 150)
	collision.shape = shape
	add_child(collision)
	
	# 创建房间视觉效果
	_create_room_visuals()

func _create_room_visuals():
	# 地板
	var floor_rect = ColorRect.new()
	floor_rect.size = Vector2(200, 150)
	floor_rect.position = Vector2(-100, -75)
	floor_rect.color = Color(0.3, 0.25, 0.2)
	add_child(floor_rect)
	
	# 边框
	var border = ColorRect.new()
	border.size = Vector2(200, 150)
	border.position = Vector2(-100, -75)
	border.color = Color(0.1, 0.08, 0.05)
	border.z_index = -1
	add_child(border)
	
	# 发光粒子效果
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 2.0
	particles.direction = Vector2(0, -1)
	particles.spread = 30
	particles.initial_velocity_min = 20
	particles.initial_velocity_max = 40
	particles.color = Color(1, 0.8, 0.3, 0.5)
	add_child(particles)

func spawn_items():
	spawned_items.clear()
	
	for i in range(item_count):
		var item_data = database.get_random_item()
		spawn_item(item_data, i)

func spawn_item(item_data: IsaacItem, index: int):
	var item = IsaacPickup.new()
	item.item_data = item_data
	
	# 排列道具
	var spacing = 60
	var start_x = -(item_count - 1) * spacing / 2
	item.position = Vector2(start_x + index * spacing, 0)
	
	item.picked_up.connect(_on_item_picked.bind(item_data))
	add_child(item)
	spawned_items.append(item)

func _on_item_picked(item: IsaacPickup, item_data: IsaacItem):
	item_picked.emit(item_data)
	spawned_items.erase(item)
	
	# 检查是否所有道具都被拾取
	if spawned_items.is_empty():
		_on_all_items_picked()

func _on_all_items_picked():
	# 道具房完成，可以重置（如果有D6）
	if reroll_enabled:
		_create_reroll_prompt()

func _create_reroll_prompt():
	# 创建重置提示
	var label = Label.new()
	label.text = "按 ↑ 重置道具"
	label.add_theme_font_size_override("font_size", 20)
	label.position = Vector2(-60, 60)
	add_child(label)

# 道具拾取物
class IsaacPickup extends Area2D:
	var item_data: IsaacItem
	
	func _ready():
		# 碰撞
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 15
		collision.shape = shape
		add_child(collision)
		
		# 视觉效果
		var rect = ColorRect.new()
		rect.size = Vector2(24, 24)
		rect.position = Vector2(-12, -12)
		rect.color = _get_rarity_color()
		add_child(rect)
		
		# 发光
		var glow = ColorRect.new()
		glow.size = Vector2(30, 30)
		glow.position = Vector2(-15, -15)
		glow.color = _get_rarity_color()
		glow.modulate.a = 0.3
		glow.z_index = -1
		add_child(glow)
		
		# 漂浮动画
		_create_float_animation()
		
		body_entered.connect(_on_body_entered)
	
	func _get_rarity_color() -> Color:
		match item_data.rarity:
			1: return Color(0.5, 0.5, 0.5)  # 灰色
			2: return Color(0.3, 0.7, 0.3)  # 绿色
			3: return Color(0.3, 0.5, 0.9)  # 蓝色
			4: return Color(0.7, 0.4, 0.9)  # 紫色
			_: return Color(1.0, 0.8, 0.2)  # 金色
	
	func _create_float_animation():
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(self, "position:y", -5, 1.0).from(0.0)
		tween.tween_property(self, "modulate:a", 0.8, 1.0).from(1.0)
	
	func _on_body_entered(body: Node2D):
		if body.name == "Player":
			_apply_item_effects(body)
			picked_up.emit(self)
			queue_free()
	
	func _apply_item_effects(player):
		# 应用道具效果
		var item_system = player.get_node_or_null("IsaacItemSystem")
		if item_system:
			item_system.add_item(item_data)
		
		# 显示道具名
		var label = Label.new()
		label.text = item_data.name
		label.add_theme_font_size_override("font_size", 16)
		label.position = body.position + Vector2(-20, -50)
		label.add_theme_color_override("font_color", _get_rarity_color())
		body.get_parent().add_child(label)
		
		var tween = create_tween()
		tween.tween_property(label, "position:y", body.position.y - 80, 1.0)
		tween.tween_property(label, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): label.queue_free())
