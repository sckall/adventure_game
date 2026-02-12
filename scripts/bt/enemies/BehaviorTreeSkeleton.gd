extends BehaviorTree

# 骷髅战士 - 近战敌人，会主动寻找玩家

@export var detect_range: float = 500.0  # 感知范围大
@export var chase_speed: float = 90.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 2.0

func _ready():
	_build_skeleton_behavior()

func _build_skeleton_behavior():
	var root = BTSelector.new()
	root.name = "SkeletonAI"
	
	# 追逐攻击序列
	var combat_seq = BTSequence.new()
	combat_seq.name = "Combat"
	
	# 检测玩家
	var detect = BTPlayerInRange.new()
	detect.name = "DetectPlayer"
	detect.detect_range = detect_range
	
	# 追逐
	var chase = BTChase.new()
	chase.name = "ChasePlayer"
	chase.speed = chase_speed
	chase.stop_distance = attack_range
	
	# 攻击
	var attack = BTAttack.new()
	attack.name = "MeleeAttack"
	attack.damage = 2.0  # 骷髅伤害高
	attack.attack_cooldown = attack_cooldown
	
	combat_seq.add_child(detect)
	combat_seq.add_child(chase)
	combat_seq.add_child(attack)
	
	# 空闲待机
	var idle = BTWaitIdle.new()
	idle.name = "Idle"
	idle.min_time = 1.0
	idle.max_time = 3.0
	
	root.add_child(combat_seq)
	root.add_child(idle)
	
	add_child(root)

func _tick(ctx: BTContext, delta: float):
	tick(ctx, delta)
