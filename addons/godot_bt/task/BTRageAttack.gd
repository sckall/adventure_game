extends BTAttack

# 愤怒攻击 - Boss第二阶段的多段攻击

@export var attack_count_max: int = 3
@export var combo_cooldown: float = 0.3

var combo_count: int = 0
var last_combo_time: float = 0.0

func _enter(ctx: BTContext):
	combo_count = 0
	last_combo_time = 0.0

func _tick(ctx: BTContext) -> BTResult:
	var agent = ctx.get_agent()
	if not is_instance_valid(agent):
		return BTResult.FAILURE
	
	var player = ctx.blackboard.get_value("player")
	if not is_instance_valid(player):
		return BTResult.FAILURE
	
	var distance = agent.global_position.distance_to(player.global_position)
	
	if distance > attack_range:
		combo_count = 0
		return BTResult.FAILURE
	
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# 检查是否可以继续连击
	if current_time - last_combo_time >= combo_cooldown:
		if combo_count < attack_count_max:
			combo_count += 1
			last_combo_time = current_time
			
			# 造成伤害
			if player.has_method("take_damage"):
				var knockback = (player.global_position - agent.global_position).normalized() * 50
				(int(damage *player.take_damage combo_count), knockback)
			
			# 播放连击动画
			if agent.has_method("play_attack"):
				agent.play_attack()
		else:
			# 连击结束，重置
			combo_count = 0
			last_attack_time = current_time  # 重置主冷却
	
	return BTResult.RUNNING
