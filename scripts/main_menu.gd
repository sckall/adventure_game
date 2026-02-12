extends Node2D

# ============ 主菜单 ============

const SETTINGS_FILE := "user://settings.json"
const MAX_LEVEL := 5

var selected_character: String = "warrior"
var save_slots: Array = [{}, {}, {}]
var status_label: Label
var settings: Dictionary = {}

var root_ui: Control
var save_overlay: Control
var save_list: VBoxContainer
var delete_confirm: ConfirmationDialog
var pending_delete_index := -1

var settings_overlay: Control
var master_slider: HSlider
var fullscreen_check: CheckButton
var vsync_check: CheckButton

var start_character_overlay: Control
var start_level_overlay: Control
var level_buttons: Array = []
var pending_start_level := 1
var character_buttons: Array = []

func _ready():
	randomize()
	_ensure_default_input_bindings()
	_load_settings()
	_apply_settings()
	_load_save_data()
	_create_menu_ui()
	print("=== 主菜单 ===")

func _ensure_default_input_bindings():
	_add_key_binding("ui_left", KEY_A)
	_add_key_binding("ui_left", KEY_LEFT)
	_add_key_binding("ui_right", KEY_D)
	_add_key_binding("ui_right", KEY_RIGHT)
	_add_key_binding("ui_accept", KEY_SPACE)
	_add_key_binding("ui_accept", KEY_ENTER)
	_add_key_binding("ui_accept", KEY_KP_ENTER)
	_add_key_binding("ui_up", KEY_W)
	_add_key_binding("ui_up", KEY_UP)

func _add_key_binding(action_name: String, keycode: Key):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			return
	var key_event = InputEventKey.new()
	key_event.keycode = keycode
	InputMap.action_add_event(action_name, key_event)

func _load_save_data():
	for i in range(3):
		var slot_file = "user://save_slot_%d.json" % i
		if FileAccess.file_exists(slot_file):
			var file = FileAccess.open(slot_file, FileAccess.READ)
			if file:
				var json = file.get_as_text()
				var parsed = JSON.parse_string(json)
				save_slots[i] = parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _load_settings():
	if not FileAccess.file_exists(SETTINGS_FILE):
		settings = {
			"master_volume": 0.85,
			"fullscreen": false,
			"vsync": true,
		}
		return
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		settings = parsed

func _save_settings():
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(settings))

func _apply_settings():
	var master = float(settings.get("master_volume", 0.85))
	master = clampf(master, 0.0, 1.0)
	var vol_linear = maxf(master, 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(vol_linear))
	AudioServer.set_bus_mute(0, master <= 0.001)

	var fullscreen = bool(settings.get("fullscreen", false))
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Maximize by default so the game fills the screen while still allowing windowed mode.
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

	var vsync = bool(settings.get("vsync", true))
	if DisplayServer.has_method("window_set_vsync_mode"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)

func _create_menu_ui():
	var layer = CanvasLayer.new()
	add_child(layer)

	root_ui = Control.new()
	root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root_ui)

	# === 背景层 ===
	var bg = _create_background()
	root_ui.add_child(bg)

	# === 装饰层 ===
	var decor = _create_decorations()
	root_ui.add_child(decor)

	# === 主面板 ===
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(center)

	var panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(440, 600)
	panel.add_theme_constant_override("separation", 12)
	center.add_child(panel)

	# 面板背景样式
	var panel_bg = PanelContainer.new()
	panel_bg.custom_minimum_size = Vector2(440, 600)
	var panel_style = _get_panel_style()
	panel_bg.add_theme_stylebox_override("panel", panel_style)
	panel.add_child(panel_bg)

	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	inner.offset_left = 20
	inner.offset_right = -20
	inner.offset_top = 20
	inner.offset_bottom = -20
	panel_bg.add_child(inner)

	# 标题带阴影
	var title_shadow = Label.new()
	title_shadow.text = "CHUI 的冒险"
	title_shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_shadow.add_theme_font_size_override("font_size", 52)
	title_shadow.add_theme_color_override("font_color", Color(0.5, 0.4, 0.1, 0.4))
	title_shadow.position = Vector2(2, 3)
	inner.add_child(title_shadow)

	var title = Label.new()
	title.text = "CHUI 的冒险"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	inner.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "2D 平台冒险游戏"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	inner.add_child(subtitle)

	var hint = Label.new()
	hint.text = "选择角色与关卡开始冒险"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	inner.add_child(hint)

	inner.add_child(_create_divider())

	# 角色图标行
	var char_row = _create_character_row()
	inner.add_child(char_row)

	inner.add_child(_create_divider())

	var start_btn = _create_button("开始游戏", Color(0.15, 0.55, 0.25))
	start_btn.pressed.connect(_open_start_flow)
	inner.add_child(start_btn)

	var save_btn = _create_button("存档管理", Color(0.2, 0.45, 0.75))
	save_btn.pressed.connect(_on_save_pressed)
	inner.add_child(save_btn)

	var settings_btn = _create_button("游戏设置", Color(0.55, 0.45, 0.25))
	settings_btn.pressed.connect(_on_settings_pressed)
	inner.add_child(settings_btn)

	var quit_btn = _create_button("退出游戏", Color(0.6, 0.25, 0.25))
	quit_btn.pressed.connect(_on_quit_pressed)
	inner.add_child(quit_btn)

	inner.add_child(_create_divider())

	status_label = Label.new()
	status_label.text = "提示: 回车快速开始游戏，Esc 退出"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8))
	inner.add_child(status_label)

	var help = Label.new()
	help.text = "操作: A/D 或 ←→ 移动 | 空格跳跃 | K 攻击"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 13)
	help.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55))
	inner.add_child(help)

	_build_save_overlay()
	_build_settings_overlay()
	_build_start_character_overlay()
	_build_start_level_overlay()

func _create_background() -> Control:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	# 深蓝色渐变背景
	bg.color = Color(0.04, 0.05, 0.12)
	return bg

func _create_decorations() -> Control:
	var decor = Control.new()
	decor.set_anchors_preset(Control.PRESET_FULL_RECT)

	# 顶部渐变光
	var top_light = ColorRect.new()
	top_light.size = Vector2(1280, 200)
	top_light.position = Vector2(0, -100)
	top_light.color = Color(0.2, 0.3, 0.5, 0.15)
	decor.add_child(top_light)

	# 角落装饰
	var corners = [
		[Vector2(-30, -30), Vector2(180, 180), Color(0.15, 0.12, 0.08, 0.4)],
		[Vector2(1130, -30), Vector2(180, 180), Color(0.08, 0.1, 0.15, 0.4)],
		[Vector2(-30, 570), Vector2(200, 100), Color(0.08, 0.06, 0.04, 0.3)],
		[Vector2(1110, 580), Vector2(200, 80), Color(0.06, 0.08, 0.12, 0.3)]
	]

	for c in corners:
		var corner = ColorRect.new()
		corner.size = c[1]
		corner.position = c[0]
		corner.color = c[2]
		decor.add_child(corner)

	# 悬浮光点
	for i in range(12):
		var orb = _create_glow_orb()
		orb.position = Vector2(randf() * 1280, randf() * 720)
		orb.modulate = Color(0.5, 0.7, 1.0, randf_range(0.15, 0.35))
		decor.add_child(orb)

	return decor

func _create_glow_orb() -> ColorRect:
	var orb = ColorRect.new()
	orb.size = Vector2(randf_range(6, 16), randf_range(6, 16))
	orb.pivot_offset = orb.size / 2
	# 呼吸动画
	var tween = create_tween().set_loops()
	var target = orb.size * 1.5
	var dur = randf_range(2, 4)
	tween.tween_property(orb, "size", target, dur).set_trans(Tween.TRANS_SINE)
	tween.tween_property(orb, "size", orb.size, dur).set_trans(Tween.TRANS_SINE)
	return orb

func _get_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.12, 0.96)
	style.border_color = Color(0.35, 0.32, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(0)
	return style

func _get_overlay_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.14, 0.98)
	style.border_color = Color(0.4, 0.38, 0.45)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(0)
	return style

func _create_divider() -> HSeparator:
	var sep = HSeparator.new()
	sep.add_theme_color_override("separation", Color(0.3, 0.28, 0.35))
	return sep

func _create_overlay_divider() -> HSeparator:
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 16)
	return sep

func _create_small_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(100, 36)
	btn.add_theme_font_size_override("font_size", 16)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.border_color = Color(0.35, 0.33, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.25, 0.23, 0.3)
	hover.border_color = Color(0.5, 0.48, 0.55)
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(6)
	hover.set_content_margin_all(12)
	btn.add_theme_stylebox_override("hover", hover)

	return btn

func _create_character_row() -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var chars = [
		["⚔️", "战士", "warrior"],
		["🗡️", "刺客", "assassin"],
		["🔮", "法师", "mage"],
		["✨", "牧师", "priest"],
		["🏹", "射手", "archer"]
	]

	for i in range(chars.size()):
		var container = VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)

		var icon = Label.new()
		icon.text = chars[i][0]
		icon.add_theme_font_size_override("font_size", 28)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.modulate = Color(0.65, 0.65, 0.7)
		container.add_child(icon)

		var name = Label.new()
		name.text = chars[i][1]
		name.add_theme_font_size_override("font_size", 12)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		container.add_child(name)

		row.add_child(container)

	return row

func _create_button(text: String, accent_color: Color = Color(0.3, 0.5, 0.7)) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 22)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# 自定义按钮样式
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.13, 0.18)
	normal_style.border_color = Color(0.4, 0.38, 0.45)
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(8)
	normal_style.set_content_margin_all(16)
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(accent_color.r * 0.25, accent_color.g * 0.25, accent_color.b * 0.25, 0.9)
	hover_style.border_color = Color(accent_color.r * 0.8, accent_color.g * 0.8, accent_color.b * 0.8)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(8)
	hover_style.set_content_margin_all(16)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(accent_color.r * 0.15, accent_color.g * 0.15, accent_color.b * 0.15)
	pressed_style.border_color = Color(accent_color.r * 0.6, accent_color.g * 0.6, accent_color.b * 0.6)
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(8)
	pressed_style.set_content_margin_all(16)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	# 悬停动画
	btn.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.02, 1.02), 0.1)
	)
	btn.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)

	return btn

func _on_character_selected(index: int):
	var ids = ["warrior", "assassin", "mage", "priest", "archer"]
	selected_character = ids[index]
	_show_status("已选择角色: %s" % selected_character)

func _show_status(text: String):
	if status_label == null:
		return
	status_label.text = text

func _on_save_pressed():
	_refresh_save_list()
	_show_overlay_deferred(save_overlay)

func _on_settings_pressed():
	_sync_settings_ui()
	_show_overlay_deferred(settings_overlay)

func _on_quit_pressed():
	get_tree().quit()

func _unhandled_input(event: InputEvent):
	if save_overlay != null and save_overlay.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_hide_overlay(save_overlay)
			get_viewport().set_input_as_handled()
			return
	if settings_overlay != null and settings_overlay.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_hide_overlay(settings_overlay)
			get_viewport().set_input_as_handled()
			return
	if start_character_overlay != null and start_character_overlay.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_hide_overlay(start_character_overlay)
			get_viewport().set_input_as_handled()
			return
	if start_level_overlay != null and start_level_overlay.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_hide_overlay(start_level_overlay)
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("ui_accept"):
		_open_start_flow()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().quit()

func _start_new_game(level: int):
	var start_level = clampi(level, 1, MAX_LEVEL)
	print("开始游戏! 角色: %s, 关卡: %d" % [selected_character, start_level])
	get_tree().set_meta("selected_character", selected_character)
	get_tree().set_meta("save_slot_index", -1)
	get_tree().set_meta("save_data", {"level": start_level})
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _show_overlay(overlay: Control):
	if overlay == null:
		return
	overlay.visible = true

func _show_overlay_deferred(overlay: Control):
	# Avoid immediate close from the same mouse click that opened it.
	call_deferred("_show_overlay", overlay)

func _hide_overlay(overlay: Control):
	if overlay == null:
		return
	overlay.visible = false

func _make_overlay_root() -> Control:
	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	root_ui.add_child(overlay)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent):
		# Close on mouse button release to avoid immediately closing a freshly opened overlay
		# (e.g. when a Button's pressed signal fires on mouse-down).
		if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_hide_overlay(overlay)
			get_viewport().set_input_as_handled()
	)
	overlay.add_child(dim)
	return overlay

func _slot_path(i: int) -> String:
	return "user://save_slot_%d.json" % i

func _write_slot(i: int, data: Dictionary) -> bool:
	var file = FileAccess.open(_slot_path(i), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	return true

func _delete_slot(i: int) -> bool:
	var path = _slot_path(i)
	if not FileAccess.file_exists(path):
		return true
	var err = DirAccess.remove_absolute(path)
	return err == OK

func _slot_summary(data: Dictionary) -> String:
	if data.is_empty():
		return "空"
	var level = int(data.get("level", 1))
	var character = String(data.get("character", "unknown"))
	var updated = int(data.get("updated_at_unix", 0))
	var updated_text = ""
	if updated > 0:
		updated_text = " | 更新: %s" % Time.get_datetime_string_from_unix_time(updated)
	return "Lv.%d | %s%s" % [level, character, updated_text]

func _build_save_overlay():
	save_overlay = _make_overlay_root()

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	save_overlay.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 460)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style = _get_overlay_panel_style()
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.offset_left = 20
	v.offset_right = -20
	v.offset_top = 20
	v.offset_bottom = -20
	panel.add_child(v)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	v.add_child(header)

	var title = Label.new()
	title.text = "📁 存档管理"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = _create_small_button("✕ 关闭")
	close_btn.pressed.connect(func(): _hide_overlay(save_overlay))
	header.add_child(close_btn)

	v.add_child(_create_overlay_divider())

	save_list = VBoxContainer.new()
	save_list.add_theme_constant_override("separation", 8)
	v.add_child(save_list)

	var footer = Label.new()
	footer.text = "💡 点击空白处或按 Esc 关闭面板"
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	v.add_child(footer)

	delete_confirm = ConfirmationDialog.new()
	delete_confirm.title = "确认删除"
	delete_confirm.confirmed.connect(_on_confirm_delete)
	save_overlay.add_child(delete_confirm)

func _refresh_save_list():
	if save_list == null:
		return
	for c in save_list.get_children():
		c.queue_free()

	for i in range(3):
		var idx := i
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		save_list.add_child(row)

		var slot_label = Label.new()
		slot_label.text = "存档 %d: %s" % [idx + 1, _slot_summary(save_slots[idx])]
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slot_label)

		var continue_btn = Button.new()
		continue_btn.text = "继续"
		continue_btn.disabled = save_slots[idx].is_empty()
		continue_btn.pressed.connect(func(): _continue_from_slot(idx))
		row.add_child(continue_btn)

		var new_btn = Button.new()
		new_btn.text = "新游戏"
		new_btn.pressed.connect(func(): _new_game_in_slot(idx))
		row.add_child(new_btn)

		var del_btn = Button.new()
		del_btn.text = "删除"
		del_btn.disabled = save_slots[idx].is_empty()
		del_btn.pressed.connect(func(): _ask_delete_slot(idx))
		row.add_child(del_btn)

func _ask_delete_slot(i: int):
	pending_delete_index = i
	delete_confirm.dialog_text = "确定删除存档 %d 吗？此操作不可恢复。" % (i + 1)
	delete_confirm.popup_centered()

func _on_confirm_delete():
	if pending_delete_index < 0:
		return
	var ok = _delete_slot(pending_delete_index)
	if ok:
		save_slots[pending_delete_index] = {}
		_show_status("已删除存档 %d" % (pending_delete_index + 1))
	else:
		_show_status("删除失败（可能无权限或文件占用）")
	pending_delete_index = -1
	_refresh_save_list()

func _continue_from_slot(i: int):
	if save_slots[i].is_empty():
		_show_status("该存档为空")
		return
	get_tree().set_meta("selected_character", String(save_slots[i].get("character", selected_character)))
	get_tree().set_meta("save_slot_index", i)
	get_tree().set_meta("save_data", save_slots[i])
	_hide_overlay(save_overlay)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _new_game_in_slot(i: int):
	var data := {
		"level": 1,
		"character": selected_character,
		"updated_at_unix": int(Time.get_unix_time_from_system()),
	}
	if not _write_slot(i, data):
		_show_status("写入存档失败")
		return
	save_slots[i] = data
	_show_status("已创建新存档 %d" % (i + 1))
	_continue_from_slot(i)

func _build_settings_overlay():
	settings_overlay = _make_overlay_root()

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 460)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style = _get_overlay_panel_style()
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.offset_left = 20
	v.offset_right = -20
	v.offset_top = 20
	v.offset_bottom = -20
	panel.add_child(v)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	v.add_child(header)

	var title = Label.new()
	title.text = "⚙️ 游戏设置"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = _create_small_button("✕ 关闭")
	close_btn.pressed.connect(func(): _hide_overlay(settings_overlay))
	header.add_child(close_btn)

	v.add_child(_create_overlay_divider())

	var vol_row = HBoxContainer.new()
	vol_row.add_theme_constant_override("separation", 10)
	v.add_child(vol_row)

	var vol_label = Label.new()
	vol_label.text = "🔊 主音量"
	vol_label.custom_minimum_size = Vector2(120, 0)
	vol_label.add_theme_font_size_override("font_size", 18)
	vol_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	vol_row.add_child(vol_label)

	master_slider = HSlider.new()
	master_slider.min_value = 0
	master_slider.max_value = 100
	master_slider.step = 1
	master_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vol_row.add_child(master_slider)

	var vol_value = Label.new()
	vol_value.text = "85%"
	vol_value.custom_minimum_size = Vector2(50, 0)
	vol_value.add_theme_font_size_override("font_size", 18)
	vol_value.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	vol_row.add_child(vol_value)

	master_slider.value_changed.connect(func(vv: float):
		vol_value.text = "%d%%" % int(vv)
	)

	fullscreen_check = CheckButton.new()
	fullscreen_check.text = "🖥️ 全屏模式"
	fullscreen_check.add_theme_font_size_override("font_size", 18)
	v.add_child(fullscreen_check)

	vsync_check = CheckButton.new()
	vsync_check.text = "🔄 垂直同步 (VSync)"
	vsync_check.add_theme_font_size_override("font_size", 18)
	v.add_child(vsync_check)

	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	actions.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(actions)

	var apply_btn = _create_small_button("✓ 应用")
	apply_btn.custom_minimum_size = Vector2(120, 36)
	apply_btn.pressed.connect(_apply_settings_from_ui)
	actions.add_child(apply_btn)

	var reset_btn = _create_small_button("↺ 默认")
	reset_btn.custom_minimum_size = Vector2(120, 36)
	reset_btn.pressed.connect(_reset_settings)
	actions.add_child(reset_btn)

	var tip = Label.new()
	tip.text = "💾 设置会自动保存，下次启动时生效"
	tip.add_theme_font_size_override("font_size", 14)
	tip.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	v.add_child(tip)

func _sync_settings_ui():
	if master_slider != null:
		master_slider.value = clampf(float(settings.get("master_volume", 0.85)) * 100.0, 0.0, 100.0)
	if fullscreen_check != null:
		fullscreen_check.button_pressed = bool(settings.get("fullscreen", false))
	if vsync_check != null:
		vsync_check.button_pressed = bool(settings.get("vsync", true))

func _apply_settings_from_ui():
	settings["master_volume"] = float(master_slider.value) / 100.0
	settings["fullscreen"] = fullscreen_check.button_pressed
	settings["vsync"] = vsync_check.button_pressed
	_save_settings()
	_apply_settings()
	_show_status("设置已应用")

func _reset_settings():
	settings = {
		"master_volume": 0.85,
		"fullscreen": false,
		"vsync": true,
	}
	_sync_settings_ui()
	_apply_settings_from_ui()

func _open_start_flow():
	_sync_start_character_ui()
	_show_overlay_deferred(start_character_overlay)

func _sync_start_character_ui():
	_update_character_buttons()
	pending_start_level = 1
	_update_level_buttons()

func _build_start_character_overlay():
	start_character_overlay = _make_overlay_root()

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_character_overlay.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 340)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style = _get_overlay_panel_style()
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.offset_left = 20
	v.offset_right = -20
	v.offset_top = 20
	v.offset_bottom = -20
	panel.add_child(v)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	v.add_child(header)

	var title = Label.new()
	title.text = "🎭 角色选择"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = _create_small_button("✕ 关闭")
	close_btn.pressed.connect(func(): _hide_overlay(start_character_overlay))
	header.add_child(close_btn)

	v.add_child(_create_overlay_divider())

	# 角色选择行
	var char_select_row = HBoxContainer.new()
	char_select_row.add_theme_constant_override("separation", 16)
	char_select_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(char_select_row)

	var chars = [
		["⚔️", "战士", "warrior"],
		["🗡️", "刺客", "assassin"],
		["🔮", "法师", "mage"],
		["✨", "牧师", "priest"],
		["🏹", "射手", "archer"]
	]

	character_buttons = []
	for i in range(chars.size()):
		var id = String(chars[i][2])
		var b = Button.new()
		b.text = "%s\n%s" % [chars[i][0], chars[i][1]]
		b.custom_minimum_size = Vector2(110, 90)
		b.add_theme_font_size_override("font_size", 18)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.pressed.connect(func():
			selected_character = id
			_update_character_buttons()
			_show_status("已选择角色: %s" % id)
		)

		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0.12, 0.13, 0.18)
		normal.border_color = Color(0.35, 0.33, 0.4)
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(10)
		normal.set_content_margin_all(10)
		b.add_theme_stylebox_override("normal", normal)

		var hover = StyleBoxFlat.new()
		hover.bg_color = Color(0.2, 0.25, 0.35)
		hover.border_color = Color(0.5, 0.6, 0.8)
		hover.set_border_width_all(2)
		hover.set_corner_radius_all(10)
		hover.set_content_margin_all(10)
		b.add_theme_stylebox_override("hover", hover)

		character_buttons.append({"id": id, "button": b})
		char_select_row.add_child(b)

	v.add_child(_create_overlay_divider())

	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	actions.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(actions)

	var next_btn = _create_small_button("下一步 →")
	next_btn.custom_minimum_size = Vector2(160, 40)
	next_btn.pressed.connect(func():
		_hide_overlay(start_character_overlay)
		_update_level_buttons()
		_show_overlay_deferred(start_level_overlay)
	)
	actions.add_child(next_btn)

	_update_character_buttons()

func _update_character_buttons():
	for entry in character_buttons:
		var id = String(entry["id"])
		var b: Button = entry["button"]
		if b == null:
			continue
		var selected = id == selected_character
		b.modulate = Color(1.15, 1.15, 1.15) if selected else Color.WHITE

func _build_start_level_overlay():
	start_level_overlay = _make_overlay_root()

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_level_overlay.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 400)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style = _get_overlay_panel_style()
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.offset_left = 20
	v.offset_right = -20
	v.offset_top = 20
	v.offset_bottom = -20
	panel.add_child(v)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	v.add_child(header)

	var title = Label.new()
	title.text = "🏰 关卡选择"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn = _create_small_button("✕ 关闭")
	close_btn.pressed.connect(func(): _hide_overlay(start_level_overlay))
	header.add_child(close_btn)

	v.add_child(_create_overlay_divider())

	var level_hint = Label.new()
	level_hint.text = "选择起始关卡 (越高越具挑战性)"
	level_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_hint.add_theme_font_size_override("font_size", 16)
	level_hint.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	v.add_child(level_hint)

	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(grid)

	level_buttons = []
	for i in range(MAX_LEVEL):
		var idx := i + 1
		var b = _create_level_button(idx)
		level_buttons.append(b)
		grid.add_child(b)

	v.add_child(_create_overlay_divider())

	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	actions.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(actions)

	var back_btn = _create_small_button("← 上一步")
	back_btn.pressed.connect(func():
		_hide_overlay(start_level_overlay)
		_show_overlay(start_character_overlay)
	)
	actions.add_child(back_btn)

	var start_btn = _create_small_button("🚀 开始游戏")
	start_btn.custom_minimum_size = Vector2(160, 40)
	start_btn.pressed.connect(func():
		_hide_overlay(start_level_overlay)
		_start_new_game(pending_start_level)
	)
	actions.add_child(start_btn)

func _create_level_button(level: int) -> Button:
	var b = Button.new()
	b.text = "%d" % level
	b.custom_minimum_size = Vector2(90, 70)
	b.add_theme_font_size_override("font_size", 32)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.13, 0.18)
	style.border_color = Color(0.35, 0.33, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.2, 0.25, 0.35)
	hover.border_color = Color(0.5, 0.6, 0.8)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(8)
	hover.set_content_margin_all(8)
	b.add_theme_stylebox_override("hover", hover)

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(0.25, 0.35, 0.5)
	pressed.border_color = Color(0.6, 0.75, 1.0)
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(8)
	pressed.set_content_margin_all(8)
	b.add_theme_stylebox_override("pressed", pressed)

	b.pressed.connect(func():
		pending_start_level = level
		_update_level_buttons()
	)

	return b

func _update_level_buttons():
	for b in level_buttons:
		if b is Button:
			var n = int(b.text)
			b.disabled = false
			b.modulate = Color(0.5, 0.8, 1.0) if n == pending_start_level else Color(1, 1, 1)
