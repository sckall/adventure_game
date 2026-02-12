@icon("res://addons/godot_bt/icons/btrevert.svg")
class_name BTInverter extends BTDecorator

## Inverts the result of a child node
## SUCCESS becomes FAILURE and vice versa
## RUNNING remains RUNNING

func tick(ctx: BTContext, result: BTNode.BTResult) -> BTNode.BTResult:
	super (ctx, result)

	# Don't invert if running or aborted
	if result == BTNode.BTResult.RUNNING or result == BTNode.BTResult.ABORTED:
		return result

	# Invert success/failure
	if result == BTNode.BTResult.SUCCESS:
		return BTNode.BTResult.FAILURE
	else:
		return BTNode.BTResult.SUCCESS
