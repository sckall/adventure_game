extends Node2D

# ============ 游戏主控 ============

var dungeon
var player
var camera
var current_level = 1

func _ready():
	# 创建地牢
	dungeon = preload("res://scripts/Dungeon.gd").new()
	add_child(dungeon)
	
	# 创建玩家
	player = preload("res://scripts/Player.gd").new()
	add_child(player)
	player.position = Vector2(100, 500)
	
	# 创建相机
	camera = Camera2D.new()
	camera.zoom = Vector2(1.5, 1.5)
	add_child(camera)
	
	# 连接信号
	player.died.connect(_on_player_died)
	
	print("=== 游戏开始 ===")

func _process(delta):
	# 相机跟随
	camera.position = camera.position.lerp(player.position, 5.0 * delta)
	
	# 检测道具收集
	for item in dungeon.items:
		if is_instance_valid(item) and player.position.distance_to(item.position) < 30:
			collect_item(item)

func collect_item(item):
	var type = item.name
	match type:
		"mushroom":
			player.heal(1)
			print("吃到蘑菇！HP回复")
		"bottle":
			player.heal(2)
			print("喝到药水！HP+2")
	
	dungeon.items.erase(item)
	item.queue_free()

func _on_player_died():
	print("玩家死亡！重新开始关卡%d" % current_level)
	player.position = Vector2(100, 500)
	player.hp = player.max_hp

func _input(event):
	# 检测出口
	if event is InputEvent and event.pressed:
		# R键重置
		if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_R):
			dungeon.generate_level(current_level)
