extends Node

# ============ 资源管理器 ============
# 用于预加载和管理游戏资源

# 预加载的场景
var _scenes: Dictionary = {}

# 预加载的纹理
var _textures: Dictionary = {}

# 预加载的音频
var _audio_streams: Dictionary = {}

# 资源配置路径
const SCENE_PATHS: Dictionary = {
	"slime": "res://scenes/slime.tscn",
	"bat": "res://scenes/bat.tscn",
	"skeleton": "res://scenes/skeleton.tscn",
	"hedgehog": "res://scenes/hedgehog.tscn",
	"snail": "res://scenes/snail.tscn",
	"spider": "res://scenes/spider.tscn",
	"snake": "res://scenes/snake.tscn",
	"ai_boss": "res://scenes/ai_boss.tscn",
	"main_menu": "res://scenes/main_menu.tscn",
	"main": "res://scenes/main.tscn"
}

# 加载状态
var _loading: bool = false
var _loaded_count: int = 0
var _total_count: int = 0

# 加载进度信号
signal resource_loading_progress(percent: int)
signal resource_loading_finished

# 初始化并预加载资源
func _ready() -> void:
	preload_all_resources()

# 预加载所有资源
func preload_all_resources() -> void:
	_loading = true
	_loaded_count = 0
	_total_count = SCENE_PATHS.size()

	print("ResourceManager INFO: 开始预加载资源...")

	# 预加载场景
	for scene_name: String in SCENE_PATHS:
		_preload_scene(scene_name, SCENE_PATHS[scene_name])

	_loading = false
	resource_loading_finished.emit()
	print("ResourceManager INFO: 资源预加载完成！")

# 预加载单个场景
func _preload_scene(name: String, path: String) -> void:
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource:
			_scenes[name] = resource
			_loaded_count += 1
			var progress: int = int(float(_loaded_count) / _total_count * 100)
			resource_loading_progress.emit(progress)
			print("ResourceManager DEBUG: 预加载场景: %s" % name)
		else:
			print("ResourceManager WARNING: 无法加载场景: %s" % path)
	else:
		print("ResourceManager ERROR: 场景文件不存在: %s" % path)

# 获取预加载的场景
func get_scene(name: String) -> PackedScene:
	if _scenes.has(name):
		return _scenes[name]
	print("ResourceManager WARNING: 场景未预加载: %s，尝试立即加载" % name)
	if SCENE_PATHS.has(name):
		var scene = load(SCENE_PATHS[name])
		if scene:
			_scenes[name] = scene
		return scene
	return null

# 实例化预加载的场景
func instantiate_scene(name: String) -> Node:
	var scene: PackedScene = get_scene(name)
	if scene:
		return scene.instantiate()
	print("ResourceManager ERROR: 无法实例化场景: %s" % name)
	return null

# 异步加载资源
func load_resource_async(path: String, type: Resource = null) -> void:
	if not ResourceLoader.exists(path):
		print("ResourceManager ERROR: 资源不存在: %s" % path)
		return

	# 简化：直接同步加载
	var res = load(path)
	if res:
		var ext: String = path.get_extension().to_lower()
		match ext:
			"tscn", "scn":
				_scenes[path.get_file().get_basename()] = res
			"png", "jpg", "jpeg", "webp":
				_textures[path.get_file()] = res
			"ogg", "mp3", "wav":
				_audio_streams[path.get_file()] = res
		resource_loading_progress.emit(100)
	else:
		print("ResourceManager ERROR: 无法加载资源: %s" % path)

# 释放未使用的资源
func unload_unused_resources() -> void:
	# 清理纹理
	for key: String in _textures:
		if _textures[key].get_reference_count() <= 1:
			_textures.erase(key)

	print("ResourceManager INFO: 已释放未使用的资源")

# 获取资源统计信息
func get_stats() -> Dictionary:
	return {
		"scenes_loaded": _scenes.size(),
		"textures_loaded": _textures.size(),
		"audio_loaded": _audio_streams.size(),
		"loading": _loading,
		"progress": int(float(_loaded_count) / max(1, _total_count) * 100)
	}

# 检查资源是否已加载
func is_scene_loaded(name: String) -> bool:
	return _scenes.has(name)

# 强制重新加载资源
func reload_resource(name: String) -> bool:
	if SCENE_PATHS.has(name):
		_preload_scene(name, SCENE_PATHS[name])
		return _scenes.has(name)
	return false
