@icon("res://addons/godot_bt/icons/btalways.svg")
class_name BTAlwaysReturn extends BTDecorator

## The result to always return
@export var _return_value: int = BTNode.BTResult.SUCCESS

## Always returns a specific result regardless of the child's result
## Will still return RUNNING if the child is running

func tick(ctx: BTContext, result: BTNode.BTResult) -> BTNode.BTResult:
	super (ctx, result)

	# If the child is still running, keep running
	if result == BTNode.BTResult.RUNNING:
		return result

	# Otherwise return the specified result
	return _return_value
