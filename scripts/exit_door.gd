extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		var main = get_parent()
		if main.has_method("_on_player_reached_exit"):
			main._on_player_reached_exit()
