extends Control

@onready var btn_start = $BtnContainer/BtnStart
@onready var btn_continue = $BtnContainer/BtnContinue
@onready var btn_shop = $BtnContainer/BtnShop
@onready var btn_save = $BtnContainer/BtnSave
@onready var btn_exit = $BtnContainer/BtnExit
@onready var stats_label = $Stats
@onready var char_label = $CharLabel
@onready var title_label = $Title
@onready var subtitle_label = $Subtitle
@onready var bg = $Bg
@onready var title_glow = $TitleGlow
@onready var particles = $BackgroundParticles
@onready var victory_info = $VictoryInfo
@onready var controls_info = $ControlsInfo

@onready var g = get_node("/root/Global")
@onready var env = get_node("/root/EnvironmentManager")
@onready var audio = get_node("/root/AudioManager")
@onready var constants = get_node("/root/GameConstants")

# 入场动画
var animation_tween: Tween

func _ready():
	# 播放入场动画
	_play_intro_animation()

	update_stats()
	update_char_display()

	if g.max_unlocked_level <= 1:
		btn_continue.disabled = true

	# 初始化环境系统（动态背景）
	_initialize_environment()

	# ============ 美化按钮样式 ============
	_setup_button_styles()

	# ============ 美化标题样式 ============
	_setup_title_styles()

	# ============ 美化统计标签 ============
	_setup_stats_styles()

	# 确保按钮可以接收输入
	btn_start.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_continue.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_shop.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_save.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_exit.mouse_filter = Control.MOUSE_FILTER_STOP

	if btn_start:
		btn_start.pressed.connect(_on_start)
	if btn_continue:
		btn_continue.pressed.connect(_on_continue)
	if btn_shop:
		btn_shop.pressed.connect(_on_shop)
	if btn_save:
		btn_save.pressed.connect(_on_save_management)
	if btn_exit:
		btn_exit.pressed.connect(_on_exit)

# 入场动画
func _play_intro_animation():
	# 初始状态
	modulate.a = 0.0
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	$BtnContainer.modulate.a = 0.0
	$BtnContainer.position.y += 50

	animation_tween = create_tween()
	animation_tween.set_parallel(false)

	# 背景淡入
	animation_tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# 标题动画（带弹性效果）
	animation_tween.tween_property(title_label, "modulate:a", 1.0, 0.4)
	animation_tween.parallel().tween_property(title_glow, "modulate:a", 0.6, 0.4)

	# 副标题淡入
	animation_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.3)

	# 按钮容器从下方滑入
	animation_tween.tween_property($BtnContainer, "modulate:a", 1.0, 0.4)
	animation_tween.parallel().tween_property($BtnContainer, "position:y", $BtnContainer.position.y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# 按钮样式设置
func _setup_button_styles():
	var buttons = [btn_start, btn_continue, btn_shop, btn_save, btn_exit]
	var button_texts = ["选择角色开始", "继续游戏", "🛒 商店", "💾 存档", "退出游戏"]

	for i in range(buttons.size()):
		var btn = buttons[i]
		btn.text = button_texts[i]
		btn.custom_minimum_size = Vector2(420, 70)
		btn.add_theme_font_size_override("font_size", 38)

		# 创建渐变按钮样式
		var normal_style = _create_gradient_button_style(_get_button_color(i), false)
		var hover_style = _create_gradient_button_style(_get_button_color(i), true)

		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)

		# 按钮文字颜色
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))

# 获取按钮颜色（渐变色 - 优化配色方案）
func _get_button_color(index: int) -> Color:
	var colors = [
		Color(0.25, 0.55, 0.95),   # 蓝色 - 开始 (更鲜艳)
		Color(0.2, 0.75, 0.5),     # 绿色 - 继续 (清新绿)
		Color(0.95, 0.55, 0.2),    # 橙色 - 商店 (暖橙色)
		Color(0.45, 0.35, 0.85),   # 紫色 - 存档 (柔和紫)
		Color(0.85, 0.3, 0.3)      # 红色 - 退出 (正红色)
	]
	return colors[index % colors.size()]

# 创建渐变按钮样式
func _create_gradient_button_style(base_color: Color, is_hover: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()

	# 简单背景色（Godot 4 StyleBoxFlat 不支持垂直渐变）
	var final_color = base_color
	if is_hover:
		final_color = Color(
			min(base_color.r + 0.15, 1.0),
			min(base_color.g + 0.15, 1.0),
			min(base_color.b + 0.15, 1.0),
			1.0
		)
	
	style.bg_color = final_color

	# 圆角
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16

	# 柔和边框
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.25)

	# 柔和阴影
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_offset = Vector2(0, 4)
	style.shadow_size = 10 if is_hover else 6

	return style

# 标题样式设置
func _setup_title_styles():
	# 主标题 - 金色渐变效果
	title_label.add_theme_font_size_override("font_size", 96)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1))  # 金黄色
	title_label.add_theme_color_override("font_shadow_color", Color(0.9, 0.5, 0.1, 0.5))  # 橙色阴影
	title_label.add_theme_constant_override("shadow_offset_x", 0)
	title_label.add_theme_constant_override("shadow_offset_y", 6)
	title_label.add_theme_constant_override("shadow_outline_size", 4)

	# 副标题 - 浅蓝色
	subtitle_label.add_theme_font_size_override("font_size", 32)
	subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.82, 1.0, 1))

# 统计样式设置
func _setup_stats_styles():
	# 统计标签 - 柔和白色
	stats_label.add_theme_font_size_override("font_size", 28)
	stats_label.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0, 1))

	# 角色标签 - 淡紫色
	char_label.add_theme_font_size_override("font_size", 26)
	char_label.add_theme_color_override("font_color", Color(0.85, 0.78, 1.0, 1))
	
	# 胜利信息 - 金橙色
	victory_info.add_theme_font_size_override("font_size", 22)
	victory_info.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45, 1))
	
	# 操作提示 - 灰蓝色
	controls_info.add_theme_font_size_override("font_size", 20)
	controls_info.add_theme_color_override("font_color", Color(0.65, 0.78, 0.9, 1))

# 初始化环境系统
func _initialize_environment():
	# 设置初始背景色（使用略微变暗的版本，适合菜单）
	var base_color = env.get_background_color()
	bg.color = _darken_color(base_color, 0.4)

	# 连接背景色更新信号
	env.background_color_updated.connect(_on_background_color_changed)

	# 连接时间段变化信号
	env.time_period_changed.connect(_on_time_period_changed)

# 背景色改变回调
func _on_background_color_changed(color: Color):
	if bg:
		bg.color = _darken_color(color, 0.4)

# 时间段改变回调
func _on_time_period_changed(period_name: String):
	print("时间段变化: " + period_name)

# 加深颜色（用于菜单背景，使其比游戏背景略暗）
func _darken_color(color: Color, factor: float) -> Color:
	return Color(
		color.r * (1.0 - factor),
		color.g * (1.0 - factor),
		color.b * (1.0 - factor),
		1.0
	)

func update_stats():
	update_stats_with_time()

# 更新统计信息（包含时间）
func update_stats_with_time():
	var time_str = env.get_time_string()
	var period_str = env.get_period_name()
	stats_label.text = "⏰ %s [%s]  🍄 蘑菇: %d  🟢 绿瓶: %d  🟡 黄瓶: %d" % [
		time_str, period_str, g.total_mushrooms, g.total_bottles_green, g.total_bottles_yellow
	]

func _process(delta):
	# 更新时间显示
	update_stats_with_time()

	# 更新标题发光动画
	if title_glow:
		var pulse = sin(Time.get_ticks_msec() * 0.002) * 0.15 + 0.5
		title_glow.modulate.a = pulse

func update_char_display():
	var info = g.get_character_info(g.selected_character)
	char_label.text = "⚔️ 当前英雄: %s (%s)" % [info["name"], info["description"]]

func _on_start():
	$BtnContainer.visible = false
	$Stats.visible = false
	$CharLabel.visible = false
	show_character_select()

func _on_continue():
	g.current_level_num = g.max_unlocked_level
	goto_game()

func _on_exit():
	get_tree().quit()

func _on_shop():
	show_shop()

func _on_save_management():
	show_save_management()

# ============ 存档管理系统 ============

func show_save_management():
	if has_node("SaveLayer"):
		$SaveLayer.queue_free()

	var layer = CanvasLayer.new()
	layer.name = "SaveLayer"
	layer.layer = 100

	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.03, 0.06, 0.12, 0.95)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			e.accept_event()
			_on_save_back()
	)
	layer.add_child(overlay)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -650
	panel.offset_top = -400
	panel.offset_right = 650
	panel.offset_bottom = 400
	panel.custom_minimum_size = Vector2(1300, 800)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.1, 0.18, 0.98)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.25, 0.55, 1.0, 0.85)
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_offset = Vector2(0, 10)
	style.shadow_size = 32
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "💾 存档管理"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.3, 0.85, 1, 1))
	vbox.add_child(title)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	vbox.add_child(grid)

	for slot in range(1, 4):
		var slot_card = create_save_slot_card(slot)
		grid.add_child(slot_card)

	var back_btn = Button.new()
	back_btn.text = "← 返回主菜单"
	back_btn.custom_minimum_size = Vector2(350, 75)
	back_btn.add_theme_font_size_override("font_size", 32)
	_back_btn_style(back_btn)
	back_btn.pressed.connect(_on_save_back)
	vbox.add_child(back_btn)

	layer.add_child(panel)
	add_child(layer)

func _back_btn_style(btn: Button):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.7)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", style)

func create_save_slot_card(slot: int):
	var slot_info = g.get_save_slot_info(slot)
	var is_current = slot == g.current_save_slot

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(400, 180)

	var card_style = StyleBoxFlat.new()
	if slot_info.get("exists", false):
		card_style.bg_color = Color(0.12, 0.18, 0.28, 0.95)
		card_style.border_color = Color(0.3, 0.4, 0.5, 0.7)
	else:
		card_style.bg_color = Color(0.15, 0.22, 0.32, 0.98)
		card_style.border_color = Color(0.3, 0.7, 1, 1) if is_current else Color(0.3, 0.5, 0.8, 0.9)

	card_style.border_width_left = 4
	card_style.border_width_top = 4
	card_style.border_width_right = 4
	card_style.border_width_bottom = 4
	card_style.corner_radius_top_left = 16
	card_style.corner_radius_top_right = 16
	card_style.corner_radius_bottom_left = 16
	card_style.corner_radius_bottom_right = 16
	card.add_theme_stylebox_override("panel", card_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	var slot_label = Label.new()
	if is_current:
		slot_label.text = "📁 存档槽 %d [当前使用]" % slot
		slot_label.add_theme_color_override("font_color", Color(0.3, 0.95, 1, 1))
	else:
		slot_label.text = "📁 存档槽 %d" % slot
		slot_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95, 1))
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(slot_label)

	if slot_info.get("exists", false):
		if slot_info.get("corrupted", false):
			var info_text = "关卡: %d\n角色: %s\n🍄 蘑菇: %d" % [
				slot_info.get("level", 1),
				slot_info.get("character", "未知"),
				slot_info.get("mushrooms", 0)
			]
			var color = Color(0.75, 0.85, 1, 1)

			var info_label = Label.new()
			info_label.text = info_text
			info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			info_label.add_theme_font_size_override("font_size", 18)
			info_label.add_theme_color_override("font_color", color)
			vbox.add_child(info_label)

			var time_label = Label.new()
			time_label.text = slot_info.get("datetime_str", "")
			time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			time_label.add_theme_font_size_override("font_size", 14)
			time_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85, 1))
			vbox.add_child(time_label)
		else:
			var empty_label = Label.new()
			empty_label.text = "存档损坏"
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.add_theme_font_size_override("font_size", 18)
			empty_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
			vbox.add_child(empty_label)
	else:
		var empty_label = Label.new()
		empty_label.text = "空存档槽"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65, 1))
		vbox.add_child(empty_label)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var load_btn = Button.new()
	load_btn.text = "加载"
	load_btn.custom_minimum_size = Vector2(190, 48)
	load_btn.add_theme_font_size_override("font_size", 20)
	if slot_info.get("exists", false) and not slot_info.get("corrupted", false) and not is_current:
		load_btn.disabled = false
		load_btn.pressed.connect(_on_load_save.bind(slot))
	else:
		load_btn.disabled = true
	btn_row.add_child(load_btn)

	var save_btn = Button.new()
	save_btn.text = "保存"
	save_btn.custom_minimum_size = Vector2(190, 48)
	save_btn.add_theme_font_size_override("font_size", 20)
	save_btn.pressed.connect(_on_save_to_slot.bind(slot))
	btn_row.add_child(save_btn)

	return card

func _on_load_save(slot: int):
	if g.load_game(slot):
		audio.play_collect()
		show_save_management()

func _on_save_to_slot(slot: int):
	g.current_save_slot = slot
	g.save_game(slot)
	audio.play_collect()
	show_save_management()

func _on_save_back():
	if has_node("SaveLayer"):
		$SaveLayer.queue_free()

# ============ 商店系统 ============

func show_shop():
	if has_node("ShopLayer"):
		$ShopLayer.queue_free()

	var layer = CanvasLayer.new()
	layer.name = "ShopLayer"
	layer.layer = 100

	# 半透明遮罩
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.03, 0.06, 0.12, 0.95)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			e.accept_event()
			_on_shop_back()
	)
	layer.add_child(overlay)

	# 中央面板
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -700
	panel.offset_top = -450
	panel.offset_right = 700
	panel.offset_bottom = 450
	panel.custom_minimum_size = Vector2(1400, 900)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.1, 0.18, 0.98)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(1.0, 0.7, 0.25, 0.85)  # 金色边框
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_offset = Vector2(0, 10)
	style.shadow_size = 32
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	panel.add_child(vbox)

	# 标题
	var title = Label.new()
	title.text = "🛒 商店 - 强化你的英雄"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
	vbox.add_child(title)

	# 蘑菇数量显示
	var mushrooms_label = Label.new()
	mushrooms_label.text = "🍄 你的蘑菇: %d" % g.total_mushrooms
	mushrooms_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mushrooms_label.add_theme_font_size_override("font_size", 38)
	mushrooms_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	vbox.add_child(mushrooms_label)

	# 升级选项网格
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	vbox.add_child(grid)

	# 升级项目
	var upgrades = [
		{
			"type": "hp",
			"name": "❤️ 生命值提升",
			"desc": "每级增加1点最大HP",
			"icon": "❤️",
			"color": Color(0.9, 0.3, 0.3, 1)
		},
		{
			"type": "speed",
			"name": "🏃 移动速度提升",
			"desc": "每级增加10点移动速度",
			"icon": "🏃",
			"color": Color(0.3, 0.8, 0.5, 1)
		},
		{
			"type": "jump",
			"name": "🦘 跳跃力提升",
			"desc": "每级增加30点跳跃力",
			"icon": "🦘",
			"color": Color(0.4, 0.6, 0.95, 1)
		},
		{
			"type": "damage",
			"name": "⚔️ 攻击力提升",
			"desc": "每级增加0.5点伤害",
			"icon": "⚔️",
			"color": Color(1, 0.6, 0.2, 1)
		}
	]

	for upgrade in upgrades:
		var card = create_upgrade_card(upgrade)
		grid.add_child(card)

	# 返回按钮
	var back_btn = Button.new()
	back_btn.text = "← 返回主菜单"
	back_btn.custom_minimum_size = Vector2(350, 80)
	back_btn.add_theme_font_size_override("font_size", 36)
	_back_btn_style(back_btn)
	back_btn.pressed.connect(_on_shop_back)
	vbox.add_child(back_btn)

	layer.add_child(panel)
	add_child(layer)

func create_upgrade_card(upgrade):
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(640, 200)

	var card_style = StyleBoxFlat.new()
	var upgrade_color = upgrade["color"]
	card_style.bg_color = Color(0.12, 0.18, 0.26, 0.98)
	card_style.border_width_left = 5
	card_style.border_width_top = 5
	card_style.border_width_right = 5
	card_style.border_width_bottom = 5
	card_style.border_color = upgrade_color
	card_style.corner_radius_top_left = 20
	card_style.corner_radius_top_right = 20
	card_style.corner_radius_bottom_left = 20
	card_style.corner_radius_bottom_right = 20
	card.add_theme_stylebox_override("panel", card_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	# 标题行
	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 16)
	vbox.add_child(title_row)

	var icon_label = Label.new()
	icon_label.text = upgrade["icon"]
	icon_label.custom_minimum_size = Vector2(60, 0)
	icon_label.add_theme_font_size_override("font_size", 42)
	title_row.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = upgrade["name"]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", upgrade_color)
	title_row.add_child(name_label)

	# 等级和价格行
	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 24)
	vbox.add_child(info_row)

	var level_box = VBoxContainer.new()
	info_row.add_child(level_box)

	var level_title = Label.new()
	level_title.text = "当前等级"
	level_title.add_theme_font_size_override("font_size", 16)
	level_title.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1))
	level_box.add_child(level_title)

	var level_value = Label.new()
	var level = g.get_upgrade_level(upgrade["type"])
	level_value.text = "%d / 5" % level
	level_value.add_theme_font_size_override("font_size", 24)
	level_value.add_theme_color_override("font_color", Color(1, 0.9, 0.6, 1))
	level_box.add_child(level_value)

	var price_box = VBoxContainer.new()
	info_row.add_child(price_box)

	var price_title = Label.new()
	price_title.text = "升级价格"
	price_title.add_theme_font_size_override("font_size", 16)
	price_title.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1))
	price_box.add_child(price_title)

	var price_value = Label.new()
	var price = g.get_upgrade_price(upgrade["type"])
	if price < 0:
		price_value.text = "已满级 ✨"
		price_value.add_theme_color_override("font_color", Color(0.4, 1, 0.4, 1))
	elif g.can_afford_upgrade(upgrade["type"]):
		price_value.text = "🍄 %d" % price
		price_value.add_theme_color_override("font_color", Color(1, 0.9, 0.4, 1))
	else:
		price_value.text = "🍄 %d" % price
		price_value.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	price_value.add_theme_font_size_override("font_size", 24)
	price_box.add_child(price_value)

	# 描述
	var desc_label = Label.new()
	desc_label.text = upgrade["desc"]
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1))
	vbox.add_child(desc_label)

	# 购买按钮
	var buy_btn = Button.new()
	if price < 0:
		buy_btn.text = "已满级"
		buy_btn.disabled = true
	elif g.can_afford_upgrade(upgrade["type"]):
		buy_btn.text = "购买升级"
		buy_btn.pressed.connect(_on_purchase_upgrade.bind(upgrade["type"]))
	else:
		buy_btn.text = "蘑菇不足"
		buy_btn.disabled = true
	buy_btn.custom_minimum_size = Vector2(620, 58)
	buy_btn.add_theme_font_size_override("font_size", 26)
	vbox.add_child(buy_btn)

	return card

func _on_purchase_upgrade(upgrade_type):
	if g.purchase_upgrade(upgrade_type):
		audio.play_collect()
		show_shop()
		update_stats()

func _on_shop_back():
	if has_node("ShopLayer"):
		$ShopLayer.queue_free()

func show_character_select():
	if has_node("CharSelectLayer"):
		$CharSelectLayer.queue_free()

	var layer = CanvasLayer.new()
	layer.name = "CharSelectLayer"
	layer.layer = 100

	# 半透明遮罩，点击可关闭
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.05, 0.08, 0.12, 0.9)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			e.accept_event()
			_on_char_select_back()
	)
	layer.add_child(overlay)

	# 中央面板
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -700
	panel.offset_top = -450
	panel.offset_right = 700
	panel.offset_bottom = 450
	panel.custom_minimum_size = Vector2(1400, 900)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.24, 0.98)
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	style.border_color = Color(0.4, 0.6, 0.85, 0.9)
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_offset = Vector2(0, 8)
	style.shadow_size = 28
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	panel.add_child(vbox)

	# 标题
	var title = Label.new()
	title.text = "⚔️ 选择你的英雄 ⚔️"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1, 0.92, 0.7, 1))
	vbox.add_child(title)

	# 副标题
	var subtitle = Label.new()
	subtitle.text = "每个角色都有独特的能力和战斗风格"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 26)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9, 1))
	vbox.add_child(subtitle)

	# 角色网格容器
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	vbox.add_child(grid)

	for char_id in g.characters:
		var info = g.characters[char_id]
		var char_card = create_character_card(info, char_id)
		grid.add_child(char_card)

	# 返回按钮
	var back_btn = Button.new()
	back_btn.text = "← 返回主菜单"
	back_btn.custom_minimum_size = Vector2(350, 75)
	back_btn.add_theme_font_size_override("font_size", 34)
	_back_btn_style(back_btn)
	back_btn.pressed.connect(_on_char_select_back)
	vbox.add_child(back_btn)

	layer.add_child(panel)
	add_child(layer)

func create_character_card(info, char_id):
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(650, 190)

	var card_style = StyleBoxFlat.new()
	var char_color = info.get("color", Color(0.5, 0.5, 0.5))
	card_style.bg_color = Color(0.15, 0.2, 0.3, 0.95)
	card_style.border_width_left = 5
	card_style.border_width_top = 5
	card_style.border_width_right = 5
	card_style.border_width_bottom = 5
	card_style.border_color = char_color
	card_style.corner_radius_top_left = 20
	card_style.corner_radius_top_right = 20
	card_style.corner_radius_bottom_left = 20
	card_style.corner_radius_bottom_right = 20
	card.add_theme_stylebox_override("panel", card_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	card.add_child(hbox)

	# 角色图标
	var icon_container = VBoxContainer.new()
	icon_container.custom_minimum_size = Vector2(110, 0)
	hbox.add_child(icon_container)

	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(85, 85)
	icon.color = char_color
	icon.z_index = 1
	icon_container.add_child(icon)

	var icon_label = Label.new()
	icon_label.text = info["name"]
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 20)
	icon_label.add_theme_color_override("font_color", char_color)
	icon_container.add_child(icon_label)

	# 信息区域
	var info_box = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 8)
	hbox.add_child(info_box)

	# 名称和描述
	var name_label = Label.new()
	name_label.text = "⭐ " + info["name"]
	name_label.add_theme_font_size_override("font_size", 36)
	name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.9, 1))
	info_box.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = info["description"]
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9, 1))
	info_box.add_child(desc_label)

	# 属性栏
	var stats_box = HBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 20)
	info_box.add_child(stats_box)

	var speed_rank = "C"
	var speed_color = Color(0.6, 0.6, 0.6, 1)
	if info["speed"] >= 300:
		speed_rank = "S"
		speed_color = Color(1, 0.8, 0.2, 1)
	elif info["speed"] >= 280:
		speed_rank = "A"
		speed_color = Color(0.3, 0.8, 0.3, 1)

	var speed_label = Label.new()
	speed_label.text = "🏃 " + speed_rank
	speed_label.add_theme_font_size_override("font_size", 24)
	speed_label.add_theme_color_override("font_color", speed_color)
	stats_box.add_child(speed_label)

	var jump_rank = "C"
	var jump_color = Color(0.6, 0.6, 0.6, 1)
	if abs(info["jump_force"]) >= 700:
		jump_rank = "S"
		jump_color = Color(1, 0.8, 0.2, 1)
	elif abs(info["jump_force"]) >= 650:
		jump_rank = "A"
		jump_color = Color(0.3, 0.8, 0.3, 1)

	var jump_label = Label.new()
	jump_label.text = "🦘 " + jump_rank
	jump_label.add_theme_font_size_override("font_size", 24)
	jump_label.add_theme_color_override("font_color", jump_color)
	stats_box.add_child(jump_label)

	var hp_label = Label.new()
	hp_label.text = "❤️ x" + str(info["hp"])
	hp_label.add_theme_font_size_override("font_size", 24)
	hp_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1))
	stats_box.add_child(hp_label)

	# 技能列表
	var skills_text = ""
	for skill in info["skills"]:
		skills_text += constants.get_skill_name(skill) + " "

	var skills_label = Label.new()
	skills_label.text = "✨ " + skills_text.strip_edges()
	skills_label.add_theme_font_size_override("font_size", 19)
	skills_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1, 1))
	info_box.add_child(skills_label)

	# 选择按钮
	var btn = Button.new()
	btn.text = "选择"
	btn.custom_minimum_size = Vector2(150, 55)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_on_char_selected.bind(char_id))
	hbox.add_child(btn)

	return card

func _on_char_selected(char_id):
	g.set_character(char_id)
	update_char_display()
	if has_node("CharSelectLayer"):
		$CharSelectLayer.queue_free()
	show_level_select()

func _on_char_select_back():
	if has_node("CharSelectLayer"):
		$CharSelectLayer.queue_free()
	$BtnContainer.visible = true
	$Stats.visible = true
	$CharLabel.visible = true

func show_level_select():
	if has_node("LevelSelectLayer"):
		$LevelSelectLayer.queue_free()

	var layer = CanvasLayer.new()
	layer.name = "LevelSelectLayer"
	layer.layer = 100

	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			e.accept_event()
			_on_level_select_back()
	)
	layer.add_child(overlay)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -480
	panel.offset_top = -320
	panel.offset_right = 480
	panel.offset_bottom = 320
	panel.custom_minimum_size = Vector2(960, 640)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.3, 0.98)
	style.border_width_left = 5
	style.border_width_top = 5
	style.border_width_right = 5
	style.border_width_bottom = 5
	style.border_color = Color(0.4, 0.6, 0.8)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🎮 选择关卡"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.7, 1))
	vbox.add_child(title)

	for i in range(1, 6):
		var btn = Button.new()
		var is_unlocked = i <= g.max_unlocked_level
		btn.text = "第 %d 关 - %s %s" % [i, g.get_level_name(i), "🔓" if is_unlocked else "🔒"]
		btn.custom_minimum_size = Vector2(700, 80)
		btn.add_theme_font_size_override("font_size", 44)

		if is_unlocked:
			btn.pressed.connect(_on_level_selected.bind(i))
		else:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)

		vbox.add_child(btn)

	var back_btn = Button.new()
	back_btn.text = "← 返回"
	back_btn.custom_minimum_size = Vector2(700, 80)
	back_btn.add_theme_font_size_override("font_size", 44)
	_back_btn_style(back_btn)
	back_btn.pressed.connect(_on_level_select_back)
	vbox.add_child(back_btn)

	layer.add_child(panel)
	add_child(layer)

func _on_level_select_back():
	if has_node("LevelSelectLayer"):
		$LevelSelectLayer.queue_free()
	$BtnContainer.visible = true
	$Stats.visible = true
	$CharLabel.visible = true

func _on_level_selected(level_num):
	g.current_level_num = level_num
	g.reset_level_data()
	goto_game()

func goto_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
