extends BehaviorTree

# Boss AI - 多阶段战斗AI

@export var detect_range: float = 600.0
@export var chase_speed: float = 80.0
@export var attack_cooldown: float = 3.0
@export var phase_change_health: float = 0.5

var current_phase: int = 1
var attack_count: int = 0

func _ready():
	_build_boss_behavior()

func _build_boss_behavior():
	var root = BTSelector.new()
	root.name = "BossAI"
	
	# 阶段1: 基础攻击循环
	var phase1_seq = BTSequence.new()
	phase1_seq.name = "Phase1"
	
	var detect = BTPlayerInRange.new()
	detect.name = "DetectPlayer"
	detect.detect_range = detect_range
	
	# 随机攻击选择
	var attack_selector = BTRandomSelector.new()
	attack_selector.name = "RandomAttack"
	
	var basic_attack = BTAttack.new()
	basic_attack.name = "BasicAttack"
	basic_attack.damage = 3.0
	basic_attack.attack_cooldown = attack_cooldown
	
	var heavy_attack = BTHeavyAttack.new()
	heavy_attack.name = "HeavyAttack"
	heavy_attack.damage = 5.0
	heavy_attack.attack_cooldown = attack_cooldown * 2
	
	attack_selector.add_child(basic_attack)
	attack_selector.add_child(heavy_attack)
	
	var chase = BTChase.new()
	chase.name = "ChaseToAttack"
	chase.speed = chase_speed
	chase.stop_distance = 100.0
	
	phase1_seq.add_child(detect)
	phase1_seq.add_child(chase)
	phase1_seq.add_child(attack_selector)
	
	# 阶段转换检测
	var phase_check = BTPhaseCheck.new()
	phase_check.name = "PhaseCheck"
	phase_check.threshold = phase_change_health
	
	# 阶段2: 愤怒模式
	var phase2_seq = BTSequence.new()
	phase2_seq.name = "Phase2"
	
	var rage_attack = BTRageAttack.new()
	rage_attack.name = "RageAttack"
	rage_attack.damage = 4.0
	rage_attack.attack_cooldown = 1.5
	
	var fast_chase = BTFastChase.new()
	fast_chase.name = "FastPursuit"
	fast_chase.speed = chase_speed * 1.5
	
	phase2_seq.add_child(phase_check)
	phase2_seq.add_child(fast_chase)
	phase2_seq.add_child(rage_attack)
	
	# 空闲
	var idle = BTWaitIdle.new()
	idle.name = "Idle"
	idle.min_time = 1.0
	idle.max_time = 2.0
	
	root.add_child(phase1_seq)
	root.add_child(phase2_seq)
	root.add_child(idle)
	
	add_child(root)

func _tick(ctx: BTContext, delta: float):
	tick(ctx, delta)
