class_name CritWeakest extends AbilityBehaviour

# Deal a critical hit to the weakest enemy within 2 tiles.
const RADIUS := 2
const CRIT_MULT := 2

func _init() -> void:
	cooldown = 6.0

func try_cast(state: EntityManager.EntityState) -> void:
	var grid = state.hexGrid
	var weakest: Entity = null
	var weakest_hp := INF
	for enemy in state.enemies:
		if enemy.is_dead:
			continue
		if grid.distance(owner.currentHex, enemy.currentHex) > RADIUS:
			continue
		if enemy.health < weakest_hp:
			weakest_hp = enemy.health
			weakest = enemy
	if weakest == null:
		return
	owner.fire_ability_projectile(weakest, owner.effective_damage() * CRIT_MULT)
