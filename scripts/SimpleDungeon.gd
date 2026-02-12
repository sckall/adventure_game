extends Node2D

# ============ 简单地牢生成器 ============
# 简单的平台关卡

var platforms: Array = []
var enemies: Array = []
var items: Array = []
var exits: Array = []

const LEVEL_WIDTH = 3000
const LEVEL_HEIGHT = 600

func generate(level_num: int = 1):
	clear_all()
	
	print("生成关卡 %d..." % level_num)
	
	# 1. 地面
	create_floor()
	
	# 2. 随机平台
	create_platforms(level_num)
	
	# 3. 敌人
	create_enemies(level_num)
	
	# 4. 道具
	create_items(level_num)
	
	# 5. 出口
	create_exit()
	
	print("关卡生成完成!")
	print("平台: %d, 敌人: %d, 道具: %d" % [platforms.size(), enemies.size(), items.size()])

func clear_all():
	for p in platforms:
		if is_instance_valid(p):
			p.queue_free()
	platforms.clear()
	
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	
	for i in items:
		if is_instance_valid(i):
			i.queue_free()
	items.clear()
	
	for ex in exits:
		if is_instance_valid(ex):
			ex.queue_free()
	exits.clear()

func create_floor():
	var floor = StaticBody2D.new()
	floor.position = Vector2(LEVEL_WIDTH/2, LEVEL_HEIGHT + 50)
	
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(LEVEL_WIDTH + 200, 100)
	shape.position = Vector2(0, 50)
	floor.add_child(shape)
	
	var rect = ColorRect.new()
	rect.size = Vector2(LEVEL_WIDTH + 200, 100)
	rect.position = Vector2(-(LEVEL_WIDTH + 200)/2, 0)
	rect.color = Color(0.3, 0.25, 0.2)
	floor.add_child(rect)
	
	add_child(floor)
	platforms.append(floor)

func create_platforms(level_num: int):
	var count = 8 + level_num * 2
	
	for i in range(count):
		var x = 300 + randi() % (LEVEL_WIDTH - 600)
		var y = 200 + randi() % 300
		var width = 80 + randi() % 120
		
		create_platform(x, y, width)

func create_platform(x: float, y: float, width: float):
	var plat = StaticBody2D.new()
	plat.position = Vector2(x, y)
	
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(width, 20)
	plat.add_child(shape)
	
	var rect = ColorRect.new()
	rect.size = Vector2(width, 20)
	rect.color = Color(0.35, 0.55, 0.25)
	plat.add_child(rect)
	
	add_child(plat)
	platforms.append(plat)

func create_enemies(level_num: int):
	var enemy_types = ["slime", "bat", "hedgehog", "snail", "skeleton"]
	var count = 4 + level_num * 2
	
	for i in range(count):
		var plat = platforms.pick_random()
		if not plat:
			continue
		
		var x = plat.position.x + randf_range(-30, 30)
		var y = plat.position.y - 30
		var type = enemy_types.pick_random()
		
		create_enemy(x, y, type, level_num)

func create_enemy(x: float, y: float, type: String, level: int):
	var enemy = Node2D.new()
	enemy.name = type
	enemy.position = Vector2(x, y)
	
	# 颜色
	var color = Color(0.3, 0.8, 0.3)  # 绿色默认
	match type:
		"bat": color = Color(0.5, 0.3, 0.6)
		"hedgehog": color = Color(0.6, 0.5, 0.3)
		"snail": color = Color(0.5, 0.4, 0.5)
		"skeleton": color = Color(0.9, 0.9, 0.9)
	
	var body = ColorRect.new()
	body.size = Vector2(32, 32)
	body.position = Vector2(-16, -16)
	body.color = color
	enemy.add_child(body)
	
	# 眼睛
	var eye = ColorRect.new()
	eye.size = Vector2(6, 6)
	eye.position = Vector2(-10, -8)
	eye.color = Color.WHITE
	enemy.add_child(eye)
	
	# 碰撞
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 16
	area.add_child(shape)
	enemy.add_child(area)
	
	# 数据
	enemy.set_meta("type", type)
	enemy.set_meta("hp", 1 + level)
	enemy.set_meta("level", level)
	
	add_child(enemy)
	enemies.append(enemy)

func create_items(level_num: int):
	var item_types = ["bottle", "mushroom"]
	var count = 3 + level_num
	
	for i in range(count):
		var plat = platforms.pick_random()
		if not plat:
			continue
		
		var x = plat.position.x + randf_range(-20, 20)
		var y = plat.position.y - 40
		var type = item_types.pick_random()
		
		create_item(x, y, type)

func create_item(x: float, y: float, type: String):
	var item = Area2D.new()
	item.position = Vector2(x, y)
	item.set_meta("type", type)
	
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 12
	item.add_child(shape)
	
	var color = Color(0.3, 0.8, 0.3)  # 绿色
	if type == "mushroom":
		color = Color(1.0, 0.3, 0.3)  # 红色
	
	var rect = ColorRect.new()
	rect.size = Vector2(20, 20)
	rect.position = Vector2(-10, -10)
	rect.color = color
	item.add_child(rect)
	
	# 漂浮动画
	var tween = create_tween().set_loops()
	tween.tween_property(item, "position:y", -3, 0.5).from(0.0)
	
	add_child(item)
	items.append(item)

func create_exit():
	var exit = Area2D.new()
	exit.name = "Exit"
	exit.position = Vector2(LEVEL_WIDTH - 100, LEVEL_HEIGHT)
	
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(50, 80)
	exit.add_child(shape)
	
	var rect = ColorRect.new()
	rect.size = Vector2(50, 80)
	rect.position = Vector2(-25, -40)
	rect.color = Color(1.0, 0.85, 0.2)
	exit.add_child(rect)
	
	add_child(exit)
	exits.append(exit)

# 获取敌人数据
func get_enemy_data(enemy: Node2D) -> Dictionary:
	return {
		"type": enemy.get_meta("type", "slime"),
		"hp": enemy.get_meta("hp", 1),
		"level": enemy.get_meta("level", 1)
	}

# 移除敌人
func remove_enemy(enemy: Node2D):
	enemies.erase(enemy)
	enemy.queue_free()
