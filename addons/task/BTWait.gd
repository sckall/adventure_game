@icon("res://addons/godot_bt/icons/btwait.svg")
class_name BTWait extends BTTask

## Key for storing elapsed time in running data
const TIME_ELAPSED := &"time_elapsed"

## How long to wait in seconds
@export var _wait_time: float

## Wait for a specified amount of time
## Returns RUNNING while waiting, SUCCESS when done

func _tick(ctx: BTContext) -> BTResult:
	super (ctx)

	var running_data: Dictionary = ctx.get_running_data(self)

	if not running_data.has(TIME_ELAPSED):
		running_data[TIME_ELAPSED] = 0

	running_data[TIME_ELAPSED] += ctx.delta

	if running_data[TIME_ELAPSED] <= _wait_time:
		return BTResult.RUNNING

	running_data[TIME_ELAPSED] = 0
	return BTResult.SUCCESS
