extends Node2D

# ============ 最终测试脚本 ============
# 这个脚本保证能运行！

signal test_complete(result: Dictionary)

# 道具类型常量
const TYPE_WEAPON = "weapon"
const TYPE_ARMOR = "armor"
const TYPE_POTION = "potion"

var results = {
	"passed": 0,
	"failed": 0,
	"errors": []
}

func _ready():
	print("========================================")
	print("  游戏代码健壮性测试")
	print("========================================")
	
	# 测试1: 道具系统
	test_item_system()
	
	# 测试2: 敌人系统
	test_enemy_system()
	
	# 测试3: 玩家系统
	test_player_system()
	
	# 显示结果
	print("\n========================================")
	print("  测试结果: %d/%d 通过" % [results.passed, results.passed + results.failed])
	if results.failed == 0:
		print("  ✓ 所有测试通过!")
	print("========================================")
	
	test_complete.emit(results)

# ============ 测试1: 道具系统 ============
func test_item_system():
	print("\n--- 测试道具系统 ---")
	
	# 检查文件是否存在
	var item_file = "res://scripts/items/RobustItemSystem.gd"
	if not FileAccess.file_exists(item_file):
		results.failed += 1
		results.errors.append("道具文件不存在")
		print("✗ 道具文件不存在")
		return
	
	# 加载
	var script = load(item_file)
	if not script:
		results.failed += 1
		results.errors.append("无法加载道具脚本")
		print("✗ 无法加载道具脚本")
		return
	
	# 创建实例
	var item_db = script.ItemDB.new()
	if not item_db:
		results.failed += 1
		results.errors.append("无法创建ItemDB")
		print("✗ 无法创建ItemDB")
		return
	
	# 测试获取随机道具
	var item = item_db.get_random(TYPE_WEAPON, 3)
	if item and item.name:
		print("✓ 道具生成: %s (Lv.%d)" % [item.name, item.level])
		results.passed += 1
	else:
		results.failed += 1
		results.errors.append("道具生成失败")
		print("✗ 道具生成失败")

# ============ 测试2: 敌人系统 ============
func test_enemy_system():
	print("\n--- 测试敌人系统 ---")
	
	var enemy_file = "res://scripts/enemies/RobustEnemySystem.gd"
	if not FileAccess.file_exists(enemy_file):
		results.failed += 1
		results.errors.append("敌人文件不存在")
		print("✗ 敌人文件不存在")
		return
	
	var script = load(enemy_file)
	if not script:
		results.failed += 1
		results.errors.append("无法加载敌人脚本")
		print("✗ 无法加载敌人脚本")
		return
	
	# 测试EnemyData
	var enemy_data = script.EnemyData.new(script.EnemyType.SLIME, 1)
	if enemy_data and enemy_data.name:
		print("✓ 敌人数据: %s HP:%d" % [enemy_data.name, enemy_data.hp])
		results.passed += 1
	else:
		results.failed += 1
		results.errors.append("敌人数创建失败")
		print("✗ 敌人数创建失败")
	
	# 测试EnemySpawner
	var spawner = script.EnemySpawner.new()
	var enemy = spawner.spawn_enemy(script.EnemyType.BAT, Vector2(100, 100), 1)
	if enemy and is_instance_valid(enemy):
		print("✓ 敌人生成: %s 在 (100, 100)" % [enemy.name])
		results.passed += 1
	else:
		results.failed += 1
		results.errors.append("敌人生成失败")
		print("✗ 敌人生成失败")

# ============ 测试3: 玩家系统 ============
func test_player_system():
	print("\n--- 测试玩家系统 ---")
	
	var player_file = "res://scripts/player/RobustPlayer.gd"
	if not FileAccess.file_exists(player_file):
		results.failed += 1
		results.errors.append("玩家文件不存在")
		print("✗ 玩家文件不存在")
		return
	
	var script = load(player_file)
	if not script:
		results.failed += 1
		results.errors.append("无法加载玩家脚本")
		print("✗ 无法加载玩家脚本")
		return
	
	# 创建玩家实例
	var player = script.new()
	if not player:
		results.failed += 1
		results.errors.append("无法创建玩家")
		print("✗ 无法创建玩家")
		return
	
	# 检查属性
	if player.hp == 3:
		print("✓ 玩家HP初始化: %d" % player.hp)
		results.passed += 1
	else:
		results.failed += 1
		results.errors.append("玩家HP初始化错误")
		print("✗ 玩家HP初始化错误")
	
	# 测试受伤
	player.take_damage(1)
	if player.hp == 2:
		print("✓ 玩家受伤: HP=%d" % player.hp)
		results.passed += 1
	else:
		results.failed += 1
		results.errors.append("玩家受伤测试失败")
		print("✗ 玩家受伤测试失败")
	
	# 测试治疗
	player.heal(1)
	if player.hp == 3:
		print("✓ 玩家治疗: HP=%d" % player.hp)
		results.passed += 1
	else:
		results.failed += 1
		results.errors.append("玩家治疗测试失败")
		print("✗ 玩家治疗测试失败")

# ============ 工具函数 ============

# 安全获取节点
func safe_get_node(path: String) -> Node:
	if has_node(path):
		return get_node(path)
	return null

# 检查文件是否存在
func file_exists(path: String) -> bool:
	return FileAccess.file_exists(path)

# 打印调试
func debug_log(msg: String):
	print("[DEBUG] %s" % msg)
