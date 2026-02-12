extends BTTask

@export var speed: float = 80.0

func _tick(ctx: BTContext) -> BTResult:
	var agent = ctx.get_agent()
	if not is_instance_valid(agent):
		return BTResult.FAILURE
	
	var target_pos = ctx.blackboard.get_value("patrol_target")
	if target_pos == null:
		return BTResult.FAILURE
	
	var direction = (target_pos - agent.global_position).normalized()
	agent.velocity.x = direction.x * speed
	
	if agent.has_method("play_walk"):
		agent.play_walk()
	
	# Check if reached target
	if agent.global_position.distance_to(target_pos) < 10:
		# Get next patrol point
		var patrol_points = ctx.blackboard.get_value("patrol_points", [])
		var current_index = ctx.blackboard.get_value("patrol_index", 0)
		
		if patrol_points.size() > 0:
			current_index = (current_index + 1) % patrol_points.size()
			ctx.blackboard.set_value("patrol_index", current_index)
			ctx.blackboard.set_value("patrol_target", patrol_points[current_index])
			return BTResult.SUCCESS
	
	return BTResult.RUNNING
