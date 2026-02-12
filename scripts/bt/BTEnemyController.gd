extends CharacterBody2D

# Behavior Tree reference
@export var behavior_tree: BehaviorTree

# Blackboard data
var blackboard: Blackboard
var ctx: BTContext

# Settings
@export var player_path: NodePath = @"../Player"
@export var patrol_points: Array[Vector2] = []
@export var detect_range: float = 400.0
@export var start_patrolling: bool = true

var player: Node2D = null

func _ready():
	# Get player reference
	if has_node(player_path):
		player = get_node(player_path)
	else:
		player = get_tree().get_first_node_in_group("player")
	
	# Initialize blackboard
	blackboard = Blackboard.new()
	
	# Setup patrol points if provided
	if patrol_points.size() > 0:
		blackboard.set_value("patrol_points", patrol_points)
		blackboard.set_value("patrol_index", 0)
		blackboard.set_value("patrol_target", patrol_points[0])
	
	# Initialize behavior tree
	if behavior_tree:
		ctx = behavior_tree.create_context(self, blackboard)
	
	# Set initial values
	blackboard.set_value("player", player)
	blackboard.set_value("player_detected", false)
	blackboard.set_value("detect_range", detect_range)

func _physics_process(delta: float) -> void:
	if is_instance_valid(behavior_tree) and ctx:
		behavior_tree.tick(ctx, delta)

# Helper methods for behavior tree
func set_patrol_target(point: Vector2):
	blackboard.set_value("patrol_target", point)

func get_patrol_target() -> Vector2:
	return blackboard.get_value("patrol_target", Vector2.ZERO)

func set_player_detected(detected: bool):
	blackboard.set_value("player_detected", detected)

func is_player_detected() -> bool:
	return blackboard.get_value("player_detected", false)
