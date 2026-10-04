class_name HugeHit extends AbilityBehaviour

# Does one huge hit to the nearest enemy in range.
const MULT := 3

func _init() -> void:
	cooldown = 10.0

func try_cast(state: EntityManager.EntityState) -> void:
	var target = state.oppInRange(owner)
	if target == null:
		return
	owner.fire_ability_projectile(target, owner.effective_damage() * MULT)
