extends BehaviorTree

# 蜘蛛 - 可能在墙壁上，从上方攻击

@export var detect_range: float = 300.0
@export var chase_speed: float = 100.0
@export var ambush_range: float = 150.0  # 伏击范围

func _ready():
	_build_spider_behavior()

func _build_spider_behavior():
	var root = BTSequence.new()
	root.name = "SpiderAI"
	
	# 条件: 检测到玩家
	var detect = BTPlayerInRange.new()
	detect.name = "DetectPlayer"
	detect.detect_range = detect_range
	
	# 追逐
	var chase = BTChase.new()
	chase.name = "Chase"
	chase.speed = chase_speed
	chase.stop_distance = 50.0
	
	# 攻击
	var attack = BTAttack.new()
	attack.name = "Bite"
	attack.damage = 1.0
	attack.attack_cooldown = 1.2
	
	# 空闲时等待
	var idle = BTWaitIdle.new()
	idle.name = "WaitForPrey"
	idle.min_time = 2.0
	idle.max_time = 4.0
	
	# 使用Selector根节点
	var selector = BTSelector.new()
	selector.name = "SpiderSelector"
	selector.add_child(root)
	selector.add_child(idle)
	
	add_child(selector)

func _tick(ctx: BTContext, delta: float):
	tick(ctx, delta)
