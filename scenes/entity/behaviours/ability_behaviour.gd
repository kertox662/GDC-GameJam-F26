class_name AbilityBehaviour extends Behaviour

# Base class for a unit's signature ability.
# Subclasses override try_cast to implement the ability
# They should set cooldown respectively
var cooldown: float = 5.0
var _cd: float = 0.0

func update(state: EntityManager.EntityState, delta: float) -> void:
	if owner == null or owner.is_dead:
		return
	if _cd > 0.0:
		_cd -= delta
		return
	try_cast(state)
	_cd = cooldown

func try_cast(state: EntityManager.EntityState) -> void:
	pass

func on_battle_start(state: EntityManager.EntityState) -> void:
	pass
