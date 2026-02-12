@icon("res://addons/godot_bt/icons/btnode.svg")
class_name BTNode extends Node

enum BTResult {
	SUCCESS,
	RUNNING,
	FAILURE,
	ABORTED,
}

enum ConditionType {
	ALL,
	ANY
}

## Used to map result types to functions
var _result_func: Dictionary = {
	BTResult.SUCCESS: _succeed,
	BTResult.FAILURE: _fail,
	BTResult.ABORTED: _abort,
	BTResult.RUNNING: _run
}

@export var _is_enabled: bool = true

## Conditions attached to this node
@export_category("Conditions")
@export var _conditions: Array[BTCondition]
@export var _condition_type: ConditionType
@export var _tick_conditions_when_running: bool = true

## Services attached to this node
@export_category("Services")
@export var _services: Array[BTService]
@export var _tick_services_when_running: bool = true

## Decorators attached to this node
@export_category("Decorators")
@export var _decorators: Array[BTDecorator]

## Whether the node is currently running
var _is_running: bool

## Reference to the parent behavior tree
var btree: BehaviorTree

## Order in the tree for priority-based operations
var order: int

func setup(owning_tree: BehaviorTree) -> void:
	btree = owning_tree

	for conditional in _conditions:
		conditional.setup(self)

## Register this node with the given context
func register_context(ctx: BTContext) -> void:
	for condition in _conditions:
		condition.register_context(ctx)

	for service in _services:
		service.register_context(ctx)

	for decorator in _decorators:
		decorator.register_context(ctx)

	# Register all child nodes
	var children: Array = get_children()
	for child in children:
		if child is BTNode:
			child.register_context(ctx)

## Get the current context from the behavior tree
func get_current_context() -> BTContext:
	return btree.get_current_context()

## Tick this node with the given context
func tick(ctx: BTContext) -> BTResult:
	ctx.current = self

	if not _is_enabled:
		return _succeed(ctx)

	if ctx.abort_issued:
		return _abort(ctx)

	# Check conditionals
	if _tick_conditions_when_running or not ctx.is_running():
		var should_tick: bool = _tick_conditions(ctx)
		if not should_tick:
			return _fail(ctx)

	# Tick services
	if _tick_services_when_running or not ctx.is_running():
		_tick_services(ctx)

	if ctx.abort_issued:
		return _abort(ctx)

	# Check if this node was running
	_is_running = ctx.running_history.pop_back() != null
	var result: BTResult = _tick(ctx)
	_is_running = false

	if result == BTResult.ABORTED or ctx.abort_issued:
		return _abort(ctx)

	# Apply decorators
	result = _tick_decorators(ctx, result)

	# If running, add to running history
	if result == BTResult.RUNNING:
		ctx.running_history.push_back(self)

	return _result_func[result].call(ctx)

## Tick all services attached to this node
func _tick_services(ctx: BTContext) -> void:
	for service in _services:
		service.tick(ctx)

## Check all conditionals attached to this node
func _tick_conditions(ctx: BTContext) -> bool:
	match _condition_type:
		ConditionType.ALL:
			return _conditions.all(
				func(cond: BTCondition) -> bool:
					return cond.tick(ctx)
			)

		ConditionType.ANY:
			return _conditions.any(
				func(cond: BTCondition) -> bool:
					return cond.tick(ctx)
			)

	assert(false, "Invalid condition type")
	return false

## Apply all decorators to the result
func _tick_decorators(ctx: BTContext, result: BTResult) -> BTResult:
	for decorator in _decorators:
		result = decorator.tick(ctx, result)

	return result

## Virtual Methods - Override in subclasses ##

## Called when the node is ticked - override in subclasses
func _tick(ctx: BTContext) -> BTResult:
	return BTResult.SUCCESS

## Called when the node succeeds
func _succeed(ctx: BTContext) -> BTResult:
	_post_tick(ctx, BTResult.SUCCESS)
	return BTResult.SUCCESS

## Called when the node fails
func _fail(ctx: BTContext) -> BTResult:
	_post_tick(ctx, BTResult.FAILURE)
	return BTResult.FAILURE

## Called when the node is aborted
func _abort(ctx: BTContext) -> BTResult:
	_post_tick(ctx, BTResult.ABORTED)
	return BTResult.ABORTED

## Called when the node is running
func _run(ctx: BTContext) -> BTResult:
	return BTResult.RUNNING

## Called after the node is ticked - override in subclasses for cleanup
func _post_tick(ctx: BTContext, result: BTResult) -> void:
	pass
