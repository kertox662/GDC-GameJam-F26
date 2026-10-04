extends Node2D

#var entityManagerScene: PackedScene = preload("res://scenes/battle/entity_manager.tscn")
var unitScene: PackedScene = preload("res://scenes/entity/units/unit.tscn")
var enemyScene: PackedScene = preload("res://scenes/entity/enemies/enemy.tscn")

func _ready() -> void:
	var manager = EntityManager.new($Battle/HexGrid)
	$Battle.add_child(manager)

	var grid: HexGrid = $Battle/HexGrid

	# One unit per class so every ability can be seen in action.
	var unit_defs = ["Sputnik", "Vostok", "Voyager", "Buran"]
	var unit_hexes = [Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 5), Vector2i(4, 6)]
	for i in unit_defs.size():
		var unit: Unit = unitScene.instantiate()
		var hex: Hex = grid.hexes[unit_hexes[i]]
		unit.currentHex = hex
		unit.setup(unit_defs[i])
		manager.addUnit(unit)
		$Battle/Entities.add_child(unit)
		unit.position = hex.position

	# A small mixed wave in the top rows.
	var enemy_defs = ["Drone", "Drone", "Cruiser"]
	var enemy_hexes = [Vector2i(1, 1), Vector2i(3, 0), Vector2i(4, 1)]
	for i in enemy_defs.size():
		var enemy: Enemy = enemyScene.instantiate()
		var hex: Hex = grid.hexes[enemy_hexes[i]]
		enemy.currentHex = hex
		enemy.setup(enemy_defs[i])
		enemy.animName = "unit2"
		manager.addEnemy(enemy)
		$Battle/Entities.add_child(enemy)
		enemy.position = hex.position

	# Unfreeze the simulation and trigger battle-start hooks (Voyager's volley).
	manager.start_battle()
