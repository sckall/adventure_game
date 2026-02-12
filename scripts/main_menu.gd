extends Node2D

# ============ 主菜单 ============

var selected_character: String = "warrior"
var save_slots: Array = [{}, {}, {}]

func _ready():
	randomize()
	_load_save_data()
	_create_menu_ui()
	
	print("=== 主菜单 ===")

func _load_save_data():
	# 模拟存档数据
	for i in range(3):
		var slot_file = "user://save_slot_%d.json" % i
		if FileAccess.file_exists(slot_file):
			var file = FileAccess.open(slot_file, FileAccess.READ)
			if file:
				var json = file.get_as_text()
				save_slots[i] = JSON.parse_string(json)

func _create_menu_ui():
	# 背景渐变
	var bg = ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.1, 0.1, 0.2)
	add_child(bg)
	
	# 标题
	var title = Label.new()
	title.text = "🎮 CHUI的冒险"
	title.position = Vector2(440, 80)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35))
	add_child(title)
	
	# 副标题
	var subtitle = Label.new()
	subtitle.text = "2D平台冒险游戏"
	subtitle.position = Vector2(500, 140)
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	add_child(subtitle)
	
	# 角色选择
	var char_label = Label.new()
	char_label.text = "选择角色:"
	char_label.position = Vector2(440, 220)
	char_label.add_theme_font_size_override("font_size", 20)
	char_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(char_label)
	
	var characters = ["⚔️ 战士", "🗡️ 刺客", "✨ 法师", "⭐ 牧师", "🏹 射手"]
	for i in range(characters.size()):
		var btn = Label.new()
		btn.text = characters[i]
		btn.position = Vector2(440 + i * 100, 260)
		btn.add_theme_font_size_override("font_size", 18)
		if i == 0:
			btn.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35))
		else:
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		btn.name = "char_%d" % i
		add_child(btn)
	
	# 开始按钮
	var start_btn = _create_button("🚀 开始游戏", 340)
	start_btn.name = "StartButton"
	add_child(start_btn)
	
	# 存档按钮
	var save_btn = _create_button("💾 存档管理", 400)
	save_btn.name = "SaveButton"
	add_child(save_btn)
	
	# 设置按钮
	var settings_btn = _create_button("⚙️ 游戏设置", 460)
	settings_btn.name = "SettingsButton"
	add_child(settings_btn)
	
	# 退出按钮
	var quit_btn = _create_button("❌ 退出游戏", 520)
	quit_btn.name = "QuitButton"
	add_child(quit_btn)
	
	# 操作说明
	var help = Label.new()
	help.text = "操作: A/D 移动 | 空格 跳跃 | K 攻击 | ESC 暂停"
	help.position = Vector2(360, 600)
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	add_child(help)

func _create_button(text: String, y: float) -> Label:
	var btn = Label.new()
	btn.text = text
	btn.position = Vector2(520, y)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	return btn

func _process(_delta):
	# 检测点击
	if Input.is_action_just_pressed("ui_accept"):
		_check_button_click()

func _check_button_click():
	# 简化的按钮检测
	var mouse_pos = get_viewport().get_mouse_position()
	
	# 开始游戏
	if mouse_pos.y > 340 and mouse_pos.y < 380:
		_start_game()
	
	# 退出
	elif mouse_pos.y > 520 and mouse_pos.y < 560:
		get_tree().quit()

func _start_game():
	print("开始游戏! 角色: %s" % selected_character)
	
	# 切换到主游戏场景
	var game = load("res://scripts/Game.gd").new()
	get_parent().add_child(game)
	queue_free()
