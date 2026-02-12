@icon("res://addons/godot_bt/icons/bt.svg")
class_name BehaviorTree extends Node

## Determines the scope of an abort operation
enum BTAbortScope {
	SELF, # Only abort the requesting node
	SUB_BRANCH, # Abort the requestor and its children
	LOWER_BRANCH, # Abort nodes with lower priority
	LOWER_PRIORITY, # Abort all nodes with lower priority
	SIBLING_BRANCH, # Abort sibling branches
	ALL, # Abort all running nodes
}

@export var _is_enabled: bool = true

## The root node of the behavior tree
var _root: BTNode

## Current context being processed
var _current_ctx: BTContext

## Total number of nodes in tree
var _node_count: int

## Ancestry relationships between nodes
var _ancestry: Dictionary = {}

func _ready() -> void:
	_root = get_child(0)
	assert(_root is BTComposite, "Root must be a composite node")

	# Build the node hierarchy
	var stack: Array[BTNode]
	stack.push_back(_root)
	_ancestry[_root] = {}

	while not stack.is_empty():
		var current: BTNode = stack.pop_back()
		current.setup(self)
		current.order = _node_count
		_node_count += 1

		var child_count: int = current.get_child_count()
		if child_count == 0:
			continue

		for i in range(child_count - 1, -1, -1):
			var child: BTNode = current.get_child(i)
			stack.push_back(child)
			var ancestry: Dictionary = _ancestry.get(current, {}).duplicate()
			ancestry[current] = null
			_ancestry[child] = ancestry

## Request an abort operation
func request_abort(requestor: BTNode, abort_scope: BTAbortScope, ctx: BTContext) -> void:
	if not _should_abort(requestor, abort_scope, ctx):
		return

	if ctx == _current_ctx:
		_current_ctx.abort_issued = true
		return

	ctx.clear_running_data()

## Check if an abort should occur
func _should_abort(requestor: BTNode, abort_scope: BTAbortScope, ctx: BTContext) -> bool:
	var abort_target: BTNode = ctx.get_running_or_current()

	if not abort_target:
		return false

	match abort_scope:
		BTAbortScope.SELF:
			return abort_target.order == requestor.order
		BTAbortScope.SUB_BRANCH:
			return abort_target.order == requestor.order or _ancestry.get(abort_target, {}).has(requestor)
		BTAbortScope.LOWER_BRANCH:
			return abort_target.order > requestor.order and not _ancestry.get(abort_target, {}).has(requestor)
		BTAbortScope.LOWER_PRIORITY:
			return abort_target.order > requestor.order
		BTAbortScope.ALL:
			return true
		BTAbortScope.SIBLING_BRANCH:
			var parent = requestor.get_parent()
			return _ancestry.get(abort_target, {}).has(parent)

	return false

## Create a context for an entity
func create_context(agent: Object, blackboard: Blackboard) -> BTContext:
	var ctx = BTContext.new(agent, blackboard)
	register_context(ctx)
	return ctx

## Get the current context
func get_current_context() -> BTContext:
	return _current_ctx

## Register a context with all nodes
func register_context(ctx: BTContext) -> void:
	_root.register_context(ctx)

## Tick the behavior tree with the given context and delta time
func tick(ctx: BTContext, delta: float) -> void:
	if not (_is_enabled and is_node_ready()):
		return

	_current_ctx = ctx

	ctx.blackboard.set_value("delta", delta)
	ctx.abort_issued = false
	ctx.delta = delta
	ctx.elapsed_time += delta

	var result: BTNode.BTResult = _root.tick(ctx)

	ctx.current = null

	if result == BTNode.BTResult.RUNNING:
		return

	ctx.clear_running_data()
