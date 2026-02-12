@icon("res://addons/godot_bt/icons/btrndselector.svg")
class_name BTRandomSelector extends BTRandomComposite

## A selector runs each child in order until one succeeds or all fail
## Returns SUCCESS if any child succeeds, FAILURE if all children fail,
## or RUNNING if a child is still running

func _tick(ctx: BTContext) -> BTResult:
	super (ctx)

	for n in _get_execution_range(ctx):
		var result: BTResult = _children[n].tick(ctx)

		# If the child is not a failure, return its result
		if result != BTResult.FAILURE:
			return result

	# All children failed
	return BTResult.FAILURE
