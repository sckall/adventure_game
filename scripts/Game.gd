extends Node2D

# ============ 游戏主控 ============

const SAVE_SLOT_COUNT := 3
const MAX_LEVEL := 5

var dungeon
var player
var camera
var current_level = 1
var save_slot_index := -1
var selected_character := "warrior"
var hud_layer
var hp_hearts := []
var hp_label
var level_label
var kill_label
var skill_hint_label
var skill_status_label
var pause_overlay
var is_paused := false
var kill_count := 0
var bgm_player
var gold := 0
var weapon := {}
var gold_label
var weapon_label
var skill_slot_label
var combo_count := 0
var combo_timer := 0.0
var combo_label
var camera_zoom := 1.6
var camera_y_offset := 90.0
var camera_follow_speed := 10.0

func _ready():
	_load_session_meta()

	# 创建地牢
	var dungeon_script = load("res://scripts/Dungeon.gd")
	if dungeon_script == null:
		push_error("Dungeon script load failed: res://scripts/Dungeon.gd")
		return
	dungeon = Node2D.new()
	dungeon.set_script(dungeon_script)
	if dungeon.get_script() == null:
		push_error("Dungeon script failed to attach: res://scripts/Dungeon.gd")
		return
	add_child(dungeon)
	
	# 创建玩家
	var player_script = load("res://scripts/player.gd")
	if player_script == null:
		push_error("Player script load failed: res://scripts/player.gd")
		return
	player = CharacterBody2D.new()
	player.set_script(player_script)
	if player == null:
		push_error("Player failed to instantiate: res://scripts/player.gd")
		return
	if not player.has_signal("died"):
		push_error("Player script failed to attach/compile: res://scripts/player.gd")
		return
	add_child(player)
	_set_player_spawn()
	
	# 创建相机
	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)
	camera.make_current()
	
	# 连接信号
	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_health_changed)
	player.skill_used.connect(_on_skill_used)
	player.enemy_killed.connect(_on_enemy_killed)
	player.skills_changed.connect(_on_skills_changed)

	_apply_save_data()

	print("=== 游戏开始 ===")

	_create_hud()
	_on_health_changed(player.hp, player.max_hp)
	_update_skill_hint()
	_update_level_label()
	_update_kill_label()
	_generate_start_weapon()
	player.set_weapon(weapon)
	_update_weapon_label()
	_update_skill_slot_label()
	_setup_bgm()
	_configure_camera()

func _configure_camera() -> void:
	if camera == null or not is_instance_valid(camera) or dungeon == null or not is_instance_valid(dungeon):
		return
	var world_w = float(dungeon.level_width)
	var world_h = float(dungeon.level_height + 80)
	camera.zoom = Vector2(camera_zoom, camera_zoom)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world_w)
	camera.limit_bottom = int(world_h)

func _physics_process(delta):
	if player == null or not is_instance_valid(player) or camera == null or not is_instance_valid(camera):
		return
	# 物理帧跟随，避免 _process 与物理更新不同步引发抖动
	# 同时做像素对齐，减少缩放后子像素导致的抖动观感
	var lookahead = Vector2.ZERO
	if player is CharacterBody2D:
		lookahead = Vector2(
			clampf(player.velocity.x * 0.08, -80.0, 80.0),
			clampf(player.velocity.y * 0.04, -40.0, 60.0)
		)
	var target = player.global_position + Vector2(0, camera_y_offset) + lookahead
	camera.global_position = camera.global_position.lerp(target, minf(1.0, camera_follow_speed * delta))

func _process(delta):
	if dungeon == null or not is_instance_valid(dungeon) or player == null or not is_instance_valid(player):
		return
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
		_update_combo_label()
	# 检测道具收集
	var items = dungeon.get("items")
	if items is Array:
		for item in items:
			if is_instance_valid(item) and player.position.distance_to(item.position) < 30:
				collect_item(item)

	# 武器拾取
	var weapons = dungeon.get("weapons")
	if weapons is Array:
		for w in weapons:
			if is_instance_valid(w) and player.position.distance_to(w.position) < 30:
				collect_weapon(w)

	# 检测出口：靠近门自动进入下一关并自动存档
	var exit_door = dungeon.get("exit_door")
	if exit_door and is_instance_valid(exit_door):
		if player.position.distance_to(exit_door.position) < 45:
			_next_level()

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
	_set_player_spawn()
	player.hp = player.max_hp
	_apply_death_penalty()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_toggle_pause()
		return
	# R 键重置当前关卡
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		dungeon.generate_level(current_level)
		_autosave()

	# F5 手动存档
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F5:
		_autosave(true)

func _load_session_meta():
	var tree = get_tree()
	if tree.has_meta("selected_character"):
		selected_character = String(tree.get_meta("selected_character"))
	if tree.has_meta("save_slot_index"):
		save_slot_index = int(tree.get_meta("save_slot_index"))
	if tree.has_meta("save_data"):
		var data = tree.get_meta("save_data")
		if typeof(data) == TYPE_DICTIONARY:
			current_level = int(data.get("level", 1))

func _apply_save_data():
	# Dungeon 默认生成 1 关；若存档关卡不同，重建关卡
	if current_level != 1:
		dungeon.generate_level(current_level)
	_set_player_spawn()

func _next_level():
	current_level += 1
	dungeon.generate_level(current_level)
	_set_player_spawn()
	_update_level_label()
	_autosave()
	_configure_camera()

func _set_player_spawn() -> void:
	if player == null or not is_instance_valid(player):
		return
	var spawn = dungeon.get("spawn_pos") if dungeon != null else null
	if spawn is Vector2:
		player.position = spawn
	else:
		player.position = Vector2(100, 500)

func _slot_path(i: int) -> String:
	return "user://save_slot_%d.json" % i

func _autosave(force: bool = false):
	if save_slot_index < 0 or save_slot_index >= SAVE_SLOT_COUNT:
		if force:
			print("未绑定存档槽，无法保存（从存档管理进入可绑定存档槽）")
		return

	var data := {
		"level": current_level,
		"character": selected_character,
		"updated_at_unix": int(Time.get_unix_time_from_system()),
	}

	var file = FileAccess.open(_slot_path(save_slot_index), FileAccess.WRITE)
	if file == null:
		print("存档写入失败")
		return
	file.store_string(JSON.stringify(data))
	print("已保存到存档 %d" % (save_slot_index + 1))

func _create_hud():
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)

	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(root)

	var panel = PanelContainer.new()
	panel.position = Vector2(16, 12)
	panel.custom_minimum_size = Vector2(300, 120)
	root.add_child(panel)

	var v = VBoxContainer.new()
	v.offset_left = 10
	v.offset_right = -10
	v.offset_top = 8
	v.offset_bottom = -8
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	hp_label = Label.new()
	hp_label.text = "生命值"
	hp_label.add_theme_font_size_override("font_size", 14)
	v.add_child(hp_label)

	var heart_row = HBoxContainer.new()
	heart_row.add_theme_constant_override("separation", 4)
	v.add_child(heart_row)

	hp_hearts = []
	for i in range(10):
		var heart = Label.new()
		heart.text = "❤"
		heart.add_theme_font_size_override("font_size", 18)
		heart.add_theme_color_override("font_color", Color(0.95, 0.2, 0.25))
		heart.visible = false
		heart_row.add_child(heart)
		hp_hearts.append(heart)

	level_label = Label.new()
	level_label.text = "关卡: 1/5"
	level_label.add_theme_font_size_override("font_size", 13)
	v.add_child(level_label)

	kill_label = Label.new()
	kill_label.text = "击杀: 0"
	kill_label.add_theme_font_size_override("font_size", 13)
	v.add_child(kill_label)

	combo_label = Label.new()
	combo_label.text = "连杀: 0"
	combo_label.add_theme_font_size_override("font_size", 13)
	v.add_child(combo_label)

	gold_label = Label.new()
	gold_label.text = "金币: 0"
	gold_label.add_theme_font_size_override("font_size", 13)
	v.add_child(gold_label)

	weapon_label = Label.new()
	weapon_label.text = "武器: -"
	weapon_label.add_theme_font_size_override("font_size", 13)
	v.add_child(weapon_label)

	skill_slot_label = Label.new()
	skill_slot_label.text = "技能槽: -"
	skill_slot_label.add_theme_font_size_override("font_size", 12)
	v.add_child(skill_slot_label)

	skill_hint_label = Label.new()
	skill_hint_label.text = ""
	skill_hint_label.add_theme_font_size_override("font_size", 13)
	v.add_child(skill_hint_label)

	skill_status_label = Label.new()
	skill_status_label.text = ""
	skill_status_label.add_theme_font_size_override("font_size", 12)
	skill_status_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	v.add_child(skill_status_label)

	_create_pause_overlay(root)

func _setup_bgm():
	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.volume_db = -12.0
		bgm_player.autoplay = true
		add_child(bgm_player)
	var stream = _safe_load_audio("res://assets/audio/audio_3.ogg", 1024 * 1024)
	if stream != null:
		bgm_player.stream = stream
		if "loop" in stream:
			stream.loop = true
		bgm_player.play()

func _safe_load_audio(path: String, min_bytes: int):
	if not FileAccess.file_exists(path):
		return null
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var size = f.get_length()
	if size < min_bytes:
		return null
	var stream = load(path)
	if stream == null:
		push_warning("Audio load failed: %s" % path)
	return stream

func _on_health_changed(current, max):
	if hp_hearts == null:
		return
	var maxv = int(max)
	var cur = int(current)
	for i in range(hp_hearts.size()):
		var heart = hp_hearts[i]
		if heart:
			heart.visible = i < maxv and i < cur
	if hp_label != null:
		hp_label.text = "生命值 %d / %d" % [cur, maxv]

func _update_skill_hint():
	if skill_hint_label == null:
		return
	match selected_character:
		"warrior":
			skill_hint_label.text = "技能: L 震地斩 | E 防御姿态 | Q 冲锋"
		"assassin":
			skill_hint_label.text = "技能: L 冲刺斩 | E 翻滚 | Q 影袭"
		"mage":
			skill_hint_label.text = "技能: L 火球 | E 冰环 | Q 瞬移"
		"priest":
			skill_hint_label.text = "技能: L 治疗 | E 护盾 | Q 净化"
		"archer":
			skill_hint_label.text = "技能: L 穿透箭 | E 多重射击 | Q 翻跃"
		_:
			skill_hint_label.text = "技能: L 主技能 | E 副技能 | Q 机动"

func _on_skill_used(slot):
	if skill_status_label == null:
		return
	var label = "技能释放: %s" % String(slot)
	skill_status_label.text = label

func _on_skills_changed(_slots):
	_update_skill_slot_label()

func _on_enemy_killed(count):
	kill_count += int(count)
	combo_count += int(count)
	combo_timer = 3.0
	_add_gold(2 * int(count))
	_update_kill_label()
	_update_combo_label()

func _update_level_label():
	if level_label == null:
		return
	level_label.text = "关卡: %d/%d" % [current_level, MAX_LEVEL]

func _update_kill_label():
	if kill_label == null:
		return
	kill_label.text = "击杀: %d" % kill_count

func _update_combo_label():
	if combo_label == null:
		return
	if combo_timer > 0.0:
		combo_label.text = "连杀: %d" % combo_count
	else:
		combo_label.text = "连杀: 0"

func _add_gold(amount: int):
	gold = max(gold + amount, 0)
	_update_gold_label()

func _apply_death_penalty():
	var lost = int(floor(gold * 0.5))
	gold = max(gold - lost, 0)
	_update_gold_label()

func _update_gold_label():
	if gold_label == null:
		return
	gold_label.text = "金币: %d" % gold

func _generate_start_weapon():
	var prefixes = ["Sharp", "Heavy", "Swift", "Jagged"]
	var suffixes = ["of Ember", "of Frost", "of Venom", "of Echo"]
	var rarity = "common" if randi() % 100 < 75 else "rare"
	var name = "Blade"
	var prefix = prefixes[randi() % prefixes.size()]
	var suffix = suffixes[randi() % suffixes.size()]
	var mult = 1.0 if rarity == "common" else 1.25
	weapon = {
		"name": "%s %s %s" % [prefix, name, suffix],
		"rarity": rarity,
		"mod": suffix,
		"damage_mult": mult
	}

func _update_weapon_label():
	if weapon_label == null:
		return
	var rarity = String(weapon.get("rarity", "common"))
	var name = String(weapon.get("name", "Blade"))
	weapon_label.text = "武器: %s (%s)" % [name, rarity]

func _update_skill_slot_label():
	if skill_slot_label == null:
		return
	if player == null:
		return
	var slots = player.skill_slots
	if slots.size() >= 3:
		skill_slot_label.text = "技能槽: 1[%s] 2[%s] 3[%s]" % [slots[0], slots[1], slots[2]]

func collect_weapon(w):
	if w == null or not is_instance_valid(w):
		return
	if w.has_meta("weapon"):
		weapon = w.get_meta("weapon")
		player.set_weapon(weapon)
		_update_weapon_label()
	dungeon.weapons.erase(w)
	w.queue_free()

func _create_pause_overlay(root: Control):
	pause_overlay = Control.new()
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(pause_overlay)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 180)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	center.add_child(panel)

	var v = VBoxContainer.new()
	v.offset_left = 12
	v.offset_right = -12
	v.offset_top = 12
	v.offset_bottom = -12
	v.add_theme_constant_override("separation", 10)
	v.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.add_child(v)

	var title = Label.new()
	title.text = "暂停"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var resume_btn = Button.new()
	resume_btn.text = "继续"
	resume_btn.pressed.connect(_toggle_pause)
	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	v.add_child(resume_btn)

	var quit_btn = Button.new()
	quit_btn.text = "退出到菜单"
	quit_btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	v.add_child(quit_btn)

func _toggle_pause():
	is_paused = not is_paused
	get_tree().paused = is_paused
	if pause_overlay != null:
		pause_overlay.visible = is_paused
