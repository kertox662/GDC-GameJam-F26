class_name TauntEnemies extends AbilityBehaviour

# Taunts enemies to make them attack this unit.
const DURATION := 2.0

func _init() -> void:
	cooldown = 6.0

func try_cast(state: EntityManager.EntityState) -> void:
	var grid = state.hexGrid
	var any_in_range := false
	for enemy in state.enemies:
		if enemy.is_dead:
			continue
		if grid.distance(owner.currentHex, enemy.currentHex) <= owner.taunt_radius:
			any_in_range = true
			break
	if not any_in_range:
		return
	owner.taunt_time = DURATION
