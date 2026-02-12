extends Node2D

# ============ 像素地牢生成器 ============

const TILE_SIZE := 32
const GRID_WIDTH := 52
const GRID_HEIGHT := 22

var level_num := 1
var platforms: Array = []
var enemies: Array = []
var items: Array = []
var exit_door: Area2D

var _bg_layer: Node2D
var _tile_layer: Node2D
var _entity_layer: Node2D

func _ready():
	randomize()
	_setup_layers()
	generate_level(1)

func _setup_layers() -> void:
	_bg_layer = Node2D.new()
	_bg_layer.name = "Background"
	add_child(_bg_layer)

	_tile_layer = Node2D.new()
	_tile_layer.name = "Tiles"
	add_child(_tile_layer)

	_entity_layer = Node2D.new()
	_entity_layer.name = "Entities"
	add_child(_entity_layer)

func generate_level(num: int) -> void:
	level_num = num
	clear_level()
	_draw_background()
	_create_border_walls()
	_create_floor_band()
	_create_platform_clusters(8 + level_num * 2)
	_place_torches(5 + int(level_num / 2))
	create_enemies(4 + level_num)
	create_items(5 + level_num)
	create_exit()

func clear_level() -> void:
	for group in [platforms, enemies, items]:
		for obj in group:
			if is_instance_valid(obj):
				obj.queue_free()
		group.clear()

	if exit_door and is_instance_valid(exit_door):
		exit_door.queue_free()
	exit_door = null

	for layer in [_bg_layer, _tile_layer, _entity_layer]:
		for n in layer.get_children():
			n.queue_free()

func _draw_background() -> void:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var t := ColorRect.new()
			t.size = Vector2(TILE_SIZE, TILE_SIZE)
			t.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			var checker := (x + y) % 2 == 0
			var base_color := Color(0.06, 0.07, 0.10) if checker else Color(0.08, 0.09, 0.12)
			var depth_tint := float(y) / float(GRID_HEIGHT) * 0.05
			t.color = base_color.lightened(depth_tint)
			_bg_layer.add_child(t)

	var top_fog := ColorRect.new()
	top_fog.position = Vector2.ZERO
	top_fog.size = Vector2(GRID_WIDTH * TILE_SIZE, 140)
	top_fog.color = Color(0.05, 0.06, 0.12, 0.28)
	_bg_layer.add_child(top_fog)

func _create_border_walls() -> void:
	for x in range(GRID_WIDTH):
		_create_solid_tile(x, GRID_HEIGHT - 1, Color(0.20, 0.18, 0.15))
	for y in range(GRID_HEIGHT):
		_create_solid_tile(0, y, Color(0.15, 0.14, 0.13))
		_create_solid_tile(GRID_WIDTH - 1, y, Color(0.15, 0.14, 0.13))

func _create_floor_band() -> void:
	for x in range(1, GRID_WIDTH - 1):
		_create_solid_tile(x, GRID_HEIGHT - 2, Color(0.26, 0.24, 0.20))

func _create_platform_clusters(cluster_count: int) -> void:
	for i in range(cluster_count):
		var length := randi_range(2, 6)
		var y := randi_range(5, GRID_HEIGHT - 5)
		var x := randi_range(2, GRID_WIDTH - length - 2)
		for j in range(length):
			_create_solid_tile(x + j, y, Color(0.24, 0.30, 0.22))

func _create_solid_tile(tile_x: int, tile_y: int, tile_color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(tile_x * TILE_SIZE + TILE_SIZE * 0.5, tile_y * TILE_SIZE + TILE_SIZE * 0.5)

	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	shape.shape = rect_shape
	body.add_child(shape)

	var visual := ColorRect.new()
	visual.size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
	visual.position = Vector2(-TILE_SIZE * 0.5 + 1, -TILE_SIZE * 0.5 + 1)
	visual.color = tile_color
	body.add_child(visual)

	var detail := ColorRect.new()
	detail.size = Vector2(TILE_SIZE - 8, 4)
	detail.position = Vector2(-TILE_SIZE * 0.5 + 4, -TILE_SIZE * 0.5 + 3)
	detail.color = tile_color.lightened(0.2)
	body.add_child(detail)

	_tile_layer.add_child(body)
	platforms.append(body)

func _place_torches(count: int) -> void:
	for i in range(count):
		var pos := _pick_walkable_spawn() + Vector2(0, -30)
		var glow := ColorRect.new()
		glow.position = pos - Vector2(10, 22)
		glow.size = Vector2(20, 36)
		glow.color = Color(0.95, 0.66, 0.22, 0.35)
		_bg_layer.add_child(glow)

		var flame := ColorRect.new()
		flame.position = pos - Vector2(4, 8)
		flame.size = Vector2(8, 8)
		flame.color = Color(1.0, 0.76, 0.32)
		_bg_layer.add_child(flame)

func create_enemies(count: int) -> void:
	var types := ["slime", "bat", "skeleton"]
	for i in range(count):
		var spawn := _pick_walkable_spawn()
		create_enemy(spawn.x, spawn.y - 20, types.pick_random())

func create_enemy(x: float, y: float, kind: String) -> void:
	var enemy := Node2D.new()
	enemy.name = kind
	enemy.position = Vector2(x, y)
	enemy.set_meta("type", kind)
	enemy.set_meta("hp", 1 + int(level_num / 3))
	enemy.set_meta("speed", 25.0 + level_num * 3.0)

	var body := ColorRect.new()
	body.size = Vector2(22, 22)
	body.position = Vector2(-11, -11)
	match kind:
		"bat":
			body.color = Color(0.50, 0.32, 0.62)
		"skeleton":
			body.color = Color(0.72, 0.72, 0.72)
		_:
			body.color = Color(0.38, 0.72, 0.35)
	enemy.add_child(body)

	var eye := ColorRect.new()
	eye.size = Vector2(10, 4)
	eye.position = Vector2(-5, -3)
	eye.color = Color(0.98, 0.95, 0.95)
	enemy.add_child(eye)

	var hitbox := Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12
	shape.shape = circle
	hitbox.add_child(shape)
	enemy.add_child(hitbox)

	_entity_layer.add_child(enemy)
	enemies.append(enemy)

func create_items(count: int) -> void:
	var types := ["mushroom", "bottle"]
	for i in range(count):
		var spawn := _pick_walkable_spawn()
		create_item(spawn.x, spawn.y - 24, types.pick_random())

func create_item(x: float, y: float, kind: String) -> void:
	var item := Area2D.new()
	item.name = kind
	item.position = Vector2(x, y)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10
	shape.shape = circle
	item.add_child(shape)

	var halo := ColorRect.new()
	halo.size = Vector2(20, 20)
	halo.position = Vector2(-10, -10)
	halo.color = Color(0.95, 0.88, 0.4, 0.22)
	item.add_child(halo)

	var rect := ColorRect.new()
	rect.size = Vector2(14, 14)
	rect.position = Vector2(-7, -7)
	rect.color = Color(0.92, 0.20, 0.25) if kind == "mushroom" else Color(0.20, 0.86, 0.44)
	item.add_child(rect)

	_entity_layer.add_child(item)
	items.append(item)

func create_exit() -> void:
	exit_door = Area2D.new()
	exit_door.name = "Exit"
	var p := _pick_walkable_spawn()
	exit_door.position = Vector2(p.x, p.y - 10)

	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(26, 40)
	shape.shape = rect_shape
	exit_door.add_child(shape)

	var frame := ColorRect.new()
	frame.size = Vector2(30, 44)
	frame.position = Vector2(-15, -22)
	frame.color = Color(0.36, 0.28, 0.12)
	exit_door.add_child(frame)

	var rect := ColorRect.new()
	rect.size = Vector2(24, 38)
	rect.position = Vector2(-12, -19)
	rect.color = Color(0.95, 0.82, 0.28)
	exit_door.add_child(rect)

	_entity_layer.add_child(exit_door)

func _pick_walkable_spawn() -> Vector2:
	var x := randi_range(3, GRID_WIDTH - 4) * TILE_SIZE + TILE_SIZE * 0.5
	var y := randi_range(7, GRID_HEIGHT - 6) * TILE_SIZE + TILE_SIZE * 0.5
	return Vector2(x, y)

func get_spawn_point() -> Vector2:
	return Vector2(3 * TILE_SIZE, (GRID_HEIGHT - 4) * TILE_SIZE)

func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dir := (player.position - enemy.position).normalized()
		var speed := float(enemy.get_meta("speed"))
		enemy.position += dir * speed * delta
