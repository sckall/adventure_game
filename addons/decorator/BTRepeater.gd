@icon("res://addons/godot_bt/icons/btrepeater.svg")
class_name BTRepeater extends BTDecorator

## Key for storing repeat count in running data
const REPEAT_COUNT := &"repeat_count"

## Number of times to repeat the child node
@export var _repeat_num: int = 1

func _ready() -> void:
	assert(_repeat_num > 0, "Repeat number must be greater than 0")

## Repeats child execution a specified number of times
## Returns RUNNING until all repetitions complete, then returns the child's result

func tick(ctx: BTContext, result: BTNode.BTResult) -> BTNode.BTResult:
	super (ctx, result)

	# If the child is still running, keep running
	if result == BTNode.BTResult.RUNNING:
		return result

	# Get or initialize repeat count
	var running_data: Dictionary = ctx.get_running_data(self)
	if not running_data.has(REPEAT_COUNT):
		running_data[REPEAT_COUNT] = 0

	# Increment count
	running_data[REPEAT_COUNT] += 1

	# If we've reached the target count, return the result
	if running_data[REPEAT_COUNT] >= _repeat_num:
		running_data.erase(REPEAT_COUNT)
		return result

	# Otherwise keep running
	return BTNode.BTResult.RUNNING
