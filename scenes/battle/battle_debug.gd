extends Node2D

#var entityManagerScene: PackedScene = preload("res://scenes/battle/entity_manager.tscn")
var unitScene: PackedScene = preload("res://scenes/entity/units/unit.tscn")
var enemyScene: PackedScene = preload("res://scenes/entity/enemies/enemy.tscn")

func _ready() -> void:
	var manager = EntityManager.new($Battle/HexGrid)
	$Battle.add_child(manager)

	var unit: Unit = unitScene.instantiate()
	var enemy1: Enemy = enemyScene.instantiate()
	var enemy2: Enemy = enemyScene.instantiate()

	var unitHex:Hex = $Battle/HexGrid.hexes[Vector2i(4,5)]
	var enemy1Hex:Hex = $Battle/HexGrid.hexes[Vector2i(2,1)]
	var enemy2Hex:Hex = $Battle/HexGrid.hexes[Vector2i(5,0)]

	unit.currentHex = unitHex
	enemy1.currentHex = enemy1Hex
	enemy2.currentHex = enemy2Hex

	# Configure combat stats from the stat tables.
	unit.setup("Sputnik")
	enemy1.setup("Drone")
	enemy2.setup("Drone")

	enemy1.animName = "unit2"
	enemy2.animName = "unit2"

	manager.addUnit(unit)
	manager.addEnemy(enemy1)
	manager.addEnemy(enemy2)

	print($Battle/HexGrid.hexScale())

	$Battle/Entities.add_child(unit)
	$Battle/Entities.add_child(enemy1)
	$Battle/Entities.add_child(enemy2)

	unit.position = unitHex.position
	enemy1.position = enemy1Hex.position
	enemy2.position = enemy2Hex.position

	print(unit.position)
	print(enemy1.position)
	print(enemy2.position)
