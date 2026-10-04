extends Node

@onready var game_manager_scn : PackedScene = preload("res://scenes/game_manager.tscn")

var game : Node:
	set(new):
		if game != null:
			game.queue_free()
		game = new
		add_child(game)

func _on_title_start():
	game = game_manager_scn.instantiate()
