extends Node

# ============ 以撒风格道具系统 ============
# 包含：道具房、掉落、被动道具、主动道具

# 道具类型枚举
enum ItemType {
	PASSIVE,   # 被动道具（自动生效）
	ACTIVE,    # 主动道具（需要按键触发）
	TRINKET,   # 小饰品（可叠加）
	STAT       # 属性提升
}

# 道具数据结构
class_name IsaacItem extends Node

var id: String
var name: String
var description: String
var type: ItemType
var icon: Texture2D
var rarity: int = 1  # 1-5星
var max_stack: int = 1

# 效果
var stat_bonuses: Dictionary = {}  # 速度+10, 伤害+20%等
var on_pickup: Callable            # 拾取时触发
var on_damage_taken: Callable      # 受伤时触发
var on_kill: Callable              # 击杀时触发
var on_fire_bullet: Callable       # 发射子弹时触发

func _init(_id: String, _name: String, _desc: String, _type: ItemType):
	id = _id
	name = _name
	description = _desc
	type = _type

# 道具数据库
class_name ItemDatabase extends Node

var all_items: Dictionary = {}  # id -> IsaacItem

func _ready():
	_init_items()

func _init_items():
	# === 1星道具（常见） ===
	_register_item(create_passive_item("square", "小方块", 
		"回复1颗红心", 1, {"health": 1}))
	
	_register_item(create_passive_item("battery", "电池", 
		"主动道具充能+1", 1, {"charge": 1}))
	
	_register_item(create_passive_item("coin", "硬币", 
		"加1块钱", 1, {"coins	
	#": 1}))
 === 2星道具（少见） ===
	_register_item(create_passive_item("sack", "爱心袋", 
		"每房间+1红心", 2, {"health_per_room": 1}))
	
	_register_item(create_passive_item("pill", "药丸", 
		"随机效果", 2, {}).with_on_pickup(func(): _use_pill()))
	
	_register_item(create_passive_item("bomb", "炸弹", 
		"+1炸弹", 2, {"bombs": 1}))
	
	_register_item(create_active_item("card", "卡牌", 
		"随机Tarot效果", 2, 2).with_on_use(func(): _use_tarot_card()))
	
	_register_item(create_stat_item("magic_mushroom", "魔法蘑菇", 
		"伤害+10%, 射程+10%", 2, {"damage": 0.1, "range": 10}))
	
	_register_item(create_stat_item("compass", "指南针", 
		"显示地图房", 2, {}))
	
	# === 3星道具（稀有） ===
	_register_item(create_stat_item("d6", "D6",
		"充能后重置房间道具", 3, {"reroll": true}).with_on_use(
		func(): reroll_room_items()))
	
	_register_item(create_stat_item("tech_x", "-tech X-",
		"科技道具，发射环形激光", 4, {"laser": true}).with_on_fire(
		func(bullet): bullet.set_meta("laser_type", "ring"))
	
	_register_item(create_stat_item("spoon_bender", "弯曲勺子",
		"眼泪带追踪", 3, {"homing": true}))
	
	_register_item(create_stat_item("dead_cat", "死猫",
		"+9条命（复活9次）", 5, {"extra_lives": 9}))
	
	_register_item(create_passive_item("gamekid", "游戏机",
		"受伤时有概率无敌并伤害敌人", 3, {"invincible_chance": 0.1}))
	
	# === 4星道具（罕见） ===
	_register_item(create_stat_item("s Brimstone", "硫磺火",
		"发射血激光", 4, {"brimstone": true}))
	
	_register_item(create_stat_item("maw_of_void", "虚空之口",
		"充能后吞噬房内所有敌人", 5, {"devour": true}))
	
	_register_item(create_stat_item("crow_god", "乌鸦之神",
		"飞行+追踪眼泪", 4, {"flight": true, "homing": true}))
	
	_register_item(create_stat_item("stopwatch", "秒表",
		"敌人减速50%", 4, {"enemy_slow": 0.5}))

func _register_item(item: IsaacItem):
	all_items[item.id] = item

func create_stat_item(id: String, name: String, desc: String, rarity: int, bonuses: Dictionary) -> IsaacItem:
	var item = IsaacItem.new(id, name, desc, ItemType.STAT)
	item.rarity = rarity
	item.stat_bonuses = bonuses
	return item

func create_passive_item(id: String, name: String, desc: String, rarity: int, bonuses: Dictionary) -> IsaacItem:
	var item = IsaacItem.new(id, name, desc, ItemType.PASSIVE)
	item.rarity = rarity
	item.stat_bonuses = bonuses
	return item

func create_active_item(id: String, name: String, desc: String, rarity: int, max_charge: int) -> IsaacItem:
	var item = IsaacItem.new(id, name, desc, ItemType.ACTIVE)
	item.rarity = rarity
	item.max_stack = max_charge
	return item

# 效果函数
func _use_pill():
	print("使用药丸，随机效果...")

func _use_tarot_card():
	print("使用Tarot卡牌...")

func reroll_room_items():
	print("重置房间道具...")

# 获取随机道具（根据稀有度权重）
func get_random_item() -> IsaacItem:
	var items_by_rarity: Dictionary = {1: [], 2: [], 3: [], 4: [], 5: []}
	
	for id in all_items:
		var item = all_items[id]
		items_by_rarity[item.rarity].append(item)
	
	# 根据稀有度权重选择
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
		return items_by_rarity[selected_rarity].pick_random()
	
	return items_by_rarity[1].pick_random()
