extends Node

# ============ 简化版道具生成器 ============

# 道具类型（用字符串，不用枚举）
const TYPE_WEAPON = "weapon"
const TYPE_ARMOR = "armor"
const TYPE_WAND = "wand"
const TYPE_RING = "ring"
const TYPE_ARTIFACT = "artifact"
const TYPE_SCROLL = "scroll"
const TYPE_POTION = "potion"
const TYPE_FOOD = "food"
const TYPE_TRINKET = "trinket"

# 稀有度
const RARITY_COMMON = 1      # 灰色
const RARITY_UNCOMMON = 2    # 绿色
const RARITY_RARE = 3        # 蓝色
const RARITY_EPIC = 4        # 紫色
const RARITY_LEGENDARY = 5    # 金色

# 道具数据库
var items = {}

func _ready():
	_init_items()

func _init_items():
	# === 武器 (等级, 稀有度, 伤害) ===
	items[TYPE_WEAPON] = [
		{"id": "dagger", "name": "匕首", "level": 1, "rarity": RARITY_COMMON, "damage": 3},
		{"id": "shortsword", "name": "短剑", "level": 1, "rarity": RARITY_COMMON, "damage": 4},
		{"id": "mace", "name": "钉锤", "level": 2, "rarity": RARITY_UNCOMMON, "damage": 5},
		{"id": "spear", "name": "长矛", "level": 2, "rarity": RARITY_UNCOMMON, "damage": 5},
		{"id": "handaxe", "name": "手斧", "level": 2, "rarity": RARITY_UNCOMMON, "damage": 6},
		{"id": "sword", "name": "剑", "level": 3, "rarity": RARITY_RARE, "damage": 7},
		{"id": "crossbow", "name": "弩", "level": 3, "rarity": RARITY_RARE, "damage": 6},
		{"id": "scimitar", "name": "弯刀", "level": 3, "rarity": RARITY_RARE, "damage": 8},
		{"id": "longsword", "name": "长剑", "level": 4, "rarity": RARITY_EPIC, "damage": 9},
		{"id": "katana", "name": "武士刀", "level": 4, "rarity": RARITY_EPIC, "damage": 10},
		{"id": "greatsword", "name": "巨剑", "level": 5, "rarity": RARITY_EPIC, "damage": 12},
		{"id": "warhammer", "name": "战锤", "level": 5, "rarity": RARITY_EPIC, "damage": 14},
	]
	
	# === 护甲 (等级, 稀有度, 防御) ===
	items[TYPE_ARMOR] = [
		{"id": "cloth", "name": "布甲", "level": 1, "rarity": RARITY_COMMON, "defense": 1},
		{"id": "leather", "name": "皮甲", "level": 1, "rarity": RARITY_COMMON, "defense": 2},
		{"id": "mail", "name": "锁甲", "level": 2, "rarity": RARITY_UNCOMMON, "defense": 3},
		{"id": "scale", "name": "鳞甲", "level": 2, "rarity": RARITY_UNCOMMON, "defense": 4},
		{"id": "plate", "name": "板甲", "level": 3, "rarity": RARITY_RARE, "defense": 6},
		{"id": "magic", "name": "魔甲", "level": 3, "rarity": RARITY_RARE, "defense": 7},
		{"id": "holy", "name": "圣甲", "level": 4, "rarity": RARITY_EPIC, "defense": 9},
	]
	
	# === 戒指 (等级, 稀有度, 效果) ===
	items[TYPE_RING] = [
		{"id": "accuracy", "name": "精准戒指", "level": 1, "rarity": RARITY_COMMON, "effect": "accuracy", "value": 5},
		{"id": "evasion", "name": "闪避戒指", "level": 1, "rarity": RARITY_COMMON, "effect": "evasion", "value": 5},
		{"id": "sharpshooting", "name": "射击戒指", "level": 2, "rarity": RARITY_UNCOMMON, "effect": "damage", "value": 10},
		{"id": "tenacity", "name": "坚韧戒指", "level": 2, "rarity": RARITY_UNCOMMON, "effect": "health", "value": 10},
		{"id": "force", "name": "力量戒指", "level": 3, "rarity": RARITY_RARE, "effect": "knockback", "value": 3},
		{"id": "furor", "name": "狂怒戒指", "level": 3, "rarity": RARITY_RARE, "effect": "speed", "value": 10},
	]
	
	# === 药水 ===
	items[TYPE_POTION] = [
		{"id": "healing", "name": "治疗药水", "level": 1, "rarity": RARITY_COMMON, "effect": "heal", "value": 10},
		{"id": "strength", "name": "力量药水", "level": 2, "rarity": RARITY_UNCOMMON, "effect": "strength", "value": 2},
		{"id": "invisibility", "name": "隐身药水", "level": 2, "rarity": RARITY_UNCOMMON, "effect": "invis", "value": 5},
		{"id": "haste", "name": "加速药水", "level": 3, "rarity": RARITY_RARE, "effect": "haste", "value": 5},
	]
	
	# === 卷轴 ===
	items[TYPE_SCROLL] = [
		{"id": "identify", "name": "鉴定卷轴", "level": 1, "rarity": RARITY_COMMON, "effect": "identify"},
		{"id": "upgrade", "name": "升级卷轴", "level": 2, "rarity": RARITY_UNCOMMON, "effect": "upgrade"},
		{"id": "teleport", "name": "传送卷轴", "level": 2, "rarity": RARITY_UNCOMMON, "effect": "teleport"},
	]
	
	# === 食物 ===
	items[TYPE_FOOD] = [
		{"id": "ration", "name": "口粮", "level": 1, "rarity": RARITY_COMMON, "effect": "heal", "value": 5},
		{"id": "meat", "name": "肉", "level": 1, "rarity": RARITY_COMMON, "effect": "heal", "value": 8},
	]
	
	# === 饰品 ===
	items[TYPE_TRINKET] = [
		{"id": "eye_newt", "name": "蝾螈眼", "level": 1, "rarity": RARITY_UNCOMMON, "effect": "detect"},
		{"id": "ferret_tuft", "name": "雪貂毛", "level": 2, "rarity": RARITY_RARE, "effect": "steal"},
	]

# 生成随机道具
func get_random_item(item_type: String, max_level: int = 1) -> Dictionary:
	var pool = items.get(item_type, [])
	if pool.is_empty():
		return {"name": "空", "level": 1}
	
	var valid = []
	for item in pool:
		if item["level"] <= max_level + 1:
			valid.append(item)
	
	if valid.is_empty():
		valid = pool
	
	return valid.pick_random()

# 生成随机武器
func get_random_weapon(max_level: int = 1) -> Dictionary:
	return get_random_item(TYPE_WEAPON, max_level)

# 生成随机护甲
func get_random_armor(max_level: int = 1) -> Dictionary:
	return get_random_item(TYPE_ARMOR, max_level)

# 生成随机戒指
func get_random_ring(max_level: int = 1) -> Dictionary:
	return get_random_item(TYPE_RING, max_level)

# 生成随机药水
func get_random_potion(max_level: int = 1) -> Dictionary:
	return get_random_item(TYPE_POTION, max_level)

# 生成随机卷轴
func get_random_scroll(max_level: int = 1) -> Dictionary:
	return get_random_item(TYPE_SCROLL, max_level)

# 根据稀有度生成道具
func get_random_by_rarity(rarity: int, item_type: String = "") -> Dictionary:
	var pool = []
	
	if item_type == "":
		# 所有类型
		for type in items:
			for item in items[type]:
				if item["rarity"] == rarity:
					pool.append(item)
	else:
		pool = items.get(item_type, [])
		var filtered = []
		for item in pool:
			if item["rarity"] == rarity:
				filtered.append(item)
		pool = filtered
	
	if pool.is_empty():
		return get_random_item(TYPE_WEAPON, 1)
	
	return pool.pick_random()

# 获取所有稀有道具（传说级）
func get_legendary_items() -> Array:
	var legendary = []
	for type in items:
		for item in items[type]:
			if item["rarity"] == RARITY_LEGENDARY:
				legendary.append(item)
	return legendary

# 颜色根据稀有度
func get_rarity_color(rarity: int) -> Color:
	match rarity:
		RARITY_COMMON: return Color(0.5, 0.5, 0.5)
		RARITY_UNCOMMON: return Color(0.3, 0.8, 0.3)
		RARITY_RARE: return Color(0.3, 0.5, 0.9)
		RARITY_EPIC: return Color(0.7, 0.4, 0.9)
		RARITY_LEGENDARY: return Color(1.0, 0.8, 0.2)
		_: return Color.WHITE

# 获取道具类型列表
func get_all_types() -> Array:
	return [TYPE_WEAPON, TYPE_ARMOR, TYPE_RING, TYPE_POTION, TYPE_SCROLL, TYPE_FOOD, TYPE_TRINKET]
