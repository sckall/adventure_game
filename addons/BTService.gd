@icon("res://addons/godot_bt/icons/btparallel.svg")
class_name BTService extends Resource

## Key for storing next tick time in service data
const NEXT_TICK_TIME := &"next_tick_time"

## Emitted when the service ticks
signal ticked()

## Whether the service is active
@export var _is_enabled: bool = true

## How often to tick this service (in seconds)
@export_range(0, 9999) var _frequency: float

## Random variation to add to frequency (0-1 multiplier)
@export_range(0, 1) var _variation: float = 0.1

## Whether to skip the first tick
@export var _skip_first: bool = true

func _init() -> void:
	resource_name = "BTService"

## Register with a context
func register_context(ctx: BTContext) -> void:
	pass

## Tick the service if it's time
func tick(ctx: BTContext) -> void:
	if not _is_enabled:
		return

	var service_data: Dictionary = ctx.get_persistent_data(self)

	# Initialize next tick time if not set
	if not service_data.has(NEXT_TICK_TIME):
		if _skip_first:
			service_data[NEXT_TICK_TIME] = ctx.elapsed_time + _frequency
		else:
			service_data[NEXT_TICK_TIME] = ctx.elapsed_time

	# Skip if not time yet
	if service_data[NEXT_TICK_TIME] > ctx.elapsed_time:
		return

	# Set next tick time with variation
	service_data[NEXT_TICK_TIME] = ctx.elapsed_time + _frequency * (1 + _variation * randf_range(-1, 1))

	_tick(ctx)
	ticked.emit()

## Virtual method to override with service logic
func _tick(ctx: BTContext) -> void:
	pass
