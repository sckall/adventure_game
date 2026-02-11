extends Node

# ============ 游戏状态管理 ============
enum GameState { MENU, PLAYING, DIALOGUE, PAUSED, VICTORY }

# 当前状态
var current_state: GameState = GameState.MENU

# 玩家数据
var total_bottles_green: int = 0
var total_bottles_yellow: int = 0
var total_mushrooms: int = 0
var unlocked_levels: int = 1
var max_unlocked_level: int = 1
var selected_character: String = "warrior"  # 当前选中的角色

# ============ 商店升级系统 ============
# 升级等级
var hp_upgrade_level: int = 0
var speed_upgrade_level: int = 0
var jump_upgrade_level: int = 0
var damage_upgrade_level: int = 0

# 升级价格 (蘑菇数量)
var upgrade_prices: Dictionary = {
	"hp": [0, 50, 100, 200, 400, 800],      # HP升级价格
	"speed": [0, 40, 80, 160, 320, 640],   # 速度升级价格
	"jump": [0, 40, 80, 160, 320, 640],   # 跳跃升级价格
	"damage": [0, 60, 120, 240, 480, 960]  # 攻击升级价格
}

# 升级效果
var upgrade_effects: Dictionary = {
	"hp": [0, 1, 2, 3, 4, 5],           # HP增加量
	"speed": [0, 10, 20, 30, 40, 50],     # 速度增加量
	"jump": [0, 30, 60, 90, 120, 150],    # 跳跃力增加量
	"damage": [0, 0.5, 1, 1.5, 2, 2.5]   # 伤害增加量
}

func get_upgrade_price(upgrade_type: String) -> int:
	var level: int = get_upgrade_level(upgrade_type)
	if level >= 5:
		return -1  # 已满级
	return upgrade_prices[upgrade_type][level + 1]

func get_upgrade_level(upgrade_type: String) -> int:
	match upgrade_type:
		"hp": return hp_upgrade_level
		"speed": return speed_upgrade_level
		"jump": return jump_upgrade_level
		"damage": return damage_upgrade_level
	return 0

func can_afford_upgrade(upgrade_type: String) -> bool:
	var price: int = get_upgrade_price(upgrade_type)
	return price >= 0 and total_mushrooms >= price

func purchase_upgrade(upgrade_type: String) -> bool:
	if not can_afford_upgrade(upgrade_type):
		return false

	var price: int = get_upgrade_price(upgrade_type)
	total_mushrooms -= price

	match upgrade_type:
		"hp": hp_upgrade_level += 1
		"speed": speed_upgrade_level += 1
		"jump": jump_upgrade_level += 1
		"damage": damage_upgrade_level += 1

	save_game()
	return true

func get_upgrade_bonus(upgrade_type: String) -> float:
	var level: int = get_upgrade_level(upgrade_type)
	return upgrade_effects[upgrade_type][level]

# 角色定义
var characters: Dictionary = {
	"warrior": {
		"name": "战士",
		"color": Color(0.8, 0.3, 0.3),
		"description": "近战专家，拥有二段跳和震地猛击",
		"skills": ["double_jump", "ground_slam"],
		"speed": 280,
		"jump_force": -700,
		"hp": 3
	},
	"assassin": {
		"name": "刺客",
		"color": Color(0.3, 0.3, 0.4),
		"description": "敏捷型，可以爬墙、冲刺和背刺",
		"skills": ["wall_climb", "dash", "backstab"],
		"speed": 320,
		"jump_force": -680,
		"hp": 2
	},
	"mage": {
		"name": "法师",
		"color": Color(0.3, 0.4, 0.9),
		"description": "魔法型，可以浮空、发射火球和冰冻术",
		"skills": ["float", "fireball", "ice_spike"],
		"speed": 250,
		"jump_force": -650,
		"hp": 1
	},
	"priest": {
		"name": "牧师",
		"color": Color(0.9, 0.9, 0.5),
		"description": "辅助型，可以治疗、护盾和圣光护盾",
		"skills": ["heal", "shield", "holy_shield"],
		"speed": 260,
		"jump_force": -660,
		"hp": 5
	},
	"archer": {
		"name": "射手",
		"color": Color(0.3, 0.8, 0.4),
		"description": "远程型，可以使用钩锁、穿透箭和多重射击",
		"skills": ["grapple", "slow_arrow", "piercing_shot", "multi_shot"],
		"speed": 290,
		"jump_force": -720,
		"hp": 2
	}
}

# 当前关卡数据
var current_level_num: int = 1
var level_bottles_green: int = 0
var level_bottles_yellow: int = 0
var level_mushrooms: int = 0
var level_started: bool = false

# 分数计算
func calculate_score() -> int:
	return level_bottles_green * 100 + level_bottles_yellow * 200 + level_mushrooms * 50

func calculate_total_score() -> int:
	return total_bottles_green * 100 + total_bottles_yellow * 200 + total_mushrooms * 50

# 关卡管理
func get_level_name(num: int) -> String:
	var names: Dictionary = {
		1: "草原",
		2: "森林",
		3: "山地",
		4: "洞穴",
		5: "城堡"
	}
	return names.get(num, "未知")

func get_level_description(num: int) -> String:
	var descs: Dictionary = {
		1: "欢迎来到冒险之旅！收集瓶子和蘑菇，小心绿色的史莱姆！",
		2: "森林深处有彩色史莱姆和飞行的蝙蝠，准备好你的远程攻击！",
		3: "山地有骷髅追踪者，它们会不断追逐你！利用跳跃技巧甩掉它们！",
		4: "黑暗洞穴里有刺猬和蜗牛，刺猬带刺触碰受伤，蜗牛移动慢但很硬！",
		5: "最终挑战！城堡里集合了所有敌人，展现你的战斗技巧！"
	}
	return descs.get(num, "")

# 角色相关
func get_character_info(char_id: String) -> Dictionary:
	return characters.get(char_id, characters.get("warrior", {}))

func set_character(char_id: String) -> void:
	if characters.has(char_id):
		selected_character = char_id
		print("Global INFO: 角色切换为: " + char_id)

# ============ 保存/加载系统 ============
# 存档槽数量
const SAVE_SLOTS: int = 3
# 当前使用的存档槽（1-3）
var current_save_slot: int = 1
# 自动存档槽（用于自动保存）
var auto_save_slot: int = 0

# 保存到文件
func save_game(slot: int = current_save_slot) -> void:
	var save_data: Dictionary = {
		"version": 1,
		"max_unlocked_level": max_unlocked_level,
		"total_bottles_green": total_bottles_green,
		"total_bottles_yellow": total_bottles_yellow,
		"total_mushrooms": total_mushrooms,
		"selected_character": selected_character,
		"hp_upgrade_level": hp_upgrade_level,
		"speed_upgrade_level": speed_upgrade_level,
		"jump_upgrade_level": jump_upgrade_level,
		"damage_upgrade_level": damage_upgrade_level,
		"timestamp": Time.get_unix_time_from_system()
	}

	var file_path: String = "user://save_slot_%d.json" % slot
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Global INFO: 已保存到存档槽 " + str(slot))
	else:
		print("Global ERROR: 无法保存到存档槽 " + str(slot))

# 加载从文件
func load_game(slot: int) -> bool:
	var file_path: String = "user://save_slot_%d.json" % slot
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Global WARNING: 存档槽 " + str(slot) + " 不存在")
		return false

	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_error: int = json.parse(json_string)
	if parse_error != OK:
		print("Global ERROR: 存档槽 " + str(slot) + " 数据解析失败")
		return false

	var save_data: Dictionary = json.data
	if save_data == null or typeof(save_data) != TYPE_DICTIONARY:
		print("Global ERROR: 存档槽 " + str(slot) + " 数据格式错误")
		return false

	# 加载数据
	max_unlocked_level = save_data.get("max_unlocked_level", 1)
	total_bottles_green = save_data.get("total_bottles_green", 0)
	total_bottles_yellow = save_data.get("total_bottles_yellow", 0)
	total_mushrooms = save_data.get("total_mushrooms", 0)
	selected_character = save_data.get("selected_character", "warrior")
	hp_upgrade_level = save_data.get("hp_upgrade_level", 0)
	speed_upgrade_level = save_data.get("speed_upgrade_level", 0)
	jump_upgrade_level = save_data.get("jump_upgrade_level", 0)
	damage_upgrade_level = save_data.get("damage_upgrade_level", 0)

	print("Global INFO: 已从存档槽 " + str(slot) + " 加载数据")
	return true

# 自动存档（存到槽0）
func auto_save() -> void:
	save_game(auto_save_slot)

# 获取存档信息（用于显示存档列表）
func get_save_slot_info(slot: int) -> Dictionary:
	var file_path: String = "user://save_slot_%d.json" % slot
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {
			"exists": false,
			"slot": slot
		}

	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_error: int = json.parse(json_string)
	if parse_error != OK:
		return {
			"exists": true,
			"slot": slot,
			"corrupted": true
		}

	var save_data: Dictionary = json.data
	var timestamp: float = save_data.get("timestamp", 0.0)
	var datetime: Dictionary = Time.get_datetime_dict_from_unix_time(timestamp)

	return {
		"exists": true,
		"slot": slot,
		"corrupted": false,
		"level": save_data.get("max_unlocked_level", 1),
		"character": save_data.get("selected_character", "warrior"),
		"mushrooms": save_data.get("total_mushrooms", 0),
		"timestamp": timestamp,
		"datetime_str": format_datetime(datetime)
	}

# 格式化日期时间
func format_datetime(dt: Dictionary) -> String:
	return "%04d-%02d-%02d %02d:%02d" % [
		dt["year"], dt["month"], dt["day"],
		dt["hour"], dt["minute"]
	]

# 删除存档
func delete_save(slot: int) -> void:
	var file_path: String = "user://save_slot_%d.json" % slot
	var error: Error = DirAccess.remove_absolute(file_path)
	if error == OK:
		print("Global INFO: 已删除存档槽 " + str(slot))
	else:
		print("Global WARNING: 删除存档槽 " + str(slot) + " 失败")

# 重置关卡数据
func reset_level_data() -> void:
	level_bottles_green = 0
	level_bottles_yellow = 0
	level_mushrooms = 0
	level_started = false

# 收集物品
func collect_item(item_type: String, color: String = "") -> void:
	match item_type:
		"bottle":
			if color == "green":
				level_bottles_green += 1
				total_bottles_green += 1
			elif color == "yellow":
				level_bottles_yellow += 1
				total_bottles_yellow += 1
		"mushroom":
			level_mushrooms += 1
			total_mushrooms += 1
	print("Global DEBUG: 收集物品: " + item_type + " " + color)

# 关卡完成
func complete_level() -> void:
	if current_level_num >= max_unlocked_level:
		max_unlocked_level = current_level_num + 1
		if max_unlocked_level > 5:
			max_unlocked_level = 5
	auto_save()  # 自动保存进度
	print("Global INFO: 关卡 " + str(current_level_num) + " 完成！最大解锁关卡: " + str(max_unlocked_level))
