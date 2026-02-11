extends Area2D

@export var mushroom_color: String = "red":
	set(value):
		mushroom_color = value
		update_color()

@onready var rect = $ColorRect

func _ready():
	update_color()
	body_entered.connect(_on_body_entered)

func update_color():
	if rect:
		match mushroom_color:
			"red":
				rect.color = Color(0.9, 0.2, 0.2)
			"green":
				rect.color = Color(0.2, 0.8, 0.2)
			"blue":
				rect.color = Color(0.2, 0.4, 0.9)
			"brown":
				rect.color = Color(0.6, 0.4, 0.2)
			"purple":
				rect.color = Color(0.7, 0.3, 0.8)
			_:
				rect.color = Color(0.9, 0.2, 0.2)

func _on_body_entered(body):
	if body.name == "Player":
		var g = get_node("/root/Global")
		g.collect_item("mushroom", mushroom_color)
		get_parent().update_ui()

		# 收集特效
		spawn_collect_effect()

		queue_free()

func spawn_collect_effect():
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 12
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.gravity = Vector2(0, 200)
	particles.scale_min = 3.0
	particles.scale_max = 6.0
	particles.color = Color(1, 0.9, 0.3, 1)
	particles.position = global_position
	get_parent().add_child(particles)

	await get_tree().create_timer(0.5).timeout
	particles.queue_free()
