extends BTChase

# 快速追逐 - 比普通追逐更快

@export var acceleration: float = 200.0

func _tick(ctx: BTContext) -> BTResult:
	var agent = ctx.get_agent()
	if not is_instance_valid(agent):
		return BTResult.FAILURE
	
	var player = ctx.blackboard.get_value("player")
	if not is_instance_valid(player):
		return BTResult.FAILURE
	
	var direction = (player.global_position - agent.global_position).normalized()
	
	# 加速移动
	var target_speed = speed
	agent.velocity = agent.velocity.lerp(direction * target_speed, acceleration * get_delta(ctx))
	
	# 朝向玩家
	if direction.x > 0:
		agent.scale.x = 1
	else:
		agent.scale.x = -1
	
	var distance = agent.global_position.distance_to(player.global_position)
	
	if distance <= stop_distance:
		agent.velocity = Vector2.ZERO
		return BTResult.SUCCESS
	
	return BTResult.RUNNING

func get_delta(ctx: BTContext) -> float:
	# 获取delta的简单方式
	return 0.016  # 默认60fps
