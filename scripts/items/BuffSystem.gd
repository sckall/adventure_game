extends Node

# ============ Shattered Pixel Dungeon 风格 Buff 系统 ============

class_name BuffSystem

# Buff类型
enum BuffType {
	NONE,
	POISON,         # 中毒
	VENOM,          # 剧毒
	FIRE,           # 燃烧
	WEAKNESS,       # 虚弱
	STUN,           # 眩晕
	PARALYSIS,      # 麻痹
	BLEEDING,       # 流血
	BLINDNESS,      # 失明
	SLOW,           # 减速
	HASTE,          # 加速
	REGENERATION,   # 回复
	SHIELD,         # 护盾
	INVISIBILITY,   # 隐身
	VULNERABILITY,  # 易伤
	AMOK,           # 狂暴
	TERROR,         # 恐惧
	FROST,          # 冰冻
	DRAGON_BLOOD    # 龙血（增益）
}

# Buff数据类
class BuffData:
	var type: BuffType = BuffType.NONE
	var duration: float = 0.0
	var remaining: float = 0.0
	var source: Node = null
	var stackable: bool = false
	var max_stacks: int = 1
	var current_stacks: int = 1
	
	# 效果值（如伤害/防御）
	var effect_value: float = 0.0
	
	func _init(_type: BuffType, _duration: float, _effect: float = 0.0):
		type = _type
		duration = _duration
		remaining = _duration
		effect_value = _effect

# Buff效果处理
class_name BuffEffect extends Node

# 应用Buff
static func apply(target: Node, buff: BuffData) -> void:
	if not target.has_method("add_buff"):
		return
	
	target.add_buff(buff)

# 创建Buff
static func create(type: BuffType, duration: float, effect: float = 0.0, source: Node = null) -> BuffData:
	return BuffData.new(type, duration, effect)

# ============ 特定Buff效果 ============

# 中毒 - 每秒造成伤害
static func poison(target: Node, duration: float, dps: float) -> BuffData:
	var buff = BuffData.new(BuffType.POISON, duration, dps)
	buff.stackable = true
	buff.max_stacks = 5
	return buff

# 剧毒 - 更强中毒
static func venom(target: Node, duration: float, dps: float) -> BuffData:
	var buff = BuffData.new(BuffType.VENOM, duration, dps)
	buff.stackable = true
	buff.max_stacks = 3
	return buff

# 燃烧 - 持续火焰伤害
static func burning(target: Node, duration: float, dps: float) -> BuffData:
	var buff = BuffData.new(BuffType.FIRE, duration, dps)
	buff.stackable = true
	buff.max_stacks = 3
	return buff

# 虚弱 - 减少攻击力
static func weakness(target: Node, duration: float, reduction: float = 0.5) -> BuffData:
	var buff = BuffData.new(BuffType.WEAKNESS, duration, reduction)
	return buff

# 眩晕 - 无法行动
static func stun(target: Node, duration: float) -> BuffData:
	return BuffData.new(BuffType.STUN, duration)

# 减速 - 移动变慢
static func slow(target: Node, duration: float, speed_mult: float = 0.5) -> BuffData:
	var buff = BuffData.new(BuffType.SLOW, duration, speed_mult)
	return buff

# 加速 - 移动变快
static func haste(target: Node, duration: float, speed_mult: float = 1.5) -> BuffData:
	var buff = BuffData.new(BuffType.HASTE, duration, speed_mult)
	return buff

# 护盾 - 吸收伤害
static func shield(target: Node, duration: float, amount: float) -> BuffData:
	var buff = BuffData.new(BuffType.SHIELD, duration, amount)
	return buff

# 回复 - 持续回血
static func regeneration(target: Node, duration: float, hps: float) -> BuffData:
	var buff = BuffData.new(BuffType.REGENERATION, duration, hps)
	return buff

# 隐身 - 敌人看不到
static func invisibility(target: Node, duration: float) -> BuffData:
	return BuffData.new(BuffType.INVISIBILITY, duration)

# 失明 - 无法攻击
static func blindness(target: Node, duration: float) -> BuffData:
	return BuffData.new(BuffType.BLINDNESS, duration)

# 流血 - 移动时造成伤害
static func bleeding(target: Node, duration: float, damage_per_step: float) -> BuffData:
	var buff = BuffData.new(BuffType.BLEEDING, duration, damage_per_step)
	buff.stackable = true
	buff.max_stacks = 3
	return buff

# 易伤 - 受到的伤害增加
static func vulnerability(target: Node, duration: float, multiplier: float = 1.5) -> BuffData:
	var buff = BuffData.new(BuffType.VULNERABILITY, duration, multiplier)
	return buff

# 恐惧 - 逃跑
static func terror(target: Node, duration: float) -> BuffData:
	return BuffData.new(BuffType.TERROR, duration)

# 冰冻 - 无法移动
static func frost(target: Node, duration: float) -> BuffData:
	return BuffData.new(BuffType.FROST, duration)

# 龙血 - 全属性增强
static func dragon_blood(target: Node, duration: float, bonus: float = 0.2) -> BuffData:
	var buff = BuffData.new(BuffType.DRAGON_BLOOD, duration, bonus)
	return buff

# ============ Buff管理器 ============
class_name BuffManager extends Node

var target: Node
var buffs: Array[BuffData] = []

func _init(_target: Node):
	target = _target

func add_buff(buff: BuffData) -> void:
	# 检查是否可叠加
	if buff.stackable:
		var existing = _find_buff(buff.type)
		if existing:
			existing.current_stacks = min(existing.current_stacks + 1, buff.max_stacks)
			existing.remaining = buff.duration
			return
	
	buff.current_stacks = 1
	buffs.append(buff)
	_on_buff_added(buff)

func remove_buff(type: BuffType) -> void:
	var buff = _find_buff(type)
	if buff:
		buffs.erase(buff)
		_on_buff_removed(buff)

func has_buff(type: BuffType) -> bool:
	return _find_buff(type) != null

func get_buff(type: BuffType) -> BuffData:
	return _find_buff(type)

func _find_buff(type: BuffType) -> BuffData:
	for buff in buffs:
		if buff.type == type:
			return buff
	return null

func process(delta: float) -> void:
	var to_remove = []
	
	for buff in buffs:
		buff.remaining -= delta
		
		# 处理持续效果
		_process_effect(buff, delta)
		
		# 时间到，移除
		if buff.remaining <= 0:
			to_remove.append(buff)
	
	for buff in to_remove:
		buffs.erase(buff)
		_on_buff_removed(buff)

func _process_effect(buff: BuffData, delta: float) -> void:
	var stacks = buff.current_stacks if buff.stackable else 1
	var effect = buff.effect_value * stacks
	
	match buff.type:
		BuffType.POISON, BuffType.VENOM, BuffType.FIRE:
			# 造成伤害
			if target.has_method("take_damage"):
				target.take_damage(int(effect * delta), Vector2.ZERO)
		
		BuffType.REGENERATION:
			# 回复生命
			if target.has_method("heal"):
				target.heal(effect * delta)
		
		BuffType.SHIELD:
			# 护盾逻辑在受伤时处理
			pass

func _on_buff_added(buff: BuffData) -> void:
	# 应用视觉/动画效果
	match buff.type:
		BuffType.STUN, BuffType.FROST:
			if target.has_method("play_stun"):
				target.play_stun()
		BuffType.POISON:
			if target.has_method("play_poison"):
				target.play_poison()
		BuffType.FIRE:
			if target.has_method("play_burn"):
				target.play_burn()

func _on_buff_removed(buff: BuffData) -> void:
	# 移除视觉效果
	match buff.type:
		BuffType.STUN, BuffType.FROST:
			if target.has_method("stop_stun"):
				target.stop_stun()

# 获取所有活跃Buff的描述
func get_buff_descriptions() -> Array[String]:
	var descriptions = []
	for buff in buffs:
		descriptions.append(_get_buff_description(buff))
	return descriptions

func _get_buff_description(buff: BuffData) -> String:
	var stacks = ""
	if buff.stackable and buff.current_stacks > 1:
		stacks = " x%d" % buff.current_stacks
	
	match buff.type:
		BuffType.POISON: return "中毒" + stacks + " (%.1f DPS)" % buff.effect_value
		BuffType.VENOM: return "剧毒" + stacks + " (%.1f DPS)" % buff.effect_value
		BuffType.FIRE: return "燃烧" + stacks + " (%.1f DPS)" % buff.effect_value
		BuffType.STUN: return "眩晕"
		BuffType.SLOW: return "减速 %.0f%%" % [(1.0 - buff.effect_value) * 100]
		BuffType.HASTE: return "加速 %.0f%%" % [(buff.effect_value - 1.0) * 100]
		BuffType.SHIELD: return "护盾 %.0f" % buff.effect_value
		BuffType.REGENERATION: return "回复 %.1f HP/s" % buff.effect_value
		BuffType.INVISIBILITY: return "隐身"
		BuffType.BLEEDING: return "流血" + stacks
		BuffType.VULNERABILITY: return "易伤 +%.0f%%" % [(buff.effect_value - 1.0) * 100]
		BuffType.FROST: return "冰冻"
		BuffType.DRAGON_BLOOD: return "龙血 +%.0f%%" % [buff.effect_value * 100]
	
	return ""
