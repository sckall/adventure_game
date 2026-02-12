@icon("res://addons/godot_bt/icons/btconditional.png")
class_name BTCondition extends Resource

@export var _is_enabled: bool = true

## Whether to invert the result
@export var _flip: bool

## The node this conditional is attached to
var _attached_node: BTNode

## Set up the conditional with its attached node
func setup(attached_node: BTNode) -> void:
	_attached_node = attached_node

## Register with a context
func register_context(ctx: BTContext) -> void:
	pass

## Evaluate the condition
func tick(ctx: BTContext) -> bool:
	if not _is_enabled:
		return true

	var result: bool = _tick(ctx)
	if _flip:
		result = not result

	return result

## Virtual method to override with condition logic
func _tick(ctx: BTContext) -> bool:
	return true
