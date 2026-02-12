extends BehaviorTree

@export var detect_range: float = 400.0
@export var attack_range: float = 60.0
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 100.0

func _ready():
	# Create the behavior tree structure
	_build_slime_behavior()

func _build_slime_behavior():
	var selector = BTSelector.new()
	selector.name = "SlimeAI"
	
	# Sequence: Check if player detected → Chase → Attack
	var chase_sequence = BTSequence.new()
	chase_sequence.name = "ChaseSequence"
	
	var player_detected = BTPlayerInRange.new()
	player_detected.name = "PlayerDetected"
	player_detected.detect_range = detect_range
	
	var chase = BTChase.new()
	chase.name = "Chase"
	chase.speed = chase_speed
	
	var attack = BTAttack.new()
	attack.name = "Attack"
	attack.attack_cooldown = 1.0
	
	chase_sequence.add_child(player_detected)
	chase_sequence.add_child(chase)
	chase_sequence.add_child(attack)
	
	# Idle/Wait when no player
	var wait_idle = BTWaitIdle.new()
	wait_idle.name = "Idle"
	wait_idle.min_time = 2.0
	wait_idle.max_time = 4.0
	
	selector.add_child(chase_sequence)
	selector.add_child(wait_idle)
	
	add_child(selector)

func _tick(ctx: BTContext, delta: float) -> void:
	tick(ctx, delta)
