extends Node
class_name DeathReplaySystem

# ============ 死亡回放系统 ============
# 记录玩家死亡前的战斗过程，支持回放分析

const MAX_REPLAY_DURATION: float = 10.0  # 最多记录10秒
const RECORD_INTERVAL: float = 1.0 / 30.0  # 30 FPS记录

# 回放帧数据
class ReplayFrame:
	var timestamp: float
	var player_position: Vector2
	var player_velocity: Vector2
	var player_hp: int
	var player_facing: float
	var boss_position: Vector2
	var boss_hp: int
	var boss_state: int
	var attack_active: bool

	func _init(t: float, pp: Vector2, pv: Vector2, php: int, pf: float, bp: Vector2, bhp: int, bs: int, aa: bool):
		timestamp = t
		player_position = pp
		player_velocity = pv
		player_hp = php
		player_facing = pf
		boss_position = bp
		boss_hp = bhp
		boss_state = bs
		attack_active = aa

	func to_dict() -> Dictionary:
		return {
			"timestamp": timestamp,
			"player_position": var_to_str(player_position),
			"player_velocity": var_to_str(player_velocity),
			"player_hp": player_hp,
			"player_facing": player_facing,
			"boss_position": var_to_str(boss_position),
			"boss_hp": boss_hp,
			"boss_state": boss_state,
			"attack_active": attack_active
		}

	static func from_dict(d: Dictionary) -> ReplayFrame:
		return ReplayFrame.new(
			d["timestamp"],
			str_to_var(d["player_position"]),
			str_to_var(d["player_velocity"]),
			d["player_hp"],
			d["player_facing"],
			str_to_var(d["boss_position"]),
			d["boss_hp"],
			d["boss_state"],
			d["attack_active"]
		)

# 当前记录数据
var is_recording: bool = false
var recording_start_time: float = 0.0
var last_record_time: float = 0.0
var current_frames: Array[ReplayFrame] = []

# 回放状态
var is_replaying: bool = false
var replay_frames: Array[ReplayFrame] = []
var replay_current_frame: int = 0
var replay_start_time: float = 0.0

# 引用
var player_ref: Node2D
var boss_ref: Node2D

# 信号
signal replay_started()
signal replay_finished()
signal replay_frame_changed(frame_index: int, total_frames: int)

func _ready():
	pass

# ============ 录制功能 ============

# 开始录制
func start_recording(player: Node2D, boss: Node2D):
	player_ref = player
	boss_ref = boss

	is_recording = true
	recording_start_time = Time.get_ticks_msec() / 1000.0
	last_record_time = 0.0
	current_frames.clear()

	print("[DeathReplay] 开始录制...")

# 停止录制并保存回放数据
func stop_recording() -> Dictionary:
	is_recording = false

	var replay_data: Dictionary = {
		"duration": Time.get_ticks_msec() / 1000.0 - recording_start_time,
		"frame_count": current_frames.size(),
		"frames": []
	}

	for frame in current_frames:
		replay_data["frames"].append(frame.to_dict())

	print("[DeathReplay] 录制完成，共 %d 帧" % replay_data["frame_count"])
	return replay_data

# 记录一帧（每帧调用）
func record_frame():
	if not is_recording:
		return

	var current_time = Time.get_ticks_msec() / 1000.0 - recording_start_time

	# 限制录制时长
	if current_time > MAX_REPLAY_DURATION:
		current_frames.pop_front()  # 移除最老的帧

	# 限制记录频率
	if current_time - last_record_time < RECORD_INTERVAL:
		return

	last_record_time = current_time

	# 收集数据
	var frame = ReplayFrame.new(
		current_time,
		player_ref.position if player_ref else Vector2.ZERO,
		player_ref.velocity if player_ref and "velocity" in player_ref else Vector2.ZERO,
		player_ref.hp if player_ref and "hp" in player_ref else 0,
		player_ref.scale.x if player_ref else 1.0,
		boss_ref.position if boss_ref else Vector2.ZERO,
		boss_ref.hp if boss_ref and "hp" in boss_ref else 0,
		boss_ref.current_state if boss_ref and "current_state" in boss_ref else 0,
		boss_ref.is_attacking if boss_ref and "is_attacking" in boss_ref else false
	)

	current_frames.append(frame)

# ============ 回放功能 ============

# 开始回放
func start_replay(replay_data: Dictionary, player: Node2D, boss: Node2D):
	player_ref = player
	boss_ref = boss

	# 解析回放数据
	replay_frames.clear()
	for frame_dict in replay_data["frames"]:
		replay_frames.append(ReplayFrame.from_dict(frame_dict))

	if replay_frames.is_empty():
		print("[DeathReplay] 没有回放数据")
		return

	is_replaying = true
	replay_current_frame = 0
	replay_start_time = Time.get_ticks_msec() / 1000.0

	print("[DeathReplay] 开始回放，共 %d 帧" % replay_frames.size())

	replay_started.emit()

	# 禁用玩家控制
	if player_ref and player_ref.has_method("set_physics_process"):
		player_ref.set_physics_process(false)

# 停止回放
func stop_replay():
	is_replaying = false

	# 恢复玩家控制
	if player_ref and player_ref.has_method("set_physics_process"):
		player_ref.set_physics_process(true)

	print("[DeathReplay] 回放结束")
	replay_finished.emit()

# 更新回放（每帧调用）
func update_replay():
	if not is_replaying or replay_frames.is_empty():
		return

	var current_time = Time.get_ticks_msec() / 1000.0 - replay_start_time

	# 找到对应时间的帧
	while replay_current_frame < replay_frames.size():
		var frame = replay_frames[replay_current_frame]
		if frame.timestamp <= current_time:
			_apply_frame(frame)
			replay_frame_changed.emit(replay_current_frame, replay_frames.size())
			replay_current_frame += 1
		else:
			break

	# 回放结束
	if replay_current_frame >= replay_frames.size():
		stop_replay()

# 应用帧数据到场景
func _apply_frame(frame: ReplayFrame):
	if player_ref:
		player_ref.position = frame.player_position
		if "velocity" in player_ref:
			player_ref.velocity = frame.player_velocity
		if "hp" in player_ref:
			player_ref.hp = frame.player_hp
		player_ref.scale.x = frame.player_facing

	if boss_ref:
		boss_ref.position = frame.boss_position
		if "hp" in boss_ref:
			boss_ref.hp = frame.boss_hp
		if "current_state" in boss_ref:
			boss_ref.current_state = frame.boss_state
		if "is_attacking" in boss_ref:
			boss_ref.is_attacking = frame.attack_active

# 跳转到指定帧（用于拖动进度条）
func jump_to_frame(frame_index: int):
	if not is_replaying or frame_index < 0 or frame_index >= replay_frames.size():
		return

	replay_current_frame = frame_index
	var frame = replay_frames[frame_index]
	_apply_frame(frame)

# 获取回放进度
func get_replay_progress() -> float:
	if replay_frames.is_empty():
		return 0.0
	return float(replay_current_frame) / replay_frames.size()

# ============ 便捷函数 ============

# 是否正在录制或回放
func is_active() -> bool:
	return is_recording or is_replaying

# 获取录制时长
func get_recording_duration() -> float:
	if current_frames.is_empty():
		return 0.0
	return current_frames[-1].timestamp

# 清除当前录制
func clear_recording():
	current_frames.clear()
	is_recording = false

# 导出回放数据为JSON（用于保存）
func export_replay_json(replay_data: Dictionary) -> String:
	return JSON.stringify(replay_data)

# 从JSON导入回放数据
func import_replay_json(json_string: String) -> Dictionary:
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("[DeathReplay] JSON解析失败")
		return {}
	return json.data

# ============ 分析功能 ============

# 分析回放数据，返回战斗统计
func analyze_replay(replay_data: Dictionary) -> Dictionary:
	var frames = replay_data.get("frames", [])
	if frames.is_empty():
		return {}

	var analysis = {
		"player_damage_taken": 0,
		"boss_damage_dealt": 0,
		"total_attacks": 0,
		"avg_distance": 0.0,
		"time_in_danger": 0.0
	}

	var total_distance = 0.0
	var danger_threshold = 150.0  # 距离Boss小于150算危险
	var danger_frames = 0

	for i in range(frames.size()):
		var frame = ReplayFrame.from_dict(frames[i])
		var dist = frame.player_position.distance_to(frame.boss_position)
		total_distance += dist

		if dist < danger_threshold:
			danger_frames += 1

		# 检测Boss攻击
		if frame.attack_active:
			analysis["total_attacks"] += 1

	analysis["avg_distance"] = total_distance / frames.size() if frames.size() > 0 else 0
	analysis["time_in_danger"] = float(danger_frames) / frames.size() * 100 if frames.size() > 0 else 0

	return analysis
