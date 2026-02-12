extends BTTask

@export var min_time: float = 1.0
@export var max_time: float = 3.0

var wait_time: float = 0.0
var elapsed: float = 0.0

func _enter(ctx: BTContext) -> void:
	wait_time = randf_range(min_time, max_time)
	elapsed = 0.0

func _tick(ctx: BTContext) -> BTResult:
	var agent = ctx.get_agent()
	if is_instance_valid(agent):
		agent.velocity = Vector2.ZERO
	
	elapsed += get_delta(ctx)
	
	if elapsed >= wait_time:
		return BTResult.SUCCESS
	
	return BTResult.RUNNING
