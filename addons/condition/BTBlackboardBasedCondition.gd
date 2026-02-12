@icon("res://addons/godot_bt/icons/btconditional.png")
class_name BTBlackboardBasedCondition extends BTReactiveCondition

## Types of checks to perform on a blackboard key
enum KeyQuery {
	IS_SET, # Check if key exists
	IS_NOT_SET # Check if key doesn't exist
}

## The type of query to perform
@export var _key_query: KeyQuery = KeyQuery.IS_SET

## The key to check
@export var _key: StringName

## Register with context and connect to blackboard signals
func register_context(ctx: BTContext) -> void:
	super (ctx)
	ctx.blackboard.value_changed.connect(_on_blackboard_value_changed.bind(ctx))

## Called when a blackboard value changes
func _on_blackboard_value_changed(key: StringName, value: Variant, ctx: BTContext) -> void:
	if key != _key:
		return

	_reevaluate(ctx)

## Check the blackboard according to the query type
func _tick(ctx: BTContext) -> bool:
	super (ctx)

	if _key_query == KeyQuery.IS_SET:
		return ctx.blackboard.has_key(_key)
	else:
		return not ctx.blackboard.has_key(_key)
