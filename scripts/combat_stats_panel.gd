extends Control
class_name CombatStatsPanel

# ============ 战斗统计面板 ============
# 实时显示战斗数据和统计信息

signal stats_closed()

# 战斗数据
var battle_stats: Dictionary = {
	"damage_dealt": 0,
	"damage_taken": 0,
	"hits_landed": 0,
	"hits_received": 0,
	"dodges": 0,
	"perfect_blocks": 0,
	"combo_count": 0,
	"max_combo": 0,
	"battle_time": 0.0,
	"boss_hp_percent": 100.0
}

# Boss学习数据（显示AI正在学什么）
var ai_learning_data: Dictionary = {
	"detected_preference": "",
	"prediction_accuracy": 0,
	"adapted_attacks": []
}

@onready var damage_dealt_label = $StatsContainer/DamageDealt/Value if has_node("StatsContainer/DamageDealt/Value") else null
@onready var damage_taken_label = $StatsContainer/DamageTaken/Value if has_node("StatsContainer/DamageTaken/Value") else null
@onready var hits_label = $StatsContainer/Hits/Value if has_node("StatsContainer/Hits/Value") else null
@onready var combo_label = $StatsContainer/Combo/Value if has_node("StatsContainer/Combo/Value") else null
@onready var time_label = $StatsContainer/Time/Value if has_node("StatsContainer/Time/Value") else null
@onready var boss_hp_bar = $BossHPContainer/HPBar if has_node("BossHPContainer/HPBar") else null
@onready var boss_hp_text = $BossHPContainer/HPText if has_node("BossHPContainer/HPText") else null
@onready var ai_info_label = $AIInfoContainer/AIInfo if has_node("AIInfoContainer/AIInfo") else null
@onready var close_btn = $CloseBtn if has_node("CloseBtn") else null

var is_visible: bool = false
var update_timer: float = 0.0

func _ready():
	_setup_styles()
	hide()

	# 连接关闭按钮
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)

func _setup_styles():
	if not damage_dealt_label:
		return  # 节点不存在，跳过设置
		
	# 设置字体大小
	var font_size_base = 24

	# 标签样式
	var stats_container = $StatsContainer if has_node("StatsContainer") else null
	if stats_container:
		for label in stats_container.get_children():
			if label is Label:
				label.add_theme_font_size_override("font_size", font_size_base)
				label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))

	# 数值样式
	damage_dealt_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3, 1))
	damage_taken_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	combo_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))

	# Boss HP条
	if boss_hp_bar:
		boss_hp_bar.add_theme_font_size_override("font_size", 20)
	if boss_hp_text:
		boss_hp_text.add_theme_font_size_override("font_size", 20)
		boss_hp_text.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 1))

	# AI信息标签
	if ai_info_label:
		ai_info_label.add_theme_font_size_override("font_size", 20)
		ai_info_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1, 1))
		ai_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# 关闭按钮
	if close_btn:
		close_btn.add_theme_font_size_override("font_size", 22)
		close_btn.custom_minimum_size = Vector2(100, 40)

func _process(delta):
	if not is_visible:
		return

	update_timer += delta
	if update_timer >= 0.1:  # 每0.1秒更新一次
		_update_display()
		update_timer = 0.0

	# 更新战斗时间
	battle_stats["battle_time"] += delta

# 显示面板
func show_panel():
	is_visible = true
	visible = true

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

# 隐藏面板
func hide_panel():
	is_visible = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): hide())

# 更新统计数据
func update_stat(key: String, value):
	if key in battle_stats:
		battle_stats[key] = value

	# 特殊处理combo
	if key == "combo_count":
		if value > battle_stats["max_combo"]:
			battle_stats["max_combo"] = value

# 增加统计值
func increment_stat(key: String, amount: int = 1):
	if key in battle_stats:
		battle_stats[key] += amount

# 更新Boss血量
func update_boss_hp(current: int, maximum: int):
	var percent = float(current) / maximum * 100
	battle_stats["boss_hp_percent"] = percent
	if boss_hp_bar:
		boss_hp_bar.value = percent
	if boss_hp_text:
		boss_hp_text.text = "Boss: %d%%" % percent

	# 根据血量改变颜色
	if boss_hp_bar:
		if percent > 60:
			boss_hp_bar.modulate = Color(0.3, 0.9, 0.3)
		elif percent > 30:
			boss_hp_bar.modulate = Color(1, 0.8, 0.2)
		else:
			boss_hp_bar.modulate = Color(1, 0.2, 0.2)

# 更新AI学习数据显示
func update_ai_info(preference: String, accuracy: float, adapted_attack: String):
	ai_learning_data["detected_preference"] = preference
	ai_learning_data["prediction_accuracy"] = accuracy
	if adapted_attack != "":
		ai_learning_data["adapted_attacks"].append(adapted_attack)
		# 只保留最近3个
		if ai_learning_data["adapted_attacks"].size() > 3:
			ai_learning_data["adapted_attacks"].pop_front()

# 更新显示
func _update_display():
	if damage_dealt_label:
		damage_dealt_label.text = str(battle_stats["damage_dealt"])
	if damage_taken_label:
		damage_taken_label.text = str(battle_stats["damage_taken"])
	if hits_label:
		hits_label.text = "%d / %d" % [battle_stats["hits_landed"], battle_stats["hits_received"]]
	if combo_label:
		combo_label.text = "%d (最大: %d)" % [battle_stats["combo_count"], battle_stats["max_combo"]]

	# 格式化时间
	var minutes = int(battle_stats["battle_time"]) / 60
	var seconds = int(battle_stats["battle_time"]) % 60
	if time_label:
		time_label.text = "%d:%02d" % [minutes, seconds]

	# 更新AI信息
	if ai_info_label:
		var ai_text = "🧠 AI分析:\n"
		if ai_learning_data["detected_preference"] != "":
			ai_text += "• 检测到: %s\n" % ai_learning_data["detected_preference"]
		if ai_learning_data["prediction_accuracy"] > 0:
			var acc_percent = int(ai_learning_data["prediction_accuracy"] * 100)
			ai_text += "• 预测精度: %d%%\n" % acc_percent
		if ai_learning_data["adapted_attacks"].size() > 0:
			ai_text += "• 适应攻击: %s" % ", ".join(ai_learning_data["adapted_attacks"])
		ai_info_label.text = ai_text

# 获取战斗总结（用于结算画面）
func get_battle_summary() -> Dictionary:
	return battle_stats.duplicate()

# 重置统计
func reset_stats():
	battle_stats = {
		"damage_dealt": 0,
		"damage_taken": 0,
		"hits_landed": 0,
		"hits_received": 0,
		"dodges": 0,
		"perfect_blocks": 0,
		"combo_count": 0,
		"max_combo": 0,
		"battle_time": 0.0,
		"boss_hp_percent": 100.0
	}
	ai_learning_data = {
		"detected_preference": "",
		"prediction_accuracy": 0,
		"adapted_attacks": []
	}

func _on_close_pressed():
	stats_closed.emit()
	hide_panel()
