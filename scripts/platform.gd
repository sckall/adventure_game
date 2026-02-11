extends StaticBody2D

@export var width: float = 100.0:
	set(value):
		width = value
		update_size()

@export var height: float = 20.0:
	set(value):
		height = value
		update_size()

@export var color: Color = Color(0.3, 0.5, 0.3):
	set(value):
		color = value
		update_color()

@onready var rect = $ColorRect
@onready var collision = $CollisionShape2D

func _ready():
	update_size()
	update_color()

func update_size():
	if rect:
		rect.size = Vector2(width, height)
		rect.position = Vector2(-width / 2, -height / 2)
	if collision:
		var shape = RectangleShape2D.new()
		shape.size = Vector2(width, height)
		collision.shape = shape
		collision.position = Vector2(0, 0)

func update_color():
	if rect:
		rect.color = color
