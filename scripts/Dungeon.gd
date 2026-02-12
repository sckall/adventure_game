extends Node2D

# ============ 地牢生成器 ============

var platforms = []
var enemies = []
var items = []
var decorations = []
var weapons = []
var exit_door
var decoration_layer
var background_layer
var midground_layer
var spawn_pos: Vector2 = Vector2(100, 500)
var exit_pos: Vector2 = Vector2(0, 0)
var main_path_positions: Array = []

var level_num = 1
var level_width = 2000
var level_height = 600
var wall_height = 500

func _ready():
	generate_level(1)

func generate_level(num):
	level_num = num
	clear_level()

	print("=== 生成地牢 %d ===" % num)

	# 背景层
	create_background()

	# 墙壁
	create_walls()

	# 地面
	create_floor()

	# 装饰层
	create_decorations()

	# 平台
	create_platforms(10 + num * 2)

	# 敌人
	create_enemies(5 + num)

	# 道具
	create_items(3 + num)

	# 武器掉落
	create_weapons(2 + num / 2)

	# 出口
	create_exit()

	print("完成: %d平台, %d敌人, %d道具" % [platforms.size(), enemies.size(), items.size()])

func clear_level():
	for n in [platforms, enemies, items, decorations, weapons]:
		for obj in n:
			if is_instance_valid(obj):
				obj.queue_free()
		n.clear()
	if exit_door and is_instance_valid(exit_door):
		exit_door.queue_free()
	exit_door = null
	if decoration_layer and is_instance_valid(decoration_layer):
		decoration_layer.queue_free()
	decoration_layer = null
	if background_layer and is_instance_valid(background_layer):
		background_layer.queue_free()
	background_layer = null
	if midground_layer and is_instance_valid(midground_layer):
		midground_layer.queue_free()
	midground_layer = null
	main_path_positions = []
	spawn_pos = Vector2(100, 500)
	exit_pos = Vector2.ZERO

func create_background():
	background_layer = Node2D.new()
	background_layer.z_index = -10
	add_child(background_layer)

	# 深色背景
	var bg = ColorRect.new()
	bg.size = Vector2(level_width + 400, wall_height + 200)
	bg.position = Vector2(-200, -100)
	bg.color = Color(0.1, 0.11, 0.16)
	background_layer.add_child(bg)

	# 渐变层（上浅下深）
	var grad_top = ColorRect.new()
	grad_top.size = Vector2(level_width + 400, 260)
	grad_top.position = Vector2(-200, -100)
	grad_top.color = Color(0.16, 0.18, 0.26, 0.45)
	background_layer.add_child(grad_top)
	var grad_mid = ColorRect.new()
	grad_mid.size = Vector2(level_width + 400, 260)
	grad_mid.position = Vector2(-200, 140)
	grad_mid.color = Color(0.12, 0.14, 0.2, 0.35)
	background_layer.add_child(grad_mid)

	# 背景石墙纹理
	for i in range(40):
		var stone = ColorRect.new()
		stone.size = Vector2(60 + randi() % 40, 30 + randi() % 20)
		stone.position = Vector2(randi() % int(level_width + 200), randi() % int(wall_height))
		stone.color = Color(0.14, 0.15, 0.2)
		background_layer.add_child(stone)

	# 远处迷雾
	for i in range(8):
		var fog = ColorRect.new()
		fog.size = Vector2(300 + randi() % 200, 200 + randi() % 100)
		fog.position = Vector2(randi() % int(level_width + 100), randi() % int(wall_height - 200))
		fog.color = Color(0.16, 0.18, 0.26, 0.2)
		background_layer.add_child(fog)

	# 中景层（剪影）
	midground_layer = Node2D.new()
	midground_layer.z_index = -7
	add_child(midground_layer)
	for i in range(8):
		var pillar = ColorRect.new()
		var h = 140 + randi() % 180
		pillar.size = Vector2(36, h)
		pillar.position = Vector2(120 + randi() % (level_width - 240), level_height - h)
		pillar.color = Color(0.18, 0.2, 0.26)
		midground_layer.add_child(pillar)
	for i in range(12):
		var slab = ColorRect.new()
		slab.size = Vector2(90 + randi() % 80, 16)
		slab.position = Vector2(80 + randi() % (level_width - 160), 120 + randi() % 260)
		slab.color = Color(0.2, 0.22, 0.28)
		midground_layer.add_child(slab)

func create_walls():
	# 左墙
	create_wall_segment(0, wall_height, 40, Color(0.2, 0.18, 0.15))
	# 右墙
	create_wall_segment(level_width, wall_height, 40, Color(0.2, 0.18, 0.15))
	# 天花板
	create_ceiling()

func create_wall_segment(x, h, w, color):
	var wall = StaticBody2D.new()
	wall.position = Vector2(x + w/2, h/2)

	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(w, h)
	wall.add_child(shape)

	var rect = ColorRect.new()
	rect.size = Vector2(w, h)
	rect.position = Vector2(-w/2, -h/2)
	rect.color = color
	wall.add_child(rect)

	# 砖块纹理
	for y in range(0, h, 40):
		for sx in range(-w/2 + 10, w/2 - 10, 35):
			var brick = ColorRect.new()
			brick.size = Vector2(30 + randi() % 8, 15 + randi() % 6)
			brick.position = Vector2(sx, y + randi() % 10)
			brick.color = color.darkened(0.15)
			wall.add_child(brick)

	# 顶部高光
	var top = ColorRect.new()
	top.size = Vector2(w, 8)
	top.position = Vector2(-w/2, -h/2)
	top.color = Color(0.48, 0.43, 0.38)
	wall.add_child(top)

	add_child(wall)
	platforms.append(wall)

func create_ceiling():
	var ceiling = StaticBody2D.new()
	ceiling.position = Vector2(level_width/2, 0)

	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(level_width + 100, 40)
	shape.position = Vector2(0, 20)
	ceiling.add_child(shape)

	var rect = ColorRect.new()
	rect.size = Vector2(level_width + 100, 40)
	rect.position = Vector2(-(level_width + 100)/2, 0)
	rect.color = Color(0.18, 0.16, 0.14)
	ceiling.add_child(rect)

	# 底部高光（地牢内部可见）
	var bottom = ColorRect.new()
	bottom.size = Vector2(level_width + 100, 6)
	bottom.position = Vector2(-(level_width + 100)/2, 34)
	bottom.color = Color(0.35, 0.32, 0.3)
	ceiling.add_child(bottom)

	# 悬挂物
	for i in range(12):
		var chain = ColorRect.new()
		chain.size = Vector2(4, 20 + randi() % 30)
		chain.position = Vector2(100 + randi() % (level_width - 200), 40)
		chain.color = Color(0.25, 0.22, 0.2)
		ceiling.add_child(chain)

	add_child(ceiling)
	platforms.append(ceiling)

func create_floor():
	var floor = StaticBody2D.new()
	floor.position = Vector2(level_width/2, level_height + 50)
	
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(level_width + 200, 100)
	shape.position = Vector2(0, 50)
	floor.add_child(shape)
	
	var rect = ColorRect.new()
	rect.size = Vector2(level_width + 200, 100)
	rect.position = Vector2(-(level_width + 200)/2, 0)
	rect.color = Color(0.36, 0.32, 0.26)
	floor.add_child(rect)

	# 顶边高光
	var highlight = ColorRect.new()
	highlight.size = Vector2(level_width + 200, 6)
	highlight.position = Vector2(-(level_width + 200)/2, 0)
	highlight.color = Color(0.62, 0.56, 0.46, 0.95)
	floor.add_child(highlight)

	# 前景描边
	var edge = ColorRect.new()
	edge.size = Vector2(level_width + 200, 3)
	edge.position = Vector2(-(level_width + 200)/2, 6)
	edge.color = Color(0.25, 0.22, 0.2, 0.7)
	floor.add_child(edge)
	
	# 苔藓细节
	for i in range(12):
		var moss = ColorRect.new()
		var w = 20 + randi() % 60
		moss.size = Vector2(w, 4)
		moss.position = Vector2(-(level_width + 200)/2 + randi() % int(level_width + 200 - w), 2)
		moss.color = Color(0.25, 0.35, 0.2, 0.7)
		floor.add_child(moss)

	# 碎石细节
	for i in range(14):
		var pebble = ColorRect.new()
		var pw = 4 + randi() % 8
		var ph = 2 + randi() % 5
		pebble.size = Vector2(pw, ph)
		pebble.position = Vector2(-(level_width + 200)/2 + randi() % int(level_width + 200 - pw), 12 + randi() % 10)
		pebble.color = Color(0.22, 0.2, 0.18, 0.9)
		floor.add_child(pebble)
	
	add_child(floor)
	platforms.append(floor)

func create_platforms(count):
	# BSP 空间分割 + 主路连通 + 关键点
	var area: Rect2 = Rect2(120, 140, level_width - 240, level_height - 240)
	var leaves: Array = []
	var depth: int = _calc_bsp_depth(count)
	_bsp_split(area, 0, depth, leaves)
	if leaves.is_empty():
		return

	main_path_positions = []
	var total: int = leaves.size()
	var sorted_indices: Array = []
	for i in range(total):
		sorted_indices.append(i)
	sorted_indices.sort_custom(func(a, b): return leaves[a].position.x < leaves[b].position.x)

	var path_count: int = clamp(int(count * 0.4), 5, total)
	var main_indices: Array = []
	for i in range(path_count):
		var idx: int = int(round(float(i) * float(total - 1) / max(1.0, float(path_count - 1))))
		var leaf_index: int = int(sorted_indices[idx])
		if not main_indices.has(leaf_index):
			main_indices.append(leaf_index)

	# 留白区块（避开主路）
	var skip_count: int = min(2, int(total * 0.15))
	var skip_indices: Array = _pick_unique_indices(total, skip_count, main_indices)

	var floor_y: float = float(level_height + 50.0)
	var band_low: float = floor_y - 110.0
	var band_mid: float = floor_y - 160.0
	var band_high: float = floor_y - 210.0
	var max_step: float = 60.0
	var used: Array = []

	# 主路径：从左到右，保证高度连续
	var prev_y: float = band_mid
	for leaf_index in main_indices:
		var rect: Rect2 = leaves[leaf_index]
		var w: float = clampf(rect.size.x * randf_range(0.55, 0.85), 150.0, 260.0)
		var x: float = _rand_x_in_rect(rect, w)
		var y: float = clampf(prev_y + randf_range(-max_step, max_step), band_mid - 40.0, band_mid + 40.0)
		prev_y = y
		create_platform(x, y, int(w))
		var pos: Vector2 = Vector2(x, y)
		main_path_positions.append(pos)
		used.append(pos)
		_add_torch_at(Vector2(x + w * 0.5, y - 18.0), 0.28)

	# 关键点：出生 / 出口
	if main_path_positions.size() > 0:
		var first = main_path_positions[0]
		var last = main_path_positions[main_path_positions.size() - 1]
		spawn_pos = Vector2(first.x, first.y - 24.0)
		exit_pos = Vector2(clampf(last.x + 180.0, 200.0, float(level_width - 80.0)), level_height - 20.0)

	# 支路平台（战斗/奖励/休息）
	for i in range(total):
		if skip_indices.has(i) or main_indices.has(i):
			continue
		var rect2: Rect2 = leaves[i]
		var w2: float = clampf(rect2.size.x * randf_range(0.4, 0.7), 90.0, 180.0)
		var x2: float = _rand_x_in_rect(rect2, w2)
		var band_pick: int = randi() % 3
		var base_y: float = band_mid
		if band_pick == 0:
			base_y = band_low
		elif band_pick == 2:
			base_y = band_high
		var y2: float = clampf(base_y + randf_range(-25.0, 25.0), band_high - 10.0, band_low + 10.0)
		var pos2: Vector2 = Vector2(x2, y2)
		if _too_close_platform(pos2, used, 170.0):
			continue
		create_platform(x2, y2, int(w2))
		used.append(pos2)
		if band_pick == 2:
			_add_torch_at(Vector2(x2 + w2 * 0.5, y2 - 18.0), 0.18)

func _calc_bsp_depth(count: int) -> int:
	var depth := 0
	var n := 1
	while n < count:
		n *= 2
		depth += 1
	return clamp(depth, 2, 4)

func _bsp_split(rect: Rect2, depth: int, max_depth: int, leaves: Array) -> void:
	if depth >= max_depth or rect.size.x < 220.0 or rect.size.y < 180.0:
		leaves.append(rect)
		return
	var split_h := rect.size.x > rect.size.y
	if rect.size.x < 320.0:
		split_h = false
	elif rect.size.y < 220.0:
		split_h = true
	if randf() < 0.2:
		split_h = !split_h
	var split := randf_range(0.4, 0.6)
	if split_h:
		var w1 := rect.size.x * split
		var r1 = Rect2(rect.position, Vector2(w1, rect.size.y))
		var r2 = Rect2(rect.position + Vector2(w1, 0), Vector2(rect.size.x - w1, rect.size.y))
		_bsp_split(r1, depth + 1, max_depth, leaves)
		_bsp_split(r2, depth + 1, max_depth, leaves)
	else:
		var h1 := rect.size.y * split
		var r1 = Rect2(rect.position, Vector2(rect.size.x, h1))
		var r2 = Rect2(rect.position + Vector2(0, h1), Vector2(rect.size.x, rect.size.y - h1))
		_bsp_split(r1, depth + 1, max_depth, leaves)
		_bsp_split(r2, depth + 1, max_depth, leaves)

func _rand_x_in_rect(rect: Rect2, w: float) -> float:
	var x_min: float = rect.position.x + 20.0
	var x_max: float = rect.position.x + rect.size.x - w - 20.0
	if x_max <= x_min:
		x_max = x_min + 1.0
	return randf_range(x_min, x_max)

func _pick_unique_indices(total: int, count: int, exclude: Array) -> Array:
	var picks: Array = []
	var tries := 0
	while picks.size() < count and tries < total * 4:
		tries += 1
		var idx = randi() % total
		if exclude.has(idx) or picks.has(idx):
			continue
		picks.append(idx)
	return picks

func _too_close_platform(pos: Vector2, positions: Array, min_dist: float) -> bool:
	for p in positions:
		if pos.distance_to(p) < min_dist:
			return true
	return false

func create_platform(x, y, w):
	var plat = StaticBody2D.new()
	plat.position = Vector2(x, y)
	
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(w, 20)
	plat.add_child(shape)
	
	var rect = ColorRect.new()
	rect.size = Vector2(w, 20)
	rect.color = Color(0.44, 0.5, 0.38)
	plat.add_child(rect)

	# 顶边高光 + 随机苔藓
	var top = ColorRect.new()
	top.size = Vector2(w, 4)
	top.color = Color(0.76, 0.8, 0.6, 0.95)
	plat.add_child(top)

	var rim = ColorRect.new()
	rim.size = Vector2(w, 2)
	rim.position = Vector2(0, 4)
	rim.color = Color(0.28, 0.26, 0.22, 0.7)
	plat.add_child(rim)

	var moss_count = 1 + randi() % 3
	for i in range(moss_count):
		var moss = ColorRect.new()
		var mw = 10 + randi() % 30
		moss.size = Vector2(mw, 3)
		moss.position = Vector2(randi() % max(1, w - mw), 2)
		moss.color = Color(0.25, 0.45, 0.25, 0.8)
		plat.add_child(moss)

	# 裂纹/碎石
	for i in range(1 + randi() % 2):
		var crack = ColorRect.new()
		var cw = 8 + randi() % 20
		crack.size = Vector2(cw, 2)
		crack.position = Vector2(randi() % max(1, w - cw), 10 + randi() % 6)
		crack.color = Color(0.18, 0.2, 0.16, 0.9)
		plat.add_child(crack)
	
	add_child(plat)
	platforms.append(plat)

func create_enemies(count):
	var types = ["slime", "bat", "hedgehog", "skeleton", "beetle", "golem", "wisp"]
	for i in range(count):
		var plat = platforms.pick_random()
		if plat:
			create_enemy(plat.position.x, plat.position.y - 30, types.pick_random())

func create_enemy(x, y, type):
	var enemy = Node2D.new()
	enemy.name = type
	enemy.position = Vector2(x, y)
	enemy.add_to_group("enemies")
	enemy.set_meta("hit_knockback", Vector2.ZERO)
	
	# 阴影
	var shadow = ColorRect.new()
	shadow.size = Vector2(22, 6)
	shadow.position = Vector2(-11, 10)
	shadow.color = Color(0, 0, 0, 0.35)
	enemy.add_child(shadow)
	
	# 颜色
	var color = Color(0.35, 0.8, 0.45) # slime 默认
	match type:
		"bat": color = Color(0.5, 0.3, 0.6)
		"slime": color = Color(0.35, 0.8, 0.45)
		"hedgehog": color = Color(0.6, 0.5, 0.3)
		"skeleton": color = Color(0.8, 0.8, 0.75)
		"beetle": color = Color(0.2, 0.3, 0.45)
		"golem": color = Color(0.35, 0.35, 0.38)
		"wisp": color = Color(0.55, 0.8, 1.0)
	
	# 身体（分层建模）
	var body = Node2D.new()
	body.name = "Body"
	enemy.add_child(body)

	var outline = ColorRect.new()
	outline.size = Vector2(28, 20)
	outline.position = Vector2(-14, -13)
	outline.color = color.darkened(0.55)
	body.add_child(outline)

	var torso = ColorRect.new()
	torso.size = Vector2(26, 18)
	torso.position = Vector2(-13, -12)
	torso.color = color
	body.add_child(torso)

	var head_outline = ColorRect.new()
	head_outline.size = Vector2(18, 14)
	head_outline.position = Vector2(-9, -25)
	head_outline.color = color.darkened(0.55)
	body.add_child(head_outline)

	var head = ColorRect.new()
	head.size = Vector2(16, 12)
	head.position = Vector2(-8, -24)
	head.color = color.lightened(0.2)
	body.add_child(head)

	var eye = ColorRect.new()
	eye.size = Vector2(4, 4)
	eye.position = Vector2(2, -20)
	eye.color = Color(1.0, 0.2, 0.2)
	body.add_child(eye)

	if type == "bat":
		outline.size = Vector2(22, 14)
		outline.position = Vector2(-11, -12)
		torso.size = Vector2(20, 12)
		torso.position = Vector2(-10, -11)
		head_outline.size = Vector2(14, 10)
		head_outline.position = Vector2(-7, -22)
		head.size = Vector2(12, 8)
		head.position = Vector2(-6, -21)
		var wing_l = ColorRect.new()
		wing_l.size = Vector2(16, 8)
		wing_l.position = Vector2(-28, -16)
		wing_l.color = color.darkened(0.2)
		body.add_child(wing_l)
		var wing_r = ColorRect.new()
		wing_r.size = Vector2(16, 8)
		wing_r.position = Vector2(12, -16)
		wing_r.color = color.darkened(0.2)
		body.add_child(wing_r)
		var ear_l = ColorRect.new()
		ear_l.size = Vector2(4, 6)
		ear_l.position = Vector2(-8, -28)
		ear_l.color = color.darkened(0.35)
		body.add_child(ear_l)
		var ear_r = ColorRect.new()
		ear_r.size = Vector2(4, 6)
		ear_r.position = Vector2(4, -28)
		ear_r.color = color.darkened(0.35)
		body.add_child(ear_r)
	elif type == "slime":
		outline.size = Vector2(26, 14)
		outline.position = Vector2(-13, -6)
		torso.size = Vector2(24, 12)
		torso.position = Vector2(-12, -5)
		head_outline.queue_free()
		head.queue_free()
		var gloss = ColorRect.new()
		gloss.size = Vector2(8, 4)
		gloss.position = Vector2(-6, -2)
		gloss.color = Color(0.8, 1.0, 0.85, 0.7)
		body.add_child(gloss)
	elif type == "hedgehog":
		var spikes = ColorRect.new()
		spikes.size = Vector2(28, 6)
		spikes.position = Vector2(-14, -18)
		spikes.color = Color(0.4, 0.3, 0.2)
		body.add_child(spikes)
	elif type == "skeleton":
		var rib = ColorRect.new()
		rib.size = Vector2(20, 4)
		rib.position = Vector2(-10, -8)
		rib.color = Color(0.7, 0.7, 0.65)
		body.add_child(rib)
	elif type == "beetle":
		var shell = ColorRect.new()
		shell.size = Vector2(26, 10)
		shell.position = Vector2(-13, -16)
		shell.color = Color(0.15, 0.2, 0.3)
		body.add_child(shell)
	elif type == "golem":
		torso.size = Vector2(30, 20)
		torso.position = Vector2(-15, -14)
		head.size = Vector2(18, 14)
		head.position = Vector2(-9, -30)
		var core = ColorRect.new()
		core.size = Vector2(10, 8)
		core.position = Vector2(-5, -10)
		core.color = Color(1.0, 0.55, 0.3, 0.9)
		body.add_child(core)
	elif type == "wisp":
		torso.size = Vector2(18, 14)
		torso.position = Vector2(-9, -10)
		head.queue_free()
		var glow = ColorRect.new()
		glow.size = Vector2(22, 22)
		glow.position = Vector2(-11, -20)
		glow.color = Color(0.5, 0.85, 1.0, 0.55)
		body.add_child(glow)
	
	# 碰撞
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	var hit_radius := 14.0
	match type:
		"golem": hit_radius = 18.0
		"beetle": hit_radius = 16.0
		"wisp": hit_radius = 12.0
	shape.shape.radius = hit_radius
	enemy.set_meta("hit_radius", hit_radius)
	area.add_child(shape)
	enemy.add_child(area)
	
	# 数据
	enemy.set_meta("type", type)
	var base_hp = 1.0
	match type:
		"bat": base_hp = 1.5
		"hedgehog": base_hp = 2.0
		"skeleton": base_hp = 2.5
		"beetle": base_hp = 3.0
		"golem": base_hp = 4.0
		"wisp": base_hp = 1.2
	enemy.set_meta("hp", base_hp)
	var contact_damage = 1.0
	match type:
		"golem": contact_damage = 2.0
		"hedgehog": contact_damage = 1.5
		"wisp": contact_damage = 1.2
	enemy.set_meta("contact_damage", contact_damage)
	var contact_knockback := Vector2(220.0, -120.0)
	match type:
		"golem": contact_knockback = Vector2(320.0, -160.0)
		"beetle": contact_knockback = Vector2(260.0, -140.0)
		"bat": contact_knockback = Vector2(200.0, -110.0)
		"slime": contact_knockback = Vector2(180.0, -100.0)
	enemy.set_meta("contact_knockback", contact_knockback)
	var vision_range := 260.0
	match type:
		"bat": vision_range = 320.0
		"wisp": vision_range = 340.0
		"golem": vision_range = 200.0
	enemy.set_meta("vision_range", vision_range)
	enemy.set_meta("ai_state", "idle")
	enemy.set_meta("ai_timer", randf_range(0.4, 1.0))
	
	add_child(enemy)
	enemies.append(enemy)

func create_items(count):
	var types = ["mushroom", "bottle"]
	for i in range(count):
		var plat = platforms.pick_random()
		if plat:
			create_item(plat.position.x, plat.position.y - 30, types.pick_random())

func create_item(x, y, type):
	var item = Area2D.new()
	item.name = type
	item.position = Vector2(x, y)
	
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 10
	item.add_child(shape)
	
	var rect = ColorRect.new()
	rect.size = Vector2(16, 16)
	rect.position = Vector2(-8, -8)
	rect.color = Color.RED if type == "mushroom" else Color.GREEN
	item.add_child(rect)
	
	add_child(item)
	items.append(item)

func create_weapons(count):
	for i in range(count):
		var plat = platforms.pick_random()
		if plat:
			create_weapon_pickup(plat.position.x, plat.position.y - 40)

func create_weapon_pickup(x, y):
	var weapon_item = Area2D.new()
	weapon_item.name = "Weapon"
	weapon_item.position = Vector2(x, y)

	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 12
	weapon_item.add_child(shape)

	var rect = ColorRect.new()
	rect.size = Vector2(18, 8)
	rect.position = Vector2(-9, -4)
	rect.color = Color(0.8, 0.8, 0.9)
	weapon_item.add_child(rect)

	weapon_item.set_meta("weapon", _roll_weapon())
	add_child(weapon_item)
	weapons.append(weapon_item)

func _roll_weapon() -> Dictionary:
	var prefixes = ["Sharp", "Heavy", "Swift", "Jagged"]
	var suffixes = ["of Ember", "of Frost", "of Venom", "of Echo"]
	var rarity = "common" if randi() % 100 < 75 else "rare"
	var name = "Blade"
	var prefix = prefixes[randi() % prefixes.size()]
	var suffix = suffixes[randi() % suffixes.size()]
	var mult = 1.0 if rarity == "common" else 1.25
	return {
		"name": "%s %s %s" % [prefix, name, suffix],
		"rarity": rarity,
		"mod": suffix,
		"damage_mult": mult
	}

func create_exit():
	exit_door = Area2D.new()
	exit_door.name = "Exit"
	if exit_pos != Vector2.ZERO:
		exit_door.position = exit_pos
	else:
		exit_door.position = Vector2(level_width - 80, level_height - 20)
	
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(40, 60)
	exit_door.add_child(shape)
	
	# 发光底座
	var glow = ColorRect.new()
	glow.size = Vector2(70, 90)
	glow.position = Vector2(-35, -50)
	glow.color = Color(1.0, 0.9, 0.3, 0.25)
	exit_door.add_child(glow)
	
	# 门框
	var frame = ColorRect.new()
	frame.size = Vector2(48, 66)
	frame.position = Vector2(-24, -33)
	frame.color = Color(0.35, 0.28, 0.15)
	exit_door.add_child(frame)
	
	# 门体
	var rect = ColorRect.new()
	rect.size = Vector2(36, 56)
	rect.position = Vector2(-18, -28)
	rect.color = Color(1.0, 0.9, 0.3)
	exit_door.add_child(rect)
	
	# 门体高光
	var door_light = ColorRect.new()
	door_light.size = Vector2(6, 46)
	door_light.position = Vector2(-14, -24)
	door_light.color = Color(1.0, 1.0, 0.75, 0.8)
	exit_door.add_child(door_light)
	
	add_child(exit_door)

func _process(delta):
	# 敌人AI：向玩家移动
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("is_stealthed") and player.is_stealthed():
			return
		for enemy in enemies:
			if is_instance_valid(enemy):
				var to_player = player.position - enemy.position
				var dist = to_player.length()
				var vision = 260.0
				if enemy.has_meta("vision_range"):
					vision = float(enemy.get_meta("vision_range"))
				if dist > vision:
					# 视野外轻微漂移/巡逻
					var t = Time.get_ticks_msec() / 1000.0
					enemy.position.x += sin(t + float(enemy.get_instance_id() % 13)) * 6.0 * delta
					continue
				var dir = to_player / max(1.0, dist)
				var state = String(enemy.get_meta("ai_state"))
				var timer = float(enemy.get_meta("ai_timer"))
				timer -= delta
				var enemy_type = String(enemy.get_meta("type"))
				if state == "windup":
					if timer <= 0.0:
						state = "lunge"
						timer = 0.18
						enemy.set_meta("lunge_dir", dir)
				elif state == "lunge":
					var lunge_dir: Vector2 = enemy.get_meta("lunge_dir")
					var lunge_speed = 180.0
					if enemy_type == "wisp":
						lunge_speed = 220.0
					elif enemy_type == "hedgehog":
						lunge_speed = 160.0
					elif enemy_type == "beetle":
						lunge_speed = 200.0
					elif enemy_type == "slime":
						lunge_speed = 150.0
					var move = lunge_dir * lunge_speed * delta
					if enemy_type == "bat" or enemy_type == "slime":
						move.y -= 40.0 * delta
					enemy.position += move
					if timer <= 0.0:
						state = "chase"
						timer = randf_range(0.5, 1.1)
				elif state == "rest":
					if timer <= 0.0:
						state = "chase"
						timer = randf_range(0.6, 1.2)
				elif state == "chase":
					if timer <= 0.0 and dist < 140.0 and (enemy_type == "bat" or enemy_type == "wisp" or enemy_type == "hedgehog" or enemy_type == "slime" or enemy_type == "beetle"):
						state = "windup"
						timer = 0.18
					elif timer <= 0.0 and enemy_type == "golem":
						state = "rest"
						timer = 0.25
				var base_speed := 40.0
				match enemy_type:
					"bat": base_speed = 55.0
					"wisp": base_speed = 60.0
					"golem": base_speed = 28.0
					"beetle": base_speed = 32.0
				if state == "chase" or state == "idle":
					enemy.position += dir * base_speed * delta
				enemy.set_meta("ai_state", state)
				enemy.set_meta("ai_timer", timer)
				if enemy.has_meta("hit_knockback"):
					var kb: Vector2 = enemy.get_meta("hit_knockback")
					if kb.length() > 0.5:
						enemy.position += kb * delta
						enemy.set_meta("hit_knockback", kb * 0.85)
					else:
						enemy.set_meta("hit_knockback", Vector2.ZERO)

func create_decorations():
	decoration_layer = Node2D.new()
	decoration_layer.z_index = -5
	add_child(decoration_layer)

	# 暗角与雾效
	for i in range(5):
		var fog = ColorRect.new()
		fog.size = Vector2(260 + randi() % 180, 120 + randi() % 100)
		fog.position = Vector2(randi() % level_width, 60 + randi() % 360)
		fog.color = Color(0.12, 0.14, 0.2, 0.18)
		decoration_layer.add_child(fog)
		decorations.append(fog)

	# 石柱
	for i in range(6):
		var pillar = ColorRect.new()
		var h = 80 + randi() % 120
		pillar.size = Vector2(30, h)
		pillar.position = Vector2(80 + randi() % (level_width - 160), level_height - h)
		pillar.color = Color(0.3, 0.3, 0.34)
		decoration_layer.add_child(pillar)
		decorations.append(pillar)

	# 晶体
	for i in range(10):
		var crystal = ColorRect.new()
		crystal.size = Vector2(10 + randi() % 16, 18 + randi() % 26)
		crystal.position = Vector2(80 + randi() % (level_width - 160), 180 + randi() % 280)
		crystal.color = Color(0.55, 0.85, 1.0, 0.7)
		decoration_layer.add_child(crystal)
		decorations.append(crystal)

	# 火把
	for i in range(6):
		var pos = Vector2(60 + randi() % (level_width - 120), 160 + randi() % 260)
		_add_torch_at(pos, 0.35)

func _add_torch_at(pos: Vector2, glow_alpha: float) -> void:
	if decoration_layer == null or not is_instance_valid(decoration_layer):
		decoration_layer = Node2D.new()
		decoration_layer.z_index = -5
		add_child(decoration_layer)
	var torch = ColorRect.new()
	torch.size = Vector2(6, 22)
	torch.position = pos
	torch.color = Color(0.35, 0.2, 0.1)
	decoration_layer.add_child(torch)
	decorations.append(torch)

	var glow = ColorRect.new()
	glow.size = Vector2(44, 44)
	glow.position = pos + Vector2(-19, -24)
	glow.color = Color(1.0, 0.7, 0.3, glow_alpha)
	decoration_layer.add_child(glow)
	decorations.append(glow)

	var flame = ColorRect.new()
	flame.size = Vector2(10, 14)
	flame.position = pos + Vector2(-2, -14)
	flame.color = Color(1.0, 0.72, 0.3, 0.9)
	decoration_layer.add_child(flame)
	decorations.append(flame)

	var flame_inner = ColorRect.new()
	flame_inner.size = Vector2(6, 8)
	flame_inner.position = pos + Vector2(0, -12)
	flame_inner.color = Color(1.0, 0.9, 0.65, 0.95)
	decoration_layer.add_child(flame_inner)
	decorations.append(flame_inner)
