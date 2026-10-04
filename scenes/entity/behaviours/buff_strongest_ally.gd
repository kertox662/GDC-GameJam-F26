class_name BuffStrongestAlly extends AbilityBehaviour

# Gives the strongest ally within 3 tiles +50% damage for 3 seconds.
const RADIUS := 3
const BONUS := 0.5
const DURATION := 3.0

func _init() -> void:
	cooldown = 8.0

func try_cast(state: EntityManager.EntityState) -> void:
	var grid = state.hexGrid
	var strongest: Entity = null
	var strongest_dmg := -1
	for ally in state.units:
		if ally.is_dead or ally == owner:
			continue
		if grid.distance(owner.currentHex, ally.currentHex) > RADIUS:
			continue
		if ally.attack_damage > strongest_dmg:
			strongest_dmg = ally.attack_damage
			strongest = ally
	if strongest == null:
		return
	strongest.add_damage_bonus(BONUS, DURATION, "hubble_buff")
