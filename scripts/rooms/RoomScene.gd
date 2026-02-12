extends Node2D

# ============ 以撒风格房间场景 ============
# 可视化单个房间

signal door_entered(direction: String)
signal enemy_defeated(enemy: Dictionary)
signal item_collected(item: Dictionary)
signal trap_triggered(trap: Dictionary)

@export var room_color: Color = Color(0.3, 0.3, 0.35)
@export var tile_size: int = 32

var room_data: RoomManager.RoomData
var grid_size: Vector2i = Vector2i(5, 4)  # 默认房间大小
var player: Node2D = null

# 房间内容
var spawned_enemies: Array = []
var spawned_items: Array = []
var spawned_traps: Array = []

# 门的位置
var doors: Dictionary = {
	"north": null,
	"south": null,
	"east": null,
	"west": null
}

# 房间边界
var room_bounds: Rect2i

func setup(data: RoomManager.RoomData, _player: Node2D):
	room_data = data
	player = _player
	grid_size = data.size
	room_color = data.color
	
	_create_room_visuals()
	_spawn_enemies()
	_spawn_items()
	_spawn_traps()
	_create_doors()

func _ready():
	pass

# ============ 创建房间视觉效果 ============

func _create_room_visuals():
	# 计算房间像素大小
	var width = grid_size.x * tile_size * 4  # 每个格子更大
	var height = grid_size.y * tile_size * 4
	
	room_bounds = Rect2i(-width/2, -height/2, width, height)
	
	# 地板
	var floor_rect = ColorRect.new()
	floor_rect.size = Vector2(width, height)
	floor_rect.position = Vector2(-width/2, -height/2)
	floor_rect.color = room_color
	add_child(floor_rect)
	
	# 墙壁/边框
	var wall_color = room_color.darkened(0.3)
	
	# 上墙
	var top_wall = ColorRect.new()
	top_wall.size = Vector2(width, tile_size * 2)
	top_wall.position = Vector2(-width/2, -height/2 - tile_size * 2)
	top_wall.color = wall_color
	add_child(top_wall)
	
	# 下墙
	var bottom_wall = ColorRect.new()
	bottom_wall.size = Vector2(width, tile_size * 2)
	bottom_wall.position = Vector2(-width/2, height/2)
	bottom_wall.color = wall_color
	add_child(bottom_wall)
	
	# 左墙
	var left_wall = ColorRect.new()
	left_wall.size = Vector2(tile_size * 2, height + tile_size * 2)
	left_wall.position = Vector2(-width/2 - tile_size * 2, -height/2)
	left_wall.color = wall_color
	add_child(left_wall)
	
	# 右墙
	var right_wall = ColorRect.new()
	right_wall.size = Vector2(tile_size * 2, height + tile_size * 2)
	right_wall.position = Vector2(width/2, -height/2)
	right_wall.color = wall_color
	add_child(right_wall)
	
	# 添加房间类型标识
	_add_room_label()

func _add_room_label():
	var label = Label.new()
	label.text = _get_room_type_name()
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	label.position = Vector2(-50, -room_bounds.size.y/2 - 40)
	add_child(label)

func _get_room_type_name() -> String:
	match room_data.type:
		RoomManager.RoomType.START: return "入口"
		RoomManager.RoomType.BOSS: return "BOSS"
		RoomManager.RoomType.SHOP: return "商店 💰"
		RoomManager.RoomType.TREASURE: return "宝藏房 💎"
		RoomManager.RoomType.SECRET: return "密室 🚪"
		RoomManager.RoomType.TRAP: return "陷阱房 ⚠️"
		_: return ""

# ============ 生成敌人 ============

func _spawn_enemies():
	if room_data.enemies.is_empty():
		return
	
	for enemy_data in room_data.enemies:
		var enemy = _create_enemy_sprite(enemy_data)
		enemy.position = _get_random_position()
		add_child(enemy)
		spawned_enemies.append({"node": enemy, "data": enemy_data})

func _create_enemy_sprite(data: Dictionary) -> Node2D:
	var enemy = Node2D.new()
	enemy.name = "Enemy"
	
	# 根据类型创建不同颜色
	var color = Color(1, 0.3, 0.3)
	match data.type:
		"slime": color = Color(0.3, 0.8, 0.3)
		"bat": color = Color(0.5, 0.3, 0.6)
		"hedgehog": color = Color(0.6, 0.5, 0.3)
		"boss": color = Color(0.8, 0.1, 0.1)
	
	# 敌人身体
	var body = ColorRect.new()
	body.size = Vector2(32, 32)
	body.position = Vector2(-16, -16)
	body.color = color
	enemy.add_child(body)
	
	# 眼睛（朝向玩家）
	var eye_left = ColorRect.new()
	eye_left.size = Vector2(6, 6)
	eye_left.position = Vector2(-10, -8)
	eye_left.color = Color.WHITE
	enemy.add_child(eye_left)
	
	var eye_right = ColorRect.new()
	eye_right.size = Vector2(6, 6)
	eye_right.position = Vector2(4, -8)
	eye_right.color = Color.WHITE
	enemy.add_child(eye_right)
	
	# 敌人名称标签
	var label = Label.new()
	label.text = _get_enemy_name(data.type)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.position = Vector2(-30, -50)
	enemy.add_child(label)
	
	return enemy

func _get_enemy_name(type: String) -> String:
	var names = {
		"slime": "史莱姆",
		"bat": "蝙蝠",
		"hedgehog": "刺猬",
		"snail": "蜗牛",
		"boss": "BOSS"
	}
	return names.get(type, type)

func _get_random_position() -> Vector2:
	var margin = 100
	return Vector2(
		randf_range(-room_bounds.size.x/2 + margin, room_bounds.size.x/2 - margin),
		randf_range(-room_bounds.size.y/2 + margin, room_bounds.size.y/2 - margin)
	)

# ============ 生成道具 ============

func _spawn_items():
	if room_data.items.is_empty():
		return
	
	for item_data in room_data.items:
		var item = _create_item_sprite(item_data)
		item.position = _get_random_position()
		add_child(item)
		spawned_items.append({"node": item, "data": item_data})

func _create_item_sprite(data: Dictionary) -> Node2D:
	var item = Area2D.new()
	item.name = "Item"
	
	# 碰撞
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15
	collision.shape = shape
	item.add_child(collision)
	
	# 根据类型和稀有度设置颜色
	var color = _get_item_color(data)
	
	var rect = ColorRect.new()
	rect.size = Vector2(24, 24)
	rect.position = Vector2(-12, -12)
	rect.color = color
	item.add_child(rect)
	
	# 发光效果
	var glow = ColorRect.new()
	glow.size = Vector2(32, 32)
	glow.position = Vector2(-16, -16)
	glow.color = color
	glow.modulate.a = 0.3
	glow.z_index = -1
	item.add_child(glow)
	
	# 漂浮动画
	var tween = create_tween().set_loops()
	tween.tween_property(item, "position:y", -5, 1.0).from(0.0)
	tween.parallel().tween_property(item, "modulate:a", 0.7, 1.0).from(1.0)
	
	# 收集信号
	item.body_entered.connect(_on_item_collected.bind(item, data))
	
	return item

func _get_item_color(data: Dictionary) -> Color:
	var rarity = data.get("rarity", 1)
	match rarity:
		1: return Color(0.5, 0.5, 0.5)  # 灰
		2: return Color(0.3, 0.8, 0.3)  # 绿
		3: return Color(0.3, 0.5, 0.9)  # 蓝
		4: return Color(0.7, 0.4, 0.9)  # 紫
		_: return Color(1.0, 0.8, 0.2)  # 金

func _on_item_collected(body: Node2D, item: Node2D, data: Dictionary):
	if body.name == "Player":
		item_collected.emit(data)
		
		# 移除道具
		var tween = create_tween()
		tween.tween_property(item, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_property(item, "modulate:a", 0.0, 0.1)
		tween.tween_callback(item.queue_free)
		
		# 从列表移除
		for i in range(spawned_items.size()):
			if spawned_items[i].node == item:
				spawned_items.remove_at(i)
				break

# ============ 生成陷阱 ============

func _spawn_traps():
	if room_data.traps.is_empty():
		return
	
	for trap_data in room_data.traps:
		var trap = _create_trap_sprite(trap_data)
		trap.position = _get_random_position()
		add_child(trap)
		spawned_traps.append({"node": trap, "data": trap_data})

func _create_trap_sprite(data: Dictionary) -> Area2D:
	var trap = Area2D.new()
	trap.name = "Trap"
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20
	collision.shape = shape
	trap.add_child(collision)
	
	var color = _get_trap_color(data.type)
	
	var rect = ColorRect.new()
	rect.size = Vector2(24, 24)
	rect.position = Vector2(-12, -12)
	rect.color = color
	trap.add_child(rect)
	
	trap.body_entered.connect(_on_trap_triggered.bind(trap, data))
	
	return trap

func _get_trap_color(type: String) -> Color:
	match type:
		"fire": return Color(1.0, 0.3, 0.1)
		"poison": return Color(0.3, 0.8, 0.3)
		"lightning": return Color(1.0, 1.0, 0.3)
		"paralysis": return Color(0.5, 0.5, 1.0)
		_: return Color(0.5, 0.5, 0.5)

func _on_trap_triggered(body: Node2D, trap: Node2D, data: Dictionary):
	if body.name == "Player":
		trap_triggered.emit(data)
		
		# 陷阱效果
		match data.type:
			"fire":
				body.take_damage(data.get("damage", 5))
			"poison":
				# 添加中毒Buff
				pass
			"lightning":
				body.take_damage(data.get("damage", 8))
				# 击退
				body.velocity = (body.position - trap.position).normalized() * 200

# ============ 创建门 ============

func _create_doors():
	var half_width = room_bounds.size.x / 2
	var half_height = room_bounds.size.y / 2
	
	# 北门
	if room_data.doors.get("north", false):
		_create_door(Vector2(0, -half_height), "north")
	
	# 南门
	if room_data.doors.get("south", false):
		_create_door(Vector2(0, half_height), "south")
	
	# 东门
	if room_data.doors.get("east", false):
		_create_door(Vector2(half_width, 0), "east")
	
	# 西门
	if room_data.doors.get("west", false):
		_create_door(Vector2(-half_width, 0), "west")

func _create_door(pos: Vector2, direction: String):
	var door = Area2D.new()
	door.name = "Door_" + direction
	
	# 碰撞
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(80, 20)
	collision.shape = shape
	door.add_child(collision)
	
	# 门视觉效果
	var door_rect = ColorRect.new()
	door_rect.size = Vector2(80, 20)
	door_rect.position = Vector2(-40, -10)
	door_rect.color = Color(0.4, 0.3, 0.2)
	door.add_child(door_rect)
	
	# 门框
	var frame = ColorRect.new()
	frame.size = Vector2(84, 24)
	frame.position = Vector2(-42, -12)
	frame.color = Color(0.3, 0.2, 0.1)
	door.add_child(frame)
	
	# 出口标识
	var arrow = Label.new()
	arrow.text = "→"
	arrow.add_theme_font_size_override("font_size", 20)
	arrow.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	arrow.position = Vector2(-10, -10)
	door.add_child(arrow)
	
	door.position = pos
	door.body_entered.connect(_on_door_entered.bind(direction))
	
	add_child(door)
	doors[direction] = door

func _on_door_entered(body: Node2D, direction: String):
	if body.name == "Player":
		door_entered.emit(direction)

# ============ 检查敌人状态 ============

func check_enemies_cleared() -> bool:
	return spawned_enemies.is_empty()

# 获取剩余敌人数量
func get_remaining_enemies() -> int:
	return spawned_enemies.size()

# 敌人死亡
func on_enemy_defeated(enemy_node: Node2D):
	for i in range(spawned_enemies.size()):
		if spawned_enemies[i].node == enemy_node:
			var data = spawned_enemies[i].data
			spawned_enemies.remove_at(i)
			enemy_defeated.emit(data)
			
			# 死亡效果
			var particles = _create_death_particles(enemy_node.position)
			add_child(particles)
			await get_tree().create_timer(0.5).timeout
			particles.queue_free()
			
			break

func _create_death_particles(pos: Vector2) -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 10
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.direction = Vector2(0, -1)
	particles.spread = 45
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 60
	particles.color = Color(1, 0.5, 0.5)
	particles.position = pos
	return particles
