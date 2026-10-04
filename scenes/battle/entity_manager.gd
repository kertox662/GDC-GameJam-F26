class_name EntityManager extends Node2D

# Emitted when every enemy on the field is dead (battle won).
signal battle_ended

var state: EntityState
# While true, combat simulation is frozen (used during preparation phase).
var paused: bool = true

var projectileScene: PackedScene = preload("res://scenes/battle/projectile.tscn")

class EntityState:
	var units: Array[Entity] = []
	var enemies: Array[Entity] = []
	var unitTiles = {} # Dictionary[Entity, Array[Hex]]
	var enemyTiles = {} # Dictionary[Entity, Array[Hex]] -> Enemies can take up multiple tiles
	var hexGrid: HexGrid

	func allyData(entity: Entity):
		if entity in unitTiles:
			return {"units": units, "tiles": unitTiles}
		elif entity in enemyTiles:
			return {"units": enemies, "tiles": enemyTiles}
		else:
			return {"units": [], "tiles": {}}

	func opponentData(entity: Entity):
		if entity in unitTiles:
			return {"units": enemies, "tiles": enemyTiles}
		elif entity in enemyTiles:
			return {"units": units, "tiles": unitTiles}
		else:
			return {"units": [], "tiles": {}}

	func findPathToClosestOpponent(entity: Entity) -> Array:
		var oppData = opponentData(entity)
		var best = null
		for opp in oppData.tiles:
			var oppTiles = oppData.tiles[opp]
			for hex in oppTiles:
				var path = hexGrid.pathToRange(entity.currentHex, hex, entity.attack_range)
				if not best or len(path) < len(best):
					best = path
		if best:
			return best.map(func(p) -> Hex: return hexGrid.hexes[p])
		return []

	func getTeamsUnitInRange(entity: Entity, data) -> Entity:
		var best = null
		var bestDist = -1
		for unit in data.units:
			if unit.is_dead:
				continue
			var d = hexGrid.distance(entity.currentHex, unit.currentHex)
			if d <= entity.attack_range:
				if entity.targeting == "farthest":
					if d > bestDist:
						bestDist = d
						best = unit
				elif best == null or d < bestDist:
					bestDist = d
					best = unit
		return best

	func oppInRange(entity: Entity) -> Entity:
		var oppData = opponentData(entity)
		return getTeamsUnitInRange(entity, oppData)

	func allyInRange(entity: Entity):
		var allyData = allyData(entity)
		return getTeamsUnitInRange(entity, allyData)

	func isHexOccupied(hex: Hex):
		return hexGrid.getOccupied(hex)

	func moveEntityBetweenHexes(entity: Entity, toHex: Hex):
		var allyData = allyData(entity)
		hexGrid.setOccupied(entity.currentHex, false)
		hexGrid.setOccupied(toHex, true)
		allyData["tiles"][entity] = [toHex]
		entity.currentHex = toHex


func _init(hexGrid: HexGrid) -> void:
	state = EntityState.new()
	state.hexGrid = hexGrid

func addUnit(unit: Entity):
	state.units.push_back(unit)
	state.unitTiles[unit] = [unit.currentHex]
	unit.is_on_field = true
	unit.died.connect(remove_entity)

func addEnemy(unit: Entity):
	state.enemies.push_back(unit)
	state.enemyTiles[unit] = [unit.currentHex]
	unit.is_on_field = true
	unit.died.connect(remove_entity)

func fire_projectile(attacker: Entity, target: Entity) -> void:
	var proj: Projectile = projectileScene.instantiate()
	proj.damage = attacker.attack_damage
	proj.target = target
	proj.target_hex = target.currentHex
	proj.position = attacker.position
	add_child(proj)

func remove_entity(entity: Entity) -> void:
	var tiles = state.unitTiles.get(entity, state.enemyTiles.get(entity, []))
	for hex in tiles:
		state.hexGrid.setOccupied(hex, false)
	state.units.erase(entity)
	state.enemies.erase(entity)
	state.unitTiles.erase(entity)
	state.enemyTiles.erase(entity)
	entity.queue_free()
	_check_battle_ended()

func detach_entity(entity: Entity) -> void:
	var tiles = state.unitTiles.get(entity, state.enemyTiles.get(entity, []))
	for hex in tiles:
		state.hexGrid.setOccupied(hex, false)
	state.units.erase(entity)
	state.enemies.erase(entity)
	state.unitTiles.erase(entity)
	state.enemyTiles.erase(entity)
	entity.trajectory = []
	entity.target = null
	entity.is_on_field = false

func _check_battle_ended() -> void:
	if state.enemies.is_empty():
		battle_ended.emit()

func _remove_dead() -> void:
	for entity in state.units + state.enemies:
		if entity.is_dead:
			remove_entity(entity)

func _physics_process(delta: float) -> void:
	if paused:
		return
	_remove_dead()
	for entity in state.units + state.enemies:
		if entity.is_dead:
			continue
		entity.pollNextAction(state)
		entity.doMove(state, delta)
		entity.update_behaviours(state, delta)
		var target = entity.doAttack()
		if target:
			fire_projectile(entity, target)
