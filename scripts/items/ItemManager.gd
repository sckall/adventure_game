extends Node

# ============ Shattered Pixel Dungeon 风格综合道具管理器 ============
# 整合：生成器、Buff系统、强化系统

class_name ItemManager

# 单例引用
var generator: ItemGenerator
var buff_system: BuffSystem
var enhancement: WeaponEnhancement

# 玩家引用
var player: Node = null

func _init():
	generator = ItemGenerator.new()
	buff_system = BuffSystem.new()

func setup_player(p: Node):
	player = p

# ============ 道具生成快捷方法 ============

# 生成随机武器
func spawn_weapon(level: int = 1) -> Dictionary:
	return generator.random_item(level, ItemGenerator.Category.WEAPON)

# 生成随机护甲
func spawn_armor(level: int = 1) -> Dictionary:
	return generator.random_item(level, ItemGenerator.Category.ARMOR)

# 生成随机法杖
func spawn_wand(level: int = 1) -> Dictionary:
	return generator.random_item(level, ItemGenerator.Category.WAND)

# 生成随机戒指
func spawn_ring(level: int = 1) -> Dictionary:
	return generator.random_item(level, ItemGenerator.Category.RING)

# 生成随机神器
func spawn_artifact(level: int = 1) -> Dictionary:
	return generator.random_item(level, ItemGenerator.Category.ARTIFACT)

# 生成随机卷轴
func spawn_scroll(level: int = 1) -> Dictionary:
	return generator.random_item(level, ItemGenerator.Category.SCROLL)

# 生成随机药水
func spawn_potion(level: int = 1) -> Dictionary:
	return generator.random_item(level, ItemGenerator.Category.POTION)

# 生成随机食物
func spawn_food() -> Dictionary:
	return generator.random_item(1, ItemGenerator.Category.FOOD)

# 生成随机炸弹
func spawn_bomb(level: int = 1) -> Dictionary:
	return generator.random_item(level, ItemGenerator.Category.BOMB)

# 生成随机饰品
func spawn_trinket(level: int = 1) -> Dictionary:
	return generator.random_item(level, ItemGenerator.Category.TRINKET)

# 生成房间掉落
func spawn_room_drops(floor_level: int, room_type: String = "normal") -> Array:
	return generator.generate_drops(floor_level, room_type)

# ============ Buff快捷方法 ============

# 给目标添加中毒
func add_poison(target: Node, duration: float = 5.0, dps: float = 2.0):
	BuffEffect.apply(target, BuffEffect.poison(target, duration, dps))

# 给目标添加燃烧
func add_burning(target: Node, duration: float = 4.0, dps: float = 3.0):
	BuffEffect.apply(target, BuffEffect.burning(target, duration, dps))

# 给目标添加虚弱
func add_weakness(target: Node, duration: float = 8.0, reduction: float = 0.5):
	BuffEffect.apply(target, BuffEffect.weakness(target, duration, reduction))

# 给目标添加眩晕
func add_stun(target: Node, duration: float = 1.5):
	BuffEffect.apply(target, BuffEffect.stun(target, duration))

# 给目标添加减速
func add_slow(target: Node, duration: float = 3.0, speed_mult: float = 0.5):
	BuffEffect.apply(target, BuffEffect.slow(target, duration, speed_mult))

# 给目标添加加速
func add_haste(target: Node, duration: float = 3.0, speed_mult: float = 1.5):
	BuffEffect.apply(target, BuffEffect.haste(target, duration, speed_mult))

# 给目标添加护盾
func add_shield(target: Node, duration: float = 5.0, amount: float = 10.0):
	BuffEffect.apply(target, BuffEffect.shield(target, duration, amount))

# 给目标添加回复
func add_regeneration(target: Node, duration: float = 5.0, hps: float = 1.0):
	BuffEffect.apply(target, BuffEffect.regeneration(target, duration, hps))

# 给目标添加隐身
func add_invisibility(target: Node, duration: float = 3.0):
	BuffEffect.apply(target, BuffEffect.invisibility(target, duration))

# 给目标添加易伤
func add_vulnerability(target: Node, duration: float = 5.0, multiplier: float = 1.5):
	BuffEffect.apply(target, BuffEffect.vulnerability(target, duration, multiplier))

# 给目标添加冰冻
func add_frost(target: Node, duration: float = 2.0):
	BuffEffect.apply(target, BuffEffect.frost(target, duration))

# ============ 武器强化快捷方法 ============

# 创建强化武器
func create_enhanced_weapon(base_damage: int, base_speed: float = 1.0) -> Dictionary:
	var weapon = {
		"base_damage": base_damage,
		"base_speed": base_speed,
		"base_crit": 0.05,
		"enhancement_level": 0,
		"enchantment": WeaponEnhancement.Enchantment.NONE,
		"curse": WeaponEnhancement.Curse.NONE,
		"damage_bonus": 0,
		"speed_bonus": 0.0,
		"crit_bonus": 0.0
	}
	return weapon

# 升级武器
func upgrade_weapon(weapon: Dictionary) -> Dictionary:
	return WeaponEnhancement.upgrade_weapon(weapon)

# 添加附魔
func add_enchantment(weapon: Dictionary, ench: int) -> Dictionary:
	return WeaponEnhancement.try_add_enchantment(weapon, ench as WeaponEnhancement.Enchantment)

# 移除附魔/诅咒
func remove_enchantment(weapon: Dictionary) -> Dictionary:
	return WeaponEnhancement.remove_enchantment(weapon)

# 获取武器描述
func get_weapon_description(weapon: Dictionary) -> String:
	return WeaponEnhancement.get_weapon_description(weapon)

# ============ 道具效果应用 ============

# 使用卷轴
func use_scroll(scroll: Dictionary, target: Node = null):
	if target == null:
		target = player
	
	match scroll.id:
		"identify":
			# 鉴定 - 显示物品属性
			if player.has_method("show_item_identify"):
				player.show_item_identify()
		"upgrade":
			# 升级 - 随机升级一件装备
			if player.has_method("upgrade_random_item"):
				player.upgrade_random_item()
		"teleport":
			# 传送 - 随机传送
			if player.has_method("random_teleport"):
				player.random_teleport()
		"recharging":
			# 充能 - 回复所有主动道具充能
			if player.has_method("restore_charges"):
				player.restore_charges()
		"mirror_image":
			# 镜像 - 创造一个分身
			if player.has_method("create_mirror"):
				player.create_mirror()
		"rage":
			# 愤怒 - 大幅提升攻击
			add_haste(target, 10.0, 2.0)
			add_strength(target, 5.0)
		"remove_curse":
			# 解除诅咒 - 移除所有诅咒
			if player.has_method("remove_curse"):
				player.remove_curse()
		"magic_mapping":
			# 魔法地图 - 显示附近房间
			if player.has_method("reveal_map"):
				player.reveal_map()

# 使用药水
func use_potion(potion: Dictionary, target: Node = null):
	if target == null:
		target = player
	
	match potion.id:
		"healing":
			# 治疗 - 回复生命
			if player.has_method("heal"):
				player.heal(10 + potion.level * 2)
		"strength":
			# 力量 - 临时力量
			add_strength(target, potion.level * 2)
		"invisibility":
			# 隐身
			add_invisibility(target, 5.0)
		"haste":
			# 加速
			add_haste(target, 5.0, 2.0)
		"mind_vision":
			# 心智视野 - 显示敌人
			if player.has_method("reveal_enemies"):
				player.reveal_enemies(10.0)
		"frost":
			# 冰霜 - 冻结附近敌人
			if player.has_method("freeze_nearby"):
				player.freeze_nearby(3.0)
		"experience":
			# 经验 - 获得经验
			if player.has_method("gain_experience"):
				player.gain_experience(potion.level * 50)
		"levitation":
			# 漂浮 - 免疫地面陷阱
			add_levitation(target, 10.0)

# 吃食物
func eat_food(food: Dictionary):
	match food.id:
		"ration", "meat":
			if player.has_method("heal"):
				player.heal(5)
		"pasty":
			if player.has_method("heal"):
				player.heal(10)

# 投掷炸弹
func throw_bomb(bomb: Dictionary, position: Vector2, direction: Vector2):
	if player.has_method("spawn_bomb"):
		player.spawn_bomb(bomb, position, direction)

# ============ 敌人生成（基于Shattered Pixel） ============

func spawn_enemy(level: int, enemy_type: String = "") -> Dictionary:
	var enemy = {
		"level": level,
		"hp": _calculate_enemy_hp(level),
		"damage": _calculate_enemy_damage(level),
		"defense": _calculate_enemy_defense(level),
		"speed": _get_enemy_speed(enemy_type),
		"type": enemy_type if enemy_type else _random_enemy_type()
	}
	return enemy

func _calculate_enemy_hp(level: int) -> int:
	return 5 + level * 3 + randi_range(0, level)

func _calculate_enemy_damage(level: int) -> int:
	return 1 + level + randi_range(0, level / 2)

func _calculate_enemy_defense(level: int) -> int:
	return level / 2

func _get_enemy_speed(type: String) -> float:
	var speeds = {
		"slime": 1.0,
		"bat": 1.5,
		"skeleton": 0.8,
		"hedgehog": 0.7,
		"snail": 0.5,
		"spider": 1.2,
		"snake": 1.3,
		"boss": 0.9
	}
	return speeds.get(type, 1.0)

func _random_enemy_type() -> String:
	var types = ["slime", "bat", "skeleton", "hedgehog", "snail", "spider", "snake"]
	return types.pick_random()

# ============ 房间生成（简化版） ============

enum RoomType {
	NORMAL,
	TREASURE,
	SHOP,
	BOSS,
	SECRET,
	TRAP
}

func generate_room(room_type: RoomType, floor_level: int) -> Dictionary:
	var room = {
		"type": room_type,
		"level": floor_level,
		"enemies": [],
		"items": [],
		"traps": [],
		"size": _get_room_size(room_type)
	}
	
	# 生成敌人
	var enemy_count = _get_enemy_count(room_type, floor_level)
	for i in range(enemy_count):
		room["enemies"].append(spawn_enemy(floor_level))
	
	# 生成道具
	var item_count = _get_item_count(room_type)
	for i in range(item_count):
		var category = _get_random_category_for_room(room_type)
		room["items"].append(generator.random_item(floor_level, category))
	
	# 生成陷阱（如果有）
	if room_type == RoomType.TRAP or randf() < 0.2:
		room["traps"] = _generate_traps(floor_level)
	
	return room

func _get_room_size(room_type: RoomType) -> Vector2i:
	match room_type:
		RoomType.BOSS: return Vector2i(6, 6)
		RoomType.SHOP: return Vector2i(5, 5)
		RoomType.TREASURE: return Vector2i(3, 3)
		_: return Vector2i(4, 4)

func _get_enemy_count(room_type: RoomType, level: int) -> int:
	match room_type:
		RoomType.BOSS: return 1
		RoomType.SHOP: return 0
		RoomType.TREASURE: return randi_range(0, 1)
		_: return randi_range(1, 2) + level / 3

func _get_item_count(room_type: RoomType) -> int:
	match room_type:
		RoomType.BOSS: return 2
		RoomType.SHOP: return 4
		RoomType.TREASURE: return 3
		RoomType.SECRET: return 2
		_: return randi_range(0, 1)

func _get_random_category_for_room(room_type: RoomType) -> int:
	match room_type:
		RoomType.BOSS: return ItemGenerator.Category.ARTIFACT
		RoomType.SHOP: return ItemGenerator.Category.WEAPON
		RoomType.TREASURE: return ItemGenerator.Category.TRINKET
		_: return ItemGenerator.Category.WEAPON

func _generate_traps(level: int) -> Array:
	var traps = []
	var trap_types = ["fire", "poison", "lightning", "paralysis"]
	
	var count = randi_range(1, 3)
	for i in range(count):
		traps.append({
			"type": trap_types.pick_random(),
			"level": level,
			"damage": _calculate_enemy_damage(level) * 2
		})
	
	return traps
