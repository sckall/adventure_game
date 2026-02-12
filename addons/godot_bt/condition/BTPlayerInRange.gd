extends BTCondition

@export var detect_range: float = 400.0

func _tick(ctx: BTContext) -> bool:
	var agent = ctx.get_agent()
	if not is_instance_valid(agent):
		return false
	
	var player = ctx.blackboard.get_value("player")
	if not is_instance_valid(player):
		return false
	
	var distance = agent.global_position.distance_to(player.global_position)
	var in_range = distance < detect_range
	
	if in_range:
		ctx.blackboard.set_value("player_detected", true)
	else:
		ctx.blackboard.set_value("player_detected", false)
	
	return in_range
