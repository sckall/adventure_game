extends Node

# ============ 地图生成器 ============
# 基于种子和噪声算法的程序化地图生成系统

# 生成参数
var seed: int = 0
var map_width: int = 4000
var map_height: int = 1200

# 噪声缩放
var noise_scale: float = 0.003
var height_noise_scale: float = 0.002
var moisture_noise_scale: float = 0.004

# 地形类型
enum TerrainType {
	OCEAN,
	BEACH,
	GRASSLAND,
	FOREST,
	MOUNTAIN,
	SNOW,
	DESERT,
	GLACIER,
	VILLAGE,
	CITY,
	ISLAND
}

# 地形配置
const TERRAIN_CONFIG = {
	TerrainType.OCEAN: {
		"name": "深海",
		"min_height": -1.0,
		"max_height": -0.3,
		"color": Color(0.1, 0.3, 0.5),
		"block_color": Color(0.15, 0.25, 0.35),
		"can_walk": false
	},
	TerrainType.BEACH: {
		"name": "沙滩",
		"min_height": -0.3,
		"max_height": 0.0,
		"color": Color(0.76, 0.7, 0.5),
		"block_color": Color(0.85, 0.75, 0.55),
		"can_walk": true
	},
	TerrainType.GRASSLAND: {
		"name": "草原",
		"min_height": 0.0,
		"max_height": 0.3,
		"color": Color(0.35, 0.65, 0.25),
		"block_color": Color(0.28, 0.55, 0.25),
		"can_walk": true
	},
	TerrainType.FOREST: {
		"name": "森林",
		"min_height": 0.15,
		"max_height": 0.5,
		"min_moisture": 0.4,
		"color": Color(0.2, 0.45, 0.15),
		"block_color": Color(0.18, 0.35, 0.12),
		"can_walk": true
	},
	TerrainType.MOUNTAIN: {
		"name": "山地",
		"min_height": 0.4,
		"max_height": 0.8,
		"color": Color(0.45, 0.4, 0.35),
		"block_color": Color(0.35, 0.32, 0.28),
		"can_walk": true
	},
	TerrainType.SNOW: {
		"name": "雪原",
		"min_height": 0.6,
		"max_height": 1.0,
		"color": Color(0.9, 0.95, 1.0),
		"block_color": Color(0.85, 0.88, 0.92),
		"can_walk": true
	},
	TerrainType.DESERT: {
		"name": "沙漠",
		"min_height": 0.1,
		"max_height": 0.5,
		"min_moisture": 0.0,
		"max_moisture": 0.2,
		"color": Color(0.85, 0.7, 0.4),
		"block_color": Color(0.75, 0.6, 0.35),
		"can_walk": true
	},
	TerrainType.GLACIER: {
		"name": "冰川",
		"min_height": 0.3,
		"max_height": 0.9,
		"min_moisture": 0.0,
		"max_moisture": 0.15,
		"special": "cold_zone",
		"color": Color(0.7, 0.85, 0.95),
		"block_color": Color(0.6, 0.75, 0.85),
		"can_walk": true
	},
	TerrainType.VILLAGE: {
		"name": "村庄",
		"special": "structure",
		"color": Color(0.6, 0.5, 0.35),
		"block_color": Color(0.55, 0.45, 0.3),
		"can_walk": true
	},
	TerrainType.CITY: {
		"name": "城市",
		"special": "structure",
		"color": Color(0.4, 0.4, 0.45),
		"block_color": Color(0.35, 0.35, 0.4),
		"can_walk": true
	},
	TerrainType.ISLAND: {
		"name": "海岛",
		"special": "isolated",
		"color": Color(0.4, 0.55, 0.3),
		"block_color": Color(0.32, 0.45, 0.25),
		"can_walk": true
	}
}

# 噪声生成器
var height_noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var temperature_noise: FastNoiseLite
var detail_noise: FastNoiseLite

# 地图数据
var terrain_map: Array = []
var platform_data: Array = []
var decoration_data: Array = []
var enemy_data: Array = []
var collectible_data: Array = []

# 生成配置
var platform_density: float = 0.4
var decoration_density: float = 0.15
var enemy_density: float = 0.08
var collectible_density: float = 0.12

# 信号
signal map_generation_started
signal map_generation_progress(percent: int)
signal map_generation_complete(terrain_data: Dictionary)

# 初始化
func _ready() -> void:
	_initialize_noise_generators()

# 初始化噪声生成器
func _initialize_noise_generators() -> void:
	height_noise = FastNoiseLite.new()
	moisture_noise = FastNoiseLite.new()
	temperature_noise = FastNoiseLite.new()
	detail_noise = FastNoiseLite.new()

# 设置种子
func set_seed(new_seed: int) -> void:
	seed = new_seed
	height_noise.set_seed(seed)
	moisture_noise.set_seed(seed + 1000)
	temperature_noise.set_seed(seed + 2000)
	detail_noise.set_seed(seed + 3000)
	print("MapGenerator INFO: 地图种子设置为: " + str(seed))

# 生成完整地图
func generate_map(use_seed: int = 0) -> Dictionary:
	if use_seed != 0:
		set_seed(use_seed)
	else:
		set_seed(randi())

	map_generation_started.emit()
	print("MapGenerator INFO: 开始生成地图...")

	# 清空数据
	terrain_map.clear()
	platform_data.clear()
	decoration_data.clear()
	enemy_data.clear()
	collectible_data.clear()

	# 生成地形
	_generate_terrain()
	map_generation_progress.emit(25)

	# 生成平台
	_generate_platforms()
	map_generation_progress.emit(50)

	# 生成装饰
	_generate_decorations()
	map_generation_progress.emit(70)

	# 生成敌人和收集品
	generate_entities()
	map_generation_progress.emit(90)

	# 生成出口
	_generate_exit()
	map_generation_progress.emit(100)

	var result: Dictionary = {
		"seed": seed,
		"terrain": terrain_map,
		"platforms": platform_data,
		"decorations": decoration_data,
		"enemies": enemy_data,
		"collectibles": collectible_data,
		"map_width": map_width,
		"map_height": map_height
	}

	map_generation_complete.emit(result)
	print("MapGenerator INFO: 地图生成完成！")

	return result

# 生成地形
func _generate_terrain() -> void:
	var grid_size: int = 50
	var cols: int = ceil(float(map_width) / grid_size)
	var rows: int = ceil(float(map_height) / grid_size)

	for y in range(rows):
		var row: Array = []
		for x in range(cols):
			var world_x: float = x * grid_size
			var world_y: float = y * grid_size

			var terrain_info: Dictionary = _get_terrain_at(world_x, world_y)
			row.append(terrain_info)

			# 记录地形数据用于后续生成
			if terrain_info.can_walk:
				terrain_map.append({
					"x": world_x,
					"y": world_y,
					"width": grid_size,
					"height": grid_size,
					"type": terrain_info.type,
					"config": terrain_info.config
				})

		terrain_map.append(row)

# 获取指定位置的地形
func _get_terrain_at(x: float, y: float) -> Dictionary:
	# 获取高度值（使用分形噪声）
	var height: float = _get_fractal_noise(height_noise, x, y, height_noise_scale, 4)

	# 获取湿度值
	var moisture: float = moisture_noise.get_noise_2d(x * moisture_noise_scale, y * moisture_noise_scale)
	moisture = (moisture + 1.0) / 2.0  # 归一化到0-1

	# 获取温度值
	var temperature: float = temperature_noise.get_noise_2d(x * 0.002, y * 0.002)
	temperature = (temperature + 1.0) / 2.0

	# 根据高度、湿度、温度确定地形类型
	var terrain_type: TerrainType = _determine_terrain_type(height, moisture, temperature)

	var config: Dictionary = TERRAIN_CONFIG[terrain_type].duplicate()

	# 添加详细变化
	var detail: float = detail_noise.get_noise_2d(x * 0.01, y * 0.01)
	config["detail"] = detail
	config["height_value"] = height
	config["moisture_value"] = moisture
	config["temperature_value"] = temperature

	# 调整颜色以适应细节变化
	config["adjusted_color"] = _adjust_color_by_detail(config["color"], detail)

	return {
		"type": terrain_type,
		"config": config,
		"can_walk": config["can_walk"],
		"height": height,
		"moisture": moisture,
		"temperature": temperature
	}

# 分形噪声（多层噪声叠加）
func _get_fractal_noise(noise: FastNoiseLite, x: float, y: float, scale: float, octaves: int) -> float:
	var value: float = 0.0
	var amplitude: float = 1.0
	var frequency: float = scale
	var max_value: float = 0.0

	for i in range(octaves):
		value += noise.get_noise_2d(x * frequency, y * frequency) * amplitude
		max_value += amplitude
		amplitude *= 0.5
		frequency *= 2.0

	return value / max_value

# 根据参数确定地形类型
func _determine_terrain_type(height: float, moisture: float, temperature: float) -> TerrainType:
	# 深海
	if height < -0.3:
		return TerrainType.OCEAN

	# 沙滩
	if height < 0.0:
		return TerrainType.BEACH

	# 高山区域
	if height > 0.7:
		if temperature < 0.35:
			return TerrainType.GLACIER
		return TerrainType.SNOW

	# 中等海拔
	if height > 0.4:
		if temperature < 0.4:
			return TerrainType.SNOW
		return TerrainType.MOUNTAIN

	# 低海拔区域
	if height > 0.0:
		# 湿度决定森林还是草原
		if moisture > 0.5:
			return TerrainType.FOREST

		# 干燥区域可能是沙漠
		if moisture < 0.25 and temperature > 0.5:
			return TerrainType.DESERT

		return TerrainType.GRASSLAND

	# 特殊结构生成点（基于噪声峰值）
	var structure_noise: float = detail_noise.get_noise_2d(height * 3.0, moisture * 3.0)
	if structure_noise > 0.7:
		if moisture > 0.6 and height > 0.2:
			return TerrainType.VILLAGE
		if height > 0.3 and temperature > 0.4:
			return TerrainType.CITY

	# 海岛检测（被水域包围的小块陆地）
	var island_noise: float = height_noise.get_noise_2d(0, 0)  # 使用全局噪声
	if island_noise > 0.5 and height > 0.1 and height < 0.3:
		return TerrainType.ISLAND

	return TerrainType.GRASSLAND

# 根据细节调整颜色
func _adjust_color_by_detail(base_color: Color, detail: float) -> Color:
	var adjustment: float = detail * 0.15
	return Color(
		clampf(base_color.r + adjustment, 0.0, 1.0),
		clampf(base_color.g + adjustment, 0.0, 1.0),
		clampf(base_color.b + adjustment, 0.0, 1.0),
		base_color.a
	)

# 生成平台
func _generate_platforms() -> void:
	for terrain_info in terrain_map:
		if not terrain_info.can_walk:
			continue

		var x: float = terrain_info.x
		var y: float = terrain_info.y
		var width: float = terrain_info.width
		var config: Dictionary = terrain_info.config

		# 基于地形类型决定平台生成
		match terrain_info.type:
			TerrainType.OCEAN:
				continue  # 不在海洋生成平台
			TerrainType.GRASSLAND, TerrainType.FOREST:
				_generate_natural_platforms(x, y, width, config)
			TerrainType.MOUNTAIN, TerrainType.SNOW:
				_generate_mountain_platforms(x, y, width, config)
			TerrainType.DESERT:
				_generate_desert_platforms(x, y, width, config)
			TerrainType.GLACIER:
				_generate_glacier_platforms(x, y, width, config)
			TerrainType.VILLAGE:
				_generate_village_platforms(x, y, width, config)
			TerrainType.CITY:
				_generate_city_platforms(x, y, width, config)
			TerrainType.ISLAND:
				_generate_island_platforms(x, y, width, config)

# 生成自然地形平台
func _generate_natural_platforms(x: float, y: float, width: float, config: Dictionary) -> void:
	var platform_chance: float = randf()

	if platform_chance > platform_density:
		return

	# 创建主平台
	var platform_height: float = _get_platform_height_from_noise(x, y)
	var platform_y: float = y - platform_height

	platform_data.append({
		"x": x + width * 0.1,
		"y": platform_y,
		"width": width * 0.8,
		"height": 20,
		"color": config["block_color"],
		"type": "standard"
	})

	# 森林中可能生成额外的树平台
	if config["name"] == "森林" and randf() < 0.3:
		platform_data.append({
			"x": x + width * 0.6,
			"y": platform_y - 80,
			"width": 40,
			"height": 15,
			"color": Color(0.25, 0.4, 0.15),
			"type": "tree_platform"
		})

# 生成山地平台
func _generate_mountain_platforms(x: float, y: float, width: float, config: Dictionary) -> void:
	if randf() > platform_density * 1.2:
		return

	# 多层平台
	var layers: int = randi_range(1, 3)
	for i in range(layers):
		var layer_y: float = y - i * 70 - 40
		var layer_width: float = width * (0.9 - i * 0.15)

		platform_data.append({
			"x": x + (width - layer_width) / 2,
			"y": layer_y,
			"width": layer_width,
			"height": 18,
			"color": config["block_color"],
			"type": "mountain_layer"
		})

# 生成沙漠平台
func _generate_desert_platforms(x: float, y: float, width: float, config: Dictionary) -> void:
	if randf() > platform_density * 0.8:
		return

	# 沙漠有较低的平顶平台
	platform_data.append({
		"x": x + width * 0.2,
		"y": y - 30,
		"width": width * 0.6,
		"height": 15,
		"color": config["block_color"],
		"type": "desert_flat"
	})

	# 添加仙人掌装饰平台
	if randf() < 0.2:
		platform_data.append({
			"x": x + width * 0.7,
			"y": y - 80,
			"width": 25,
			"height": 12,
			"color": Color(0.65, 0.55, 0.3),
			"type": "cactus_platform"
		})

# 生成冰川平台
func _generate_glacier_platforms(x: float, y: float, width: float, config: Dictionary) -> void:
	if randf() > platform_density * 0.9:
		return

	# 冰川有光滑的斜坡平台
	var slope: float = randf_range(-10, 10)
	platform_data.append({
		"x": x + width * 0.1,
		"y": y - 20 + slope,
		"width": width * 0.8,
		"height": 16,
		"color": config["block_color"],
		"type": "ice_slope",
		"slippery": true
	})

# 生成村庄平台
func _generate_village_platforms(x: float, y: float, width: float, config: Dictionary) -> void:
	# 村庄总是有多个小平台
	var house_count: int = randi_range(2, 4)

	for i in range(house_count):
		var house_x: float = x + (width / house_count) * i + 20
		var house_y: float = y - 50 - i * 10

		platform_data.append({
			"x": house_x,
			"y": house_y,
			"width": 60,
			"height": 20,
			"color": Color(0.55, 0.45, 0.3),
			"type": "house_platform"
		})

# 生成城市平台
func _generate_city_platforms(x: float, y: float, width: float, config: Dictionary) -> void:
	# 城市有规则的建筑布局
	var building_count: int = 3
	var building_width: float = width / building_count

	for i in range(building_count):
		var building_height: float = 40 + i * 30

		platform_data.append({
			"x": x + building_width * i + 10,
			"y": y - building_height,
			"width": building_width - 20,
			"height": 15,
			"color": Color(0.38, 0.38, 0.42),
			"type": "building_platform"
		})

# 生成海岛平台
func _generate_island_platforms(x: float, y: float, width: float, config: Dictionary) -> void:
	# 海岛中心有主平台
	platform_data.append({
		"x": x + width * 0.3,
		"y": y - 25,
		"width": width * 0.4,
		"height": 18,
		"color": config["block_color"],
		"type": "island_main"
	})

# 从噪声获取平台高度
func _get_platform_height_from_noise(x: float, y: float) -> float:
	var height_noise: float = detail_noise.get_noise_2d(x * 0.005, y * 0.005)
	return (height_noise + 1.0) * 100  # 0-200范围

# 生成装饰
func _generate_decorations() -> void:
	for terrain_info in terrain_map:
		if not terrain_info.can_walk:
			continue

		var x: float = terrain_info.x
		var y: float = terrain_info.y
		var config: Dictionary = terrain_info.config

		# 基于地形生成装饰
		_generate_terrain_decorations(x, y, config)

# 生成地形装饰
func _generate_terrain_decorations(x: float, y: float, config: Dictionary) -> void:
	var decoration_count: int = 0
	var base_y: float = y - 50

	match config["name"]:
		"森林":
			decoration_count = randi_range(2, 5)
			for i in range(decoration_count):
				decoration_data.append({
					"type": "tree",
					"x": x + randf() * 30,
					"y": base_y - randf() * 30,
					"color": Color(0.15, 0.35, 0.1)
				})
		"沙漠":
			if randf() < 0.3:
				decoration_data.append({
					"type": "cactus",
					"x": x + randf() * 40,
					"y": base_y,
					"color": Color(0.5, 0.4, 0.2)
				})
		"雪原", "冰川":
			decoration_count = randi_range(1, 3)
			for i in range(decoration_count):
				decoration_data.append({
					"type": "snow_rock",
					"x": x + randf() * 35,
					"y": base_y - randf() * 20,
					"color": Color(0.85, 0.9, 0.95)
				})
		"村庄":
			decoration_data.append({
				"type": "well",
				"x": x + 20,
				"y": base_y - 20,
				"color": Color(0.4, 0.35, 0.25)
			})
		"城市":
			decoration_data.append({
				"type": "streetlamp",
				"x": x + 10,
				"y": base_y - 40,
				"color": Color(0.9, 0.85, 0.6)
			})
		"海岛":
			if randf() < 0.5:
				decoration_data.append({
					"type": "palm",
					"x": x + randf() * 40,
					"y": base_y - 10,
					"color": Color(0.35, 0.5, 0.2)
				})
		"草原":
			if randf() < 0.2:
				decoration_data.append({
					"type": "rock",
					"x": x + randf() * 45,
					"y": base_y,
					"color": Color(0.5, 0.45, 0.4)
				})

# 生成实体（敌人和收集品）
func generate_entities() -> void:
	for platform in platform_data:
		# 生成敌人
		if randf() < enemy_density:
			_generate_enemy_at_platform(platform)

		# 生成收集品
		if randf() < collectible_density:
			_generate_collectible_at_platform(platform)

# 在平台生成敌人
func _generate_enemy_at_platform(platform: Dictionary) -> void:
	var enemy_types: Array = ["slime"]
	var platform_x: float = platform["x"] + platform["width"] / 2
	var platform_y: float = platform["y"]

	# 根据地形调整敌人类型
	match platform["type"]:
		"forest", "mountain_layer":
			enemy_types.append_array(["bat", "skeleton"])
		"desert_flat":
			enemy_types = ["slime", "hedgehog"]
		"ice_slope":
			enemy_types = ["snail", "slime"]

	var enemy_type: String = enemy_types.pick_random()
	var colors: Array = _get_enemy_colors_for_terrain(platform["type"])
	var color_name: String = colors.pick_random()

	enemy_data.append({
		"type": enemy_type,
		"x": platform_x,
		"y": platform_y - 20,
		"color_name": color_name,
		"patrol": platform["width"] * 0.6
	})

# 获取地形对应的敌人颜色
func _get_enemy_colors_for_terrain(platform_type: String) -> Array:
	match platform_type:
		"ice_slope", "glacier":
			return ["cyan", "gray", "blue"]
		"desert_flat":
			return ["yellow", "orange", "red"]
		"forest", "tree_platform":
			return ["green", "pink", "purple"]
		_:
			return ["green", "blue", "yellow", "pink"]

# 在平台生成收集品
func _generate_collectible_at_platform(platform: Dictionary) -> void:
	var platform_x: float = platform["x"] + platform["width"] / 2
	var platform_y: float = platform["y"] - 30
	var collectible_type: String = "bottle" if randf() < 0.6 else "mushroom"
	var colors: Array = ["green", "yellow", "red", "blue", "purple"]

	if collectible_type == "mushroom":
		colors = ["red", "blue", "green", "brown", "purple"]

	collectible_data.append({
		"type": collectible_type,
		"x": platform_x + randf_range(-20, 20),
		"y": platform_y + randf_range(-10, 10),
		"color": colors.pick_random()
	})

# 生成出口
func _generate_exit() -> void:
	if platform_data.is_empty():
		return

	# 找到最后生成的平台
	var last_platform: Dictionary = platform_data.back()

	var exit_x: float = last_platform["x"] + last_platform["width"] + 100
	var exit_y: float = last_platform["y"] - 20

	platform_data.append({
		"is_exit": true,
		"x": exit_x,
		"y": exit_y,
		"width": 60,
		"height": 60,
		"color": Color(1.0, 0.85, 0.2),
		"type": "exit"
	})

# 获取地图统计信息
func get_map_statistics() -> Dictionary:
	var terrain_counts: Dictionary = {}
	for key in TERRAIN_CONFIG:
		terrain_counts[key] = 0

	for terrain_info in terrain_map:
		if terrain_info.has("type"):
			var type = terrain_info["type"]
			terrain_counts[type] = terrain_counts.get(type, 0) + 1

	return {
		"total_terrain_blocks": terrain_map.size(),
		"total_platforms": platform_data.size(),
		"total_decorations": decoration_data.size(),
		"total_enemies": enemy_data.size(),
		"total_collectibles": collectible_data.size(),
		"terrain_distribution": terrain_counts
	}

# 导出地图为JSON
func export_map_to_json(path: String) -> void:
	var map_data: Dictionary = {
		"seed": seed,
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"terrain": terrain_map,
		"platforms": platform_data,
		"decorations": decoration_data,
		"enemies": enemy_data,
		"collectibles": collectible_data
	}

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(map_data))
		file.close()
		print("MapGenerator INFO: 地图已导出到: " + path)

# 从JSON导入地图
func import_map_from_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("MapGenerator ERROR: 无法打开地图文件: " + path)
		return {}

	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var error: int = json.parse(json_string)
	if error != OK:
		print("MapGenerator ERROR: 地图文件解析失败")
		return {}

	var map_data: Dictionary = json.data
	if map_data.has("seed"):
		set_seed(map_data["seed"])

	terrain_map = map_data.get("terrain", [])
	platform_data = map_data.get("platforms", [])
	decoration_data = map_data.get("decorations", [])
	enemy_data = map_data.get("enemies", [])
	collectible_data = map_data.get("collectibles", [])

	print("MapGenerator INFO: 地图已从文件导入")
	return map_data

# 获取可视化调试数据
func get_debug_visualization_data() -> Dictionary:
	var blocks: Array = []
	var colors: Array = []

	for terrain_info in terrain_map:
		blocks.append({
			"position": Vector2(terrain_info.x, terrain_info.y),
			"size": Vector2(terrain_info.width, terrain_info.height)
		})
		colors.append(terrain_info.config["color"])

	return {
		"blocks": blocks,
		"colors": colors
	}
