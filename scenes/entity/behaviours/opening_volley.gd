class_name OpeningVolley extends AbilityBehaviour

# Shoot 3 times at the start of battle
const SHOTS := 3
const SHOT_FRACTION := 0.5

func _init() -> void:
	cooldown = 9999.0 # only ever cast via on_battle_start

func on_battle_start(state: EntityManager.EntityState) -> void:
	var grid = state.hexGrid
	var farthest: Entity = null
	var farthest_d := -1
	for enemy in state.enemies:
		if enemy.is_dead:
			continue
		var d = grid.distance(owner.currentHex, enemy.currentHex)
		if d > farthest_d:
			farthest_d = d
			farthest = enemy
	if farthest == null:
		return
	var dmg = int(owner.effective_damage() * SHOT_FRACTION)
	for i in SHOTS:
		owner.fire_ability_projectile(farthest, dmg)
