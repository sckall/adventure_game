class_name BTCheckDistance2D extends BTBlackboardBasedCondition

enum ComparisonType {
	LESS,
	GREATER,
	EQUAL,
	NOT_EQUAL,
}

@export var _comparison_type: ComparisonType = ComparisonType.EQUAL
@export var _or_equals: bool = false
@export var _distance: float = 50.0

func _tick(ctx: BTContext) -> bool:
	if not super (ctx):
		return false

	var check_position: Vector2 = ctx.blackboard.get_vector(_key)
	if not check_position:
		return false

	var check_distance: float = ctx.agent.global_position.distance_to(check_position)

	match _comparison_type:
		ComparisonType.LESS:
			return check_distance < _distance or (_or_equals and is_equal_approx(check_distance, _distance))
		ComparisonType.GREATER:
			return check_distance > _distance or (_or_equals and is_equal_approx(check_distance, _distance))
		ComparisonType.EQUAL:
			return is_equal_approx(check_distance, _distance)
		_:
			return not is_equal_approx(check_distance, _distance)
