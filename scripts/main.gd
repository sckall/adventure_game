extends Node2D

# ============ 简化的主游戏脚本 ============
# 专注于玩家与敌人的对战

@onready var player = $Player
@onready var audio = get_node("/root/AudioManager")
@onready var camera = $Camera2D

var g = null

# 敌人列表
var enemies = []

# UI引用
var boss_intro_ui: Control = null
var combat_stats_panel: Control = null
var death_replay_ui: Control = null
var death_replay_system = null
var current_boss = null

# 地图设置
const LEVEL_WIDTH = 3000
const LEVEL_HEIGHT = 600

func _ready() -> void:
	g = get_node("/root/Global")
	g.current_state = g.GameState.PLAYING

	audio.play_bgm()

	# 设置相机
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = LEVEL_WIDTH
	camera.limit_bottom = LEVEL_HEIGHT
	camera.position_smoothing_enabled = true

	# 初始化UI
	_init_ui_systems()

	# 连接玩家死亡信号
	if is_instance_valid(player):
		player.player_died.connect(_on_player_died)

	# 创建简单的平地关卡
	create_simple_level()

func _init_ui_systems():
	# Boss预告UI
	var boss_intro_scene = load("res://scenes/boss_intro_ui.tscn")
	if boss_intro_scene:
		boss_intro_ui = boss_intro_scene.instantiate()
		$CanvasLayer.add_child(boss_intro_ui)

	# 战斗统计面板
	var stats_scene = load("res://scenes/combat_stats_panel.tscn")
	if stats_scene:
		combat_stats_panel = stats_scene.instantiate()
		$CanvasLayer.add_child(combat_stats_panel)

	# 死亡回放系统
	death_replay_system = DeathReplaySystem.new()
	add_child(death_replay_system)

	# 死亡回放UI
	var replay_ui_scene = load("res://scenes/death_replay_ui.tscn")
	if replay_ui_scene:
		death_replay_ui = replay_ui_scene.instantiate()
		$CanvasLayer.add_child(death_replay_ui)

func create_simple_level():
	# 清理旧关卡
	for child in $Level.get_children():
		child.queue_free()
	enemies.clear()
	g.reset_level_data()

	# 添加玩家到组
	if not player.is_in_group("player"):
		player.add_to_group("player")

	# 创建地面（简单的平地）
	create_ground()

	# 在地图上放置敌人
	spawn_enemies()

	# 创建终点
	create_exit()

	# 设置玩家位置
	player.position = Vector2(150, 530)

func create_ground():
	# 主地面
	var ground = StaticBody2D.new()
	ground.position = Vector2(LEVEL_WIDTH / 2, 580)
	ground.add_to_group("ground")

	# 碰撞
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(LEVEL_WIDTH + 200, 100)
	collision.shape = shape
	collision.position = Vector2(0, 50)
	ground.add_child(collision)

	# 可视
	var rect = ColorRect.new()
	rect.size = Vector2(LEVEL_WIDTH + 200, 100)
	rect.position = Vector2(-(LEVEL_WIDTH + 200) / 2, 0)
	rect.color = Color(0.35, 0.55, 0.25)  # 草地绿
	ground.add_child(rect)

	$Level.add_child(ground)

func spawn_enemies():
	var resource_mgr = get_node("/root/ResourceManager")

	# 根据关卡数放置敌人
	var enemy_count = 5 + g.current_level_num * 2
	
	for i in range(enemy_count):
		var x = 400 + randi() % (LEVEL_WIDTH - 600)
		var y = 530 - randi() % 100  # 不同高度的平台
		
		# 随机选择敌人类型
		var enemy_types = ["slime", "bat", "hedgehog", "snail", "snake", "spider", "skeleton"]
		if g.current_level_num >= 3:
			enemy_types.append("boss")
		
		var enemy_type = enemy_types.pick_random()
		
		match enemy_type:
			"slime":
				var slime = resource_mgr.instantiate_scene("slime")
				if slime:
					slime.position = Vector2(x, y)
					slime.color_name = ["green", "blue", "pink", "yellow"].pick_random()
					slime.patrol_distance = 80 + randi() % 40
					$Level.add_child(slime)
					enemies.append(slime)
			
			"bat":
				var bat = resource_mgr.instantiate_scene("bat")
				if bat:
					bat.position = Vector2(x, y - 80)
					bat.color_name = ["purple", "red"].pick_random()
					$Level.add_child(bat)
					enemies.append(bat)
			
			"hedgehog":
				var hedgehog = resource_mgr.instantiate_scene("hedgehog")
				if hedgehog:
					hedgehog.position = Vector2(x, y)
					hedgehog.color_name = ["brown", "gray"].pick_random()
					$Level.add_child(hedgehog)
					enemies.append(hedgehog)
			
			"snail":
				var snail = resource_mgr.instantiate_scene("snail")
				if snail:
					snail.position = Vector2(x, y)
					snail.color_name = ["purple", "green"].pick_random()
					$Level.add_child(snail)
					enemies.append(snail)
			
			"snake":
				var snake = resource_mgr.instantiate_scene("snake")
				if snake:
					snake.position = Vector2(x, y)
					snake.color_name = ["green", "red"].pick_random()
					$Level.add_child(snake)
					enemies.append(snake)
			
			"spider":
				var spider = resource_mgr.instantiate_scene("spider")
				if spider:
					spider.position = Vector2(x, y - 120)
					spider.color_name = "black"
					$Level.add_child(spider)
					enemies.append(spider)
			
			"skeleton":
				var skeleton = resource_mgr.instantiate_scene("skeleton")
				if skeleton:
					skeleton.position = Vector2(x, y - 20)
					$Level.add_child(skeleton)
					enemies.append(skeleton)
			
			"boss":
				if current_boss == null:
					var boss = resource_mgr.instantiate_scene("ai_boss")
					if boss:
						boss.position = Vector2(x, y)
						boss.boss_name = "BOSS"
						boss.max_hp = 10 + g.current_level_num * 5
						boss.hp = boss.max_hp
						$Level.add_child(boss)
						enemies.append(boss)
						current_boss = boss
						boss.boss_defeated.connect(_on_boss_defeated)

func create_exit():
	var exit = Area2D.new()
	exit.name = "Exit"
	exit.position = Vector2(LEVEL_WIDTH - 100, 520)

	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(50, 80)
	exit.add_child(shape)

	# 出口视觉效果
	var rect = ColorRect.new()
	rect.size = Vector2(50, 80)
	rect.position = Vector2(-25, -40)
	rect.color = Color(1.0, 0.85, 0.2)
	exit.add_child(rect)

	var glow = ColorRect.new()
	glow.size = Vector2(60, 90)
	glow.position = Vector2(-30, -45)
	glow.color = Color(1.0, 0.95, 0.4, 0.5)
	glow.z_index = -1
	exit.add_child(glow)

	exit.body_entered.connect(_on_exit_entered)
	$Level.add_child(exit)

func _on_exit_entered(body: Node2D):
	if body.name == "Player":
		# 检查是否所有敌人都被击败
		var all_defeated = true
		for e in enemies:
			if is_instance_valid(e) and e.has_method("get_hp") and e.get_hp() > 0:
				all_defeated = false
				break
		
		if all_defeated:
			complete_level()
		else:
			show_message("击败所有敌人才能通过！")

func show_message(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position.y = 100
	$CanvasLayer.add_child(label)
	
	await get_tree().create_timer(2.0).timeout
	label.queue_free()

func complete_level():
	g.complete_level()
	show_victory()

func show_victory():
	g.current_state = g.GameState.VICTORY
	$CanvasLayer/VictoryPanel.visible = true
	
	var score = g.calculate_score()
	$CanvasLayer/VictoryPanel/VBox/Title.text = "🎉 第 %d 关完成！" % g.current_level_num
	$CanvasLayer/VictoryPanel/VBox/Score.text = "得分: %d" % score
	$CanvasLayer/VictoryPanel/VBox/Total.text = "总得分: %d" % g.calculate_total_score()

func _process(delta):
	# 相机跟随
	if player and is_instance_valid(player):
		camera.position = camera.position.lerp(player.position, 5.0 * delta)
	
	# 更新关卡信息
	$CanvasLayer/LevelLabel.text = "第 %d 关 - 击败所有敌人！" % g.current_level_num

func _on_player_died():
	print("Main: 玩家死亡！")
	
	if death_replay_system:
		var replay_data = death_replay_system.stop_recording()
		if death_replay_ui and not replay_data.is_empty():
			death_replay_ui.show_death_replay(death_replay_system, replay_data)

func _on_boss_defeated():
	print("Boss被击败！")
	current_boss = null
	
	if combat_stats_panel:
		combat_stats_panel.hide_panel()
	
	await get_tree().create_timer(1.0).timeout
	complete_level()

func _on_death_retry_requested():
	# 重试关卡
	player.hp = player.max_hp
	player.position = Vector2(150, 530)
	player.velocity = Vector2.ZERO
	
	if death_replay_ui:
		death_replay_ui.hide()
	
	create_simple_level()
