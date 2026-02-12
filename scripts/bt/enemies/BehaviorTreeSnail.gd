extends BehaviorTree

# 蜗牛 - 移动缓慢，主要巡逻，偶尔检查玩家

@export var detect_range: float = 200.0
@export var patrol_speed: float = 30.0  # 很慢
@export var chase_speed: float = 25.0

func _ready():
	_build_snail_behavior()

func _build_snail_behavior():
	var root = BTSelector.new()
	root.name = "SnailAI"
	
	# 检测到玩家才追逐
	var chase_seq = BTSequence.new()
	chase_seq.name = "ResponseToPlayer"
	
	var detect = BTPlayerInRange.new()
	detect.name = "DetectPlayer"
	detect.detect_range = detect_range
	
	var chase = BTChase.new()
	chase.name = "SlowChase"
	chase.speed = chase_speed
	chase.stop_distance = 40.0
	
	chase_seq.add_child(detect)
	chase_seq.add_child(chase)
	
	# 主要行为: 悠闲巡逻
	var patrol = BTPatrol.new()
	patrol.name = "Patrol"
	patrol.speed = patrol_speed
	
	var wait = BTWaitIdle.new()
	wait.name = "Rest"
	wait.min_time = 3.0  # 休息时间长
	wait.max_time = 5.0
	
	var patrol_seq = BTSequence.new()
	patrol_seq.add_child(patrol)
	patrol_seq.add_child(wait)
	
	root.add_child(chase_seq)
	root.add_child(patrol_seq)
	
	add_child(root)

func _tick(ctx: BTContext, delta: float):
	tick(ctx, delta)
