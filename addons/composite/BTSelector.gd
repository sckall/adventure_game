@icon("res://addons/godot_bt/icons/btselector.svg")
class_name BTSelector extends BTComposite

## A selector runs each child in order until one succeeds or all fail
## Returns SUCCESS if any child succeeds, FAILURE if all children fail,
## or RUNNING if a child is still running

func _tick(ctx: BTContext) -> BTResult:
	super (ctx)

	# Try each child in order starting from offset
	for n in range(_offset, _children.size()):
		var result: BTResult = _children[n].tick(ctx)

		# If the child is not a failure, return its result
		if result != BTResult.FAILURE:
			return result

	# All children failed
	return BTResult.FAILURE
