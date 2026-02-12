@icon("res://addons/godot_bt/icons/btcomposite.svg")
class_name BTComposite extends BTNode

## Children nodes of this composite
var _children: Array[BTNode]

## Offset to start ticking from
var _offset: int = 0

func _ready() -> void:
	for child in get_children():
		_children.push_back(child)

func _tick(ctx: BTContext) -> BTResult:
	super (ctx)

	# Reset offset or get from running history
	_offset = 0
	if ctx.is_running():
		_offset = ctx.running_history.back().get_index()

	return BTResult.SUCCESS
