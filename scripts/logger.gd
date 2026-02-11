extends Node

# ============ 日志系统 ============
# 提供统一的日志记录和错误处理

# 日志级别
enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3,
	FATAL = 4
}

# 当前日志级别（设置低于此级别的日志不会显示）
var current_log_level: LogLevel = LogLevel.DEBUG

# 日志历史（用于调试）
var _log_history: Array[Dictionary] = []
const MAX_LOG_HISTORY: int = 500

# 日志文件路径
var _log_file_path: String = ""
var _file_logging_enabled: bool = true

# 错误统计
var _error_count: int = 0
var _warning_count: int = 0

# 日志信号
signal log_logged(level: LogLevel, category: String, message: String, timestamp: float)

# 初始化
func _ready() -> void:
	# 设置日志文件路径
	_log_file_path = "user://logs/game_%s.log" % _get_timestamp_string()
	_ensure_log_directory()

	# 记录初始化
	info("Logger", "日志系统初始化完成")
	info("Logger", "日志文件: %s" % _log_file_path)

# 获取时间戳字符串
func _get_timestamp_string() -> String:
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d%02d%02d_%02d%02d%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]

# 确保日志目录存在
func _ensure_log_directory() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir:
		dir.make_dir("logs")

# 格式化日志消息
func _format_log_message(level: LogLevel, category: String, message: String) -> String:
	var level_name: String = LogLevel.keys()[level]
	var time: String = Time.get_time_string_from_system()
	return "[%s] [%s] [%s] %s" % [time, level_name, category, message]

# 写入日志到文件
func _write_to_file(message: String) -> void:
	if not _file_logging_enabled:
		return

	var file: FileAccess = FileAccess.open(_log_file_path, FileAccess.WRITE)
	if file:
		file.seek_end()
		file.store_line(message)
		file.close()

# 添加到历史记录
func _add_to_history(level: LogLevel, category: String, message: String) -> void:
	var entry: Dictionary = {
		"level": level,
		"category": category,
		"message": message,
		"timestamp": Time.get_unix_time_from_system()
	}

	_log_history.append(entry)

	# 保持历史记录在限制内
	if _log_history.size() > MAX_LOG_HISTORY:
		_log_history.pop_front()

# 核心日志函数
func _log(level: LogLevel, category: String, message: String) -> void:
	# 检查日志级别
	if level < current_log_level:
		return

	# 统计错误和警告
	if level >= LogLevel.ERROR:
		_error_count += 1
	elif level >= LogLevel.WARNING:
		_warning_count += 1

	# 格式化消息
	var formatted: String = _format_log_message(level, category, message)

	# 打印到控制台
	match level:
		LogLevel.DEBUG, LogLevel.INFO:
			print(formatted)
		LogLevel.WARNING:
			print_rich("[color=yellow]%s[/color]" % formatted)
		LogLevel.ERROR, LogLevel.FATAL:
			print_rich("[color=red]%s[/color]" % formatted)
			push_error(formatted)

	# 写入文件
	_write_to_file(formatted)

	# 添加到历史
	_add_to_history(level, category, message)

	# 发射信号
	log_logged.emit(level, category, message, Time.get_unix_time_from_system())

# ============ 公共日志方法 ============

# 调试级别日志
func debug(category: String, message: String) -> void:
	_log(LogLevel.DEBUG, category, message)

# 信息级别日志
func info(category: String, message: String) -> void:
	_log(LogLevel.INFO, category, message)

# 警告级别日志
func warning(category: String, message: String) -> void:
	_log(LogLevel.WARNING, category, message)

# 错误级别日志
func error(category: String, message: String) -> void:
	_log(LogLevel.ERROR, category, message)

# 致命错误级别日志
func fatal(category: String, message: String) -> void:
	_log(LogLevel.FATAL, category, message)

# ============ 断言方法 ============

# 断言条件为真
func assert_true(condition: bool, category: String, message: String) -> void:
	if not condition:
		error(category, "断言失败: " + message)

# 断言条件为假
func assert_false(condition: bool, category: String, message: String) -> void:
	if condition:
		error(category, "断言失败: " + message)

# 断言对象有效
func assert_valid(obj: Variant, category: String, object_name: String = "对象") -> void:
	if obj == null:
		error(category, "%s 为 null" % object_name)
	elif obj is Object and not is_instance_valid(obj):
		error(category, "%s 无效" % object_name)

# ============ 工具方法 ============

# 设置日志级别
func set_log_level(level: LogLevel) -> void:
	current_log_level = level
	info("Logger", "日志级别设置为: %s" % LogLevel.keys()[level])

# 启用/禁用文件日志
func set_file_logging(enabled: bool) -> void:
	_file_logging_enabled = enabled
	info("Logger", "文件日志 %s" % ("已启用" if enabled else "已禁用"))

# 获取日志历史
func get_log_history() -> Array[Dictionary]:
	return _log_history.duplicate()

# 清除日志历史
func clear_history() -> void:
	_log_history.clear()
	info("Logger", "日志历史已清除")

# 获取统计信息
func get_stats() -> Dictionary:
	return {
		"error_count": _error_count,
		"warning_count": _warning_count,
		"history_size": _log_history.size(),
		"log_level": LogLevel.keys()[current_log_level],
		"file_logging": _file_logging_enabled
	}

# 导出日志到文件
func export_logs(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		error("Logger", "无法创建日志导出文件: %s" % path)
		return

	for entry: Dictionary in _log_history:
		var level_name: String = LogLevel.keys()[entry.level]
		var datetime: Dictionary = Time.get_datetime_dict_from_unix_time(entry.timestamp)
		var timestamp: String = "%04d-%02d-%02d %02d:%02d:%02d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute, datetime.second
		]
		file.store_line("[%s] [%s] [%s] %s" % [timestamp, level_name, entry.category, entry.message])

	file.close()
	info("Logger", "日志已导出到: %s" % path)

# 重置统计
func reset_stats() -> void:
	_error_count = 0
	_warning_count = 0
	info("Logger", "统计信息已重置")

