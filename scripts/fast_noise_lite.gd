extends RefCounted

# ============ 简化噪声生成器 ============
# 内置实现，无需外部插件

# 噪声类型
enum NoiseType { PERLIN, VALUE, SIMPLEX }

var _seed: int = 0
var _noise_type: int = NoiseType.PERLIN
var _frequency: float = 1.0
var _octaves: int = 1
var _lacunarity: float = 2.0
var _persistence: float = 0.5
var _offset: Vector2 = Vector2.ZERO

# 排列表用于优化
var _permutation: Array[int] = []

func _init() -> void:
	set_seed(_seed)

# 设置种子
func set_seed(seed: int) -> void:
	_seed = seed
	_generate_permutation()

# 生成排列表
func _generate_permutation() -> void:
	_permutation.clear()
	for i in range(256):
		_permutation.append(i)

	# 使用种子打乱
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _seed
	for i in range(256):
		var j: int = rng.randi_range(0, 255)
		var temp: int = _permutation[i]
		_permutation[i] = _permutation[j]
		_permutation[j] = temp

	# 复制排列表以避免溢出
	for i in range(256):
		_permutation.append(_permutation[i])

# 淡入淡出函数
func _fade(t: float) -> float:
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)

# 线性插值
func _lerp(a: float, b: float, t: float) -> float:
	return a + t * (b - a)

# 梯度计算
func _grad(hash: int, x: float, y: float, z: float = 0.0) -> Vector3:
	var h: int = hash & 15
	var u: float
	var v: float

	if h < 8:
		u = x if h < 4 else y
		v = y if h < 4 else z
	else:
		u = y if h == 12 or h == 14 else x
		v = z if h < 8 else x

	return (Vector3(u, v, 0.0) * 2.0 - Vector3(1.0, 1.0, 0.0)) * (1.0 - (h & 1))

# 获取2D噪声值
func get_noise_2d(x: float, y: float) -> float:
	var nx: float = x * _frequency + _offset.x
	var ny: float = y * _frequency + _offset.y

	return _perlin_noise_2d(nx, ny)

# Perlin噪声2D
func _perlin_noise_2d(x: float, y: float) -> float:
	var xi: int = int(floor(x)) & 255
	var yi: int = int(floor(y)) & 255
	var xf: float = x - floor(x)
	var yf: float = y - floor(y)

	var u: float = _fade(xf)
	var v: float = _fade(yf)

	var aaa: float = _grad(_permutation[xi + _permutation[yi]], xf, yf).x
	var aba: float = _grad(_permutation[xi + 1 + _permutation[yi]], xf - 1, yf).x
	var aab: float = _grad(_permutation[xi + _permutation[yi + 1]], xf, yf - 1).x
	var abb: float = _grad(_permutation[xi + 1 + _permutation[yi + 1]], xf - 1, yf - 1).x

	var x1: float = _lerp(aaa, aba, u)
	var x2: float = _lerp(aab, abb, u)

	return _lerp(x1, x2, v)

# 获取分形噪声（多层叠加）
func get_noise_2d_fractal(x: float, y: float, octaves: int = 4) -> float:
	var total: float = 0.0
	var frequency: float = _frequency
	var amplitude: float = 1.0
	var max_value: float = 0.0

	for i in range(octaves):
		total += get_noise_2d(x * frequency, y * frequency) * amplitude
		max_value += amplitude
		amplitude *= _persistence
		frequency *= _lacunarity

	return total / max_value

# 设置频率
func set_frequency(freq: float) -> void:
	_frequency = freq

# 设置八度音阶
func set_octaves(oct: int) -> void:
	_octaves = oct

# 设置持续性
func set_persistence(persist: float) -> void:
	_persistence = persist

# 设置空隙度
func set_lacunarity(lac: float) -> void:
	_lacunarity = lac

# 设置偏移
func set_offset(x: float, y: float) -> void:
	_offset = Vector2(x, y)

# 获取3D噪声值
func get_noise_3d(x: float, y: float, z: float) -> float:
	var nx: float = x * _frequency
	var ny: float = y * _frequency
	var nz: float = z * _frequency

	return _perlin_noise_3d(nx, ny, nz)

# Perlin噪声3D
func _perlin_noise_3d(x: float, y: float, z: float) -> float:
	var xi: int = int(floor(x)) & 255
	var yi: int = int(floor(y)) & 255
	var zi: int = int(floor(z)) & 255
	var xf: float = x - floor(x)
	var yf: float = y - floor(y)
	var zf: float = z - floor(z)

	var u: float = _fade(xf)
	var v: float = _fade(yf)
	var w: float = _fade(zf)

	var p_zi: int = _permutation[zi]
	var p_yi_zi: int = _permutation[yi + p_zi]
	var a: Vector3 = _grad(_permutation[xi + p_yi_zi], xf, yf, zf)
	var b: Vector3 = _grad(_permutation[xi + 1 + p_yi_zi], xf - 1, yf, zf)
	var p_yi_z1: int = _permutation[yi + 1 + p_zi]
	var c: Vector3 = _grad(_permutation[xi + p_yi_z1], xf, yf - 1, zf)
	var d: Vector3 = _grad(_permutation[xi + 1 + p_yi_z1], xf - 1, yf - 1, zf)

	var a1: float = _lerp(a.x, b.x, u)
	var b1: float = _lerp(c.x, d.x, u)
	var a2: float = _lerp(a.y, b.y, u)
	var b2: float = _lerp(c.y, d.y, u)

	return _lerp(_lerp(a1, b1, v), _lerp(a2, b2, v), w)
