@icon("res://addons/godot_bt/icons/btconditional.png")
class_name BTReactiveCondition extends BTCondition

## Key for storing the last result
const LAST_RESULT := &"last_result"

## When to trigger an abort
enum AbortTrigger {
	NONE, # Never abort
	ON_REEVALUATED, # Abort whenever reevaluated
	ON_RESULT_CHANGED, # Abort when result changes
	ON_RESULT_TRUE, # Abort when result becomes true
	ON_RESULT_FALSE # Abort when result becomes false
}

## Signal emitted when an abort is requested
signal abort_requested(node: BTNode, abort_scope: BehaviorTree.BTAbortScope, ctx: BTContext)

## When to trigger an abort
@export var _abort_trigger: AbortTrigger = AbortTrigger.NONE

## What scope to abort
@export var _abort_scope: BehaviorTree.BTAbortScope = BehaviorTree.BTAbortScope.SELF

## Set up the conditional with its attached node
func setup(attached_node: BTNode) -> void:
	super (attached_node)
	abort_requested.connect(_attached_node.btree.request_abort)

## Evaluate and store the result
func tick(ctx: BTContext) -> bool:
	if not _is_enabled:
		return true

	return ctx.get_persistent_data(self).get("last_result", super (ctx))

## Reevaluate the condition and potentially trigger an abort
func _reevaluate(ctx: BTContext) -> void:
	if not _is_enabled:
		return

	var result: bool = super.tick(ctx)
	var data: Dictionary = ctx.get_persistent_data(self)
	var request_abort: bool = false

	# Determine if we should abort based on trigger type
	match _abort_trigger:
		AbortTrigger.NONE:
			pass

		AbortTrigger.ON_REEVALUATED:
			request_abort = true

		AbortTrigger.ON_RESULT_CHANGED:
			if not data.has(LAST_RESULT) or result != data[LAST_RESULT]:
				request_abort = true

		AbortTrigger.ON_RESULT_TRUE:
			if (not data.has(LAST_RESULT) or result != data[LAST_RESULT]) and result == true:
				request_abort = true

		AbortTrigger.ON_RESULT_FALSE:
			if (not data.has(LAST_RESULT) or result != data[LAST_RESULT]) and result == false:
				request_abort = true

	# Request abort if needed
	if request_abort:
		abort_requested.emit(_attached_node, _abort_scope, ctx)

	# Store the result
	data[LAST_RESULT] = result
