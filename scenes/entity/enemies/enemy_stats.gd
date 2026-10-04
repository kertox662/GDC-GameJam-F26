class_name EnemyStats

class EnemyDef:
	var hp: int
	var damage: int
	var interval: float
	var range: int
	var targeting: String

	func _init(hp: int, damage: int, interval: float, range: int, targeting: String) -> void:
		self.hp = hp
		self.damage = damage
		self.interval = interval
		self.range = range
		self.targeting = targeting

static var ENEMIES: Dictionary = {
	"Drone": EnemyDef.new(300, 10, 0.5, 1, "nearest"),
	"Cruiser": EnemyDef.new(700, 30, 1.0, 2, "farthest"),
	"Mothership": EnemyDef.new(6000, 60, 1.0, 4, "nearest"),
}

static func getEnemy(id: String):
	return ENEMIES.get(id, null)
