class_name HealLowestAlly extends AbilityBehaviour

# Heals the lowest HP ally within 2 tiles for 25% of its max health.
const RADIUS := 2
const HEAL_FRACTION := 0.25

func _init() -> void:
	cooldown = 5.0

func try_cast(state: EntityManager.EntityState) -> void:
	var grid = state.hexGrid
	var lowest: Entity = null
	var lowest_ratio := INF
	for ally in state.units:
		if ally.is_dead or ally == owner:
			continue
		if grid.distance(owner.currentHex, ally.currentHex) > RADIUS:
			continue
		var ratio = float(ally.health) / float(ally.max_health)
		if ratio < lowest_ratio:
			lowest_ratio = ratio
			lowest = ally
	if lowest == null:
		return
	lowest.heal(int(lowest.max_health * HEAL_FRACTION))
