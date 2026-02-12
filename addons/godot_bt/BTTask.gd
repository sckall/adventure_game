@icon("res://addons/godot_bt/icons/btleaf.svg")
class_name BTTask extends BTNode

## Base class for all leaf nodes (tasks)
## Tasks perform the actual work in a behavior tree

func _tick(ctx: BTContext) -> BTResult:
	super (ctx)
	return BTResult.SUCCESS
