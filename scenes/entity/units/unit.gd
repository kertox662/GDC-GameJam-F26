class_name Unit extends Entity

const MAX_LEVEL := 3
# stat multiplier per level
const LEVEL_STAT_MULT := 1.8
# sprite size multiplier per level
const LEVEL_SCALE := [1.0, 1.25, 1.5]

var unit_id: String = ""
var level: int = 1


func _ready() -> void:
	super._ready()
	if unit_id != "":
		_apply_stats()

func setup(id: String, lvl: int = 1) -> void:
	unit_id = id
	level = clampi(lvl, 1, MAX_LEVEL)
	_apply_stats()

# Merge this unit with an identical unit
# returns true if the merge happened
# Caller should handle the unoccupied hexes
func merge_with(other: Unit) -> bool:
	if other == null or other == self:
		return false
	if unit_id != other.unit_id or level != other.level or level >= MAX_LEVEL:
		return false
	level += 1
	_apply_stats()
	# Keep full health after merging.
	health = max_health
	if other.get_parent():
		other.get_parent().remove_child(other)
	other.queue_free()
	return true

func _apply_stats() -> void:
	var def = UnitStats.getUnit(unit_id)
	if def:
		var mult := pow(LEVEL_STAT_MULT, level - 1)
		max_health = int(def.hp * mult)
		attack_damage = int(def.damage * mult)
		attack_interval = def.interval
		attack_range = def.range
		targeting = "nearest"
		health = max_health
	scale = Vector2.ONE * LEVEL_SCALE[level - 1]
