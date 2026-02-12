extends Node2D

# ============ 简化版游戏主场景 ============
# 测试能否正常运行

@onready var player = $Player
@onready var camera = $Camera2D
@onready var enemies = $Enemies
@onready var items = $Items

var item_db: Node

func _ready():
	item_db = get_node_or_null("/root/ItemDB")
	if not item_db:
		item_db = load("res://scripts/items/SimpleItemDB.gd").new()
		add_child(item_db)
	
	print("=== 游戏启动测试 ===")
	
	# 测试道具生成
	var weapon = item_db.get_random_weapon(2)
	print("随机武器: %s (伤害: %d)" % [weapon["name"], weapon.get("damage", 0)])
	
	var armor = item_db.get_random_armor(2)
	print("随机护甲: %s (防御: %d)" % [armor["name"], armor.get("defense", 0)])
	
	var potion = item_db.get_random_potion(1)
	print("随机药水: %s" % potion["name"])
	
	# 生成几个敌人测试
	_spawn_test_enemies()
	
	print("=== 测试完成 ===")

func _spawn_test_enemies():
	var enemy_types = ["slime", "bat", "hedgehog", "skeleton"]
	
	for i in range(4):
		var enemy = _create_simple_enemy(enemy_types[i])
		enemy.position = Vector2(200 + i * 150, 500)
		enemies.add_child(enemy)

func _create_simple_enemy(type: String) -> Node2D:
	var e = Node2D.new()
	e.name = type
	
	# 身体
	var body = ColorRect.new()
	body.size = Vector2(32, 32)
	body.position = Vector2(-16, -16)
	
	match type:
		"slime": body.color = Color(0.3, 0.8, 0.3)
		"bat": 
			body.size = Vector2(24, 16)
			body.color = Color(0.5, 0.3, 0.6)
		"hedgehog": body.color = Color(0.6, 0.5, 0.3)
		"skeleton": body.color = Color(0.9, 0.9, 0.9)
	
	e.add_child(body)
	
	# 眼睛
	var eye = ColorRect.new()
	eye.size = Vector2(4, 4)
	eye.position = Vector2(-8, -6)
	eye.color = Color.WHITE
	e.add_child(eye)
	
	# HP标签
	var label = Label.new()
	label.text = type.capitalize()
	label.add_theme_font_size_override("font_size", 12)
	label.position = Vector2(-20, -40)
	e.add_child(label)
	
	# 简单碰撞
	var col = Area2D.new()
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 16
	shape.shape = circle
	col.add_child(shape)
	e.add_child(col)
	
	return e

func _process(delta):
	# 测试敌人移动
	for enemy in enemies.get_children():
		if enemy.name in ["slime", "hedgehog", "skeleton"]:
			if enemy.position.x > 800:
				enemy.position.x = 200
			else:
				enemy.position.x += 50 * delta

# 测试掉落道具
func _on_item_pickup(item_data: Dictionary):
	var item = _create_item_sprite(item_data)
	items.add_child(item)

func _create_item_sprite(data: Dictionary) -> Area2D:
	var item = Area2D.new()
	
	var rect = ColorRect.new()
	rect.size = Vector2(20, 20)
	rect.position = Vector2(-10, -10)
	rect.color = item_db.get_rarity_color(data.get("rarity", 1))
	item.add_child(rect)
	
	# 漂浮动画
	var tween = create_tween().set_loops()
	tween.tween_property(item, "position:y", -5, 0.5).from(0.0)
	
	return item
