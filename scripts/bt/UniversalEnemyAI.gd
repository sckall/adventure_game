extends CharacterBody2D

# 通用敌人AI控制器
# 支持自动检测敌人类型并加载对应行为树

@export var enemy_type: String = "slime"  # slime, hedgehog, skeleton, snail, snake, spider, bat, boss
@export var auto_detect_type: bool = true

# 行为树引用
var behavior_tree: BehaviorTree
var blackboard: Blackboard
var ctx: BTContext

# 玩家引用
var player: Node2D = null

# AI参数
@export var detect_range: float = 400.0
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 100.0
@export var attack_damage: float = 1.0
@export var attack_cooldown: float = 1.0

func _ready():
	_auto_detect_enemy_type()
	_setup_behavior_tree()
	_get_player_reference()

func _auto_detect_enemy_type():
	if not auto_detect_type:
		return
	
	# 根据节点名称自动检测
	var node_name = name.to_lower()
	
	if "slime" in node_name:
		enemy_type = "slime"
	elif "hedgehog" in node_name:
		enemy_type = "hedgehog"
	elif "skeleton" in node_name:
		enemy_type = "skeleton"
	elif "snail" in node_name:
		enemy_type = "snail"
	elif "snake" in node_name:
		enemy_type = "snake"
	elif "spider" in node_name:
		enemy_type = "spider"
	elif "bat" in node_name:
		enemy_type = "bat"
	elif "boss" in node_name or "ai_boss" in node_name:
		enemy_type = "boss"

func _setup_behavior_tree():
	var bt_script = _get_bt_script_for_type(enemy_type)
	
	if bt_script:
		behavior_tree = bt_script.new()
		behavior_tree.detect_range = detect_range
		
		if enemy_type == "slime":
			behavior_tree.chase_speed = chase_speed
		elif enemy_type == "hedgehog":
			behavior_tree.patrol_speed = patrol_speed
			behavior_tree.chase_speed = chase_speed
		
		# 初始化Blackboard
		blackboard = Blackboard.new()
		ctx = behavior_tree.create_context(self, blackboard)
		
		# 设置初始值
		blackboard.set_value("player", player)
		blackboard.set_value("detect_range", detect_range)
		blackboard.set_value("patrol_points", [])
		blackboard.set_value("patrol_index", 0)

func _get_bt_script_for_type(type: String) -> Script:
	var bt_path = "res://scripts/bt/enemies/BehaviorTree%s.gd" % type.capitalize()
	var script = load(bt_path)
	
	if not script:
		# 默认使用史莱姆行为树
		script = load("res://scripts/bt/BehaviorTreeSlime.gd")
	
	return script

func _get_player_reference():
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	
	# 订阅玩家死亡事件
	if player and player.has_signal("died"):
		player.died.connect(_on_player_died)

func _physics_process(delta: float) -> void:
	if is_instance_valid(behavior_tree) and ctx:
		behavior_tree.tick(ctx, delta)

# 公共方法
func set_player(new_player: Node2D):
	player = new_player
	if blackboard:
		blackboard.set_value("player", player)

func set_detect_range(range: float):
	detect_range = range
	if blackboard:
		blackboard.set_value("detect_range", range)

func _on_player_died():
	# 玩家死亡，停止追逐
	if blackboard:
		blackboard.set_value("player", null)
		blackboard.set_value("player_detected", false)
	
	# 恢复空闲状态
	velocity = Vector2.ZERO
