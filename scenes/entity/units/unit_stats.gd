class_name UnitStats

class UnitDef:
	var cost: int
	var unit_class: String
	var hp: int
	var damage: int
	var interval: float
	var range: int

	func _init(cost: int, unit_class: String, hp: int, damage: int, interval: float, range: int) -> void:
		self.cost = cost
		self.unit_class = unit_class
		self.hp = hp
		self.damage = damage
		self.interval = interval
		self.range = range

static var UNITS: Dictionary = {
	"Sputnik": UnitDef.new(1, "Interceptor", 350, 25, 0.7, 2),
	"Soyuz": UnitDef.new(1, "Support", 400, 15, 1.0, 2),
	"Vostok": UnitDef.new(2, "Vanguard", 1000, 35, 1.0, 1),
	"Buran": UnitDef.new(2, "Interceptor", 450, 50, 0.8, 2),
	"Voyager": UnitDef.new(2, "Artillery", 400, 55, 1.4, 3),
	"Hubble": UnitDef.new(2, "Support", 450, 20, 1.0, 3),
	"Mir": UnitDef.new(3, "Vanguard", 1600, 30, 1.2, 1),
	"Apollo": UnitDef.new(3, "Artillery", 600, 70, 1.6, 3),
}

static func getUnit(id: String):
	return UNITS.get(id, null)
