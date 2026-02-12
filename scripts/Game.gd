extends Node2D

# ============ 游戏主控(像素地牢重制) ============

var dungeon: Node2D
var player: CharacterBody2D
var camera: Camera2D

var current_level := 1
var defeated_enemies := 0

var hud_layer: CanvasLayer
var hp_fill: ColorRect
var hp_label: Label
var progress_label: Label
var hint_label: Label
var state_label: Label
var damage_flash: ColorRect
var attack_indicator: ColorRect
var _last_hp := 4

func _ready() -> void:
	_create_world()
	_create_hud()
	_connect_signals()
	_update_hud()

func _create_world() -> void:
	dungeon = preload("res://scripts/Dungeon.gd").new()
	add_child(dungeon)

	player = preload("res://scripts/player.gd").new()
	add_child(player)
	player.position = dungeon.get_spawn_point()

	camera = Camera2D.new()
	camera.enabled = true
	camera.zoom = Vector2(1.2, 1.2)
	add_child(camera)
	camera.position = player.position

func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)

	# 受伤闪屏：强化反馈
	damage_flash = ColorRect.new()
	damage_flash.position = Vector2.ZERO
	damage_flash.size = Vector2(1920, 1080)
	damage_flash.color = Color(0.95, 0.15, 0.15, 0.0)
	hud_layer.add_child(damage_flash)

	var panel := ColorRect.new()
	panel.size = Vector2(780, 98)
	panel.position = Vector2(12, 10)
	panel.color = Color(0.01, 0.02, 0.04, 0.88)
	hud_layer.add_child(panel)

	var panel_border := ColorRect.new()
	panel_border.size = panel.size + Vector2(4, 4)
	panel_border.position = panel.position - Vector2(2, 2)
	panel_border.color = Color(0.23, 0.30, 0.47, 0.9)
	hud_layer.add_child(panel_border)
	hud_layer.move_child(panel_border, 1)

	var title_label := Label.new()
	title_label.position = Vector2(30, 16)
	title_label.text = "PIXEL DUNGEON"
	title_label.add_theme_color_override("font_color", Color(0.99, 0.89, 0.31))
	hud_layer.add_child(title_label)

	var hp_bg := ColorRect.new()
	hp_bg.position = Vector2(30, 42)
	hp_bg.size = Vector2(230, 16)
	hp_bg.color = Color(0.16, 0.07, 0.10, 0.95)
	hud_layer.add_child(hp_bg)

	hp_fill = ColorRect.new()
	hp_fill.position = hp_bg.position + Vector2(2, 2)
	hp_fill.size = Vector2(226, 12)
	hp_fill.color = Color(0.92, 0.24, 0.30)
	hud_layer.add_child(hp_fill)

	hp_label = Label.new()
	hp_label.position = Vector2(270, 40)
	hp_label.add_theme_color_override("font_color", Color(1, 0.88, 0.88))
	hud_layer.add_child(hp_label)

	progress_label = Label.new()
	progress_label.position = Vector2(30, 66)
	progress_label.add_theme_color_override("font_color", Color(0.65, 0.95, 0.78))
	hud_layer.add_child(progress_label)

	state_label = Label.new()
	state_label.position = Vector2(470, 40)
	state_label.add_theme_color_override("font_color", Color(0.95, 0.76, 0.31))
	hud_layer.add_child(state_label)

	hint_label = Label.new()
	hint_label.position = Vector2(470, 64)
	hint_label.text = "A/D移动 空格跳跃 J近战 R重开"
	hint_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.98))
	hud_layer.add_child(hint_label)

	attack_indicator = ColorRect.new()
	attack_indicator.position = Vector2(760, 66)
	attack_indicator.size = Vector2(16, 16)
	attack_indicator.color = Color(0.34, 0.42, 0.62)
	hud_layer.add_child(attack_indicator)

func _connect_signals() -> void:
	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_health_changed)

func _process(delta: float) -> void:
	camera.position = camera.position.lerp(player.position, 6.0 * delta)
	_process_items()
	_process_enemy_damage()
	_process_player_attack()
	_process_exit()
	_update_visual_effects(delta)
	_update_hud()

func _process_items() -> void:
	for item in dungeon.items.duplicate():
		if is_instance_valid(item) and player.position.distance_to(item.position) < 22:
			collect_item(item)

func _process_enemy_damage() -> void:
	for enemy in dungeon.enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		if player.position.distance_to(enemy.position) < 20:
			player.take_damage(1)

func _process_player_attack() -> void:
	if not Input.is_key_pressed(KEY_J):
		return
	if not player.try_attack():
		return

	var target := _find_attack_target()
	if target:
		_remove_enemy(target)

func _find_attack_target() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	for enemy in dungeon.enemies:
		if not is_instance_valid(enemy):
			continue
		var to_enemy := enemy.position - player.position
		var distance := to_enemy.length()
		if distance > player.attack_range:
			continue
		if to_enemy.x * player.facing < -8.0:
			continue
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest

func _process_exit() -> void:
	if not dungeon.exit_door:
		return

	if dungeon.enemies.is_empty() and player.position.distance_to(dungeon.exit_door.position) < 28:
		current_level += 1
		defeated_enemies = 0
		dungeon.generate_level(current_level)
		player.position = dungeon.get_spawn_point()

func collect_item(item: Area2D) -> void:
	match item.name:
		"mushroom":
			player.heal(1)
		"bottle":
			player.heal(2)
	dungeon.items.erase(item)
	item.queue_free()

func _remove_enemy(enemy: Node2D) -> void:
	dungeon.enemies.erase(enemy)
	defeated_enemies += 1
	enemy.queue_free()

func _on_player_died() -> void:
	player.position = dungeon.get_spawn_point()

func _on_health_changed(current: int, _max: int) -> void:
	if current < _last_hp:
		damage_flash.color.a = 0.25
	_last_hp = current
	_update_hud()

func _update_visual_effects(delta: float) -> void:
	damage_flash.color.a = move_toward(damage_flash.color.a, 0.0, 1.2 * delta)

	var attack_ready := player.attack_timer <= 0.01
	attack_indicator.color = Color(0.22, 0.88, 0.44) if attack_ready else Color(0.34, 0.42, 0.62)

func _update_hud() -> void:
	if not is_instance_valid(player):
		return

	var hp_ratio := clamp(float(player.hp) / max(1.0, float(player.max_hp)), 0.0, 1.0)
	hp_fill.size.x = 226.0 * hp_ratio
	hp_fill.color = Color(0.92, 0.22, 0.30).lerp(Color(0.95, 0.76, 0.30), 1.0 - hp_ratio)
	hp_label.text = "生命 %d / %d" % [player.hp, player.max_hp]
	progress_label.text = "关卡 %d  剩余敌人 %d  已击败 %d" % [current_level, dungeon.enemies.size(), defeated_enemies]
	state_label.text = "出口%s" % ("已开启" if dungeon.enemies.is_empty() else "封锁中")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		defeated_enemies = 0
		dungeon.generate_level(current_level)
		player.position = dungeon.get_spawn_point()
