extends Node2D

# ============ 简单地牢 ============

var platforms = []
var enemies = []
var items = []
var exit_door

var level_num = 1
var level_width = 2000
var level_height = 600

func _ready():
	generate_level(1)

func generate_level(num):
	level_num = num
	clear_level()
	
	print("=== 生成地牢 %d ===" % num)
	
	# 地面
	create_floor()
	
	# 平台
	create_platforms(10 + num * 2)
	
	# 敌人
	create_enemies(5 + num)
	
	# 道具
	create_items(3 + num)
	
	# 出口
	create_exit()
	
	print("完成: %d平台, %d敌人, %d道具" % [platforms.size(), enemies.size(), items.size()])

func clear_level():
	for n in [platforms, enemies, items]:
		for obj in n:
			if is_instance_valid(obj):
				obj.queue_free()
		n.clear()
	if exit_door and is_instance_valid(exit_door):
		exit_door.queue_free()
	exit_door = null

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
	rect.color = Color(0.3, 0.25, 0.2)
	floor.add_child(rect)
	
	add_child(floor)
	platforms.append(floor)

func create_platforms(count):
	for i in range(count):
		var x = 200 + randi() % (level_width - 400)
		var y = 200 + randi() % (level_height - 300)
		var w = 100 + randi() % 100
		create_platform(x, y, w)

func create_platform(x, y, w):
	var plat = StaticBody2D.new()
	plat.position = Vector2(x, y)
	
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(w, 20)
	plat.add_child(shape)
	
	var rect = ColorRect.new()
	rect.size = Vector2(w, 20)
	rect.color = Color(0.4, 0.5, 0.3)
	plat.add_child(rect)
	
	add_child(plat)
	platforms.append(plat)

func create_enemies(count):
	var types = ["slime", "bat", "hedgehog"]
	for i in range(count):
		var plat = platforms.pick_random()
		if plat:
			create_enemy(plat.position.x, plat.position.y - 30, types.pick_random())

func create_enemy(x, y, type):
	var enemy = Node2D.new()
	enemy.name = type
	enemy.position = Vector2(x, y)
	
	# 颜色
	var color = Color.GREEN
	match type:
		"bat": color = Color(0.5, 0.3, 0.6)
		"hedgehog": color = Color(0.6, 0.5, 0.3)
	
	var body = ColorRect.new()
	body.size = Vector2(28, 28)
	body.position = Vector2(-14, -14)
	body.color = color
	enemy.add_child(body)
	
	# 碰撞
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 14
	area.add_child(shape)
	enemy.add_child(area)
	
	# 数据
	enemy.set_meta("type", type)
	enemy.set_meta("hp", 1)
	
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

func create_exit():
	exit_door = Area2D.new()
	exit_door.name = "Exit"
	exit_door.position = Vector2(level_width - 80, level_height - 20)
	
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(40, 60)
	exit_door.add_child(shape)
	
	var rect = ColorRect.new()
	rect.size = Vector2(40, 60)
	rect.position = Vector2(-20, -30)
	rect.color = Color(1.0, 0.9, 0.3)
	exit_door.add_child(rect)
	
	add_child(exit_door)

func _process(delta):
	# 敌人AI：向玩家移动
	var player = get_tree().get_first_node_in_group("player")
	if player:
		for enemy in enemies:
			if is_instance_valid(enemy):
				var dir = (player.position - enemy.position).normalized()
				enemy.position += dir * 40.0 * delta
