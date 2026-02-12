@icon("res://addons/godot_bt/icons/btdecorator.svg")
class_name BTDecorator extends Resource

## Register with a context
func register_context(ctx: BTContext) -> void:
	pass

## Process a result from a child node and return potentially modified result
func tick(ctx: BTContext, result: BTNode.BTResult) -> BTNode.BTResult:
	return result
