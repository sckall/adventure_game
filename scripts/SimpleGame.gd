extends Node2D

# ============ 简单游戏主场景 ============

@onready var player = $Player
@onready var camera = $Camera2D

var dungeon: Node

func _ready():
	print("=== 游戏启动 ===")
	
	# 生成地牢
	dungeon = SimpleDungeon.new()
	add_child(dungeon)
	dungeon.generate(1)
	
	# 玩家位置
	player.position = Vector2(100, 500)
	
	print("=== 游戏就绪 ===")

func _process(delta):
	# 相机跟随
	camera.position = camera.position.lerp(player.position, 5.0 * delta)
	
	# 简单的敌人AI
	for enemy in dungeon.enemies:
		if is_instance_valid(enemy):
			# 向玩家移动
			var dir = (player.position - enemy.position).normalized()
			enemy.position += dir * 30.0 * delta
			
			# 旋转眼睛朝向玩家
			for child in enemy.get_children():
				if child.name == "" and child is ColorRect and child.size == Vector2(6, 6):
					child.position.x = -10 if dir.x < 0 else 4
