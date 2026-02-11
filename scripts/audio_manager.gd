extends Node

# 音效管理器 - 完整的程序化音效系统
# 包含环境音效、战斗音效、UI音效

var jump_sfx: AudioStreamPlayer
var attack_sfx: AudioStreamPlayer
var hurt_sfx: AudioStreamPlayer
var collect_sfx: AudioStreamPlayer
var enemy_death_sfx: AudioStreamPlayer
var ui_sfx: AudioStreamPlayer
var footstep_sfx: AudioStreamPlayer
var land_sfx: AudioStreamPlayer
var boss_music: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

# 环境音效状态
var is_footstep_playing: bool = false
var footstep_timer: float = 0.0

# 背景音乐播放器
var bgm_player: AudioStreamPlayer

func _ready():
	# 创建音效播放器
	jump_sfx = create_sfx_player()
	attack_sfx = create_sfx_player()
	hurt_sfx = create_sfx_player()
	collect_sfx = create_sfx_player()
	enemy_death_sfx = create_sfx_player()
	ui_sfx = create_sfx_player()
	footstep_sfx = create_sfx_player()
	land_sfx = create_sfx_player()
	boss_music = create_sfx_player()
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "Ambient"
	add_child(ambient_player)
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	add_child(bgm_player)
	
	# 启动环境音效
	_play_ambient_sounds()

func create_sfx_player() -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.bus = "SFX"
	add_child(player)
	return player

# ============ 基础音效 ============

# 播放跳跃音效
func play_jump():
	play_tone(jump_sfx, 350, 0.12, "sine", 0.4)
	# 添加滑音效果
	get_tree().create_timer(0.05).timeout.connect(func():
		play_tone(jump_sfx, 450, 0.08, "sine", 0.3)
	)

# 播放攻击音效
func play_attack():
	play_tone(attack_sfx, 800, 0.08, "square", 0.25)
	play_tone(attack_sfx, 600, 0.1, "sawtooth", 0.2)

# 播放受伤音效
func play_hurt():
	play_tone(hurt_sfx, 250, 0.15, "sawtooth", 0.35)
	play_tone(hurt_sfx, 150, 0.2, "square", 0.25)

# 播放收集音效（双音叠加）
func play_collect():
	play_tone(collect_sfx, 880, 0.08, "sine", 0.3)
	get_tree().create_timer(0.08).timeout.connect(func():
		play_tone(collect_sfx, 1100, 0.12, "sine", 0.35)
	)
	get_tree().create_timer(0.16).timeout.connect(func():
		play_tone(collect_sfx, 1320, 0.16, "sine", 0.3)
	)

# 播放敌人死亡音效（降低音调）
func play_enemy_death():
	play_tone(enemy_death_sfx, 200, 0.1, "sawtooth", 0.4)
	get_tree().create_timer(0.1).timeout.connect(func():
		play_tone(enemy_death_sfx, 100, 0.25, "sawtooth", 0.35)
	)

# 播放UI音效
func play_ui_select():
	play_tone(ui_sfx, 600, 0.05, "sine", 0.2)

func play_ui_confirm():
	play_tone(ui_sfx, 880, 0.08, "sine", 0.3)
	get_tree().create_timer(0.08).timeout.connect(func():
		play_tone(ui_sfx, 1100, 0.1, "sine", 0.25)
	)

func play_ui_cancel():
	play_tone(ui_sfx, 400, 0.1, "sawtooth", 0.25)

# ============ 脚步声 ============

func play_footstep():
	if is_footstep_playing:
		return
	is_footstep_playing = true
	
	var ground_types = ["grass", "stone", "wood"]
	var ground_type = ground_types.pick_random()
	
	match ground_type:
		"grass":
			play_tone(footstep_sfx, 150, 0.05, "sine", 0.15)
		"stone":
			play_tone(footstep_sfx, 200, 0.04, "square", 0.12)
		"wood":
			play_tone(footstep_sfx, 250, 0.06, "triangle", 0.15)
	
	get_tree().create_timer(0.15).timeout.connect(func():
		is_footstep_playing = false
	)

# 落地音效
func play_land():
	play_tone(land_sfx, 100, 0.1, "sawtooth", 0.3)

# ============ 背景音乐 ============

func play_bgm():
	if not bgm_player.playing:
		var bgm = create_bgm_melody()
		bgm_player.stream = bgm
		bgm_player.volume_db = -12
		bgm_player.play()

func play_boss_bgm():
	# Boss战音乐 - 更紧张
	if not boss_music.playing:
		var music = create_boss_music()
		boss_music.stream = music
		boss_music.volume_db = -10
		boss_music.play()

func stop_bgm():
	bgm_player.stop()
	boss_music.stop()

# ============ 环境音效 ============

func _play_ambient_sounds():
	# 循环播放环境音效
	_play_wind_effect()
	_play_bird_chirps()
	_play_distant_ambience()

func _play_wind_effect():
	# 风声 - 使用低频噪音
	var wind = create_noise_stream(0.15, 0.5)
	ambient_player.stream = wind
	ambient_player.volume_db = -25
	ambient_player.play()

func _play_bird_chirps():
	# 随机鸟叫
	var chirp_timer = get_tree().create_timer(5.0 + randf() * 10)
	chirp_timer.timeout.connect(func():
		if ambient_player.playing:
			play_tone(ambient_player, 2000 + randf() * 1000, 0.1, "sine", 0.1)
			get_tree().create_timer(0.15).timeout.connect(func():
				play_tone(ambient_player, 2500 + randf() * 500, 0.12, "sine", 0.08)
			)
		_play_bird_chirps()
	)

func _play_distant_ambience():
	# 远处环境音
	var timer = get_tree().create_timer(15.0 + randf() * 15)
	timer.timeout.connect(func():
		if ambient_player.playing:
			# 远处流水声
			play_tone(ambient_player, 80, 2.0, "sine", 0.05)
		_play_distant_ambience()
	)

# ============ 核心音效生成 ============

func play_tone(player: AudioStreamPlayer, frequency: float, duration: float, wave_type: String, volume: float = 0.3):
	var stream = AudioStreamGenerator.new()
	stream.buffer_length = duration
	stream.mix_rate = 44100
	player.stream = stream
	player.play()

	var playback = player.get_stream_playback()
	var frames_to_fill = int(stream.mix_rate * duration)

	for i in range(frames_to_fill):
		var time = float(i) / stream.mix_rate
		var phase = 2.0 * PI * frequency * time
		var sample = 0.0

		match wave_type:
			"sine":
				sample = sin(phase)
			"square":
				sample = 1.0 if sin(phase) > 0 else -1.0
			"sawtooth":
				sample = 2.0 * (phase / (2.0 * PI) - floor(phase / (2.0 * PI) + 0.5))
			"triangle":
				sample = 2.0 * abs(2.0 * (phase / (2.0 * PI) - floor(phase / (2.0 * PI) + 0.5))) - 1.0

		# ADSR包络
		var envelope = 1.0
		var attack = duration * 0.05
		var decay = duration * 0.2
		var sustain = duration * 0.5
		var release = duration * 0.25

		if time < attack:
			envelope = time / attack
		elif time < attack + decay:
			envelope = 1.0 - (time - attack) / decay * 0.3
		elif time < attack + decay + sustain:
			envelope = 0.7
		else:
			envelope = 0.7 * (duration - time) / release

		sample *= envelope * volume
		playback.push_frame(Vector2(sample, sample))

# 创建BGM旋律
func create_bgm_melody() -> AudioStreamGenerator:
	var stream = AudioStreamGenerator.new()
	stream.buffer_length = 8.0
	stream.mix_rate = 44100
	return stream

# 创建Boss音乐
func create_boss_music() -> AudioStreamGenerator:
	var stream = AudioStreamGenerator.new()
	stream.buffer_length = 12.0
	stream.mix_rate = 44100
	return stream

# 创建噪音流（用于风声等）
func create_noise_stream(volume: float, duration: float) -> AudioStreamGenerator:
	var stream = AudioStreamGenerator.new()
	stream.buffer_length = duration
	stream.mix_rate = 44100
	return stream
