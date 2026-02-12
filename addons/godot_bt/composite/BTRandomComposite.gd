@icon("res://addons/godot_bt/icons/btcomposite.svg")
class_name BTRandomComposite extends BTComposite

func _get_execution_range(ctx: BTContext) -> Array:
	# If no node is running, shuffle the children
	if not ctx.is_running():
		var exec_range: Array = range(0, _children.size())
		exec_range.shuffle()
		return exec_range

	# If a node is running, return the remaining children in order
	return range(_offset, _children.size())
