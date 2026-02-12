extends BehaviorTree

# 蛇 - 快速移动，攻击性强

@export var detect_range: float = 350.0
@export var chase_speed: float = 150.0  # 非常快
@export var attack_cooldown: float = 1.0

func _ready():
	_build_snake_behavior()

func _build_snake_behavior():
	var root = BTSelector.new()
	root.name = "SnakeAI"
	
	# 快速追逐攻击
	var hunt_seq = BTSequence.new()
	hunt_seq.name = "Hunt"
	
	var detect = BTPlayerInRange.new()
	detect.name = "DetectPlayer"
	detect.detect_range = detect_range
	
	var chase = BTFastChase.new()  # 使用快速追逐
	chase.name = "FastChase"
	chase.speed = chase_speed
	chase.stop_distance = 40.0
	
	var attack = BTAttack.new()
	attack.name = "QuickAttack"
	attack.damage = 1.5
	attack.attack_cooldown = attack_cooldown
	
	hunt_seq.add_child(detect)
	hunt_seq.add_child(chase)
	hunt_seq.add_child(attack)
	
	# 巡逻
	var patrol = BTPatrol.new()
	patrol.name = "Patrol"
	patrol.speed = 60.0
	
	var wait = BTWaitIdle.new()
	wait.name = "Rest"
	wait.min_time = 1.0
	wait.max_time = 2.0
	
	root.add_child(hunt_seq)
	root.add_child(patrol)
	root.add_child(wait)
	
	add_child(root)

func _tick(ctx: BTContext, delta: float):
	tick(ctx, delta)
