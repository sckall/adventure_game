@icon("res://addons/godot_bt/icons/btparallel.svg")
class_name BTParallel extends BTComposite

## Optional node that determines when to complete
@export var _complete_target: BTNode

## A parallel node runs all children at once
## By default, returns RUNNING until _complete_target finishes

func _tick(ctx: BTContext) -> BTResult:
	super (ctx)

	for child in _children:
		var data: Dictionary = ctx.get_running_data(child)

		# Get or create history for this child
		var child_hist: Array[BTNode] = []
		if data.has("child_history"):
			child_hist = data.get("child_history")
		else:
			data["child_history"] = child_hist

		# Run the child with its own history
		ctx.running_history = child_hist
		var result: BTResult = child.tick(ctx)
		ctx.running_history = []

		if result == BTResult.ABORTED:
			return BTResult.ABORTED

		# If this child is the complete target and it's done running,
		# return its result
		if _complete_target and child == _complete_target and result != BTResult.RUNNING:
			return result

	# By default, keep running
	return BTResult.RUNNING

func _post_tick(ctx: BTContext, result: BTResult) -> void:
	super (ctx, result)

	# Clean up child histories if we're done
	if result != BTResult.RUNNING:
		for child in _children:
			var data: Dictionary = ctx.get_running_data(child)
			if data.has("child_history"):
				data.erase("child_history")
