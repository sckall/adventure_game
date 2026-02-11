extends Node2D

# ============ 引用全局状态 ============
@onready var player = $Player
@onready var audio = get_node("/root/AudioManager")
@onready var camera = $Camera2D
@onready var background = $Background
@onready var resource_mgr = get_node("/root/ResourceManager")
@onready var object_pool = get_node("/root/ObjectPoolManager")
@onready var env = get_node("/root/EnvironmentManager")

var g = null

# 关卡元素
var slimes = []

# ============ UI系统 ============
var boss_intro_ui: Control = null
var combat_stats_panel: Control = null
var death_replay_ui: Control = null
var death_replay_system = null

# 当前Boss引用
var current_boss = null

# 视差背景引用
var parallax_bg = null
var parallax_far = null
var parallax_mid = null
var parallax_near = null

# 视口尺寸（与 project.godot 一致）
const VIEW_W = 1920
const VIEW_H = 1080
const SCALE_X = 1.0
const SCALE_Y = 1.0

func _ready() -> void:
	# 获取全局状态
	g = get_node("/root/Global")
	g.current_state = g.GameState.PLAYING

	# 播放背景音乐
	audio.play_bgm()

	# 初始化环境系统
	_initialize_environment()

	# 设置视差背景
	_setup_parallax_background()

	# 确保Level节点存在
	if not has_node("Level"):
		print("ERROR: Level节点不存在!")
		return

	# 设置UI元素字体大小（适应全屏）
	$CanvasLayer/LevelLabel.add_theme_font_size_override("font_size", 42)
	$CanvasLayer/LevelLabel.add_theme_color_override("font_color", Color(1, 0.95, 0.7, 1))
	$CanvasLayer/StatsLabel.add_theme_font_size_override("font_size", 36)
	$CanvasLayer/StatsLabel.add_theme_color_override("font_color", Color(0.8, 0.95, 1, 1))
	$CanvasLayer/BackBtn.add_theme_font_size_override("font_size", 26)
	$CanvasLayer/BackBtn.custom_minimum_size = Vector2(180, 50)
	
	# 设置返回按钮样式
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	back_style.corner_radius_top_left = 8
	back_style.corner_radius_top_right = 8
	back_style.corner_radius_bottom_left = 8
	back_style.corner_radius_bottom_right = 8
	back_style.border_width_left = 2
	back_style.border_width_top = 2
	back_style.border_width_right = 2
	back_style.border_width_bottom = 2
	back_style.border_color = Color(0.4, 0.4, 0.5, 0.8)
	back_style.shadow_color = Color(0, 0, 0, 0.3)
	back_style.shadow_offset = Vector2(0, 2)
	back_style.content_margin_left = 10
	back_style.content_margin_right = 10
	back_style.content_margin_top = 5
	back_style.content_margin_bottom = 5
	$CanvasLayer/BackBtn.add_theme_stylebox_override("normal", back_style)

	var back_hover = StyleBoxFlat.new()
	back_hover.bg_color = Color(0.3, 0.3, 0.4, 0.95)
	back_hover.corner_radius_top_left = 8
	back_hover.corner_radius_top_right = 8
	back_hover.corner_radius_bottom_left = 8
	back_hover.corner_radius_bottom_right = 8
	back_hover.border_width_left = 2
	back_hover.border_width_top = 2
	back_hover.border_width_right = 2
	back_hover.border_width_bottom = 2
	back_hover.border_color = Color(0.5, 0.5, 0.6, 0.9)
	back_hover.content_margin_left = 10
	back_hover.content_margin_right = 10
	back_hover.content_margin_top = 5
	back_hover.content_margin_bottom = 5
	$CanvasLayer/BackBtn.add_theme_stylebox_override("hover", back_hover)

	var back_pressed = StyleBoxFlat.new()
	back_pressed.bg_color = Color(0.15, 0.15, 0.25, 1.0)
	back_pressed.corner_radius_top_left = 8
	back_pressed.corner_radius_top_right = 8
	back_pressed.corner_radius_bottom_left = 8
	back_pressed.corner_radius_bottom_right = 8
	back_pressed.border_width_left = 2
	back_pressed.border_width_top = 2
	back_pressed.border_width_right = 2
	back_pressed.border_width_bottom = 2
	back_pressed.border_color = Color(0.6, 0.6, 0.7, 1.0)
	back_pressed.content_margin_left = 10
	back_pressed.content_margin_right = 10
	back_pressed.content_margin_top = 5
	back_pressed.content_margin_bottom = 5
	$CanvasLayer/BackBtn.add_theme_stylebox_override("pressed", back_pressed)

	# 确保按钮可以接收鼠标事件
	$CanvasLayer/BackBtn.mouse_filter = Control.MOUSE_FILTER_STOP

	# 手动连接返回按钮信号
	if not $CanvasLayer/BackBtn.pressed.is_connected(_on_back_pressed):
		$CanvasLayer/BackBtn.pressed.connect(_on_back_pressed)

	# 初始化UI系统
	_init_ui_systems()

	# 连接玩家死亡信号
	if is_instance_valid(player) and player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)

	load_level(g.current_level_num)

# 初始化环境系统
func _initialize_environment():
	# 设置初始背景色
	background.color = env.get_background_color()
	background.size = Vector2(VIEW_W, VIEW_H)

	# 连接背景色更新信号
	env.background_color_updated.connect(_on_background_color_changed)

	# 连接时间段变化信号
	env.time_period_changed.connect(_on_time_period_changed)

# ============ 视差背景系统 ============
func _setup_parallax_background():
	# 创建视差背景节点
	var parallax = ParallaxBackground.new()
	parallax.name = "ParallaxBackground"
	parallax.layer = -50  # 在Background(-100)前面，但在游戏元素后面
	add_child(parallax, true)
	
	# 远景图层（最慢）- 山脉轮廓
	var far_layer = ParallaxLayer.new()
	far_layer.name = "FarLayer"
	far_layer.motion_scale = Vector2(0.1, 0.1)  # 极慢移动
	far_layer.motion_mirroring = Vector2(4500, 0)  # 支持超长地图
	parallax.add_child(far_layer)
	
	# 创建远景山脉
	var far_bg = ColorRect.new()
	far_bg.name = "FarMountains"
	far_bg.size = Vector2(4500, 600)
	far_bg.position = Vector2(0, VIEW_H - 600)
	far_bg.color = Color(0.15, 0.18, 0.25, 1)  # 深色山脉
	far_layer.add_child(far_bg)
	
	# 添加山脉山峰装饰
	for i in range(25):
		var peak = ColorRect.new()
		peak.size = Vector2(100 + randf() * 150, 100 + randf() * 200)
		peak.position = Vector2(i * 180 + randf() * 50, VIEW_H - 600 - peak.size.y + randf() * 50)
		peak.color = Color(0.1, 0.12, 0.18, 1)
		far_layer.add_child(peak)
	
	# 中景图层（中等速度）- 树木剪影
	var mid_layer = ParallaxLayer.new()
	mid_layer.name = "MidLayer"
	mid_layer.motion_scale = Vector2(0.3, 0.3)
	mid_layer.motion_mirroring = Vector2(4500, 0)
	parallax.add_child(mid_layer)
	
	# 创建中景树木
	for i in range(35):
		var tree = ColorRect.new()
		tree.size = Vector2(30 + randf() * 40, 150 + randf() * 150)
		tree.position = Vector2(i * 130 + randf() * 30, VIEW_H - 250 - tree.size.y)
		tree.color = Color(0.12, 0.15, 0.2, 1)
		mid_layer.add_child(tree)
	
	# 近景图层（较快）- 草丛前景
	var near_layer = ParallaxLayer.new()
	near_layer.name = "NearLayer"
	near_layer.motion_scale = Vector2(0.6, 0.6)
	near_layer.motion_mirroring = Vector2(4500, 0)
	parallax.add_child(near_layer)
	
	# 创建前景草丛
	for i in range(60):
		var grass = ColorRect.new()
		grass.size = Vector2(10 + randf() * 15, 30 + randf() * 40)
		grass.position = Vector2(i * 75 + randf() * 20, VIEW_H - 100 - grass.size.y)
		grass.color = Color(0.08, 0.1, 0.12, 1)
		near_layer.add_child(grass)
	
	# 保存引用以便更新
	parallax_bg = parallax
	parallax_far = far_layer
	parallax_mid = mid_layer
	parallax_near = near_layer

func _update_parallax_colors():
	# 根据时间段更新视差背景颜色
	var base_color = env.get_background_color()
	var darker_color = Color(
		base_color.r * 0.3,
		base_color.g * 0.3,
		base_color.b * 0.4,
		1.0
	)
	
	# 更新各图层颜色
	if parallax_far:
		for child in parallax_far.get_children():
			if child is ColorRect:
				child.color = darker_color
	
	if parallax_mid:
		for child in parallax_mid.get_children():
			if child is ColorRect:
				child.color = Color(darker_color.r * 0.8, darker_color.g * 0.8, darker_color.b * 0.9, 1.0)

# 背景色改变回调
func _on_background_color_changed(color: Color):
	if background:
		background.color = color
	_update_parallax_colors()

# 时间段改变回调
func _on_time_period_changed(period_name: String):
	print("时间段变化: ", period_name)
	_update_parallax_colors()

# ============ UI系统初始化 ============
func _init_ui_systems():
	# 创建Boss预告UI系统
	var boss_intro_scene = load("res://scenes/boss_intro_ui.tscn")
	if boss_intro_scene:
		boss_intro_ui = boss_intro_scene.instantiate()
		$CanvasLayer.add_child(boss_intro_ui)
		if boss_intro_ui.has_signal("intro_completed"):
			boss_intro_ui.intro_completed.connect(_on_boss_intro_completed)

	# 创建战斗统计面板
	var stats_scene = load("res://scenes/combat_stats_panel.tscn")
	if stats_scene:
		combat_stats_panel = stats_scene.instantiate()
		$CanvasLayer.add_child(combat_stats_panel)

	# 创建死亡回放系统
	death_replay_system = DeathReplaySystem.new()
	add_child(death_replay_system)

	# 创建死亡回放UI
	var replay_ui_scene = load("res://scenes/death_replay_ui.tscn")
	if replay_ui_scene:
		death_replay_ui = replay_ui_scene.instantiate()
		$CanvasLayer.add_child(death_replay_ui)
		if death_replay_ui.has_signal("retry_requested"):
			death_replay_ui.retry_requested.connect(_on_death_retry_requested)

func _on_boss_intro_completed():
	print("Main", "Boss预告完成，开始战斗")

func _on_death_retry_requested():
	# 重试当前关卡
	print("Main", "重试关卡 %d" % g.current_level_num)

	# 重置玩家状态
	player.hp = player.max_hp
	player.position = Vector2(150, 530)
	player.velocity = Vector2.ZERO

	# 隐藏死亡回放UI
	if death_replay_ui:
		death_replay_ui.hide()

	# 重新加载关卡
	load_level(g.current_level_num)

func load_level(level_num: int):
	# 清理旧关卡
	for child in $Level.get_children():
		child.queue_free()
	slimes.clear()

	# 重置关卡数据
	g.reset_level_data()

	# 将玩家添加到player组（供Boss系统识别）
	if not player.is_in_group("player"):
		player.add_to_group("player")

	# 设置相机限制（支持更长的地图）
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 4200  # 支持第5关的超长地图
	camera.limit_bottom = 1080
	camera.position_smoothing_enabled = true

	# 根据关卡创建
	match level_num:
		1: create_level_1()
		2: create_level_2()
		3: create_level_3()
		4: create_level_4()
		5: create_level_5()

	# 设置玩家位置（按视口缩放）
	player.position = Vector2(150, 530)
	camera.position = player.position
	update_ui()

# 从场景文件加载关卡
func load_level_from_scene(scene_path: String):
	var level_scene = load(scene_path)
	if level_scene:
		var level_instance = level_scene.instantiate()
		$Level.add_child(level_instance)

func sx(x): return int(x * SCALE_X)
func sy(y): return int(y * SCALE_Y)
func sw(w): return int(w * SCALE_X)
func sh(h): return int(h * SCALE_Y)

func create_block(x, y, w, h, color):
	var body = StaticBody2D.new()
	body.position = Vector2(sx(x), sy(y))

	var rw = sw(w)
	var rh = sh(h)

	# 可视部分
	var rect = ColorRect.new()
	rect.size = Vector2(rw, rh)
	rect.color = color
	body.add_child(rect)
	
	# 碰撞部分
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(rw, rh)
	collision.shape = shape
	collision.position = Vector2(rw / 2, rh / 2)
	body.add_child(collision)
	
	$Level.add_child(body)

func create_platform(x, y, w, h):
	# 草地顶层（绿色）
	var grass_top = Color(0.28, 0.55, 0.25)
	create_block(x, y, w, 15, grass_top)
	
	# 泥土层（棕色）- 平台主体
	var dirt = Color(0.45, 0.38, 0.28)
	create_block(x, y + 15, w, h - 15, dirt)

func create_exit(x, y):
	var exit = Area2D.new()
	exit.name = "Exit"
	exit.position = Vector2(sx(x), sy(y))

	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(40, 60)
	exit.add_child(shape)

	# 出口主体 - 金色
	var rect = ColorRect.new()
	rect.size = Vector2(40, 60)
	rect.position = Vector2(-20, -30)
	rect.color = Color(1.0, 0.85, 0.2)  # 更明亮的金色
	exit.add_child(rect)

	# 发光效果 - 更温暖的金色光芒
	var glow = ColorRect.new()
	glow.size = Vector2(50, 70)
	glow.position = Vector2(-25, -35)
	glow.color = Color(1.0, 0.95, 0.4, 0.6)  # 更明亮的金色光晕
	glow.z_index = -1
	exit.add_child(glow)

	# 内部核心 - 白色高亮
	var core = ColorRect.new()
	core.size = Vector2(20, 40)
	core.position = Vector2(-10, -20)
	core.color = Color(1, 0.95, 0.7, 0.9)
	exit.add_child(core)

	exit.body_entered.connect(_on_exit_entered)
	$Level.add_child(exit)

func _on_exit_entered(body: Node2D) -> void:
	if body.name == "Player":
		# 检查是否所有敌人都被击败
		var all_enemies_defeated = true
		for s in slimes:
			if is_instance_valid(s) and s.hp > 0:
				all_enemies_defeated = false
				break
		
		if all_enemies_defeated:
			_on_player_reached_exit()
		else:
			# 显示提示
			show_message("请先击败所有敌人！")

func create_bottle(x: float, y: float, color_name: String) -> void:
	var bottle: Area2D = Area2D.new()
	bottle.position = Vector2(sx(x), sy(y))
	bottle.set_meta("type", "bottle")
	bottle.set_meta("color", color_name)

	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 12
	bottle.add_child(shape)

	var rect: ColorRect = ColorRect.new()
	rect.size = Vector2(20, 24)
	rect.position = Vector2(-10, -12)

	# 优化后的瓶子颜色 - 更鲜艳
	match color_name:
		"green":
			rect.color = Color(0.3, 0.85, 0.35)  # 鲜绿色
		"yellow":
			rect.color = Color(1.0, 0.85, 0.2)  # 明黄色
		_:
			rect.color = Color(0.3, 0.85, 0.35)

	bottle.add_child(rect)

	# 添加发光效果
	var glow: ColorRect = ColorRect.new()
	glow.size = Vector2(28, 32)
	glow.position = Vector2(-14, -14)
	if color_name == "green":
		glow.color = Color(0.3, 0.85, 0.35, 0.4)
	else:
		glow.color = Color(1.0, 0.85, 0.2, 0.4)
	glow.z_index = -1
	bottle.add_child(glow)

	bottle.body_entered.connect(func(b: Node2D): _on_item_collected(b, bottle))
	$Level.add_child(bottle)

func create_mushroom(x: float, y: float, color_name: String) -> void:
	var m: Area2D = Area2D.new()
	m.position = Vector2(sx(x), sy(y))
	m.set_meta("type", "mushroom")
	m.set_meta("color", color_name)

	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 12
	m.add_child(shape)

	var rect: ColorRect = ColorRect.new()
	rect.size = Vector2(20, 20)
	rect.position = Vector2(-10, -10)
	rect.color = get_mushroom_color(color_name)
	m.add_child(rect)

	m.body_entered.connect(func(b: Node2D): _on_item_collected(b, m))
	$Level.add_child(m)

func create_slime(x: float, y: float, color_name: String, patrol: float = 80) -> void:
	var slime: Node2D = resource_mgr.instantiate_scene("slime")
	if not slime:
		print("Main", "无法创建史莱姆")
		return

	slime.position = Vector2(sx(x), sy(y))
	slime.color_name = color_name
	slime.patrol_distance = sw(patrol)

	slime.set_meta("type", "slime")
	slime.set_meta("color", color_name)

	$Level.add_child(slime)
	slimes.append(slime)

# ============ 新敌人创建函数 ============

func create_bat(x: float, y: float, color_name: String, range: float = 100) -> void:
	var bat: Node2D = resource_mgr.instantiate_scene("bat")
	if not bat:
		print("Main", "无法创建蝙蝠")
		return

	bat.position = Vector2(sx(x), sy(y))
	bat.color_name = color_name
	bat.fly_range = sw(range)

	bat.set_meta("type", "bat")
	$Level.add_child(bat)
	slimes.append(bat)

func create_skeleton(x: float, y: float) -> void:
	var skeleton: Node2D = resource_mgr.instantiate_scene("skeleton")
	if not skeleton:
		print("Main", "无法创建骷髅")
		return

	skeleton.position = Vector2(sx(x), sy(y))

	skeleton.set_meta("type", "skeleton")
	$Level.add_child(skeleton)
	slimes.append(skeleton)

func create_hedgehog(x: float, y: float, color_name: String, patrol: float = 60) -> void:
	var hedgehog: Node2D = resource_mgr.instantiate_scene("hedgehog")
	if not hedgehog:
		print("Main", "无法创建刺猬")
		return

	hedgehog.position = Vector2(sx(x), sy(y))
	hedgehog.color_name = color_name
	hedgehog.patrol_distance = sw(patrol)

	hedgehog.set_meta("type", "hedgehog")
	$Level.add_child(hedgehog)
	slimes.append(hedgehog)

func create_snail(x: float, y: float, color_name: String, patrol: float = 50) -> void:
	var snail: Node2D = resource_mgr.instantiate_scene("snail")
	if not snail:
		print("Main", "无法创建蜗牛")
		return

	snail.position = Vector2(sx(x), sy(y))
	snail.color_name = color_name
	snail.patrol_distance = sw(patrol)

	snail.set_meta("type", "snail")
	$Level.add_child(snail)
	slimes.append(snail)

# ============ 蜘蛛创建函数 ============
func create_spider(x: float, y: float, color_name: String = "black") -> void:
	var spider: Node2D = resource_mgr.instantiate_scene("spider")
	if not spider:
		print("Main", "无法创建蜘蛛")
		return

	spider.position = Vector2(sx(x), sy(y))
	spider.color_name = color_name

	spider.set_meta("type", "spider")
	$Level.add_child(spider)
	slimes.append(spider)

# ============ 蛇创建函数 ============
func create_snake(x: float, y: float, color_name: String = "green") -> void:
	var snake: Node2D = resource_mgr.instantiate_scene("snake")
	if not snake:
		print("Main", "无法创建蛇")
		return

	snake.position = Vector2(sx(x), sy(y))
	snake.color_name = color_name

	snake.set_meta("type", "snake")
	$Level.add_child(snake)
	slimes.append(snake)

# ============ AI Boss创建函数 ============

func create_ai_boss(x: float, y: float, boss_name: String = "暗影领主", max_hp: int = 20) -> void:
	var boss: Node2D = resource_mgr.instantiate_scene("ai_boss")
	if not boss:
		print("Main", "无法创建Boss")
		return

	boss.position = Vector2(sx(x), sy(y))
	boss.boss_name = boss_name
	boss.max_hp = max_hp
	boss.hp = max_hp

	boss.set_meta("type", "boss")
	boss.boss_defeated.connect(_on_boss_defeated)

	# 连接Boss信号到UI系统
	if boss.has_signal("boss_intro_requested"):
		boss.boss_intro_requested.connect(_on_boss_intro_requested.bind(boss))
	if boss.has_signal("stats_updated"):
		boss.stats_updated.connect(_on_boss_stats_updated)
	if boss.has_signal("ai_learning_updated"):
		boss.ai_learning_updated.connect(_on_ai_learning_updated)

	$Level.add_child(boss)
	slimes.append(boss)
	current_boss = boss

	# 开始录制死亡回放
	if death_replay_system:
		death_replay_system.start_recording(player, boss)

	print("Main", "Boss '%s' 已创建" % boss_name)

func get_mushroom_color(color_name: String) -> Color:
	var colors: Dictionary = {
		"red": Color(1.0, 0.35, 0.35),      # 鲜红色
		"green": Color(0.25, 0.85, 0.35),    # 鲜绿色
		"blue": Color(0.25, 0.55, 1.0),     # 鲜蓝色
		"brown": Color(0.7, 0.5, 0.25),     # 棕色
		"purple": Color(0.85, 0.4, 0.95)     # 鲜紫色
	}
	return colors.get(color_name, Color.WHITE)

func get_slime_color(color_name: String) -> Color:
	var colors: Dictionary = {
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
	return colors.get(color_name, Color(0.35, 0.85, 0.4))

func _on_item_collected(body: Node2D, item: Area2D) -> void:
	if body.name == "Player" and item and item.has_meta("type"):
		var type_str: String = item.get_meta("type")
		var color: String = item.get_meta("color", "")
		var pos: Vector2 = item.global_position

		g.collect_item(type_str, color)
		audio.play_collect()  # 播放收集音效
		spawn_collect_effect(pos)
		update_ui()
		item.queue_free()

func _on_slime_hit(body: Node2D) -> void:
	if body.name == "Player":
		body.take_damage()

func spawn_collect_effect(pos: Vector2) -> void:
	var particles: CPUParticles2D = object_pool.get_object("particles")
	if not particles:
		print("Main", "无法从对象池获取粒子")
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
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = Color(1, 0.9, 0.3, 1)
	particles.position = pos
	add_child(particles)

	await get_tree().create_timer(0.5).timeout
	object_pool.return_object(particles)

func update_ui():
	$CanvasLayer/LevelLabel.text = "第 %d 关 - %s" % [g.current_level_num, g.get_level_name(g.current_level_num)]
	update_stats_with_time()

# 更新统计信息（包含时间）
func update_stats_with_time():
	var time_str = env.get_time_string()
	var period_str = env.get_period_name()
	$CanvasLayer/StatsLabel.text = "⏰ %s [%s]  🍄 %d  🟢 %d  🟡 %d" % [
		time_str, period_str, g.level_mushrooms, g.level_bottles_green, g.level_bottles_yellow
	]

func _process(delta):
	# 更新相机跟随玩家
	if player and is_instance_valid(player):
		camera.position = camera.position.lerp(player.position, 5.0 * delta)
	
	# 更新视差背景滚动
	if parallax_bg:
		parallax_bg.scroll_offset = camera.position - Vector2(VIEW_W / 2, VIEW_H / 2)
	
	# 更新时间显示
	update_stats_with_time()

	# 更新死亡回放系统
	if death_replay_system and death_replay_system.is_active():
		if death_replay_system.is_recording:
			death_replay_system.record_frame()
		elif death_replay_system.is_replaying:
			death_replay_system.update_replay()

	# 消息定时器
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			# 移除消息标签
			for child in $CanvasLayer.get_children():
				if child is Label and child.position.y == 100:
					child.queue_free()

	# 只更新史莱姆的巡逻移动（旧代码方式创建的史莱姆）
	for s in slimes:
		if is_instance_valid(s) and s.has_meta("patrol"):
			var patrol = s.get_meta("patrol")
			var start_x = s.get_meta("start_x")
			var dir = s.get_meta("dir")

			s.velocity.x = dir * 60
			s.move_and_slide()

			if s.position.x > start_x + patrol:
				s.set_meta("dir", -1)
				s.scale.x = -1
			elif s.position.x < start_x - patrol:
				s.set_meta("dir", 1)
				s.scale.x = 1

# ============ 关卡创建 ============
# 长地图 + 峡谷地形设计

# 第1关：草原 + 小峡谷
func create_level_1():
	# 随机种子生成 - 每次都不同
	var session_seed = int(Time.get_unix_time_from_system()) % 10000
	var level_seed = g.current_level_num * 1000 + session_seed
	seed(level_seed)

	# 关卡长度（基于关卡号递增）
	var level_length = 3000 + g.current_level_num * 500 + randi() % 500
	
	# 创建起始平台（固定）
	create_platform(0, 580, 400 + randi() % 200, 100)
	
	# 随机生成中间平台
	var current_x = 500
	var current_y = 550 + randi() % 50
	var platform_count = 15 + g.current_level_num * 3 + randi() % 5
	
	var last_y = 580
	for i in range(platform_count):
		var gap = 60 + randi() % 60  # 平台间距减小到60-120，确保能跳上去
		var platform_width = 120 + randi() % 80  # 平台宽度
		var height_change = randi() % 100 - 40  # 高度变化
		
		current_x += gap
		current_y = clamp(last_y - height_change, 300, 580)
		
		# 创建平台
		create_platform(current_x, current_y, platform_width, 20)
		last_y = current_y
		
		# 30%概率在平台上方放置收集品
		if randf() < 0.3:
			var bottle_color = ["green", "yellow"].pick_random()
			create_bottle(current_x + platform_width/2, current_y - 40, bottle_color)
		
		# 20%概率放置蘑菇
		if randf() < 0.2:
			var mushroom_color = ["red", "blue", "purple", "brown"].pick_random()
			create_mushroom(current_x + randi() % int(platform_width), current_y - 30, mushroom_color)
		
		# 25%概率放置敌人
		if randf() < 0.25:
			var enemy_type = ["slime", "bat", "hedgehog", "snail"].pick_random()
			match enemy_type:
				"slime":
					var colors = ["green", "blue", "pink", "yellow", "cyan", "purple"]
					create_slime(current_x + randi() % int(platform_width), current_y - 10, colors.pick_random(), 50 + randi() % 50)
				"bat":
					create_bat(current_x + platform_width/2, current_y - 100 + randi() % 50, ["purple", "red", "blue"].pick_random())
				"hedgehog":
					create_hedgehog(current_x + randi() % int(platform_width), current_y - 15, ["brown", "gray", "purple"].pick_random())
				"snail":
					create_snail(current_x + randi() % int(platform_width), current_y - 10, ["purple", "green", "yellow"].pick_random())
	
	# 创建终点平台（确保在末尾）
	create_exit(current_x + 300, last_y - 20)
	create_platform(current_x + 200, last_y + 40, 250, 100)

# 第2关：更高难度的随机地图
func create_level_2():
	var session_seed = int(Time.get_unix_time_from_system()) % 10000
	var level_seed = g.current_level_num * 1000 + session_seed
	seed(level_seed)
	
	var level_length = 3200 + g.current_level_num * 500 + randi() % 500
	
	# 起始平台
	create_platform(0, 580, 350 + randi() % 150, 100)
	
	# 峡谷挑战 - 更大跳跃间隔
	var current_x = 450
	var current_y = 550 + randi() % 30
	var last_y = 580
	
	for i in range(18 + g.current_level_num * 2):
		var gap = 70 + randi() % 60  # 减小间距到70-130
		var platform_width = 100 + randi() % 80
		var height_change = randi() % 80 - 20  # 减小高度变化
		
		current_x += gap
		current_y = clamp(last_y - height_change, 280, 580)
		
		create_platform(current_x, current_y, platform_width, 20)
		last_y = current_y
		
		# 更高难度的放置
		if randf() < 0.35:
			create_bottle(current_x + platform_width/2, current_y - 40, ["green", "yellow"].pick_random())
		if randf() < 0.15:
			create_mushroom(current_x, current_y - 30, ["blue", "brown", "purple"].pick_random())
		if randf() < 0.3:
			var types = ["slime", "bat", "skeleton", "hedgehog"]
			var t = types.pick_random()
			if t == "slime":
				create_slime(current_x, current_y - 10, ["blue", "pink", "cyan"].pick_random(), 60 + randi() % 40)
			elif t == "bat":
				create_bat(current_x + platform_width/2, current_y - 80, ["red", "blue"].pick_random())
			elif t == "skeleton":
				create_skeleton(current_x, current_y - 25)
			else:
				create_hedgehog(current_x, current_y - 15, ["gray", "purple"].pick_random())
	
	create_exit(current_x + 300, last_y - 20)
	create_platform(current_x + 200, last_y + 40, 250, 100)

# 第3关：极简平台 + 迷你Boss
func create_level_3():
	var session_seed = int(Time.get_unix_time_from_system()) % 10000
	var level_seed = g.current_level_num * 1000 + session_seed
	seed(level_seed)
	
	var level_length = 3500 + g.current_level_num * 500 + randi() % 500
	
	create_platform(0, 580, 300 + randi() % 100, 100)
	
	var current_x = 400
	var current_y = 520 + randi() % 40
	var last_y = 580
	
	for i in range(20 + g.current_level_num * 2):
		var gap = 55 + randi() % 55  # 减小间距到55-110
		var platform_width = 80 + randi() % 60
		var height_change = randi() % 70 - 15  # 减小高度变化
		
		current_x += gap
		current_y = clamp(last_y - height_change, 250, 560)
		
		create_platform(current_x, current_y, platform_width, 20)
		last_y = current_y
		
		if randf() < 0.4:
			create_bottle(current_x + platform_width/2, current_y - 40, ["green", "yellow"].pick_random())
		if randf() < 0.12:
			create_mushroom(current_x, current_y - 30, ["red", "purple"].pick_random())
		if randf() < 0.35:
			var t = ["slime", "bat", "hedgehog", "snail", "spider", "snake"].pick_random()
			match t:
				"slime":
					create_slime(current_x, current_y - 10, ["cyan", "gray", "orange"].pick_random(), 50 + randi() % 50)
				"bat":
					create_bat(current_x + platform_width/2, current_y - 60 + randi() % 30, ["purple", "red"].pick_random())
				"hedgehog":
					create_hedgehog(current_x, current_y - 15, ["brown", "gray"].pick_random())
				"snail":
					create_snail(current_x, current_y - 10, ["purple", "green"].pick_random())
				"spider":
					create_spider(current_x + platform_width/2, current_y - 150, ["black", "brown"].pick_random())
				"snake":
					create_snake(current_x + platform_width/2, current_y + 5, ["green", "red"].pick_random())
	
	# 迷你Boss
	create_platform(current_x + 250, last_y + 40, 200, 100)
	create_ai_boss(current_x + 250, last_y, "山地领主", 8 + g.current_level_num * 2)
	
	create_exit(current_x + 400, last_y - 20)
	create_platform(current_x + 300, last_y + 40, 200, 100)

# 第4关：洞穴挑战
func create_level_4():
	var session_seed = int(Time.get_unix_time_from_system()) % 10000
	var level_seed = g.current_level_num * 1000 + session_seed
	seed(level_seed)
	
	create_platform(0, 580, 250 + randi() % 100, 100)
	
	var current_x = 350
	var current_y = 530 + randi() % 30
	var last_y = 580
	
	for i in range(22 + g.current_level_num * 2):
		var gap = 50 + randi() % 50  # 减小间距到50-100
		var platform_width = 70 + randi() % 50
		var height_change = randi() % 60 - 15  # 减小高度变化
		
		current_x += gap
		current_y = clamp(last_y - height_change, 230, 550)
		
		create_platform(current_x, current_y, platform_width, 20)
		last_y = current_y
		
		if randf() < 0.45:
			create_bottle(current_x + platform_width/2, current_y - 40, ["green", "yellow"].pick_random())
		if randf() < 0.1:
			create_mushroom(current_x, current_y - 30, ["green", "brown", "purple"].pick_random())
		if randf() < 0.4:
			var t = ["slime", "bat", "hedgehog", "snail", "spider", "snake", "skeleton"].pick_random()
			match t:
				"slime":
					create_slime(current_x, current_y - 10, ["yellow", "orange", "gray"].pick_random(), 40 + randi() % 40)
				"bat":
					create_bat(current_x + platform_width/2, current_y - 50 + randi() % 20, ["purple", "red"].pick_random())
				"hedgehog":
					create_hedgehog(current_x, current_y - 15, ["brown", "gray"].pick_random())
				"snail":
					create_snail(current_x, current_y - 10, ["purple", "green", "yellow"].pick_random())
				"spider":
					create_spider(current_x + platform_width/2, current_y - 120, ["black", "brown", "red"].pick_random())
				"snake":
					create_snake(current_x + platform_width/2, current_y + 5, ["green", "red", "yellow"].pick_random())
				"skeleton":
					create_skeleton(current_x, current_y - 25)
	
	create_platform(current_x + 200, last_y + 40, 180, 100)
	create_ai_boss(current_x + 200, last_y, "洞穴守护者", 10 + g.current_level_num * 2)
	
	create_exit(current_x + 350, last_y - 20)
	create_platform(current_x + 250, last_y + 40, 180, 100)

# 第5关：终极挑战 - Boss关
func create_level_5():
	var session_seed = int(Time.get_unix_time_from_system()) % 10000
	var level_seed = g.current_level_num * 1000 + session_seed
	seed(level_seed)
	
	create_platform(0, 580, 350 + randi() % 100, 100)
	
	var current_x = 450
	var current_y = 520 + randi() % 40
	var last_y = 580
	
	for i in range(25 + g.current_level_num * 2):
		var gap = 45 + randi() % 45  # 减小间距到45-90
		var platform_width = 60 + randi() % 50
		var height_change = randi() % 50 - 12  # 减小高度变化
		
		current_x += gap
		current_y = clamp(last_y - height_change, 200, 540)
		
		create_platform(current_x, current_y, platform_width, 20)
		last_y = current_y
		
		if randf() < 0.5:
			create_bottle(current_x + platform_width/2, current_y - 40, ["green", "yellow"].pick_random())
		if randf() < 0.08:
			create_mushroom(current_x, current_y - 30, ["red", "blue", "purple", "brown"].pick_random())
		if randf() < 0.45:
			var t = ["slime", "bat", "hedgehog", "snail", "spider", "snake", "skeleton"].pick_random()
			match t:
				"slime":
					create_slime(current_x, current_y - 10, ["cyan", "gray", "orange", "purple"].pick_random(), 50 + randi() % 50)
				"bat":
					create_bat(current_x + platform_width/2, current_y - 40 + randi() % 20, ["purple", "red", "blue"].pick_random())
				"hedgehog":
					create_hedgehog(current_x, current_y - 15, ["brown", "gray", "purple"].pick_random())
				"snail":
					create_snail(current_x, current_y - 10, ["purple", "green", "yellow", "red"].pick_random())
				"spider":
					create_spider(current_x + platform_width/2, current_y - 100, ["black", "brown", "red", "purple"].pick_random())
				"snake":
					create_snake(current_x + platform_width/2, current_y + 5, ["green", "red", "yellow", "blue"].pick_random())
				"skeleton":
					create_skeleton(current_x, current_y - 25)
	
	# 最终Boss
	create_platform(current_x + 200, last_y + 40, 300, 100)
	create_ai_boss(current_x + 200, last_y, "暗影领主", 15 + g.current_level_num * 3)
	
	# 移除出口（Boss击败后自动完成）

# ============ 游戏流程 ============

var message_timer: float = 0.0

func show_message(text: String):
	# 创建临时消息显示
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position.y = 100
	$CanvasLayer.add_child(label)
	
	message_timer = 2.0

func _on_player_reached_exit():
	g.complete_level()
	show_victory()

func show_victory():
	g.current_state = g.GameState.VICTORY

	$CanvasLayer/VictoryPanel.visible = true

	var score = g.calculate_score()
	var total = g.calculate_total_score()

	# 计算奖励
	var mushroom_reward = g.level_mushrooms
	var next_level = g.current_level_num + 1
	
	$CanvasLayer/VictoryPanel/VBox/Title.text = "🎉 第 %d 关完成！" % g.current_level_num
	$CanvasLayer/VictoryPanel/VBox/Score.text = "本关得分: %d" % score
	$CanvasLayer/VictoryPanel/VBox/Total.text = "总得分: %d" % total
	$CanvasLayer/VictoryPanel/VBox/Items.text = "🍄 %d  🟢 %d  🟡 %d" % [g.level_mushrooms, g.level_bottles_green, g.level_bottles_yellow]
	
	# 添加奖励提示
	if g.level_mushrooms > 0:
		$CanvasLayer/VictoryPanel/VBox/Items.text += "\n💰 获得 %d 蘑菇奖励！" % g.level_mushrooms
	
	# 关卡解锁提示
	if g.current_level_num < g.max_unlocked_level:
		$CanvasLayer/VictoryPanel/VBox/Items.text += "\n🔓 第 %d 关已解锁！" % next_level

	# 设置胜利面板字体大小（适应全屏）
	$CanvasLayer/VictoryPanel/VBox/Title.add_theme_font_size_override("font_size", 56)
	$CanvasLayer/VictoryPanel/VBox/Title.add_theme_color_override("font_color", Color(1, 0.9, 0.4, 1))
	$CanvasLayer/VictoryPanel/VBox/Score.add_theme_font_size_override("font_size", 40)
	$CanvasLayer/VictoryPanel/VBox/Score.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 1))
	$CanvasLayer/VictoryPanel/VBox/Total.add_theme_font_size_override("font_size", 40)
	$CanvasLayer/VictoryPanel/VBox/Total.add_theme_color_override("font_color", Color(0.9, 0.85, 1, 1))
	$CanvasLayer/VictoryPanel/VBox/Items.add_theme_font_size_override("font_size", 36)
	$CanvasLayer/VictoryPanel/VBox/Items.add_theme_color_override("font_color", Color(0.85, 0.95, 1, 1))
	$CanvasLayer/VictoryPanel/VBox/Items.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$CanvasLayer/VictoryPanel/VBox/Items.custom_minimum_size.y = 120
	$CanvasLayer/VictoryPanel/VBox/BtnNext.add_theme_font_size_override("font_size", 32)
	$CanvasLayer/VictoryPanel/VBox/BtnNext.custom_minimum_size = Vector2(240, 70)

	if g.current_level_num < 5:
		$CanvasLayer/VictoryPanel/VBox/BtnNext.text = "下一关"
		$CanvasLayer/VictoryPanel/VBox/BtnNext.pressed.disconnect(_on_next_level)
		$CanvasLayer/VictoryPanel/VBox/BtnNext.pressed.connect(_on_next_level)
	else:
		$CanvasLayer/VictoryPanel/VBox/BtnNext.text = "返回主菜单"
		$CanvasLayer/VictoryPanel/VBox/BtnNext.pressed.disconnect(_on_next_level)
		$CanvasLayer/VictoryPanel/VBox/BtnNext.pressed.connect(_on_back_menu)

func _on_next_level():
	$CanvasLayer/VictoryPanel.visible = false
	g.current_level_num += 1
	load_level(g.current_level_num)

func _on_back_menu():
	audio.stop_bgm()  # 停止背景音乐
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_back_pressed():
	print("Main: 返回主菜单按钮被点击！")
	_on_back_menu()

# ============ Boss事件处理 ============

func _on_boss_defeated():
	print("Boss被击败！关卡即将完成...")

	# 停止死亡回放录制
	if death_replay_system and death_replay_system.is_recording:
		death_replay_system.clear_recording()

	# 隐藏战斗统计面板
	if combat_stats_panel:
		combat_stats_panel.hide_panel()

	current_boss = null

	# 延迟后完成关卡
	await get_tree().create_timer(2.0).timeout
	_on_player_reached_exit()

# Boss预告请求处理
func _on_boss_intro_requested(boss):
	if not boss_intro_ui:
		return

	# 确定Boss能力列表
	var abilities: Array = ["近战", "弹幕"]
	if boss.max_hp >= 12:
		abilities.append("冲撞")
	if boss.max_hp >= 15:
		abilities.append("震地波")
	if boss.max_hp >= 20:
		abilities.append_array(["传送", "狂暴"])

	# 暂停游戏
	get_tree().paused = true

	# 显示预告
	boss_intro_ui.show_boss_intro(
		boss.boss_name,
		_get_boss_title(boss.boss_name),
		boss.max_hp,
		abilities
	)

	# 预告完成后恢复游戏
	await boss_intro_ui.intro_completed
	get_tree().paused = false

	# 显示战斗统计面板
	if combat_stats_panel:
		combat_stats_panel.show_panel()
		combat_stats_panel.update_boss_hp(boss.hp, boss.max_hp)

func _get_boss_title(name: String) -> String:
	var titles: Dictionary = {
		"山地领主": "山脉的守护者",
		"洞穴守护者": "黑暗中的潜伏者",
		"暗影领主": "最终BOSS"
	}
	return titles.get(name, "强大的敌人")

# Boss统计更新处理
func _on_boss_stats_updated(stats: Dictionary):
	if combat_stats_panel and current_boss:
		if "damage_dealt" in stats:
			combat_stats_panel.increment_stat("hits_landed")
		if "boss_current_hp" in stats:
			combat_stats_panel.update_boss_hp(stats["boss_current_hp"], current_boss.max_hp)
		if "boss_hp_percent" in stats:
			var percent: float = stats["boss_hp_percent"]
			combat_stats_panel.update_boss_hp(int(percent / 100 * current_boss.max_hp), current_boss.max_hp)

# AI学习数据更新处理
func _on_ai_learning_updated(preference: String, accuracy: float, attack: String):
	if combat_stats_panel:
		combat_stats_panel.update_ai_info(preference, accuracy, attack)

# 玩家死亡处理
func _on_player_died():
	print("Main", "玩家死亡！")

	# 停止死亡回放录制
	if death_replay_system and death_replay_system.is_recording:
		var replay_data = death_replay_system.stop_recording()

		# 显示死亡回放UI
		if death_replay_ui and not replay_data.is_empty():
			death_replay_ui.show_death_replay(death_replay_system, replay_data)
