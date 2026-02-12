extends Node

# ============ Shattered Pixel Dungeon 风格武器强化系统 ============

class_name WeaponEnhancement

# 强化等级最大值
const MAX_ENHANCEMENT = 5

# 附魔类型
enum Enchantment {
	NONE,
	SHARP,         # 锋利 - +伤害
	HEAVY,         # 重型 - +伤害
	SWIFT,         # 迅捷 - +攻速
	LUCKY,         # 幸运 - +暴击
	VORPAL,        #  vorpal - 必定暴击
	BLAZING,       # 烈焰 - 火焰伤害
	FROZEN,        # 冰霜 - 冰冻效果
	SHOCKING,      # 雷击 - 闪电伤害
	POISONED,      # 淬毒 - 中毒效果
	VOID,          # 虚空 - 穿透伤害
	SANGUINE       # 血红 - 生命窃取
}

# 诅咒类型
enum Curse {
	NONE,
	FRAGILE,       # 易碎 - 可能断裂
	PUNISHING,     # 惩罚 - 伤害使用者
	DEMONIC,       # 恶魔 - 随机负面效果
	HEAVY,         # 沉重 - 减速
	SHATTERED      # 破碎 - 低耐久
}

# 武器数据
class EnhancedWeapon:
	var base_damage: int = 0
	var base_speed: float = 1.0
	var enhancement_level: int = 0
	var enchantment: Enchantment = Enchantment.NONE
	var curse: Curse = Curse.NONE
	
	# 等级加成
	var damage_bonus: int = 0
	var speed_bonus: float = 0.0
	var accuracy_bonus: float = 0.0
	var crit_bonus: float = 0.0
	
	func get_total_damage() -> int:
		var dmg = base_damage + damage_bonus
		
		# 附魔加成
		match enchantment:
			Enchantment.SHARP, Enchantment.HEAVY:
				dmg += 2 * enhancement_level
			Enchantment.VORPAL:
				if enhancement_level >= 3:
					dmg += 3
		
		return dmg
	
	func get_total_speed() -> float:
		var spd = base_speed + speed_bonus
		
		match enchantment:
			Enchantment.SWIFT:
				spd += 0.1 * enhancement_level
		
		match curse:
			Curse.HEAVY:
				spd -= 0.15
		
		return clamp(spd, 0.3, 3.0)

	func get_crit_chance() -> float:
		var crit = crit_bonus
		
		match enchantment:
			Enchantment.LUCKY:
				crit += 0.05 * enhancement_level
			Enchantment.VORPAL:
				crit += 0.1 * enhancement_level
		
		return clamp(crit, 0.0, 1.0)

# 附魔描述
static func get_enchantment_name(enchant: Enchantment) -> String:
	match enchant:
		Enchantment.SHARP: return "锋利"
		Enchantment.HEAVY: return "重型"
		Enchantment.SWIFT: return "迅捷"
		Enchantment.LUCKY: return "幸运"
		Enchantment.VORPAL: return "致命"
		Enchantment.BLAZING: return "烈焰"
		Enchantment.FROZEN: return "冰霜"
		Enchantment.SHOCKING: return "雷击"
		Enchantment.POISONED: return "淬毒"
		Enchantment.VOID: return "虚空"
		Enchantment.SANGUINE: return "血红"
		_: return ""

static func get_enchantment_description(enchant: Enchantment) -> String:
	match enchant:
		Enchantment.SHARP: return "增加伤害"
		Enchantment.HEAVY: return "高伤害，慢攻速"
		Enchantment.SWIFT: return "提升攻击速度"
		Enchantment.LUCKY: return "暴击率提升"
		Enchantment.VORPAL: return "高暴击率"
		Enchantment.BLAZING: return "附加火焰伤害"
		Enchantment.FROZEN: return "可能冻结敌人"
		Enchantment.SHOCKING: return "附加闪电伤害"
		Enchantment.POISONED: return "附加中毒效果"
		Enchantment.VOID: return "穿透敌人护甲"
		Enchantment.SANGUINE: return "攻击回复生命"
		_: return ""

static func get_curse_name(curse: Curse) -> String:
	match curse:
		Curse.FRAGILE: return "易碎"
		Curse.PUNISHING: return "惩罚"
		Curse.DEMONIC: return "恶魔"
		Curse.HEAVY: return "沉重"
		Curse.SHATTERED: return "破碎"
		_: return ""

static func get_curse_description(curse: Curse) -> String:
	match curse:
		Curse.FRAGILE: return "有几率在攻击时损坏"
		Curse.PUNISHING: return "使用时可能受伤"
		Curse.DEMONIC: return "随机负面效果"
		Curse.HEAVY: return "降低攻击速度"
		Curse.SHATTERED: return "耐久度降低"
		_: return ""

# ============ 强化逻辑 ============

# 应用强化到武器
static func apply_enhancement(weapon: Dictionary, level: int) -> Dictionary:
	if level < 0 or level > MAX_ENHANCEMENT:
		return weapon
	
	weapon["enhancement_level"] = level
	
	# 等级加成计算
	if level > 0:
		weapon["damage_bonus"] = level * 2
		weapon["accuracy_bonus"] = level * 0.05
		weapon["crit_bonus"] = level * 0.02
	
	return weapon

# 尝试添加附魔
static func try_add_enchantment(weapon: Dictionary, ench: Enchantment) -> Dictionary:
	var roll = randf()
	var success_chance = 0.3  # 30%基础成功率
	
	# 卷轴/附魔物品提升成功率
	if weapon.has("enchant_chance_bonus"):
		success_chance += weapon["enchant_chance_bonus"]
	
	if roll < success_chance:
		weapon["enchantment"] = ench
		_apply_enchant_effects(weapon, ench)
	else:
		# 失败可能导致诅咒
		if randf() < 0.3:
			weapon["curse"] = _random_curse()
	
	return weapon

func _apply_enchant_effects(weapon: Dictionary, ench: Enchantment) -> void:
	match ench:
		Enchantment.SHARP:
			weapon["damage_bonus"] = weapon.get("damage_bonus", 0) + 2
		Enchantment.HEAVY:
			weapon["damage_bonus"] = weapon.get("damage_bonus", 0) + 4
			weapon["speed_bonus"] = weapon.get("speed_bonus", 0) - 0.1
		Enchantment.SWIFT:
			weapon["speed_bonus"] = weapon.get("speed_bonus", 0) + 0.15
		Enchantment.LUCKY:
			weapon["crit_bonus"] = weapon.get("crit_bonus", 0) + 0.1
		Enchantment.VORPAL:
			weapon["crit_bonus"] = weapon.get("crit_bonus", 0) + 0.2
		Enchantment.BLAZING:
			weapon["fire_damage"] = weapon.get("damage", 1) * 0.3
		Enchantment.FROZEN:
			weapon["freeze_chance"] = 0.3
		Enchantment.SHOCKING:
			weapon["lightning_damage"] = weapon.get("damage", 1) * 0.25
		Enchantment.POISONED:
			weapon["poison_damage"] = 2.0
		Enchantment.VOID:
			weapon["armor_piercing"] = 0.5
		Enchantment.SANGUINE:
			weapon["lifesteal"] = 0.1

func _random_curse() -> Curse:
	var curses = [Curse.FRAGILE, Curse.PUNISHING, Curse.DEMONIC, Curse.HEAVY]
	return curses.pick_random()

# 升级武器
static func upgrade_weapon(weapon: Dictionary) -> Dictionary:
	var current_level = weapon.get("enhancement_level", 0)
	
	if current_level >= MAX_ENHANCEMENT:
		return weapon  # 已满级
	
	# 升级成功率
	var success_rate = 0.8 - current_level * 0.1  # 80%, 70%, 60%, 50%, 40%
	if randf() < success_rate:
		weapon["enhancement_level"] = current_level + 1
		_apply_enchant_effects(weapon, Enchantment.NONE)
	else:
		# 升级失败 - 可能降级或损坏
		if randf() < 0.3:
			weapon["enhancement_level"] = max(0, current_level - 1)
		# 有几率触发诅咒
		if randf() < 0.2:
			weapon["curse"] = _random_curse()
	
	return weapon

# 移除附魔/诅咒
static func remove_enchantment(weapon: Dictionary) -> Dictionary:
	weapon.erase("enchantment")
	weapon.erase("curse")
	return weapon

# 计算武器属性
static func calculate_weapon_stats(weapon: Dictionary) -> Dictionary:
	var stats = {
		"damage": weapon.get("base_damage", 1),
		"speed": weapon.get("base_speed", 1.0),
		"crit_chance": weapon.get("base_crit", 0.05),
		"enchantment": weapon.get("enchantment", Enchantment.NONE),
		"curse": weapon.get("curse", Curse.NONE),
		"level": weapon.get("enhancement_level", 0)
	}
	
	# 强化加成
	var level = stats["level"]
	stats["damage"] += level * 2
	stats["crit_chance"] += level * 0.02
	
	# 附魔效果
	match stats["enchantment"]:
		Enchantment.SHARP: stats["damage"] += 3
		Enchantment.HEAVY: stats["damage"] += 5
		Enchantment.SWIFT: stats["speed"] += 0.2
		Enchantment.LUCKY: stats["crit_chance"] += 0.1
		Enchantment.VORPAL: stats["crit_chance"] += 0.2
	
	# 诅咒效果
	match stats["curse"]:
		Curse.HEAVY: stats["speed"] -= 0.2
		Curse.PUNISHING: stats["damage"] -= 2
	
	return stats

# 生成强化描述字符串
static func get_weapon_description(weapon: Dictionary) -> String:
	var stats = calculate_weapon_stats(weapon)
	var desc = ""
	
	# 等级
	if stats["level"] > 0:
		var plus_str = "+" + str(stats["level"])
		desc += "[color=#FFD700]" + plus_str + "[/color] "
	
	# 基础伤害
	desc += "%d 伤害" % stats["damage"]
	
	# 速度
	if stats["speed"] > 1.1:
		desc += " (快速)"
	elif stats["speed"] < 0.9:
		desc += " (慢速)"
	
	# 附魔
	if stats["enchantment"] != Enchantment.NONE:
		var ench_name = get_enchantment_name(stats["enchantment"])
		desc += "\n[color=#9370DB]" + ench_name + "[/color]: "
		desc += get_enchantment_description(stats["enchantment"])
	
	# 诅咒
	if stats["curse"] != Curse.NONE:
		var curse_name = get_curse_name(stats["curse"])
		desc += "\n[color=#8B0000]" + curse_name + "[/color]: "
		desc += get_curse_description(stats["curse"])
	
	return desc

# 附魔列表（用于生成）
static func get_all_enchantments() -> Array[Enchantment]:
	return [
		Enchantment.SHARP,
		Enchantment.HEAVY,
		Enchantment.SWIFT,
		Enchantment.LUCKY,
		Enchantment.VORPAL,
		Enchantment.BLAZING,
		Enchantment.FROZEN,
		Enchantment.SHOCKING,
		Enchantment.POISONED,
		Enchantment.VOID,
		Enchantment.SANGUINE
	]

# 随机附魔（基于等级）
static func random_enchantment(level: int) -> Enchantment:
	var available = []
	
	match level:
		1: available = [Enchantment.SHARP, Enchantment.SWIFT, Enchantment.LUCKY]
		2: available = [Enchantment.SHARP, Enchantment.HEAVY, Enchantment.SWIFT, Enchantment.LUCKY]
		3: available = [Enchantment.VORPAL, Enchantment.BLAZING, Enchantment.SHOCKING]
		4, 5: available = get_all_enchantments()
	
	return available.pick_random()
