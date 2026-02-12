extends Node

# ============ 健壮版道具系统 ============
# 核心原则：
# 1. 避免空引用检查
# 2. 简单的数据结构
# 3. 默认值处理
# 4. 清晰的错误提示

# 道具类型常量
const TYPE_WEAPON = "weapon"
const TYPE_ARMOR = "armor"
const TYPE_POTION = "potion"
const TYPE_SCROLL = "scroll"
const TYPE_FOOD = "food"
const TYPE_RING = "ring"

# 稀有度常量
const RARITY_COMMON = 1
const RARITY_UNCOMMON = 2
const RARITY_RARE = 3
const RARITY_EPIC = 4
const RARITY_LEGENDARY = 5

# 道具数据类
class_name GameItem

var id: String = ""
var name: String = ""
var type: String = ""
var rarity: int = 1
var level: int = 1
var value: int = 0

func _init(_id: String = "", _name: String = "", _type: String = "", _rarity: int = 1, _level: int = 1, _value: int = 0):
	id = _id
	name = _name
	type = _type
	rarity = _rarity
	level = _level
	value = _value

func debug_print():
	print("Item: %s (%s) Lv.%d [稀有度%d]" % [name, type, level, rarity])

func get_rarity_color() -> Color:
	match rarity:
		RARITY_COMMON: return Color(0.5, 0.5, 0.5)
		RARITY_UNCOMMON: return Color(0.3, 0.8, 0.3)
		RARITY_RARE: return Color(0.3, 0.5, 0.9)
		RARITY_EPIC: return Color(0.7, 0.4, 0.9)
		RARITY_LEGENDARY: return Color(1.0, 0.8, 0.2)
		_: return Color.WHITE

# 道具数据库
class_name ItemDB extends Node

var items: Array = []

func _ready():
	_init_items()

func _init_items():
	items = []
	
	# 武器
	add_item("dagger", "匕首", TYPE_WEAPON, RARITY_COMMON, 1, 3)
	add_item("shortsword", "短剑", TYPE_WEAPON, RARITY_COMMON, 1, 4)
	add_item("mace", "钉锤", TYPE_WEAPON, RARITY_UNCOMMON, 2, 5)
	add_item("spear", "长矛", TYPE_WEAPON, RARITY_UNCOMMON, 2, 5)
	add_item("sword", "剑", TYPE_WEAPON, RARITY_RARE, 3, 7)
	add_item("longsword", "长剑", TYPE_WEAPON, RARITY_EPIC, 4, 9)
	add_item("katana", "武士刀", TYPE_WEAPON, RARITY_EPIC, 4, 10)
	add_item("greatsword", "巨剑", TYPE_WEAPON, RARITY_EPIC, 5, 12)
	add_item("warhammer", "战锤", TYPE_WEAPON, RARITY_EPIC, 5, 14)
	
	# 护甲
	add_item("cloth", "布甲", TYPE_ARMOR, RARITY_COMMON, 1, 1)
	add_item("leather", "皮甲", TYPE_ARMOR, RARITY_COMMON, 1, 2)
	add_item("mail", "锁甲", TYPE_ARMOR, RARITY_UNCOMMON, 2, 3)
	add_item("plate", "板甲", TYPE_ARMOR, RARITY_RARE, 3, 6)
	add_item("holy", "圣甲", TYPE_ARMOR, RARITY_EPIC, 4, 9)
	
	# 药水
	add_item("potion_heal", "治疗药水", TYPE_POTION, RARITY_COMMON, 1, 10)
	add_item("potion_strength", "力量药水", TYPE_POTION, RARITY_UNCOMMON, 2, 2)
	add_item("potion_speed", "加速药水", TYPE_POTION, RARITY_RARE, 3, 5)
	add_item("potion_invis", "隐身药水", TYPE_POTION, RARITY_UNCOMMON, 2, 5)
	
	# 食物
	add_item("food_ration", "口粮", TYPE_FOOD, RARITY_COMMON, 1, 5)
	add_item("food_meat", "肉", TYPE_FOOD, RARITY_COMMON, 1, 8)
	
	# 戒指
	add_item("ring_accuracy", "精准戒指", TYPE_RING, RARITY_COMMON, 1, 0)
	add_item("ring_evasion", "闪避戒指", TYPE_RING, RARITY_COMMON, 1, 0)
	add_item("ring_damage", "伤害戒指", TYPE_RING, RARITY_UNCOMMON, 2, 0)
	add_item("ring_speed", "速度戒指", TYPE_RING, RARITY_RARE, 3, 0)
	
	print("ItemDB: 初始化完成，共%d个道具" % items.size())

func add_item(_id: String, _name: String, _type: String, _rarity: int, _level: int, _value: int):
	var item = GameItem.new(_id, _name, _type, _rarity, _level, _value)
	items.append(item)

func get_item(item_id: String) -> GameItem:
	for item in items:
		if item.id == item_id:
			return item
	print("警告: 找不到道具 %s" % item_id)
	return null

func get_random(item_type: String = "", max_level: int = 5) -> GameItem:
	var valid = []
	for item in items:
		if item.level <= max_level + 1:
			if item_type == "" or item.type == item_type:
				valid.append(item)
	
	if valid.is_empty():
		valid = items
	
	if valid.is_empty():
		return null
	
	return valid.pick_random()

func get_by_type(item_type: String) -> Array:
	var result = []
	for item in items:
		if item.type == item_type:
			result.append(item)
	return result

# 道具管理器
class_name ItemManager extends Node

var db: ItemDB
var inventory: Array = []

func _ready():
	# 尝试获取或创建数据库
	db = get_node_or_null("/root/ItemDB")
	if not db:
		db = ItemDB.new()
		add_child(db)
	print("ItemManager: 启动成功")

func add_item(item: GameItem):
	if item:
		inventory.append(item)
		print("获得: %s" % item.name)

func get_random_item(item_type: String = "", max_level: int = 3) -> GameItem:
	if db:
		return db.get_random(item_type, max_level)
	return null

func get_enemy_drop(enemy_level: int = 1) -> Array:
	var drops = []
	if randf() < 0.3:
		var item = get_random_item(TYPE_FOOD, enemy_level)
		if item:
			drops.append(item)
	if randf() < 0.1:
		var item = get_random_item("", enemy_level)
		if item:
			drops.append(item)
	return drops

func has_item(item_id: String) -> bool:
	for item in inventory:
		if item.id == item_id:
			return true
	return false

func get_item_count(item_type: String = "") -> int:
	if item_type == "":
		return inventory.size()
	var count = 0
	for item in inventory:
		if item.type == item_type:
			count += 1
	return count

func clear_inventory():
	inventory.clear()
	print("背包已清空")
