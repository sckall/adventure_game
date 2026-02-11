extends Control
class_name BossIntroUI

# ============ Boss战预告界面 ============
# 在Boss战开始前显示Boss信息

signal intro_completed()

@onready var boss_name_label = $VBoxContainer/BossName
@onready var boss_title_label = $VBoxContainer/BossTitle
@onready var hp_bar = $VBoxContainer/HPBarContainer/HPBar
@onready var hp_text = $VBoxContainer/HPBarContainer/HPText
@onready var warning_label = $VBoxContainer/WarningLabel
@onready var abilities_container = $VBoxContainer/AbilitiesContainer
@onready var vs_label = $VSLabel

var boss_name: String = ""
var boss_title: String = ""
var max_hp: int = 20
var abilities: Array = []
var intro_timer: float = 0.0
const INTRO_DURATION: float = 3.5  # 预告持续时间

func _ready():
	# 初始隐藏
	modulate.a = 0.0

	# 设置字体样式
	_setup_styles()

func _setup_styles():
	# Boss名称 - 大号金色字体
	boss_name_label.add_theme_font_size_override("font_size", 72)
	boss_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	boss_name_label.add_theme_color_override("font_shadow_color", Color(0.5, 0.2, 0, 0.8))
	boss_name_label.add_theme_constant_override("shadow_offset_x", 4)
	boss_name_label.add_theme_constant_override("shadow_offset_y", 4)

	# Boss称号 - 中号白色字体
	boss_title_label.add_theme_font_size_override("font_size", 36)
	boss_title_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))

	# HP条样式
	hp_bar.add_theme_font_size_override("font_size", 28)
	hp_text.add_theme_font_size_override("font_size", 24)
	hp_text.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 1))

	# 警告文字 - 闪烁红色
	warning_label.add_theme_font_size_override("font_size", 32)
	warning_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))

	# VS标签
	vs_label.add_theme_font_size_override("font_size", 96)
	vs_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))

	# 能力标签样式
	for ability_label in abilities_container.get_children():
		ability_label.add_theme_font_size_override("font_size", 22)
		ability_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6, 1))

# 显示Boss预告
func show_boss_intro(name: String, title: String, hp: int, boss_abilities: Array = []):
	boss_name = name
	boss_title = title
	max_hp = hp
	abilities = boss_abilities

	# 更新UI内容
	boss_name_label.text = boss_name
	boss_title_label.text = boss_title
	hp_text.text = "HP: %d" % max_hp

	# 更新HP条
	_update_hp_bar(max_hp, max_hp)

	# 更新能力列表
	_update_abilities(abilities)

	# 播放预告动画
	_play_intro_animation()

# 更新HP条显示
func _update_hp_bar(current: int, maximum: int):
	var hp_percent = float(current) / maximum
	hp_bar.value = hp_percent * 100
	hp_text.text = "HP: %d / %d" % [current, maximum]

	# 根据血量百分比改变颜色
	if hp_percent > 0.6:
		hp_bar.modulate = Color(0.3, 0.9, 0.3)
	elif hp_percent > 0.3:
		hp_bar.modulate = Color(1, 0.8, 0.2)
	else:
		hp_bar.modulate = Color(1, 0.2, 0.2)

# 更新能力列表
func _update_abilities(ability_list: Array):
	# 清空现有能力标签
	for child in abilities_container.get_children():
		child.queue_free()

	# 添加新能力标签
	var ability_names = {
		"近战": "⚔️ 近战专家",
		"弹幕": "🔮 弹幕攻击",
		"冲撞": "💥 冲撞",
		"传送": "✨ 传送打击",
		"震地": "🌋 震地波",
		"狂暴": "🔥 狂暴模式"
	}

	for ability in ability_list:
		var label = Label.new()
		label.text = ability_names.get(ability, "🔹 " + ability)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		abilities_container.add_child(label)

# 播放预告动画
func _play_intro_animation():
	# 淡入效果
	var tween = create_tween()
	tween.set_parallel(true)

	# 背景/主容器淡入
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# VS标签缩放动画
	tween.tween_property(vs_label, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(vs_label, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.3)
	tween.tween_property(vs_label, "modulate:a", 0.0, 0.5).set_delay(2.5)

	# 警告文字闪烁
	tween.tween_property(warning_label, "modulate:a", 0.3, 0.4)
	tween.tween_property(warning_label, "modulate:a", 1.0, 0.4).set_delay(0.4)
	tween.tween_property(warning_label, "modulate:a", 0.3, 0.4).set_delay(0.8)
	tween.tween_property(warning_label, "modulate:a", 1.0, 0.4).set_delay(1.2)
	tween.tween_property(warning_label, "modulate:a", 0.3, 0.4).set_delay(1.6)

	# HP条填充动画
	tween.tween_property(hp_bar, "value", 100.0, 1.0).set_delay(0.3).set_trans(Tween.TRANS_BACK)

	# 等待动画完成后隐藏
	await get_tree().create_timer(INTRO_DURATION).timeout

	# 淡出
	var fade_out = create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 0.5)

	await fade_out.finished
	intro_completed.emit()
	hide()
