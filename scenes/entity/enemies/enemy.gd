class_name Enemy extends Entity

var enemy_id: String = ""

func _ready() -> void:
	super._ready()
	if enemy_id != "":
		_apply_stats()

func setup(id: String) -> void:
	enemy_id = id
	_apply_stats()

func _apply_stats() -> void:
	var def = EnemyStats.getEnemy(enemy_id)
	if def:
		max_health = def.hp
		attack_damage = def.damage
		attack_interval = def.interval
		attack_range = def.range
		targeting = def.targeting
		health = max_health
