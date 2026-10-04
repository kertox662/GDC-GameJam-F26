class_name Battle extends Node2D

var end_pos = null

func _physics_process(delta: float) -> void:
	var start = $HexGrid.current_selected_hex()
	if start and end_pos:
		var path = $HexGrid.pathToRange(start, end_pos, 2)
		$Path.clear_points()
		for p in path:
			var nextPoint = $HexGrid.position + $HexGrid.getHexFromGrid(p).position
			$Path.add_point(nextPoint)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == 1:
			var hex = $HexGrid.current_selected_hex()
			if hex:
				$HexGrid.setOccupied(hex, !$HexGrid.getOccupied(hex))
		elif event.button_index == 2:
			end_pos = $HexGrid.current_selected_hex()
		else:
			print(event.button_index)
