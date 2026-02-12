extends BTTask

@export var speed: float = 120.0
@export var stop_distance: float = 50.0

func _tick(ctx: BTContext) -> BTResult:
	var agent = ctx.get_agent()
	if not is_instance_valid(agent):
		return BTResult.FAILURE
	
	var player = ctx.blackboard.get_value("player")
	if not is_instance_valid(player):
		return BTResult.FAILURE
	
	var direction = (player.global_position - agent.global_position).normalized()
	
	# Stop if close enough to attack
	var distance = agent.global_position.distance_to(player.global_position)
	if distance <= stop_distance:
		agent.velocity = Vector2.ZERO
		return BTResult.SUCCESS
	
	agent.velocity.x = direction.x * speed
	
	# Face the player
	if direction.x > 0:
		agent.scale.x = 1
	else:
		agent.scale.x = -1
	
	return BTResult.RUNNING
