extends Node

# ============ 玩家道具系统 ============
# 管理玩家拥有的所有道具

signal item_added(item_data)
signal item_activated(item_data)

@export var max_passive_items: int = 12
@export var max_active_items: int = 1
@export var max_trinkets: int = 2

# 玩家状态加成汇总
var total_stats: Dictionary = {
	"speed": 0,        # 移动速度加成（百分比）
	"damage": 0,       # 伤害加成（百分比）
	"fire_rate": 0,    # 射速加成（百分比）
	"range": 0,       # 射程加成
	"tears": 0,       # 眼泪/子弹大小
	"luck": 0,        # 幸运值
	"shot_speed": 0,  # 弹速
	"health": 0,      # 生命值加成
	"extra_lives": 0, # 额外生命
}

# 特殊效果标记
var special_flags: Dictionary = {
	"flight": false,          # 飞行
	"homing": false,          # 追踪
	"invincible_chance": 0,  # 无敌概率
	"enemy_slow": 0,        # 敌人减速
	"laser": false,          # 激光
	"brimstone": false,     # 血激光
	"reroll": false,         # 重置道具
	"devour": false,         # 吞噬
}

# 玩家引用
var player: CharacterBody2D

# 已拥有的道具
var passive_items: Array = []
var active_items: Array = []
var trinkets: Array = []

func _ready():
	player = get_parent()

func add_item(item_data: IsaacItem):
	match item_data.type:
		ItemType.PASSIVE:
			_add_passive_item(item_data)
		ItemType.ACTIVE:
			_add_active_item(item_data)
		ItemType.TRINKET:
			_add_trinket(item_data)
		ItemType.STAT:
			_apply_stat_bonuses(item_data.stat_bonuses)

func _add_passive_item(item_data: IsaacItem):
	if passive_items.size() >= max_passive_items:
		print("已达到最大被动道具数量！")
		return
	
	passive_items.append(item_data)
	_apply_stat_bonuses(item_data.stat_bonuses)
	item_added.emit(item_data)
	print("获得被动道具: " + item_data.name)

func _add_active_item(item_data: IsaacItem):
	if active_items.size() >= max_active_items:
		print("已达到最大主动道具数量！")
		return
	
	active_items.append(item_data)
	item_added.emit(item_data)
	print("获得主动道具: " + item_data.name)

func _add_trinket(item_data: IsaacItem):
	if trinkets.size() >= max_trinkets:
		print("已达到最大饰品数量！")
		return
	
	trinkets.append(item_data)
	_apply_stat_bonuses(item_data.stat_bonuses)
	print("获得饰品: " + item_data.name)

func _apply_stat_bonuses(bonuses: Dictionary):
	for stat in bonuses:
		if stat in total_stats:
			total_stats[stat] += bonuses[stat]
		elif stat in special_flags:
			special_flags[stat] = bonuses[stat]
	
	_apply_stats_to_player()

func _apply_stats_to_player():
	# 将加成应用到玩家属性
	var g = get_node_or_null("/root/Global")
	
	# 速度
	if total_stats["speed"] != 0:
		player.move_speed *= (1.0 + total_stats["speed"])
	
	# 伤害
	if total_stats["damage"] != 0:
		g.set_upgrade_bonus("damage", int(total_stats["damage"] * 10))
	
	# 射程
	if total_stats["range"] != 0:
		player.fire_range += total_stats["range"]

# 激活主动道具
func activate_active_item():
	if active_items.is_empty():
		return
	
	var active_item = active_items.back()  # 使用最近获得的主动道具
	if active_item and active_item.on_use.is_valid():
		active_item.on_use.call()
		item_activated.emit(active_item)

# 检查是否有某个效果
func has_flag(flag: String) -> bool:
	return special_flags.get(flag, false)

# 获取某个加成的最终值
func get_stat(stat: String) -> float:
	return total_stats.get(stat, 0.0)

# 计算实际伤害加成
func calculate_damage_multiplier() -> float:
	return 1.0 + total_stats["damage"]

# 计算射速加成
func calculate_fire_rate_multiplier() -> float:
	return 1.0 + total_stats["fire_rate"]

# 显示当前道具列表
func get_item_list_string() -> String:
	var result = "=== 拥有的道具 ===\n"
	
	result += "\n被动道具:\n"
	for item in passive_items:
		result += "- %s (%s)\n" % [item.name, item.description]
	
	if active_items.size() > 0:
		result += "\n主动道具:\n"
		for item in active_items:
			result += "- %s (%s)\n" % [item.name, item.description]
	
	if trinkets.size() > 0:
		result += "\n饰品:\n"
		for item in trinkets:
			result += "- %s\n" % [item.name]
	
	result += "\n=== 属性加成 ===\n"
	result += "速度: +%d%%\n" % [int(total_stats["speed"] * 100)]
	result += "伤害: +%d%%\n" % [int(total_stats["damage"] * 100)]
	result += "射程: +%d\n" % [total_stats["range"]]
	
	if special_flags["flight"]:
		result += "飞行: 是\n"
	if special_flags["homing"]:
		result += "追踪: 是\n"
	
	return result
