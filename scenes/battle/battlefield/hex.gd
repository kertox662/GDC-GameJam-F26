class_name Hex extends Area2D

signal on_mouse_entered(Hex)
signal on_mouse_exited(Hex)

func _on_mouse_entered() -> void:
	on_mouse_entered.emit(self)

func _on_mouse_exited() -> void:
	on_mouse_exited.emit(self)
