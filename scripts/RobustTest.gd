extends Node2D

# ============ 最小化可运行测试 ============
# 这个脚本保证能运行！

signal test_passed(message: String)

var test_count: int = 0
var passed_count: int = 0
var failed_count: int = 0

func _ready():
	print("========================================")
	print("  开始测试 - 确保代码健壮性")
	print("========================================")
	
	# 运行测试
	test_item_system()
	test_enemy_system()
	test_player_system()
	
	# 显示结果
	_show_results()

func test_item_system():
	print("\n--- 测试道具系统 ---")
	test_count += 1
	
	# 测试1: 创建道具数据库
	var db_path = "res://scripts/items/RobustItemSystem.gd"
	if FileAccess.file_exists(db_path):
		var db = load(db_path).new()
		add_child(db)
		
		if db and db.has_method("get_random"):
			var item = db.get_random_item("weapon", 3)
			if item:
				print("✓ 道具生成: %s" % item.name)
				passed_count += 1
			else:
				print("✗ 道具生成失败")
				failed_count += 1
		else:
			print("✗ 道具系统方法缺失")
			failed_count += 1
	else:
		print("✗ 道具文件不存在: %s" % db_path)
		failed_count += 1

func test_enemy_system():
	print("\n--- 测试敌人系统 ---")
	test_count += 1
	
	var enemy_path = "res://scripts/enemies/RobustEnemySystem.gd"
	if FileAccess.file_exists(enemy_path):
		var spawner = load(enemy_path).EnemySpawner.new()
		add_child(spawner)
		
		if spawner and spawner.has_method("spawn_enemy"):
			var enemy = spawner.spawn_enemy(0, Vector2(100, 100), 1)
			if enemy:
				print("✓ 敌人生成: %s" % enemy.get_type_name())
				passed_count += 1
			else:
				print("✗ 敌人生成失败")
				failed_count += 1
		else:
			print("✗ 敌人生成方法缺失")
			failed_count += 1
	else:
		print("✗ 敌人文件不存在")
		failed_count += 1

func test_player_system():
	print("\n--- 测试玩家系统 ---")
	test_count += 1
	
	var player_path = "res://scripts/player/RobustPlayer.gd"
	if FileAccess.file_exists(player_path):
		var player = load(player_path).new()
		add_child(player)
		
		if player:
			print("✓ 玩家创建成功 HP:%d" % player.hp)
			passed_count += 1
			
			# 测试受伤
			player.take_damage(1)
			if player.hp == 2:
				print("✓ 玩家受伤测试通过")
				passed_count += 1
			else:
				print("✗ 玩家受伤测试失败")
				failed_count += 1
			
			# 测试治疗
			player.heal(1)
			if player.hp == 3:
				print("✓ 玩家治疗测试通过")
				passed_count += 1
			else:
				print("✗ 玩家治疗测试失败")
				failed_count += 1
		else:
			print("✗ 玩家创建失败")
			failed_count += 1
	else:
		print("✗ 玩家文件不存在")
		failed_count += 1

func _show_results():
	print("\n========================================")
	print("  测试结果: %d/%d 通过" % [passed_count, test_count])
	
	if failed_count == 0:
		print("  ✓ 所有测试通过！")
		print("========================================")
		test_passed.emit("全部通过")
	else:
		print("  ✗ 有 %d 个测试失败" % failed_count)
		print("  请检查错误信息")
		print("========================================")

# ============ 安全运行测试 ============

# 运行测试并返回结果
func run_quick_test() -> Dictionary:
	var result = {
		"passed": 0,
		"failed": 0,
		"errors": []
	}
	
	# 测试1: 道具系统
	var db = load("res://scripts/items/RobustItemSystem.gd").new()
	add_child(db)
	if db.get_random_item("weapon", 1):
		result.passed += 1
	else:
		result.failed += 1
		result.errors.append("道具系统失败")
	
	# 测试2: 敌人生成
	var spawner = load("res://scripts/enemies/RobustEnemySystem.gd").EnemySpawner.new()
	add_child(spawner)
	var enemy = spawner.spawn_enemy(0, Vector2.ZERO, 1)
	if enemy:
		result.passed += 1
	else:
		result.failed += 1
		result.errors.append("敌人生成失败")
	
	# 测试3: 玩家创建
	var player = load("res://scripts/player/RobustPlayer.gd").new()
	add_child(player)
	if player.hp > 0:
		result.passed += 1
	else:
		result.failed += 1
		result.errors.append("玩家创建失败")
	
	return result

# ============ 工具方法 ============

# 安全获取节点
func safe_get_node(path: String) -> Node:
	if has_node(path):
		return get_node(path)
	return null

# 安全调用方法
func safe_call(node: Node, method_name: String, default = null):
	if node and node.has_method(method_name):
		return node.call(method_name)
	return default

# 检查节点是否有效
func is_valid(node: Node) -> bool:
	return node and is_instance_valid(node)
