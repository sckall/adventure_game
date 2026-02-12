extends Node

# ============ 健壮版道具系统 ============
# 核心原则：
# 1. 避免空引用检查
# 2. 简单的数据结构
# 3. 默认值处理
# 4. 清晰的错误提示

# 道具基类
class_name GameItem extends Node

var id: String = ""
var name: String = ""
var type: String = ""
var rarity: int = 1
var level: int = 1

# 安全获取值
func get_value(key: String, default):
	if has_method("get"):
		return get(key, default)
	return default

# 打印调试信息
func debug_print():
	print("Item: %s (%s) Lv.%d [稀有度%d]" % [name, type, level, rarity])

# ============ 简单道具数据库 ============
class_name ItemDB extends Node

var items: Array = []

func _ready():
	_init_items()

func _init_items():
	items = []
	
	# 武器
	add_item("dagger", "匕首", "weapon", 1, 3)
	add_item("shortsword", "短剑", "weapon", 1, 4)
	add_item("mace", "钉锤", "weapon", 2, 5)
	add_item("spear", "长矛", "weapon", 2, 5)
	add_item("sword", "剑", "weapon", 3, 7)
	add_item("longsword", "长剑", "weapon", 4, 9)
	add_item("katana", "武士刀", "weapon", 4, 10)
	add_item("greatsword", "巨剑", "weapon", 5, 12)
	add_item("warhammer", "战锤", "weapon", 5, 14)
	
	# 护甲
	add_item("cloth", "布甲", "armor", 1, 1)
	add_item("leather", "皮甲", "armor", 1, 2)
	add_item("mail", "锁甲", "armor", 2, 3)
	add_item("plate", "板甲", "armor", 3, 6)
	add_item("holy", "圣甲", "armor", 4, 9)
	
	# 戒指
	add_item("ring_accuracy", "精准戒指", "ring", 1, 0)
	add_item("ring_evasion", "闪避戒指", "ring", 1, 0)
	add_item("ring_damage", "伤害戒指", "ring", 2, 0)
	add_item("ring_speed", "速度戒指", "ring", 3, 0)
	
	# 药水
	add_item("potion_heal", "治疗药水", "potion", 1, 10)
	add_item("potion_strength", "力量药水", "potion", 2, 2)
	add_item("potion_speed", "加速药水", "potion", 3, 5)
	add_item("potion_invis", "隐身药水", "potion", 2, 5)
	
	# 食物
	add_item("food_ration", "口粮", "food", 1, 5)
	add_item("food_meat", "肉", "food", 1, 8)
	
	print("ItemDB: 初始化完成，共%d个道具" % items.size())

func add_item(_id: String, _name: String, _type: String, _level: int, _value: int):
	var item = GameItem.new()
	item.id = _id
	item.name = _name
	item.type = _type
	item.level = _level
	item.rarity = _level  # 等级越高稀有度越高
	items.append(item)

# 安全获取道具
func get_item(id: String) -> GameItem:
	for item in items:
		if item.id == id:
			return item
	print("警告: 找不到道具 %s" % id)
	return null

# 随机获取
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

# 获取所有某类型的道具
func get_by_type(item_type: String) -> Array:
	var result = []
	for item in items:
		if item.type == item_type:
			result.append(item)
	return result

# ============ 道具管理器 ============
class_name ItemManager extends Node

var db: ItemDB
var inventory: Array = []

func _ready():
	if not FileAccess.file_exists("res://scripts/items"):
		return
	
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

# 生成敌人掉落
func get_enemy_drop(enemy_level: int = 1) -> Array:
	var drops = []
	
	# 30%概率掉落
	if randf() < 0.3:
		var item = get_random_item("food", enemy_level)
		if item:
			drops.append(item)
	
	# 10%概率掉落道具
	if randf() < 0.1:
		var item = get_random_item("", enemy_level)
		if item:
			drops.append(item)
	
	return drops

# 检查道具是否存在
func has_item(item_id: String) -> bool:
	for item in inventory:
		if item.id == item_id:
			return true
	return false

# 获取道具数量
func get_item_count(item_type: String = "") -> int:
	if item_type == "":
		return inventory.size()
	
	var count = 0
	for item in inventory:
		if item.type == item_type:
			count += 1
	return count

# 清空背包
func clear_inventory():
	inventory.clear()
	print("背包已清空")
