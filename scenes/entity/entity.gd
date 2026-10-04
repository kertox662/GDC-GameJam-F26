class_name Entity extends CharacterBody2D

const TRAVEL_TOL = 4

# emitted when this entity's health reaches 0.
signal died(entity: Entity)
# emitted whenever this entity takes damag
signal damaged(entity: Entity, amount: int)

var trajectory: Array = []
var behaviours: Array[Behaviour] = []
var modifiers: Array[Modifier] = []

const DEFAULT_SPEED = 100
const NUDGE_SPEED = 5
var speed = DEFAULT_SPEED
var target: Entity = null
var currentHex: Hex = null
var home_hex: Hex = null # Where the unit started
var is_on_field: bool = false # Whether on field or "on hold"

# Combat states
var max_health: int = 100
var health: int = 100
var attack_damage: int = 10
var attack_interval: float = 1.0  # seconds between attacks
var attack_range: int = 1  # in hexes
var targeting: String = "nearest"

var is_dead: bool = false
var attackOffCooldown: bool = true

@export var animName = "unit1"

func _ready() -> void:
	position = Vector2(400,400)
	health = max_health
	$Sprite.play(animName)


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	health = maxi(0, health - amount)
	damaged.emit(self, amount)
	if health <= 0:
		_die()

func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	health = mini(max_health, health + amount)

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	var dead_anim = animName + "dead"
	if $Sprite.sprite_frames and $Sprite.sprite_frames.has_animation(dead_anim):
		$Sprite.play(dead_anim)
	else:
		$Sprite.stop()
	died.emit(self)


func pollNextAction(state: EntityManager.EntityState):
	if is_dead:
		return
	if (
		(
			len(trajectory) == 0 or
			trajectory[0] == currentHex
		) and
		position.distance_to(currentHex.position) > TRAVEL_TOL
	):
		trajectory = [currentHex]
		target = null
		return

	var opp = state.oppInRange(self)
	if opp:
		trajectory = []
		target = opp
	else:
		if len(trajectory) == 0:
			trajectory = state.findPathToClosestOpponent(self)
		target = null

func doMove(state: EntityManager.EntityState, delta: float):
	if is_dead:
		return
	if len(trajectory) == 0:
		var dir = currentHex.position - position
		position += dir.normalized() * delta * NUDGE_SPEED
		return
	var next = trajectory[0]
	if next != currentHex and state.isHexOccupied(next):
		speed = DEFAULT_SPEED * 3
		trajectory = [currentHex]

	var vel = (next.position - position) as Vector2
	if vel.length_squared() > 0.0001:
		position += vel.normalized() * delta * speed
	if position.distance_squared_to(next.position) <= position.distance_squared_to(currentHex.position):
		if next != currentHex:
			state.moveEntityBetweenHexes(self, next)
	if position.distance_squared_to(next.position) < TRAVEL_TOL:
		trajectory.pop_front()
		speed = DEFAULT_SPEED

# Returns the entity to attack this frame, or null if unable to attack.
# The EntityManager is responsible for firing the projectile at the returned target.
func doAttack() -> Entity:
	if is_dead or not canAttack() or not target:
		return null
	attackOffCooldown = false
	$AttackCooldown.start(attack_interval)
	return target

func canAttack() -> bool:
	return attackOffCooldown

func update_behaviours(state: EntityManager.EntityState, delta: float) -> void:
	for behaviour in behaviours:
		behaviour.update(state, delta)

func process(gameState):
	pass

func _on_attack_cooldown_timeout() -> void:
	attackOffCooldown = true
