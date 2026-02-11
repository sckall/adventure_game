extends Node

# 环境管理器 - 基于系统时间的动态背景色
# 实现黎明、白天、中午、傍晚、黑夜的颜色渐变

signal time_period_changed(period_name: String)
signal background_color_updated(color: Color)

# 时间段定义
enum TimePeriod {
	DAWN,       # 黎明 (5:00 - 7:00)
	MORNING,    # 早晨 (7:00 - 10:00)
	NOON,       # 中午 (10:00 - 15:00)
	AFTERNOON,  # 下午 (15:00 - 18:00)
	DUSK,       # 傍晚 (18:00 - 20:00)
	NIGHT       # 黑夜 (20:00 - 5:00)
}

# 各时间段的颜色定义
var period_colors = {
	TimePeriod.DAWN: Color(0.4, 0.35, 0.5),       # 紫蓝色黎明
	TimePeriod.MORNING: Color(0.5, 0.6, 0.75),    # 清新的蓝绿色早晨
	TimePeriod.NOON: Color(0.6, 0.75, 0.85),      # 明亮的天空蓝中午
	TimePeriod.AFTERNOON: Color(0.7, 0.65, 0.5),  # 温暖的橙黄色下午
	TimePeriod.DUSK: Color(0.5, 0.3, 0.4),        # 紫红色傍晚
	TimePeriod.NIGHT: Color(0.08, 0.1, 0.15)      # 深蓝色黑夜
}

# 时间段名称
var period_names = {
	TimePeriod.DAWN: "黎明",
	TimePeriod.MORNING: "早晨",
	TimePeriod.NOON: "中午",
	TimePeriod.AFTERNOON: "下午",
	TimePeriod.DUSK: "傍晚",
	TimePeriod.NIGHT: "黑夜"
}

# 当前状态
var current_period: TimePeriod = TimePeriod.MORNING
var current_color: Color = period_colors[TimePeriod.MORNING]
var target_color: Color = period_colors[TimePeriod.MORNING]
var transition_speed: float = 0.02  # 颜色过渡速度

# 是否启用实时时间（false 时使用加速的游戏时间）
var use_real_time: bool = true

# 游戏时间偏移（分钟）- 用于测试不同时间
var time_offset_minutes: int = 0

# 游戏时间倍速（仅当 use_real_time = false 时有效）
var game_time_speed: float = 1.0

# 当前游戏时间（累计分钟）
var game_time_minutes: float = 0.0

func _ready():
	# 初始化时间
	update_time_period()

func _process(delta):
	if use_real_time:
		# 使用系统时间
		update_time_period()
	else:
		# 使用游戏时间
		game_time_minutes += delta * game_time_speed
		update_time_period_from_game_time()

	# 平滑过渡颜色
	smooth_color_transition(delta)

# 获取当前系统时间的小时和分钟
func get_current_time() -> Dictionary:
	var datetime = Time.get_datetime_dict_from_system()
	var hour = datetime.hour
	var minute = datetime.minute

	# 应用时间偏移
	var total_minutes = hour * 60 + minute + time_offset_minutes
	total_minutes = (total_minutes + 24 * 60) % (24 * 60)  # 确保在0-24小时范围内

	return {
		"hour": total_minutes / 60,
		"minute": total_minutes % 60
	}

# 根据时间确定当前时间段
func update_time_period():
	var time = get_current_time()
	var hour = time["hour"]
	var minute = time["minute"]
	var time_value = hour + minute / 60.0

	var new_period: TimePeriod

	# 判断时间段
	if time_value >= 5.0 and time_value < 7.0:
		new_period = TimePeriod.DAWN
	elif time_value >= 7.0 and time_value < 10.0:
		new_period = TimePeriod.MORNING
	elif time_value >= 10.0 and time_value < 15.0:
		new_period = TimePeriod.NOON
	elif time_value >= 15.0 and time_value < 18.0:
		new_period = TimePeriod.AFTERNOON
	elif time_value >= 18.0 and time_value < 20.0:
		new_period = TimePeriod.DUSK
	else:
		new_period = TimePeriod.NIGHT

	# 如果时间段改变，发出信号
	if new_period != current_period:
		current_period = new_period
		time_period_changed.emit(period_names[current_period])

	# 设置目标颜色
	target_color = period_colors[current_period]

# 从游戏时间更新时间段
func update_time_period_from_game_time():
	var day_minutes = 24 * 60
	var current_day_time = game_time_minutes % day_minutes
	var hour = current_day_time / 60
	var time_value = hour + (current_day_time % 60) / 60.0

	var new_period: TimePeriod

	if time_value >= 5.0 and time_value < 7.0:
		new_period = TimePeriod.DAWN
	elif time_value >= 7.0 and time_value < 10.0:
		new_period = TimePeriod.MORNING
	elif time_value >= 10.0 and time_value < 15.0:
		new_period = TimePeriod.NOON
	elif time_value >= 15.0 and time_value < 18.0:
		new_period = TimePeriod.AFTERNOON
	elif time_value >= 18.0 and time_value < 20.0:
		new_period = TimePeriod.DUSK
	else:
		new_period = TimePeriod.NIGHT

	if new_period != current_period:
		current_period = new_period
		time_period_changed.emit(period_names[current_period])

	target_color = period_colors[current_period]

# 平滑颜色过渡
func smooth_color_transition(delta):
	var color_diff = target_color - current_color
	var magnitude = sqrt(color_diff.r * color_diff.r + color_diff.g * color_diff.g + color_diff.b * color_diff.b)

	if magnitude > 0.001:
		current_color = current_color.lerp(target_color, transition_speed)
		background_color_updated.emit(current_color)

# 获取当前背景色
func get_background_color() -> Color:
	return current_color

# 获取当前时间段名称
func get_period_name() -> String:
	return period_names[current_period]

# 设置时间偏移（用于测试）
func set_time_offset(minutes: int):
	time_offset_minutes = minutes
	update_time_period()

# 设置是否使用实时时间
func set_use_real_time(use_real: bool):
	use_real_time = use_real
	if not use_real:
		# 初始化游戏时间为当前时间
		var time = get_current_time()
		game_time_minutes = time["hour"] * 60 + time["minute"]

# 设置游戏时间速度
func set_game_time_speed(speed: float):
	game_time_speed = speed

# 获取当前时间字符串
func get_time_string() -> String:
	if use_real_time:
		var time = get_current_time()
		return "%02d:%02d" % [time["hour"], time["minute"]]
	else:
		var day_minutes = int(game_time_minutes) % (24 * 60)
		return "%02d:%02d" % [day_minutes / 60, day_minutes % 60]

# ============ 测试/调试函数 ============
# 快捷切换到不同时间段（用于测试）

func set_dawn():
	set_time_offset(5 * 60)  # 5:00

func set_morning():
	set_time_offset(8 * 60)  # 8:00

func set_noon():
	set_time_offset(12 * 60)  # 12:00

func set_afternoon():
	set_time_offset(16 * 60)  # 16:00

func set_dusk():
	set_time_offset(19 * 60)  # 19:00

func set_night():
	set_time_offset(22 * 60)  # 22:00

# 启用快速时间模式（用于测试时间流逝）
func enable_fast_time(speed: float = 60.0):
	"""speed: 时间倍速，默认60倍即1分钟=1小时"""
	set_use_real_time(false)
	set_game_time_speed(speed)

# 恢复实时时间模式
func enable_real_time():
	set_use_real_time(true)
