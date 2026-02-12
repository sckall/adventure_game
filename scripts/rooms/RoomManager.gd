extends Node

# ============ 以撒风格房间系统 ============
# 核心：网格布局的房间，探索型关卡

class_name RoomManager

# 房间类型
enum RoomType {
	NORMAL,      # 普通战斗房间
	TREASURE,    # 宝藏房
	SHOP,        # 商店
	START,       # 起始房间
	EXIT,        # 出口房间
	SECRET,      # 密室
	MINIBOSS,    # 迷你Boss房
	BOSS,        # Boss房
	TRAP,        # 陷阱房
}

# 房间数据
class RoomData:
	var type: RoomType = RoomType.NORMAL
	var grid_pos: Vector2i = Vector2i.ZERO  # 网格位置
	var room_id: int = 0  # 房间唯一ID
	var size: Vector2i = Vector2i(5, 5)  # 房间大小（格子）
	var enemies: Array = []  # 敌人列表
	var items: Array = []  # 道具列表
	var traps: Array = []  # 陷阱列表
	var is_cleared: bool = false  # 是否清理完毕
	var doors: Dictionary = {"north": false, "south": false, "east": false, "west": false}  # 门的状态
	var color: Color = Color(0.3, 0.3, 0.35)  # 房间颜色

	func _init(_type: RoomType = RoomType.NORMAL, _pos: Vector2i = Vector2i.ZERO):
		type = _type
		grid_pos = _pos
		room_id = _generate_id()

	static func _generate_id() -> int:
		return randi() % 100000

# 地图数据
var rooms: Dictionary = {}  # grid_pos -> RoomData
var map_size: Vector2i = Vector2i(5, 5)  # 地图网格大小
var current_room: RoomData = null
var player_start_pos: Vector2 = Vector2.ZERO

# 相机设置
const ROOM_WIDTH = 1280
const ROOM_HEIGHT = 720
const TILE_SIZE = 32

# 信号
signal room_entered(room: RoomData)
signal room_cleared(room: RoomData)
signal all_rooms_cleared()

func _ready():
	pass

# ============ 地图生成 ============

# 生成完整地图
func generate_map(seed_value: int = 0) -> void:
	if seed_value != 0:
		seed(seed_value)
	
	rooms.clear()
	
	# 1. 生成房间位置
	var room_positions = _generate_room_positions()
	
	# 2. 创建房间
	for pos in room_positions:
		var room_type = _determine_room_type(pos, room_positions.size())
		var room = RoomData.new(room_type, pos)
		_setup_room(room)
		rooms[pos] = room
	
	# 3. 连接房间
	_connect_rooms(room_positions)
	
	# 4. 设置起始房间
	current_room = rooms.get(Vector2i(2, 2))  # 地图中心
	
	print("Map Generated: %d rooms" % rooms.size())

# 生成房间位置
func _generate_room_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	var min_rooms = 8
	var max_rooms = 15
	var target_count = randi() % (max_rooms - min_rooms + 1) + min_rooms
	
	# 从中心开始
	positions.append(Vector2i(2, 2))
	
	while positions.size() < target_count:
		# 随机选择一个现有房间
		var existing = positions.pick_random()
		
		# 随机选择一个方向扩展
		var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
		var dir = directions.pick_random()
		var new_pos = existing + dir
		
		# 检查是否越界或已存在
		if new_pos.x < 0 or new_pos.x >= map_size.x or new_pos.y < 0 or new_pos.y >= map_size.y:
			continue
		if new_pos in positions:
			continue
		
		positions.append(new_pos)
	
	return positions

# 确定房间类型
func _determine_room_type(pos: Vector2i, total_rooms: int) -> RoomType:
	# 起始房间（中心）
	if pos == Vector2i(2, 2):
		return RoomType.START
	
	# Boss房（最远的一个房间）
	if positions_farthest_from_center().has(pos):
		return RoomType.BOSS
	
	# 5%概率是宝藏房
	if randf() < 0.05:
		return RoomType.TREASURE
	
	# 8%概率是商店
	if randf() < 0.08:
		return RoomType.SHOP
	
	# 3%概率是密室
	if randf() < 0.03:
		return RoomType.SECRET
	
	# 5%概率是陷阱房
	if randf() < 0.05:
		return RoomType.TRAP
	
	return RoomType.NORMAL

func positions_farthest_from_center() -> Array[Vector2i]:
	var farthest: Array[Vector2i] = []
	var max_dist = 0
	
	for pos in rooms:
		var dist = pos.distance_to(Vector2i(2, 2))
		if dist > max_dist:
			max_dist = dist
			farthest = [pos]
		elif dist == max_dist:
			farthest.append(pos)
	
	return farthest

# 设置房间内容
func _setup_room(room: RoomData) -> void:
	match room.type:
		RoomType.START:
			room.color = Color(0.2, 0.6, 0.3)  # 绿色
			room.size = Vector2i(5, 4)
			# 起始房间有出口
		
		RoomType.BOSS:
			room.color = Color(0.5, 0.1, 0.1)  # 深红色
			room.size = Vector2i(6, 5)
			room.enemies = _generate_boss_enemies()
		
		RoomType.SHOP:
			room.color = Color(0.6, 0.5, 0.2)  # 金色
			room.size = Vector2i(4, 3)
			room.items = _generate_shop_items()
		
		RoomType.TREASURE:
			room.color = Color(0.8, 0.7, 0.2)  # 金黄色
			room.size = Vector2i(3, 3)
			room.items = _generate_treasure_items()
			room.enemies = []
		
		RoomType.SECRET:
			room.color = Color(0.3, 0.2, 0.5)  # 紫色
			room.size = Vector2i(3, 3)
			room.items = _generate_secret_items()
		
		RoomType.TRAP:
			room.color = Color(0.4, 0.2, 0.2)  # 红褐色
			room.size = Vector2i(4, 4)
			room.traps = _generate_traps()
		
		RoomType.NORMAL:
			room.color = Color(0.3, 0.3, 0.35)  # 灰色
			room.size = Vector2i(5, 4)
			room.enemies = _generate_normal_enemies()
			if randf() < 0.3:
				room.items = [_generate_random_item()]

# 连接房间（创建门）
func _connect_rooms(positions: Array[Vector2i]) -> void:
	for pos in positions:
		var room = rooms[pos]
		
		# 检查四个方向是否有相邻房间
		if positions.has(pos + Vector2i(0, -1)):
			room.doors["north"] = true
		if positions.has(pos + Vector2i(0, 1)):
			room.doors["south"] = true
		if positions.has(pos + Vector2i(-1, 0)):
			room.doors["west"] = true
		if positions.has(pos + Vector2i(1, 0)):
			room.doors["east"] = true

# ============ 房间生成内容 ============

func _generate_normal_enemies() -> Array:
	var enemies = []
	var count = randi_range(1, 3)
	var types = ["slime", "bat", "hedgehog", "snail"]
	
	for i in range(count):
		enemies.append({
			"type": types.pick_random(),
			"level": _get_current_floor()
		})
	
	return enemies

func _generate_boss_enemies() -> Array:
	return [{"type": "boss", "level": _get_current_floor()}]

func _generate_shop_items() -> Array:
	var items = []
	var count = randi_range(3, 5)
	var categories = ["weapon", "armor", "potion", "scroll"]
	
	for i in range(count):
		items.append({
			"type": categories.pick_random(),
			"level": _get_current_floor(),
			"price": randi_range(10, 50) * _get_current_floor()
		})
	
	return items

func _generate_treasure_items() -> Array:
	var items = []
	var count = randi_range(2, 4)
	var categories = ["artifact", "ring", "trinket"]
	
	for i in range(count):
		items.append({
			"type": categories.pick_random(),
			"level": _get_current_floor() + 1,
			"rarity": randi_range(3, 5)
		})
	
	return items

func _generate_secret_items() -> Array:
	return [{"type": "special", "level": _get_current_floor() + 2, "rarity": 4}]

func _generate_traps() -> Array:
	var traps = []
	var types = ["fire", "poison", "lightning", "paralysis"]
	var count = randi_range(2, 4)
	
	for i in range(count):
		traps.append({
			"type": types.pick_random(),
			"level": _get_current_floor()
		})
	
	return traps

func _generate_random_item() -> Dictionary:
	var categories = ["weapon", "armor", "potion", "scroll", "food"]
	return {
		"type": categories.pick_random(),
		"level": _get_current_floor()
	}

func _get_current_floor() -> int:
	return 1  # 简化：当前楼层

# ============ 房间切换 ============

# 进入房间
func enter_room(pos: Vector2i) -> RoomData:
	var room = rooms.get(pos)
	if room:
		current_room = room
		room_entered.emit(room)
		
		# 检查是否所有敌人都被击败
		if room.enemies.is_empty() and not room.is_cleared:
			_open_all_doors()
			room.is_cleared = true
			room_cleared.emit(room)
		
		# 检查是否所有房间都清理完毕
		if _all_rooms_cleared():
			all_rooms_cleared.emit()
	
	return room

# 打开门
func _open_all_doors() -> void:
	if current_room:
		for dir in current_room.doors:
			current_room.doors[dir] = false

# 检查所有房间是否清理完毕
func _all_rooms_cleared() -> bool:
	for pos in rooms:
		var room = rooms[pos]
		if room.type != RoomType.SHOP and room.type != RoomType.SECRET:
			if not room.is_cleared:
				return false
	return true

# ============ 获取相邻房间 ============

func get_adjacent_room(direction: String) -> RoomData:
	if not current_room:
		return null
	
	var offset = Vector2i.ZERO
	match direction:
		"north": offset = Vector2i(0, -1)
		"south": offset = Vector2i(0, 1)
		"east": offset = Vector2i(1, 0)
		"west": offset = Vector2i(-1, 0)
	
	var target = current_room.grid_pos + offset
	return rooms.get(target)

# ============ 获取房间位置（用于绘制） ============

func get_room_world_position(grid_pos: Vector2i) -> Vector2:
	# 每个房间间隔一定距离
	var spacing = Vector2(ROOM_WIDTH + 100, ROOM_HEIGHT + 100)
	return Vector2(grid_pos.x * spacing.x, grid_pos.y * spacing.y)

# ============ 地图信息 ============

func get_map_summary() -> String:
	var summary = "=== 地图概览 ===\n"
	summary += "房间总数: %d\n" % rooms.size()
	
	var cleared = 0
	for pos in rooms:
		if rooms[pos].is_cleared:
			cleared += 1
	
	summary += "清理完毕: %d\n" % cleared
	summary += "待清理: %d\n" % (rooms.size() - cleared)
	
	return summary
