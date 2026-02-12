extends BTCondition

# 检查Boss是否应该进入下一阶段

@export var threshold: float = 0.5  # 50%血量

func _tick(ctx: BTContext) -> bool:
	var agent = ctx.get_agent()
	if not is_instance_valid(agent):
		return false
	
	# 检查血量
	var health = 1.0
	var max_health = 1.0
	
	if agent.has_method("get_health"):
		health = agent.get_health()
	if agent.has_method("get_max_health"):
		max_health = agent.get_max_health()
	
	var health_percent = health / max_health if max_health > 0 else 1.0
	
	# 检查是否应该进入愤怒阶段
	var should_rage = health_percent < threshold
	
	if should_rage:
		ctx.blackboard.set_value("boss_phase", 2)
		# 播放阶段转换效果
		if agent.has_method("enter_rage_mode"):
			agent.enter_rage_mode()
	
	return should_rage
