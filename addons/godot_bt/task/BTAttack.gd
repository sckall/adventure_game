extends BTTask

@export var damage: float = 1.0
@export var attack_cooldown: float = 1.0

var last_attack_time: float = 0.0

func _tick(ctx: BTContext) -> BTResult:
	var agent = ctx.get_agent()
	if not is_instance_valid(agent):
		return BTResult.FAILURE
	
	var player = ctx.blackboard.get_value("player")
	if not is_instance_valid(player):
		return BTResult.FAILURE
	
	var distance = agent.global_position.distance_to(player.global_position)
	
	if distance > 60:
		return BTResult.FAILURE  # Too far to attack
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_time < attack_cooldown:
		return BTResult.RUNNING  # On cooldown
	
	# Perform attack
	last_attack_time = current_time
	
	if player.has_method("take_damage"):
		var knockback = Vector2(player.global_position - agent.global_position).normalized() * 30
		player.take_damage(int(damage), knockback)
	
	# Play attack animation
	if agent.has_method("play_attack"):
		agent.play_attack()
	
	return BTResult.SUCCESS
