class_name ShieldAdjacentAllies extends AbilityBehaviour

# Give allies 50% damage reduction
# 3 seconds.
const RADIUS := 1
const REDUCTION := 0.5
const DURATION := 3.0

func _init() -> void:
	cooldown = 8.0

func try_cast(state: EntityManager.EntityState) -> void:
	var grid = state.hexGrid
	for ally in state.units:
		if ally.is_dead or ally == owner:
			continue
		if grid.distance(owner.currentHex, ally.currentHex) > RADIUS:
			continue
		ally.shield_reduction = REDUCTION
		ally.shield_time = DURATION
