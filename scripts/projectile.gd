extends Node2D

var velocity := Vector2.ZERO
var damage := 1.0
var lifetime := 1.0
var hit_radius := 10.0
var color := Color(0.7, 0.8, 1.0, 0.9)

func _ready() -> void:
	_create_visual()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	position += velocity * delta

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D) or not is_instance_valid(enemy):
			continue
		if position.distance_to(enemy.position) <= hit_radius:
			_apply_damage(enemy, damage)
			queue_free()
			return

func _apply_damage(enemy: Node2D, dmg: float) -> void:
	var hp_val = 1.0
	if enemy.has_meta("hp"):
		hp_val = float(enemy.get_meta("hp"))
	hp_val -= dmg
	if hp_val <= 0.0:
		enemy.queue_free()
		return
	enemy.set_meta("hp", hp_val)
	if enemy.get_child_count() > 0:
		var child = enemy.get_child(0)
		if child is CanvasItem:
			child.modulate = Color(1.2, 1.2, 1.2)
			var t := create_tween()
			t.tween_property(child, "modulate", Color.WHITE, 0.08)

func _create_visual() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _solid_texture(10, 4, color)
	sprite.centered = true
	add_child(sprite)

func _solid_texture(w: int, h: int, col: Color) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(col)
	return ImageTexture.create_from_image(img)
