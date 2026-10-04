extends Control
signal start

func _input(event):
	if event is InputEventKey and visible:
		hide()
		start.emit()
