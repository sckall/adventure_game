extends BTAttack

# 重攻击 - 伤害更高，有前摇动画

@export var windup_time: float = 0.5  # 前摇时间
@export var knockback_force: float = 100.0

var state: String = "idle"  # idle, winding_up, attacking, cooldown
var windup_timer: float = 0.0

func _enter(ctx: BTContext):
	state = "idle"
	windup_timer = 0.0

func _tick(ctx: BTContext) -> BTResult:
	var agent = ctx.get_agent()
	if not is_instance_valid(agent):
		return BTResult.FAILURE
	
	var player = ctx.blackboard.get_value("player")
	if not is_instance_valid(player):
		return BTResult.FAILURE
	
	var distance = agent.global_position.distance_to(player.global_position)
	
	if distance > attack_range * 1.5:
		state = "idle"
		return BTResult.FAILURE
	
	var current_time = Time.get_ticks_msec() / 1000.0
	
	match state:
		"idle":
			if current_time - last_attack_time >= attack_cooldown:
				state = "winding_up"
				windup_timer = windup_time
				# 播放预警动画
				if agent.has_method("play_windup"):
					agent.play_windup()
			return BTResult.RUNNING
		
		"winding_up":
			windup_timer -= get_delta(ctx)
			if windup_timer <= 0:
				state = "attacking"
				last_attack_time = current_time
				
				# 造成伤害
				if player.has_method("take_damage"):
					var knockback = (player.global_position - agent.global_position).normalized() * knockback_force
					player.take_damage(int(damage), knockback)
				
				# 播放攻击动画
				if agent.has_method("play_attack"):
					agent.play_attack()
			return BTResult.RUNNING
		
		"cooldown":
			return BTResult.SUCCESS
	
	return BTResult.RUNNING

func get_delta(ctx: BTContext) -> float:
	return 0.016
