extends Control

# ============ 以撒风格游戏UI ============

@onready var health_bar = $HealthBar
@onready var minimap = $Minimap
@onready var room_info = $RoomInfo
@onready var message_label = $MessageLabel
@onready var inventory = $Inventory
@onready var buffs = $Buffs

# 消息显示
var message_timer: float = 0.0
var current_message: String = ""

func _ready():
	pass

# ============ 显示消息 ============

func show_message(text: String):
	message_label.text = text
	message_label.modulate.a = 1.0
	message_timer = 2.0

func _process(delta):
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			# 淡出
			var tween = create_tween()
			tween.tween_property(message_label, "modulate:a", 0.0, 0.3)

# ============ 更新小地图 ============

func update_minimap(rooms: Dictionary, current_room):
	if not minimap:
		return
	
	# 清空小地图
	for child in minimap.get_children():
		child.queue_free()
	
	# 计算小地图范围
	var min_x = 9999
	var max_x = -9999
	var min_y = 9999
	var max_y = -9999
	
	for pos in rooms:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)
	
	var range_x = max_x - min_x + 1
	var range_y = max_y - min_y + 1
	
	var cell_size = 20
	var map_width = range_x * cell_size
	var map_height = range_y * cell_size
	
	# 绘制小地图背景
	var bg = ColorRect.new()
	bg.size = Vector2(map_width + 4, map_height + 4)
	bg.position = Vector2(-2, -2)
	bg.color = Color(0.1, 0.1, 0.1, 0.8)
	minimap.add_child(bg)
	
	# 绘制房间
	for pos in rooms:
		var room = rooms[pos]
		var cell = ColorRect.new()
		cell.size = Vector2(cell_size - 2, cell_size - 2)
		cell.position = Vector2(
			(pos.x - min_x) * cell_size + 1,
			(pos.y - min_y) * cell_size + 1
		)
		
		# 根据房间类型设置颜色
		var color = _get_room_color(room.type)
		
		# 当前房间高亮
		if room == current_room:
			cell.color = Color.WHITE
			# 添加外发光
			var glow = ColorRect.new()
			glow.size = cell.size + Vector2(4, 4)
			glow.position = cell.position - Vector2(2, 2)
			glow.color = Color(1, 1, 0, 0.5)
			minimap.add_child(glow)
		elif room.is_cleared:
			# 已清理的房间变暗
			color = color.darkened(0.5)
		
		cell.color = color
		minimap.add_child(cell)
		
		# 绘制连接线
		_draw_connections(minimap, pos, room, min_x, min_y, cell_size)

func _get_room_color(type: int) -> Color:
	match type:
		RoomManager.RoomType.START: return Color(0.2, 0.8, 0.3)  # 绿色
		RoomManager.RoomType.BOSS: return Color(0.9, 0.1, 0.1)  # 红色
		RoomManager.RoomType.SHOP: return Color(0.9, 0.8, 0.2)   # 金色
		RoomManager.RoomType.TREASURE: return Color(0.9, 0.7, 0.2)  # 金黄色
		RoomManager.RoomType.SECRET: return Color(0.6, 0.3, 0.8)  # 紫色
		RoomManager.RoomType.TRAP: return Color(0.5, 0.2, 0.2)   # 红褐色
		_: return Color(0.4, 0.4, 0.5)  # 灰色

func _draw_connections(parent: Node, pos: Vector2i, room: RoomData, offset_x: int, offset_y: int, cell_size: int):
	var center = Vector2(
		(pos.x - offset_x) * cell_size + cell_size / 2 + 1,
		(pos.y - offset_y) * cell_size + cell_size / 2 + 1
	)
	
	var line_color = Color(0.3, 0.3, 0.3)
	
	if room.doors.get("north", false):
		_draw_line(parent, center, Vector2(0, -cell_size/2), line_color)
	if room.doors.get("south", false):
		_draw_line(parent, center, Vector2(0, cell_size/2), line_color)
	if room.doors.get("east", false):
		_draw_line(parent, center, Vector2(cell_size/2, 0), line_color)
	if room.doors.get("west", false):
		_draw_line(parent, center, Vector2(-cell_size/2, 0), line_color)

func _draw_line(parent: Node, from: Vector2, offset: Vector2, color: Color):
	var line = Line2D.new()
	line.add_point(from)
	line.add_point(from + offset)
	line.width = 2
	line.default_color = color
	parent.add_child(line)

# ============ 显示房间信息 ============

func show_room_info(info: String):
	room_info.text = info

# ============ 生命值显示 ============

func update_health(current: int, max: int):
	if health_bar:
		health_bar.value = float(current) / max * 100

# ============ 物品栏 ============

func add_item_to_inventory(item: Dictionary):
	if inventory:
		inventory.add_item(item)

# ============ Buff显示 ============

func add_buff(buff_name: String, duration: float):
	if buffs:
		buffs.add_buff(buff_name, duration)

func remove_buff(buff_name: String):
	if buffs:
		buffs.remove_buff(buff_name)
