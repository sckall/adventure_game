extends BehaviorTree

# 蝙蝠 - 飞行敌人，巡逻范围大，发现玩家后快速追击

@export var detect_range: float = 400.0
@export var patrol_speed: float = 70.0
@export var chase_speed: float = 130.0  # 快速

func _ready():
	_build_bat_behavior()

func _build_bat_behavior():
	var root = BTSelector.new()
	root.name = "BatAI"
	
	# 追逐玩家
	var hunt_seq = BTSequence.new()
	hunt_seq.name = "Hunt"
	
	var detect = BTPlayerInRange.new()
	detect.name = "DetectPlayer"
	detect.detect_range = detect_range
	
	var chase = BTChase.new()
	chase.name = "DiveBomb"
	chase.speed = chase_speed
	chase.stop_distance = 30.0  # 靠近攻击
	
	var attack = BTAttack.new()
	attack.name = "DiveAttack"
	attack.damage = 0.5  # 伤害低
	attack.attack_cooldown = 1.5
	
	hunt_seq.add_child(detect)
	hunt_seq.add_child(chase)
	hunt_seq.add_child(attack)
	
	# 巡逻 - 飞行巡逻
	var patrol = BTPatrol.new()
	patrol.name = "FlyPatrol"
	patrol.speed = patrol_speed
	
	var wait = BTWaitIdle.new()
	wait.name = "Hover"
	wait.min_time = 1.0
	wait.max_time = 2.0
	
	root.add_child(hunt_seq)
	root.add_child(patrol)
	root.add_child(wait)
	
	add_child(root)

func _tick(ctx: BTContext, delta: float):
	tick(ctx, delta)
