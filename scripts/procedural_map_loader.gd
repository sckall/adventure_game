extends Node2D

# ============ 程序化地图加载器 ============
# 将MapGenerator生成的地图数据加载到游戏中

var map_data: Dictionary = {}
var current_seed: int = 0

@onready var map_gen = get_node("/root/MapGenerator")
@onready var g = get_node("/root/Global")
@onready var audio = get_node("/root/AudioManager")
@onready var object_pool = get_node("/root/ObjectPoolManager")
@onready var resource_mgr = get_node("/root/ResourceManager")

# 从生成器加载地图
func load_procedural_map(seed_value: int = 0) -> void:
	current_seed = seed_value

	print("ProceduralMapLoader", "开始加载程序化地图，种子: %d" % seed_value)

	# 生成地图数据
	map_data = map_gen.generate_map(seed_value)

	# 等待生成完成
	await map_gen.map_generation_complete

	# 清理旧关卡
	_clear_existing_level()

	# 构建地图
	_build_map_from_data()

	print("ProceduralMapLoader", "程序化地图加载完成")

# 清理现有关卡
func _clear_existing_level() -> void:
	var level_node = get_node_or_null("/root/Node2D/Level")
	if not level_node:
		return

	for child in level_node.get_children():
		child.queue_free()

# 从地图数据构建关卡
func _build_map_from_data() -> void:
	var level_node = get_node_or_null("/root/Node2D/Level")
	if not level_node:
		print("ProceduralMapLoader", "无法找到Level节点")
		return

	# 设置背景色为适应程序化地图的渐变色
	_setup_procedural_background()

	# 生成平台
	_generate_platforms_from_data(level_node)

	# 生成收集品
	_generate_collectibles_from_data(level_node)

	# 生成敌人
	_generate_enemies_from_data(level_node)

	# 生成出口
	_generate_exit_from_data(level_node)

# 设置程序化地图背景
func _setup_procedural_background() -> void:
	var bg_node = get_node_or_null("/root/Node2D/Background")
	if not bg_node:
		return

	# 创建一个基于地形的渐变背景
	var gradient_color = Color(0.15, 0.2, 0.3)
	bg_node.color = gradient_color

# 从数据生成平台
func _generate_platforms_from_data(level_node: Node2D) -> void:
	var platforms: Array = map_data.get("platforms", [])

	for platform in platforms:
		if platform.get("is_exit", false):
			continue

		_create_platform(level_node, platform)

# 创建单个平台
func _create_platform(level_node: Node2D, platform_data: Dictionary) -> void:
	var x: float = platform_data["x"]
	var y: float = platform_data["y"]
	var width: float = platform_data["width"]
	var height: float = platform_data.get("height", 20)
	var color: Color = platform_data["color"]

	# 转换坐标系统
	var sx: float = scale_x(x)
	var sy: float = scale_y(y)
	var sw: float = scale_w(width)
	var sh: float = scale_h(height)

	var body = StaticBody2D.new()
	body.position = Vector2(sx, sy)

	# 可视部分
	var rect = ColorRect.new()
	rect.size = Vector2(sw, sh)
	rect.color = color
	body.add_child(rect)

	# 碰撞部分
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(sw, sh)
	collision.shape = shape
	collision.position = Vector2(sw / 2, sh / 2)
	body.add_child(collision)

	# 添加平台类型特定效果
	_apply_platform_type_effects(body, rect, platform_data)

	level_node.add_child(body)

# 应用平台类型特效
func _apply_platform_type_effects(body: StaticBody2D, rect: ColorRect, platform_data: Dictionary) -> void:
	var platform_type: String = platform_data.get("type", "standard")

	match platform_type:
		"ice_slope":
			# 冰川平台：添加发光效果
			rect.z_index = -1
			var glow = ColorRect.new()
			glow.size = rect.size + Vector2(4, 4)
			glow.position = Vector2(-2, -2)
			glow.color = Color(0.8, 0.9, 1.0, 0.3)
			body.add_child(glow)
		"desert_flat":
			# 沙漠平台：添加沙尘效果标记
			rect.z_index = 0
		"mountain_layer":
			# 山地平台：添加阴影效果
			var shadow = ColorRect.new()
			shadow.size = Vector2(rect.size.x, 8)
			shadow.position = Vector2(0, rect.size.y)
			shadow.color = Color(0, 0, 0, 0.2)
			shadow.z_index = -1
			body.add_child(shadow)
		"tree_platform":
			# 森林树平台：添加树叶装饰
			var leaf = ColorRect.new()
			leaf.size = Vector2(6, 6)
			leaf.position = Vector2(rect.size.x - 3, -rect.size.y - 3)
			leaf.color = Color(0.3, 0.6, 0.2)
			body.add_child(leaf)

# 生成收集品
func _generate_collectibles_from_data(level_node: Node2D) -> void:
	var collectibles: Array = map_data.get("collectibles", [])

	for item in collectibles:
		_create_collectible(level_node, item)

# 创建单个收集品
func _create_collectible(level_node: Node2D, item_data: Dictionary) -> void:
	var item_type: String = item_data["type"]
	var x: float = item_data["x"]
	var y: float = item_data["y"]
	var color: String = item_data.get("color", "green")

	var area = Area2D.new()
	area.position = Vector2(scale_x(x), scale_y(y))
	area.set_meta("type", item_type)
	area.set_meta("color", color)

	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 12
	area.add_child(shape)

	var rect = ColorRect.new()
	rect.size = Vector2(20, 24 if item_type == "bottle" else 20)
	rect.position = Vector2(-10, -12)

	match color:
		"green":
			rect.color = Color(0.3, 0.85, 0.35)
		"yellow":
			rect.color = Color(1.0, 0.85, 0.2)
		"red":
			rect.color = Color(1.0, 0.35, 0.35)
		"blue":
			rect.color = Color(0.25, 0.55, 1.0)
		"purple":
			rect.color = Color(0.85, 0.4, 0.95)
		"brown":
			rect.color = Color(0.7, 0.5, 0.25)
		_:
			rect.color = Color(0.3, 0.85, 0.35)

	area.add_child(rect)
	area.body_entered.connect(func(body): _on_collectible_collected(body, area))
	level_node.add_child(area)

# 收集品收集回调
func _on_collectible_collected(body: Node2D, item: Area2D) -> void:
	if body.name == "Player" and item and item.has_meta("type"):
		var type_str: String = item.get_meta("type")
		var color: String = item.get_meta("color", "")
		var pos: Vector2 = item.global_position

		g.collect_item(type_str, color)
		audio.play_collect()
		_spawn_collect_effect(pos)
		item.queue_free()

# 生成收集效果
func _spawn_collect_effect(pos: Vector2) -> void:
	var particles = object_pool.get_object("particles")
	if not particles:
		return

	particles.emitting = true
	particles.amount = 12
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.gravity = Vector2(0, 200)
	particles.scale_min = 3.0
	particles.scale_max = 6.0
	particles.color = Color(1, 0.9, 0.3, 1)
	particles.position = pos

	var main_node = get_node_or_null("/root/Node2D")
	if main_node:
		main_node.add_child(particles)

		await get_tree().create_timer(0.5).timeout
	object_pool.return_object(particles)

# 生成敌人
func _generate_enemies_from_data(level_node: Node2D) -> void:
	var enemies: Array = map_data.get("enemies", [])

	for enemy in enemies:
		_create_enemy(level_node, enemy)

# 创建单个敌人
func _create_enemy(level_node: Node2D, enemy_data: Dictionary) -> void:
	var enemy_type: String = enemy_data["type"]
	var x: float = enemy_data["x"]
	var y: float = enemy_data["y"]
	var color_name: String = enemy_data.get("color_name", "green")
	var patrol: float = enemy_data.get("patrol", 80)

	# 使用ResourceManager创建敌人
	var enemy = resource_mgr.instantiate_scene(enemy_type)
	if not enemy:
		print("ProceduralMapLoader", "无法创建敌人: %s" % enemy_type)
		return

	enemy.position = Vector2(scale_x(x), scale_y(y))
	enemy.color_name = color_name
	enemy.patrol_distance = scale_w(patrol)

	enemy.set_meta("type", enemy_type)
	enemy.set_meta("color", color_name)

	level_node.add_child(enemy)

# 生成出口
func _generate_exit_from_data(level_node: Node2D) -> void:
	var platforms: Array = map_data.get("platforms", [])

	for platform in platforms:
		if platform.get("is_exit", false):
			_create_exit(level_node, platform)
			break

# 创建出口
func _create_exit(level_node: Node2D, platform_data: Dictionary) -> void:
	var x: float = platform_data["x"]
	var y: float = platform_data["y"]

	var exit = Area2D.new()
	exit.name = "Exit"
	exit.position = Vector2(scale_x(x), scale_y(y))

	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(60, 60)
	exit.add_child(shape)

	# 出口主体 - 金色
	var rect = ColorRect.new()
	rect.size = Vector2(40, 60)
	rect.position = Vector2(-20, -30)
	rect.color = Color(1.0, 0.85, 0.2)
	exit.add_child(rect)

	# 发光效果
	var glow = ColorRect.new()
	glow.size = Vector2(50, 70)
	glow.position = Vector2(-25, -35)
	glow.color = Color(1.0, 0.95, 0.4, 0.6)
	glow.z_index = -1
	exit.add_child(glow)

	# 内部核心
	var core = ColorRect.new()
	core.size = Vector2(20, 40)
	core.position = Vector2(-10, -20)
	core.color = Color(1, 0.95, 0.7, 0.9)
	exit.add_child(core)

	exit.body_entered.connect(func(body): _on_exit_entered(body))
	level_node.add_child(exit)

# 出口进入回调
func _on_exit_entered(body: Node2D) -> void:
	if body.name == "Player":
		_on_player_reached_exit()

# 玩家到达出口
func _on_player_reached_exit() -> void:
	g.complete_level()
	var main_node = get_node_or_null("/root/Node2D")
	if main_node and main_node.has_method("show_victory"):
		main_node.show_victory()

# ============ 坐标转换函数 ============

# 从project.godot获取的视口配置
const VIEW_W = 1920
const VIEW_H = 1080
const SCALE_X = VIEW_W / 1280.0
const SCALE_Y = VIEW_H / 720.0

func scale_x(x: float) -> float:
	return x * SCALE_X

func scale_y(y: float) -> float:
	return y * SCALE_Y

func scale_w(w: float) -> float:
	return w * SCALE_X

func scale_h(h: float) -> float:
	return h * SCALE_Y

# ============ 地形配色方案 ============
# 根据地形类型获取对应的配色

const TERRAIN_COLOR_SCHEMES = {
	"grassland": {
		"sky_top": Color(0.5, 0.7, 0.9),
		"sky_bottom": Color(0.7, 0.85, 0.95),
		"ground": Color(0.28, 0.55, 0.25),
		"accent": Color(0.4, 0.65, 0.3)
	},
	"forest": {
		"sky_top": Color(0.3, 0.5, 0.7),
		"sky_bottom": Color(0.5, 0.65, 0.8),
		"ground": Color(0.18, 0.35, 0.12),
		"accent": Color(0.25, 0.45, 0.15)
	},
	"mountain": {
		"sky_top": Color(0.6, 0.7, 0.85),
		"sky_bottom": Color(0.75, 0.8, 0.9),
		"ground": Color(0.35, 0.32, 0.28),
		"accent": Color(0.45, 0.4, 0.35)
	},
	"snow": {
		"sky_top": Color(0.85, 0.9, 0.95),
		"sky_bottom": Color(0.92, 0.95, 1.0),
		"ground": Color(0.85, 0.88, 0.92),
		"accent": Color(0.9, 0.93, 0.97)
	},
	"desert": {
		"sky_top": Color(0.9, 0.85, 0.7),
		"sky_bottom": Color(1.0, 0.95, 0.8),
		"ground": Color(0.75, 0.6, 0.35),
		"accent": Color(0.85, 0.7, 0.4)
	},
	"glacier": {
		"sky_top": Color(0.65, 0.8, 0.95),
		"sky_bottom": Color(0.75, 0.88, 1.0),
		"ground": Color(0.6, 0.75, 0.85),
		"accent": Color(0.7, 0.82, 0.92)
	},
	"village": {
		"sky_top": Color(0.55, 0.7, 0.85),
		"sky_bottom": Color(0.7, 0.82, 0.95),
		"ground": Color(0.55, 0.45, 0.3),
		"accent": Color(0.65, 0.55, 0.35)
	},
	"city": {
		"sky_top": Color(0.5, 0.55, 0.65),
		"sky_bottom": Color(0.6, 0.65, 0.75),
		"ground": Color(0.35, 0.35, 0.4),
		"accent": Color(0.45, 0.45, 0.5)
	},
	"island": {
		"sky_top": Color(0.5, 0.75, 0.9),
		"sky_bottom": Color(0.7, 0.88, 1.0),
		"ground": Color(0.32, 0.45, 0.25),
		"accent": Color(0.4, 0.55, 0.3)
	},
	"ocean": {
		"sky_top": Color(0.1, 0.25, 0.4),
		"sky_bottom": Color(0.15, 0.35, 0.5),
		"ground": Color(0.15, 0.25, 0.35),
		"accent": Color(0.1, 0.3, 0.45)
	},
	"beach": {
		"sky_top": Color(0.6, 0.8, 0.95),
		"sky_bottom": Color(0.75, 0.88, 1.0),
		"ground": Color(0.85, 0.75, 0.55),
		"accent": Color(0.9, 0.82, 0.6)
	}
}

# 获取地形配色方案
func get_terrain_color_scheme(terrain_type: String) -> Dictionary:
	return TERRAIN_COLOR_SCHEMES.get(terrain_type, TERRAIN_COLOR_SCHEMES["grassland"])
