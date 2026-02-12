extends Node2D

# ============ 以撒风格游戏主控制器 ============
# 整合：房间系统、玩家、相机

@onready var player = $Player
@onready var camera = $Camera2D
@onready var ui = $CanvasLayer/UI

var room_manager: RoomManager
var current_room_scene: RoomScene = null

# 地图偏移量（用于切换房间时移动玩家）
var room_spacing: Vector2 = Vector2(1500, 900)

# 房间转换状态
var is_transitioning: bool = false
var transition_duration: float = 0.5

func _ready():
	room_manager = RoomManager.new()
	add_child(room_manager)
	
	# 生成地图
	room_manager.generate_map()
	
	# 显示初始房间
	_show_room(room_manager.current_room)
	
	# 连接信号
	room_manager.room_entered.connect(_on_room_entered)
	room_manager.room_cleared.connect(_on_room_cleared)
	room_manager.all_rooms_cleared.connect(_on_all_rooms_cleared)

func _show_room(room: RoomManager.RoomData):
	# 移除当前房间
	if current_room_scene:
		current_room_scene.queue_free()
	
	# 创建新房间
	current_room_scene = RoomScene.new()
	current_room_scene.name = "CurrentRoom"
	
	# 设置房间
	current_room_scene.setup(room, player)
	
	# 计算世界位置
	var world_pos = room_manager.get_room_world_position(room.grid_pos)
	current_room_scene.position = world_pos
	
	# 添加到场景
	add_child(current_room_scene)
	
	# 连接房间信号
	current_room_scene.door_entered.connect(_on_door_entered)
	current_room_scene.enemy_defeated.connect(_on_enemy_defeated)
	current_room_scene.item_collected.connect(_on_item_collected)
	current_room_scene.trap_triggered.connect(_on_trap_triggered)
	
	# 移动玩家到房间中心
	if room.type == RoomManager.RoomType.START:
		player.position = current_room_scene.position
		camera.position = player.position
	
	print("Entered room: %s at %s" % [RoomManager.RoomType.keys()[room.type], str(world_pos)])

func _on_door_entered(direction: String):
	if is_transitioning:
		return
	
	# 检查是否有相邻房间
	var next_room = room_manager.get_adjacent_room(direction)
	if not next_room:
		print("No room in that direction!")
		return
	
	# 开始房间转换
	_start_room_transition(next_room, direction)

func _start_room_transition(next_room: RoomManager.RoomData, direction: String):
	is_transitioning = true
	
	# 计算下一个房间的世界位置
	var next_pos = room_manager.get_room_world_position(next_room.grid_pos)
	var offset = Vector2.ZERO
	
	match direction:
		"north": offset = Vector2(0, -room_spacing.y)
		"south": offset = Vector2(0, room_spacing.y)
		"east": offset = Vector2(room_spacing.x, 0)
		"west": offset = Vector2(-room_spacing.x, 0)
	
	# 创建转换效果
	var transition = _create_transition_effect()
	add_child(transition)
	
	# 等待转换完成
	await get_tree().create_timer(transition_duration).timeout
	
	# 切换到新房间
	room_manager.enter_room(next_room.grid_pos)
	_show_room(next_room)
	
	# 移动玩家
	var target_player_pos = current_room_scene.position + _get_door_opposite_offset(direction)
	player.position = target_player_pos
	
	# 更新相机
	camera.position = player.position
	
	transition.queue_free()
	is_transitioning = false

func _get_door_opposite_offset(direction: String) -> Vector2:
	match direction:
		"north": return Vector2(0, 300)
		"south": return Vector2(0, -300)
		"east": return Vector2(-500, 0)
		"west": return Vector2(500, 0)
		_: return Vector2.ZERO

func _create_transition_effect() -> Control:
	var overlay = Control.new()
	overlay.name = "TransitionOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = Color.BLACK
	rect.modulate.a = 0.0
	overlay.add_child(rect)
	
	# 淡入淡出效果
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, transition_duration / 2)
	tween.tween_property(rect, "modulate:a", 0.0, transition_duration / 2)
	
	return overlay

func _process(delta):
	# 更新相机跟随
	if is_instance_valid(player):
		camera.position = camera.position.lerp(player.position, 5.0 * delta)
	
	# 更新小地图/UI
	_update_room_ui()

func _on_room_entered(room: RoomManager.RoomData):
	print("Room entered: %s" % RoomManager.RoomType.keys()[room.type])
	
	# 更新UI显示
	_update_room_info(room)

func _on_room_cleared(room: RoomManager.RoomData):
	print("Room cleared: %s" % room.grid_pos)
	
	# 显示完成提示
	_show_message("房间清理完毕！")
	
	# 打开所有门（如果有）
	# 这里不需要额外处理，RoomScene会自动打开

func _on_all_rooms_cleared():
	print("All rooms cleared!")
	_show_message("所有房间清理完毕！")
	
	# 显示地图完成统计
	var summary = room_manager.get_map_summary()
	print(summary)

func _on_enemy_defeated(enemy: Dictionary):
	print("Defeated: %s" % enemy.type)
	
	# 检查是否房间清理完毕
	if current_room_scene and current_room_scene.check_enemies_cleared():
		# 房间清理完成
		pass

func _on_item_collected(item: Dictionary):
	print("Collected: %s (rarity: %d)" % [item.get("type", "unknown"), item.get("rarity", 1)])
	
	# 应用道具效果
	_apply_item_effect(item)

func _on_trap_triggered(trap: Dictionary):
	print("Trap triggered: %s" % trap.type)

func _apply_item_effect(item: Dictionary):
	var type = item.get("type", "")
	var level = item.get("level", 1)
	
	match type:
		"weapon":
			# 生成武器并装备
			var weapon = ItemManager.new().spawn_weapon(level)
			_equip_weapon(weapon)
		"armor":
			var armor = ItemManager.new().spawn_armor(level)
			_equip_armor(armor)
		"potion":
			# 直接使用
			_use_potion(level)
		"scroll":
			_use_scroll(level)
		"food":
			_eat_food()
		"ring", "artifact", "trinket":
			_add_passive_item(type, level)

func _equip_weapon(weapon: Dictionary):
	print("Equipped weapon: damage=%d" % weapon.get("damage", 1))
	# TODO: 集成到玩家系统

func _equip_armor(armor: Dictionary):
	print("Equipped armor: defense=%d" % armor.get("defense", 1))
	# TODO: 集成到玩家系统

func _use_potion(level: int):
	print("Used potion (level %d)" % level)
	# TODO: 应用药水效果

func _use_scroll(level: int):
	print("Used scroll (level %d)" % level)
	# TODO: 应用卷轴效果

func _eat_food():
	print("Ate food")
	# TODO: 回复生命

func _add_passive_item(type: String, level: int):
	print("Added passive item: %s (level %d)" % [type, level])
	# TODO: 添加到玩家被动道具

func _update_room_ui():
	# 更新小地图
	if ui and ui.has_method("update_minimap"):
		ui.update_minimap(room_manager.rooms, room_manager.current_room)

func _update_room_info(room: RoomManager.RoomData):
	if ui and ui.has_method("show_room_info"):
		var info = "%s\n敌人: %d" % [
			RoomManager.RoomType.keys()[room.type],
			current_room_scene.get_remaining_enemies() if current_room_scene else 0
		]
		ui.show_room_info(info)

func _show_message(text: String):
	if ui:
		ui.show_message(text)

# ============ 公开方法 ============

func get_room_manager() -> RoomManager:
	return room_manager

func get_current_room() -> RoomScene:
	return current_room_scene

func is_transitioning_rooms() -> bool:
	return is_transitioning

# 跳转到指定房间（调试用）
func debug_goto_room(grid_x: int, grid_y: int):
	var pos = Vector2i(grid_x, grid_y)
	if room_manager.rooms.has(pos):
		room_manager.enter_room(pos)
		_show_room(room_manager.rooms[pos])
