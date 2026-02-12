extends Node

# ============ Shattered Pixel Dungeon 风格道具生成器 ============
# 基于 Shattered Pixel Dungeon 的 Generator.java 移植

class_name ItemGenerator

# 道具类别枚举
enum Category {
	WEAPON,     # 武器
	ARMOR,      # 护甲
	WAND,       # 法杖
	WEAPON_MISSILES,  # 投射武器
	ARTIFACT,   # 神器
	RING,       # 戒指
	SCROLL,     # 卷轴
	POTION,     # 药水
	FOOD,       # 食物
	BOMB,       # 炸弹
	TRINKET,    # 饰品
	SEED,       # 种子
	STONE,      # 宝石
	GOLD        # 金币
}

# 稀有度权重 (基于Shattered Pixel Dungeon)
const RARITY_WEIGHTS = {
	1: 60,   # 常见
	2: 25,   # 少见
	3: 10,   # 稀有
	4: 4,    # 罕见
	5: 1     # 传说
}

# 道具数据库
var item_database: Dictionary = {}

func _ready():
	_init_database()

func _init_database():
	# === 武器 (基于等级生成) ===
	item_database[Category.WEAPON] = {
		1: ["dagger", "shortsword", "gloves"],
		2: ["mace", "spear", "handaxe"],
		3: ["sword", "crossbow", "scimitar"],
		4: ["longsword", "katana", "rapier"],
		5: ["greatsword", "warhammer", "scythe"],
		6: ["glaive", "runeblade"]
	}
	
	# === 护甲 ===
	item_database[Category.ARMOR] = {
		1: ["cloth", "leather"],
		2: ["mail", "scale"],
		3: ["plate", "magic"],
		4: ["holy", "shadow"]
	}
	
	# === 法杖 ===
	item_database[Category.WAND] = {
		1: ["magic_missile"],
		2: ["fireblast", "frost"],
		3: ["lightning", "corrosion"],
		4: ["disintegration", "prismatic"]
	}
	
	# === 投射武器 ===
	item_database[Category.WEAPON_MISSILES] = {
		1: ["dart", "throwing_stone"],
		2: ["shuriken", "throwing_knife"],
		3: ["javelin", "boomerang"],
		4: ["trident", "kunai"]
	}
	
	# === 戒指 ===
	item_database[Category.RING] = {
		1: ["accuracy", "evasion"],
		2: ["sharpshooting", "tenacity"],
		3: ["force", "furor"],
		4: ["arcana", "wealth"]
	}
	
	# === 神器 ===
	item_database[Category.ARTIFACT] = {
		1: ["cloak", "talisman"],
		2: ["horn", "rose"],
		3: ["hourglass", "toolkit"],
		4: ["chains", "book"]
	}
	
	# === 卷轴 ===
	item_database[Category.SCROLL] = {
		1: ["identify", "teleport"],
		2: ["upgrade", "recharge"],
		3: ["mirror_image", "rage"],
		4: ["magic_mapping", "remove_curse"]
	}
	
	# === 药水 ===
	item_database[Category.POTION] = {
		1: ["healing", "strength"],
		2: ["invisibility", "haste"],
		3: ["mind_vision", "frost"],
		4: ["experience", "levitation"]
	}
	
	# === 食物 ===
	item_database[Category.FOOD] = {
		1: ["ration", "meat"],
		2: ["mystery_meat", "pasty"]
	}
	
	# === 炸弹 ===
	item_database[Category.BOMB] = {
		1: ["bomb", "sticky_bomb"],
		2: ["fire_bomb", "frost_bomb"],
		3: ["holy_bomb", "smoke_bomb"]
	}
	
	# === 饰品 ===
	item_database[Category.TRINKET] = = {
		1: ["eye_newt", "ferret_tuft"],
		2: ["moss_clump", "mimic_tooth"],
		3: ["vial_blood", "salt_cube"],
		4: ["crystal", "clover"]
	}
	
	# === 种子/植物 ===
	item_database[Category.SEED] = {
		1: ["firebloom", "blindweed"],
		2: ["earthroot", "icecap"],
		3: ["fadeleaf", "sungrass"]
	}
	
	# === 宝石 ===
	item_database[Category.STONE] = {
		1: ["stone_aggression"],
		2: ["stone_blink", "stone_flock"],
		3: ["stone_augmentation", "stone_enchantment"],
		4: ["stone_deep_sleep", "stone_clarvoyance"]
	}

# 生成随机道具
func random_item(level: int = 1, category: Category = Category.WEAPON) -> Dictionary:
	var rarity = _calculate_rarity()
	var items = _get_items_by_category_and_rarity(category, level, rarity)
	
	if items.is_empty():
		return _get_fallback_item()
	
	var item_id = items.pick_random()
	return _create_item(item_id, level, rarity)

# 计算稀有度
func _calculate_rarity() -> int:
	var roll = randi() % 100
	var cumulative = 0
	
	for r in [1, 2, 3, 4, 5]:
		cumulative += RARITY_WEIGHTS[r]
		if roll < cumulative:
			return r
	
	return 1

# 根据类别和稀有度获取道具列表
func _get_items_by_category_and_rarity(category: Category, level: int, rarity: int) -> Array:
	var result = []
	
	if not item_database.has(category):
		return result
	
	var by_level = item_database[category]
	
	# 允许低等级道具在高等级出现
	for lvl in by_level:
		if lvl <= level + 1:
			var items_at_level = by_level[lvl]
			for item_id in items_at_level:
				var item_rarity = _get_item_rarity(item_id, category)
				if item_rarity == rarity:
					result.append(item_id)
	
	return result

# 获取道具稀有度
func _get_item_rarity(item_id: String, category: Category) -> int:
	var rare_items = {
		"runeblade": 4, "greatsword": 3, "katana": 4,
		"holy": 4, "shadow": 4,
		"prismatic": 4, "disintegration": 4,
		"chains": 5, "book": 4, "hourglass": 4,
		"clover": 5, "crystal": 4
	}
	return rare_items.get(item_id, 1)

# 创建道具数据
func _create_item(item_id: String, level: int, rarity: int) -> Dictionary:
	var item = {
		"id": item_id,
		"level": level,
		"rarity": rarity,
		"enchantment": _maybe_add_enchantment(rarity),
		"curse": _maybe_add_curse(rarity)
	}
	
	# 添加基础属性
	match _get_category_for_item(item_id):
		Category.WEAPON:
			item["damage"] = _calculate_weapon_damage(level, rarity)
			item["speed"] = 1.0 + (rarity - 1) * 0.1
		Category.ARMOR:
			item["defense"] = _calculate_armor_defense(level, rarity)
			item["durability"] = 100
		Category.RING:
			item["effect"] = _get_ring_effect(item_id, rarity)
	
	return item

# 计算武器伤害
func _calculate_weapon_damage(level: int, rarity: int) -> int:
	var base = 2 + level
	var multiplier = 1.0 + (rarity - 1) * 0.25
	return int(base * multiplier)

# 计算护甲防御
func _calculate_armor_defense(level: int, rarity: int) -> int:
	var base = level
	var bonus = (rarity - 1) * 2
	return base + bonus

# 可能的附魔
func _maybe_add_enchantment(rarity: int) -> String:
	if randf() < rarity * 0.15:  # 稀有度越高，附魔概率越大
		var enchantments = ["sharp", "heavy", "swift", "lucky", "vorpal", "blazing", "frozen"]
		return enchantments.pick_random()
	return ""

# 可能的诅咒
func _maybe_add_curse(rarity: int) -> String:
	if randf() < 0.05:  # 诅咒概率较低
		var curses = ["fragile", "punishing", "demonic"]
		return curses.pick_random()
	return ""

# 获取戒指效果
func _get_ring_effect(ring_id: String, rarity: int) -> Dictionary:
	var effects = {
		"accuracy": {"hit_bonus": 2 + rarity},
		"evasion": {"dodge_bonus": 2 + rarity},
		"sharpshooting": {"damage": 0.1 + rarity * 0.05},
		"tenacity": {"hp_bonus": 5 + rarity * 3},
		"force": {"knockback": rarity},
		"furor": {"speed": 0.1 + rarity * 0.05},
		"arcana": {"spell_power": rarity * 2},
		"wealth": {"drop_bonus": rarity * 0.1}
	}
	return effects.get(ring_id, {})

# 获取类别的道具ID列表
func _get_items_by_category(category: Category) -> Array:
	for cat in item_database:
		if cat == category:
			var result = []
			for lvl in item_database[cat]:
				for item_id in item_database[cat][lvl]:
					result.append(item_id)
			return result
	return []

# 备用道具
func _get_fallback_item() -> Dictionary:
	return {
		"id": "gold",
		"level": 1,
		"rarity": 1,
		"amount": randi_range(5, 15)
	}

# 获取类别的工具函数
func _get_category_for_item(item_id: String) -> Category:
	for cat in item_database:
		for lvl in item_database[cat]:
			if item_id in item_database[cat][lvl]:
				return cat
	return Category.WEAPON

# 生成完整掉落表（用于房间生成）
func generate_drops(floor_level: int, room_type: String) -> Array:
	var drops = []
	
	match room_type:
		"normal":
			# 普通房间：1-2个普通道具
			if randf() < 0.4:
				drops.append(random_item(floor_level, _random_category()))
		"treasure":
			# 宝藏房：1-2个稀有道具
			drops.append(random_item(floor_level, _random_category()))
			if randf() < 0.5:
				drops.append(random_item(floor_level, _random_category()))
		"shop":
			# 商店：3-5个道具
			for i in range(randi_range(3, 5)):
				drops.append(random_item(floor_level, _random_category()))
		"boss":
			# Boss：固定掉落+随机
			drops.append(random_item(floor_level + 2, Category.ARTIFACT))
			drops.append(random_item(floor_level, _random_category()))
	
	return drops

# 随机类别
func _random_category() -> Category:
	var categories = Category.values()
	return categories.pick_random()
