@icon("res://addons/godot_bt/icons/btrndsequence.svg")
class_name BTRandomSequence extends BTRandomComposite

## A sequence runs each child in order until one fails or all succeed
## Returns SUCCESS if all children succeed, FAILURE if any child fails,
## or RUNNING if a child is still running

func _tick(ctx: BTContext) -> BTResult:
	super (ctx)

	# Try each child in order starting from offset
	for n in _get_execution_range(ctx):
		var result: BTResult = _children[n].tick(ctx)

		# If the child is not a success, return its result
		if result != BTResult.SUCCESS:
			return result

	# All children succeeded
	return BTResult.SUCCESS
