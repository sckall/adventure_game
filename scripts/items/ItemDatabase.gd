extends Node

# ============ 以撒风格道具数据库 ============

var all_items: Dictionary = {}

func _ready():
	_init_items()

func _init_items():
	# 1星道具（常见）
	all_items["square"] = {
		"name": "小方块",
		"description": "回复1颗红心",
		"rarity": 1,
		"type": "passive",
		"effect": {"health": 1}
	}
	
	all_items["battery"] = {
		"name": "电池",
		"description": "主动道具充能+1",
		"rarity": 1,
		"type": "passive",
		"effect": {"charge": 1}
	}
	
	all_items["coin"] = {
		"name": "硬币",
		"description": "+1块钱",
		"rarity": 1,
		"type": "passive",
		"effect": {"coins": 1}
	}
	
	# 2星道具（少见）
	all_items["sack"] = {
		"name": "爱心袋",
		"description": "每房间+1红心",
		"rarity": 2,
		"type": "passive",
		"effect": {"health_per_room": 1}
	}
	
	all_items["bomb"] = {
		"name": "炸弹",
		"description": "+1炸弹",
		"rarity": 2,
		"type": "passive",
		"effect": {"bombs": 1}
	}
	
	# 3星道具（稀有）
	all_items["dead_cat"] = {
		"name": "死猫",
		"description": "+9条命",
		"rarity": 5,
		"type": "passive",
		"effect": {"extra_lives": 9}
	}
	
	all_items["spoon_bender"] = {
		"name": "弯曲勺子",
		"description": "眼泪带追踪",
		"rarity": 3,
		"type": "passive",
		"effect": {"homing": true}
	}
	
	all_items["compass"] = {
		"name": "指南针",
		"description": "显示地图",
		"rarity": 2,
		"type": "passive",
		"effect": {"map": true}
	}
	
	all_items["gamekid"] = {
		"name": "游戏机",
		"description": "受伤时有概率无敌",
		"rarity": 3,
		"type": "passive",
		"effect": {"invincible_chance": 0.1}
	}
	
	# 4星道具（罕见）
	all_items["stopwatch"] = {
		"name": "秒表",
		"description": "敌人减速50%",
		"rarity": 4,
		"type": "passive",
		"effect": {"enemy_slow": 0.5}
	}
	
	all_items["crow_god"] = {
		"name": "乌鸦之神",
		"description": "飞行+追踪",
		"rarity": 4,
		"type": "passive",
		"effect": {"flight": true, "homing": true}
	}

# 获取随机道具
func get_random_item() -> Dictionary:
	var items_by_rarity = {1: [], 2: [], 3: [], 4: [], 5: []}
	
	for id in all_items:
		var item = all_items[id]
		items_by_rarity[item.rarity].append(id)
	
	var weights = {1: 60, 2: 25, 3: 10, 4: 4, 5: 1}
	var roll = randi() % 100
	var cumulative = 0
	var selected_rarity = 1
	
	for rarity in [1, 2, 3, 4, 5]:
		cumulative += weights[rarity]
		if roll < cumulative:
			selected_rarity = rarity
			break
	
	if items_by_rarity[selected_rarity].size() > 0:
		var id = items_by_rarity[selected_rarity].pick_random()
		return all_items[id]
	
	return all_items["square"]

# 根据ID获取道具
func get_item_by_id(id: String) -> Dictionary:
	return all_items.get(id, {})
