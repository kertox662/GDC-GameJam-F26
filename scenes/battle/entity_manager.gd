class_name EntityManager extends Node2D

signal battle_ended # Emitted when every enemy on the field is dead.
signal battle_lost

var state: EntityState
var paused: bool = true # Pauses battling during preparation.

var projectileScene: PackedScene = preload("res://scenes/battle/projectile.tscn")

class EntityState:
	var units: Array[Entity] = []
	var enemies: Array[Entity] = []
	var corpses: Array[Entity] = [] # Dead units that stay on the field and keep occupying their hex
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
		var taunt = tauntInRange(entity)
		if taunt:
			return taunt
		return getTeamsUnitInRange(entity, oppData)

	func allyInRange(entity: Entity):
		var allyData = allyData(entity)
		return getTeamsUnitInRange(entity, allyData)

	# returns nearest living unit that is taunting and within its taunt radius.
	func tauntInRange(entity: Entity) -> Entity:
		var data = opponentData(entity)
		var best = null
		var bestDist = -1
		for unit in data.units:
			if unit.is_dead or not unit.is_taunting():
				continue
			var d = hexGrid.distance(entity.currentHex, unit.currentHex)
			if d <= unit.taunt_radius:
				if best == null or d < bestDist:
					bestDist = d
					best = unit
		return best

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
	unit.manager = self
	unit.died.connect(remove_entity)

func addEnemy(unit: Entity):
	state.enemies.push_back(unit)
	state.enemyTiles[unit] = [unit.currentHex]
	unit.is_on_field = true
	unit.manager = self
	unit.died.connect(remove_entity)

# Begin the battle.
# Unpauses the simulation and runs start of battle effects
func start_battle() -> void:
	paused = false
	for unit in state.units:
		if not unit.is_dead:
			unit.on_battle_start(state)

func fire_projectile(attacker: Entity, target: Entity, damage: int = -1) -> void:
	var proj: Projectile = projectileScene.instantiate()
	proj.damage = damage if damage >= 0 else attacker.effective_damage()
	proj.target = target
	proj.target_hex = target.currentHex
	proj.position = attacker.position
	add_child(proj)

func _make_corpse(entity: Entity) -> void:
	if entity is Unit:
		entity.corpse_hex = entity.currentHex
		state.corpses.append(entity)
		entity.modulate = Color(0.45, 0.45, 0.45, 0.8)
		if entity.has_node("Sprite"):
			entity.get_node("Sprite").modulate = Color(0.45, 0.45, 0.45, 0.8)
		if entity.has_node("Weapon"):
			entity.get_node("Weapon").visible = false
	else:
		entity.queue_free()

func remove_entity(entity: Entity) -> void:
	var tiles = state.unitTiles.get(entity, state.enemyTiles.get(entity, []))
	var is_unit = entity is Unit
	
	# Only delete dead enemies.
	if not is_unit:
		for hex in tiles:
			state.hexGrid.setOccupied(hex, false)
	state.units.erase(entity)
	state.enemies.erase(entity)
	state.unitTiles.erase(entity)
	state.enemyTiles.erase(entity)
	_make_corpse(entity)
	_check_battle_ended()

# TODO (bring back units)
func clear_corpses() -> void:
	for corpse in state.corpses:
		if corpse.corpse_hex:
			state.hexGrid.setOccupied(corpse.corpse_hex, false)
		corpse.queue_free()
	state.corpses.clear()

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
	if state.units.is_empty():
		battle_lost.emit()

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
		entity.tick_timers(delta)
		entity.pollNextAction(state)
		entity.doMove(state, delta)
		entity.update_behaviours(state, delta)
		var target = entity.doAttack()
		if target:
			fire_projectile(entity, target)
