class_name BTTargetKey extends Resource

## Utility class to get target information from the blackboard
## Can get directions, positions, and distances to targets

enum TargetingMode {
	DIRECTION, # The key contains a direction vector
	POSITION, # The key contains a position vector
	NODE, # The key contains a Node2D reference
}

## How to interpret the target key
@export var targeting_mode: TargetingMode = TargetingMode.NODE

## The key in the blackboard that holds the target
@export var target_key: StringName

## Get the direction to the target
func get_target_direction(ctx: BTContext) -> Vector2:
	if not ctx.blackboard.has_key(target_key):
		return Vector2.ZERO

	match targeting_mode:
		TargetingMode.DIRECTION:
			return ctx.blackboard.get_vector(target_key)

		_:
			var target_position: Vector2 = get_target_position(ctx)
			if not target_position:
				return Vector2.ZERO

			if not is_instance_valid(ctx.agent) or not ctx.agent is Node2D:
				return Vector2.ZERO

			return ctx.agent.global_position.direction_to(target_position)

## Get the distance to the target
func get_target_distance(ctx: BTContext) -> float:
	var target_position: Vector2 = get_target_position(ctx)
	if not target_position:
		return NAN

	if not is_instance_valid(ctx.agent) or not ctx.agent is Node2D:
		return NAN

	return ctx.agent.global_position.distance_to(target_position)

## Get the target position
func get_target_position(ctx: BTContext) -> Vector2:
	if not ctx.blackboard.has_key(target_key):
		return Vector2.ZERO

	match targeting_mode:
		TargetingMode.DIRECTION:
			var direction: Vector2 = ctx.blackboard.get_vector(target_key)
			if not direction:
				return Vector2.ZERO

			if not is_instance_valid(ctx.agent) or not ctx.agent is Node2D:
				return Vector2.ZERO

			# Use a large distance in the direction
			return ctx.agent.global_position + direction * 10000

		TargetingMode.POSITION:
			return ctx.blackboard.get_vector(target_key)

		TargetingMode.NODE:
			var target: Node2D = ctx.blackboard.get_node(target_key)
			if not is_instance_valid(target):
				return Vector2.ZERO

			return target.global_position

	return Vector2.ZERO
