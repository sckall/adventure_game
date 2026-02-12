extends Node

# 敌人AI管理器 - 自动为所有敌人应用行为树

@export var auto_start: bool = true

func _ready():
	if auto_start:
		start_all_enemy_ai()

func start_all_enemy_ai():
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy.has_method("setup_behavior_tree"):
			enemy.setup_behavior_tree()

func get_player():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	return player

func update_player_reference(player):
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy.has_method("set_player"):
			enemy.set_player(player)
