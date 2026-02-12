@icon("res://addons/godot_bt/icons/blackboard.svg")
class_name Blackboard extends Resource

## A Blackboard is the AI agent's memory. It stores key-value pairs that can be used to share information between tasks and conditions.
## Keys are StringNames and values can be any Variant type.
## The blackboard is a dictionary-like structure with extra steps for type checking. It allows you to set, get, and remove values using keys for the most common types.
## It also provides utility functions for comparing values, checking if a value is zero or empty, and copying values from another blackboard.
## The blackboard is not thread-safe, so it should only be used in the main thread. It is also not designed to be used in a multiplayer context.
## A Blackboard resource can be instantiated and used in a Behavior Tree.
## The blackboard is not a replacement for a database or a data structure. It is a simple key-value store that is designed around the Behavior Tree system.

## Emitted when a value changes
signal value_changed(key: StringName, value: Variant)

## Dictionary of _values stored in the blackboard
@export var _values: Dictionary = {}

## Copy values from another blackboard
func copy_from(other: Blackboard) -> void:
	set_values(other.get_values())

## Returns a copy of the values in the blackboard.
func get_values() -> Dictionary:
	return _values.duplicate(true)

## Set multiple _values at once or overwrite existing ones
func set_values(new_values: Dictionary) -> void:
	for key in new_values:
		set_value(key, new_values[key])

## Toggle a boolean value
func toggle_bool(key: StringName) -> void:
	var current: bool = get_bool(key)
	set_value(key, not current)

## Negate a value. Generates an error if the value is not a valid number type or vector.
func negate(key: StringName) -> void:
	var current: Variant = get_value(key)
	assert(typeof(current) in [TYPE_INT, TYPE_FLOAT, TYPE_VECTOR2])
	set_value(key, -current)

## Increment a numeric value. Generates an error if the value is not a valid number type.
func increment_number(key: StringName, amount: float = 1.0) -> void:
	var current: Variant = get_value(key)
	assert(typeof(current) in [TYPE_INT, TYPE_FLOAT])
	set_value(key, current + amount)

## Increment a Vector2 value towards a target
func increment_vector(key: StringName, to := Vector2.ONE, amount := 1.0) -> void:
	var current: Vector2 = get_vector(key)
	set_value(key, current.move_toward(to, amount * get_float("delta")))

## Increment a Vector3 value towards a target
func increment_vector3(key: StringName, to := Vector3.ONE, amount := 1.0) -> void:
	var current: Vector3 = get_vector3(key)
	set_value(key, current.move_toward(to, amount * get_float("delta")))

## Get a boolean value or false if it doesn't exist
func get_bool(key: StringName) -> bool:
	var value: Variant = get_value(key)
	if value == null:
		return false

	assert(typeof(value) == TYPE_BOOL, "'%s' is not a bool" % key)
	return value

## Get an integer value or zero if it doesn't exist. Generates an error if the value is not an integer.
func get_int(key: StringName) -> int:
	var value: Variant = get_value(key)
	if value == null:
		return 0

	assert(typeof(value) == TYPE_INT, "'%s' is not an integer" % key)
	return value

## Get a vector value or zero vector if it doesn't exist. Generates an error if the value is not a vector.
func get_vector(key: StringName) -> Vector2:
	var value: Variant = get_value(key)
	if value == null:
		return Vector2.ZERO

	assert(typeof(value) == TYPE_VECTOR2, "'%s' is not a vector" % key)
	return value

## Get a vector value or zero vector if it doesn't exist. Generates an error if the value is not a vector.
func get_vector3(key: StringName) -> Vector3:
	var value: Variant = get_value(key)
	if value == null:
			return Vector3.ZERO

	assert(typeof(value) == TYPE_VECTOR3, "'%s' is not a Vector3" % key)
	return value

## Get a string value or empty string if it doesn't exist. Generates an error if the value is not a string.
func get_string(key: StringName) -> String:
	var value: Variant = get_value(key)
	if value == null:
		return ""

	assert(typeof(value) == TYPE_STRING, "'%s' is not a string" % key)
	return value

## Get a string name value or empty string if it doesn't exist. Generates an error if the value is not a string name.
func get_string_name(key: StringName) -> StringName:
	var value: Variant = get_value(key)
	if value == null:
		return ""

	assert(typeof(value) == TYPE_STRING_NAME, "'%s' is not a string name" % key)
	return value

## Get a float value or zero if it doesn't exist. Generates an error if the value is not a float.
func get_float(key: StringName) -> float:
	var value: Variant = get_value(key)
	if value == null:
		return 0.0

	assert(typeof(value) == TYPE_FLOAT, "'%s' is not a float" % key)
	return value

## Get a node value or null if it doesn't exist. Generates an error if the value is not a node.
func get_node(key: StringName) -> Node:
	var value: Variant = get_value(key)
	if value == null:
		return null

	assert(value is Node, "'%s' is not a Node" % key)
	return value

## Get an array value or empty array if it doesn't exist. Generates an error if the value is not an array.
func get_array(key: StringName) -> Array:
	var value: Variant = get_value(key)
	if value == null:
		return []

	assert(typeof(value) == TYPE_ARRAY, "'%s' is not an array" % key)
	return value

## Get a dictionary value or empty dictionary if it doesn't exist. Generates an error if the value is not a dictionary.
func get_dictionary(key: StringName) -> Dictionary:
	var value: Variant = get_value(key)
	if value == null:
		return {}

	assert(typeof(value) == TYPE_DICTIONARY, "'%s' is not a dictionary" % key)
	return value

## Get the type of a value as Variant.Type
func get_type(key: StringName) -> Variant.Type:
	return typeof(get_value(key))

## Check if a value is zero or empty.
## A value is considered zero or empty if:
## - It doesn't exist in the blackboard
## - It is a boolean and false
## - It is an integer and 0
## - It is a float and 0.0
## - It is a vector and (0, 0)
## - It is a string, node path, string name or collection and is empty
func is_zero_or_empty(key: StringName) -> bool:
	if not has_key(key):
		return true

	var value: Variant = get_value(key)

	match typeof(value):
		TYPE_INT, TYPE_BOOL:
			return not value
		TYPE_FLOAT:
			return is_zero_approx(value)
		TYPE_VECTOR2, TYPE_VECTOR3:
			return value.is_zero_approx()
		TYPE_STRING, TYPE_NODE_PATH, TYPE_STRING_NAME, TYPE_ARRAY, TYPE_DICTIONARY:
			return value.is_empty()
		_:
			return value == null

## Compare two entries in the blackboard. It checks if both keys exist and if their values are approximately equal.
func compare_entries(key1: StringName, key2: StringName) -> bool:
	if not (has_key(key1) and has_key(key2)):
		return false

	return _compare_values(get_value(key1), get_value(key2))

## Clear all values
func clear() -> void:
	var keys: Array[StringName] = _values.keys()
	for key in keys:
		remove_key(key)

## Remove a key
func remove_key(key: StringName) -> void:
	if not _values.has(key):
		return

	_values.erase(key)
	value_changed.emit(key, null)

## Get all keys
func get_keys() -> Array:
	return _values.keys()

## Get a string representation of all entries. Useful to plug into a Label node for debugging.
func get_entries_as_string() -> String:
	var result := "Blackboard{\n"
	for key in _values:
		result += "\t%s: %s\n" % [key, str(_values[key])]

	result += "}"
	return result

## Set a BB entry with the given key and value.
## If the key exists, it adds it to the blackboard and emits a signal to notify change.
## If the key already exists and the value is the same, it does nothing.
## If the key doesn't exist or is empty, it does nothing.
func set_value(key: StringName, value: Variant = null) -> void:
	if not key:
		return

	if has_key(key) and _values[key] == value:
		return

	_values[key] = value
	value_changed.emit(key, value)

## Get a value from the BB entry with the given key. If the key doesn't exist, it returns the default value and adds it to the blackboard.
func get_value(key: StringName, default: Variant = null) -> Variant:
	return _values.get(key, default)

## Check if a key exists. If the key is empty, it returns false.
func has_key(key: StringName) -> bool:
	return key and _values.has(key)

## Helper function to compare two values. It checks if the types are the same and uses approximate comparison for floats and vectors.
func _compare_values(value1: Variant, value2: Variant) -> bool:
	assert(typeof(value1) == typeof(value2), "Types are different: %s vs %s" % [typeof(value1), typeof(value2)])

	match typeof(value1):
		TYPE_FLOAT:
			return is_equal_approx(value1, value2)
		TYPE_VECTOR2, TYPE_VECTOR3:
			return value1.is_equal_approx(value2)
		_:
			return value1 == value2
