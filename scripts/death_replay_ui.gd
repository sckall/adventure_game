extends Control
class_name DeathReplayUI

# ============ 死亡回放UI ============
# 显示死亡回放界面

signal replay_finished()
signal retry_requested()

@onready var title_label = $VBoxContainer/Title
@onready var stats_label = $VBoxContainer/Stats
@onready var replay_btn = $VBoxContainer/Buttons/ReplayBtn
@onready var retry_btn = $VBoxContainer/Buttons/RetryBtn
@onready var skip_btn = $VBoxContainer/Buttons/SkipBtn
@onready var progress_bar = $VBoxContainer/ProgressContainer/ProgressBar
@onready var progress_label = $VBoxContainer/ProgressContainer/ProgressLabel

var replay_system: DeathReplaySystem
var replay_data: Dictionary

func _ready():
	_setup_styles()
	hide()

func _setup_styles():
	# 标题样式
	title_label.add_theme_font_size_override("font_size", 56)
	title_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))

	# 统计标签样式
	stats_label.add_theme_font_size_override("font_size", 24)
	stats_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))

	# 按钮样式
	var btn_size = Vector2(150, 50)
	replay_btn.custom_minimum_size = btn_size
	retry_btn.custom_minimum_size = btn_size
	skip_btn.custom_minimum_size = btn_size

	for btn in [replay_btn, retry_btn, skip_btn]:
		btn.add_theme_font_size_override("font_size", 24)

	# 进度条样式
	progress_bar.add_theme_font_size_override("font_size", 20)
	progress_label.add_theme_font_size_override("font_size", 20)
	progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))

func _process(delta):
	if replay_system and replay_system.is_replaying:
		progress_bar.value = replay_system.get_replay_progress() * 100
		var current_sec = int(replay_system.get_replay_progress() * replay_data.get("duration", 0))
		var total_sec = int(replay_data.get("duration", 0))
		progress_label.text = "%d:%02d / %d:%02d" % [
			current_sec / 60, current_sec % 60,
			total_sec / 60, total_sec % 60
		]

# 显示死亡回放界面
func show_death_replay(system: DeathReplaySystem, data: Dictionary):
	replay_system = system
	replay_data = data

	# 更新统计信息
	var analysis = system.analyze_replay(data)
	stats_label.text = """
	死亡分析:
	• 平均与Boss距离: %.0f
	• 危险时间占比: %.1f%%
	• Boss攻击次数: %d
	""" % [
		analysis.get("avg_distance", 0),
		analysis.get("time_in_danger", 0),
		analysis.get("total_attacks", 0)
	]

	# 淡入显示
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

	# 连接信号
	replay_system.replay_finished.connect(_on_replay_system_finished)

	# 开始回放
	await get_tree().create_timer(1.0).timeout
	replay_system.start_replay(data, _get_player(), _get_boss())

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")

func _get_boss() -> Node2D:
	var bosses = get_tree().get_nodes_in_group("boss")
	return bosses[0] if bosses.size() > 0 else null

func _on_replay_pressed():
	if replay_system and replay_data:
		replay_system.start_replay(replay_data, _get_player(), _get_boss())
		hide()

func _on_retry_pressed():
	replay_finished.emit()
	retry_requested.emit()
	hide()

func _on_skip_pressed():
	if replay_system:
		replay_system.stop_replay()
	replay_finished.emit()
	hide()

func _on_replay_system_finished():
	# 回放结束，显示按钮
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	visible = true

func _on_replay_btn_pressed():
	_on_replay_pressed()
	hide()

func _on_retry_btn_pressed():
	_on_retry_pressed()

func _on_skip_btn_pressed():
	_on_skip_pressed()
