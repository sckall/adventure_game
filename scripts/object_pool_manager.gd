extends Node

# ============ 对象池管理器 ============
# 用于管理频繁创建/销毁的对象，减少GC压力

# 对象池配置
const POOL_CONFIG = {
	"particles": { "size": 20, "scene": null, "type": "cpu_particles" },
	"projectiles": { "size": 15, "scene": null, "type": "projectile" },
	"collision_shapes": { "size": 30, "scene": null, "type": "collision_shape" },
	"color_rects": { "size": 30, "scene": null, "type": "color_rect" }
}

# 对象池存储
var pools: Dictionary = {}

# 初始化对象池
func _ready() -> void:
	_initialize_pools()

# 初始化所有对象池
func _initialize_pools() -> void:
	for pool_name: String in POOL_CONFIG:
		_create_pool(pool_name, POOL_CONFIG[pool_name].size, POOL_CONFIG[pool_name].type)

# 创建单个对象池
func _create_pool(pool_name: String, size: int, type: String) -> void:
	pools[pool_name] = []

	for i: int in size:
		var obj: Node = _create_pooled_object(type)
		if obj:
			obj.set_meta("pool_name", pool_name)
			obj.set_meta("active", false)
			add_child(obj)
			obj.process_mode = Node.PROCESS_MODE_DISABLED
			obj.visible = false
			pools[pool_name].append(obj)

# 创建池化对象
func _create_pooled_object(type: String) -> Node:
	match type:
		"cpu_particles":
			var particles: CPUParticles2D = CPUParticles2D.new()
			particles.one_shot = true
			return particles
		"collision_shape":
			return CollisionShape2D.new()
		"color_rect":
			return ColorRect.new()
		"projectile":
			var projectile: Area2D = Area2D.new()
			var shape: CollisionShape2D = CollisionShape2D.new()
			shape.shape = CircleShape2D.new()
			projectile.add_child(shape)
			return projectile
		_:
			print("ObjectPoolManager WARNING: Unknown pool type: %s" % type)
			return null

# 从对象池获取对象
func get_object(pool_name: String) -> Node:
	if not pools.has(pool_name):
		print("ObjectPoolManager ERROR: Pool not found: %s" % pool_name)
		return null

	var pool: Array = pools[pool_name]

	# 查找非活跃对象
	for obj: Node in pool:
		if not obj.get_meta("active", false):
			obj.set_meta("active", true)
			obj.process_mode = Node.PROCESS_MODE_INHERIT
			obj.visible = true
			return obj

	# 池已满，创建新对象（可选：扩展池）
	print("ObjectPoolManager WARNING: Pool '%s' exhausted, creating new object" % pool_name)
	var type: String = POOL_CONFIG[pool_name].type
	var new_obj: Node = _create_pooled_object(type)
	if new_obj:
		new_obj.set_meta("pool_name", pool_name)
		new_obj.set_meta("active", true)
		pool.append(new_obj)
		add_child(new_obj)
	return new_obj

# 归还对象到池
func return_object(obj: Node) -> void:
	if not obj or not obj.has_meta("pool_name"):
		return

	var pool_name: String = obj.get_meta("pool_name")
	obj.set_meta("active", false)
	obj.process_mode = Node.PROCESS_MODE_DISABLED
	obj.visible = false

	# 重置对象状态
	if obj is CPUParticles2D:
		obj.emitting = false
	elif obj is Area2D:
		obj.position = Vector2(-10000, -10000)  # 移出屏幕

# 预热对象池（确保池中有足够的对象）
func warm_pool(pool_name: String, count: int) -> void:
	if not pools.has(pool_name):
		return

	var pool: Array = pools[pool_name]
	var current_size: int = pool.size()

	if current_size >= count:
		return

	var type: String = POOL_CONFIG[pool_name].type
	for i: int in (count - current_size):
		var obj: Node = _create_pooled_object(type)
		if obj:
			obj.set_meta("pool_name", pool_name)
			obj.set_meta("active", false)
			add_child(obj)
			obj.process_mode = Node.PROCESS_MODE_DISABLED
			obj.visible = false
			pool.append(obj)

# 清理所有对象池
func clear_pools() -> void:
	for pool_name: String in pools:
		var pool: Array = pools[pool_name]
		for obj: Node in pool:
			if is_instance_valid(obj):
				obj.queue_free()
	pools.clear()

# 获取池统计信息
func get_pool_stats() -> Dictionary:
	var stats: Dictionary = {}
	for pool_name: String in pools:
		var pool: Array = pools[pool_name]
		var active_count: int = 0
		for obj: Node in pool:
			if obj.get_meta("active", false):
				active_count += 1
		stats[pool_name] = {
			"total": pool.size(),
			"active": active_count,
			"inactive": pool.size() - active_count
		}
	return stats
