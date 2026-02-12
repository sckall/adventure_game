extends BehaviorTree

@export var detect_range: float = 300.0
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 80.0
@export var patrol_wait_time: float = 2.0

func _ready():
	_build_hedgehog_behavior()

func _build_hedgehog_behavior():
	var root = BTSelector.new()
	root.name = "HedgehogAI"
	
	# 高优先级: 追逐并攻击玩家
	var chase_seq = BTSequence.new()
	chase_seq.name = "ChaseAndAttack"
	
	var detect = BTPlayerInRange.new()
	detect.name = "PlayerDetected"
	detect.detect_range = detect_range
	
	var chase = BTChase.new()
	chase.name = "Chase"
	chase.speed = chase_speed
	chase.stop_distance = 70.0  # 保持一定距离
	
	var attack = BTAttack.new()
	attack.name = "Attack"
	attack.damage = 1.0
	attack.attack_cooldown = 1.5
	
	chase_seq.add_child(detect)
	chase_seq.add_child(chase)
	chase_seq.add_child(attack)
	
	# 低优先级: 巡逻
	var patrol = BTPatrol.new()
	patrol.name = "Patrol"
	patrol.speed = patrol_speed
	
	var wait = BTWaitIdle.new()
	wait.name = "Rest"
	wait.min_time = patrol_wait_time
	wait.max_time = patrol_wait_time * 2
	
	var patrol_seq = BTSequence.new()
	patrol_seq.name = "PatrolSequence"
	patrol_seq.add_child(patrol)
	patrol_seq.add_child(wait)
	
	root.add_child(chase_seq)
	root.add_child(patrol_seq)
	
	add_child(root)

func _tick(ctx: BTContext, delta: float):
	tick(ctx, delta)
