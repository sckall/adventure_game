extends Node

# ============ 游戏常量配置 ============
# 集中管理游戏中使用的各种常量

# ============ 技能名称映射 ============
const SKILL_NAMES = {
	"double_jump": "二段跳",
	"wall_climb": "爬墙",
	"dash": "冲刺",
	"float": "浮空",
	"fireball": "火球",
	"ice_spike": "冰冻术",
	"heal": "治疗",
	"shield": "护盾",
	"holy_shield": "圣光护",
	"grapple": "钩锁",
	"slow_arrow": "减速箭",
	"ground_slam": "震地猛击",
	"backstab": "背刺",
	"piercing_shot": "穿透箭",
	"multi_shot": "多重射击"
}

# ============ 关卡名称 ============
const LEVEL_NAMES = {
	1: "草原",
	2: "森林",
	3: "山地",
	4: "洞穴",
	5: "城堡"
}

# ============ 角色等级评级 ============
const RANK_S_THRESHOLD_SPEED = 300
const RANK_A_THRESHOLD_SPEED = 280
const RANK_S_THRESHOLD_JUMP = 700
const RANK_A_THRESHOLD_JUMP = 650

# ============ 物品颜色 ============
const MUSHROOM_COLORS = {
	"red": Color(1.0, 0.35, 0.35),
	"green": Color(0.25, 0.85, 0.35),
	"blue": Color(0.25, 0.55, 1.0),
	"brown": Color(0.7, 0.5, 0.25),
	"purple": Color(0.85, 0.4, 0.95)
}

const SLIME_COLORS = {
	"green": Color(0.35, 0.85, 0.4),
	"blue": Color(0.35, 0.6, 0.95),
	"pink": Color(0.95, 0.6, 0.8),
	"yellow": Color(1.0, 0.95, 0.35),
	"orange": Color(1.0, 0.65, 0.25),
	"cyan": Color(0.35, 0.85, 0.85),
	"purple": Color(0.8, 0.45, 0.9),
	"gray": Color(0.65, 0.65, 0.65),
	"red": Color(0.95, 0.35, 0.35)
}

# ============ 平台颜色 ============
const PLATFORM_GRASS_TOP = Color(0.28, 0.55, 0.25)
const PLATFORM_GRASS_BODY = Color(0.35, 0.45, 0.25)
const PLATFORM_DIRT = Color(0.45, 0.38, 0.28)

# ============ 出口门颜色 ============
const EXIT_MAIN = Color(1.0, 0.85, 0.2)
const EXIT_GLOW = Color(1.0, 0.95, 0.4, 0.6)
const EXIT_CORE = Color(1, 0.95, 0.7, 0.9)

# ============ 瓶子颜色 ============
const BOTTLE_GREEN = Color(0.3, 0.85, 0.35)
const BOTTLE_GREEN_GLOW = Color(0.3, 0.85, 0.35, 0.4)
const BOTTLE_YELLOW = Color(1.0, 0.85, 0.2)
const BOTTLE_YELLOW_GLOW = Color(1.0, 0.85, 0.2, 0.4)

# ============ 升级配置 ============
const UPGRADE_MAX_LEVEL = 5
const UPGRADE_PRICES = {
	"hp": [0, 50, 100, 200, 400, 800],
	"speed": [0, 40, 80, 160, 320, 640],
	"jump": [0, 40, 80, 160, 320, 640],
	"damage": [0, 60, 120, 240, 480, 960]
}

const UPGRADE_EFFECTS = {
	"hp": [0, 1, 2, 3, 4, 5],
	"speed": [0, 10, 20, 30, 40, 50],
	"jump": [0, 30, 60, 90, 120, 150],
	"damage": [0, 0.5, 1, 1.5, 2, 2.5]
}

# ============ 辅助函数 ============

# 获取技能显示名称
static func get_skill_name(skill_id: String) -> String:
	return SKILL_NAMES.get(skill_id, skill_id)

# 获取关卡名称
static func get_level_name(level_num: int) -> String:
	return LEVEL_NAMES.get(level_num, "未知")

# 获取蘑菇颜色
static func get_mushroom_color(color_name: String) -> Color:
	return MUSHROOM_COLORS.get(color_name, Color.WHITE)

# 获取史莱姆颜色
static func get_slime_color(color_name: String) -> Color:
	return SLIME_COLORS.get(color_name, Color(0.35, 0.85, 0.4))

# 获取速度等级
static func get_speed_rank(speed: float) -> Dictionary:
	if speed >= RANK_S_THRESHOLD_SPEED:
		return {"rank": "S", "color": Color(1, 0.8, 0.2, 1)}
	elif speed >= RANK_A_THRESHOLD_SPEED:
		return {"rank": "A", "color": Color(0.3, 0.8, 0.3, 1)}
	else:
		return {"rank": "C", "color": Color(0.6, 0.6, 0.6, 1)}

# 获取跳跃等级
static func get_jump_rank(jump_force: float) -> Dictionary:
	var abs_jump = abs(jump_force)
	if abs_jump >= RANK_S_THRESHOLD_JUMP:
		return {"rank": "S", "color": Color(1, 0.8, 0.2, 1)}
	elif abs_jump >= RANK_A_THRESHOLD_JUMP:
		return {"rank": "A", "color": Color(0.3, 0.8, 0.3, 1)}
	else:
		return {"rank": "C", "color": Color(0.6, 0.6, 0.6, 1)}
