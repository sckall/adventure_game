@icon("res://addons/godot_bt/icons/btrepeatuntil.svg")
class_name BTRepeatUntil extends BTDecorator

## The result that should cause the repeating to stop
@export var _expected_result: int = BTNode.BTResult.SUCCESS

## Repeats child execution until it returns the expected result
## Returns RUNNING until the expected result is achieved

func tick(ctx: BTContext, result: BTNode.BTResult) -> BTNode.BTResult:
	super (ctx, result)

	# If the child is still running, keep running
	if result == BTNode.BTResult.RUNNING:
		return result

	# If we got the expected result, we're done
	if result == _expected_result:
		return result

	# Otherwise, repeat
	return BTNode.BTResult.RUNNING
