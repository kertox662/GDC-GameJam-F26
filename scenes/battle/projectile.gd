class_name Projectile extends Area2D

var damage: int = 0
var target: Entity = null
var target_hex: Hex = null 
var speed: float = 900.0

var _landed: bool = false

func _ready() -> void:
	if target_hex:
		rotation = (target_hex.position - position).angle()
		# Once it enters the hex considered it a hit. 
		target_hex.area_entered.connect(_on_target_hex_entered)

func _physics_process(delta: float) -> void:
	if _landed or not target or target.is_dead:
		queue_free()
		return
	var dest = target_hex.position if target_hex else target.position
	var dir = dest - position
	var step = speed * delta
	if dir.length() <= step:
		position = dest
		_land()
	else:
		position += dir.normalized() * step

func _on_target_hex_entered(area: Area2D) -> void:
	if area == self:
		_land()

func _land() -> void:
	if _landed:
		return
	_landed = true
	if target and not target.is_dead:
		target.take_damage(damage)
	queue_free()
