class_name BTContext extends RefCounted

signal current_set()

## The owning agent (can be any object)
var agent: Object

## The blackboard used for data sharing
var blackboard: Blackboard

## Additional data that can be used by the implementation
var custom_data: Dictionary

## Currently ticking node
var current: BTNode

## Time elapsed since tree started
var elapsed_time: float

## Delta time for current tick
var delta: float

## History of running nodes
var running_history: Array[BTNode]

## Whether an abort was issued
var abort_issued: bool

## Data that persists between ticks
var _persistent_data: Dictionary = {}

## Data that only persists while a node is running
var _running_data: Dictionary = {}

## Initialize with an agent and blackboard
func _init(agent: Object, blackboard: Blackboard) -> void:
	self.agent = agent
	self.blackboard = blackboard
	self.custom_data = {}

## Get the node that is currently running or the current node
func get_running_or_current() -> BTNode:
	if is_running():
		return running_history.front()

	return current

## Get data specific to a running node
func get_running_data(obj: Object) -> Dictionary:
	var id: int = obj.get_instance_id()
	if not _running_data.has(id):
		_running_data[id] = {}

	return _running_data[id]

## Get data that persists between ticks for a specific object
func get_persistent_data(obj: Object) -> Dictionary:
	var id: int = obj.get_instance_id()
	if not _persistent_data.has(id):
		_persistent_data[id] = {}

	return _persistent_data[id]

## Clear running data and history
func clear_running_data() -> void:
	running_history.clear()
	_running_data.clear()

## Clear all persistent data
func clear_persistent_data() -> void:
	_persistent_data.clear()

## Return whether there are any running nodes
func is_running() -> bool:
	return not running_history.is_empty()
