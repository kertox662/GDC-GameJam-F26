class_name Entity extends CharacterBody2D

const TRAVEL_TOL = 4

# emitted when this entity's health reaches 0.
signal died(entity: Entity)
# emitted whenever this entity takes damag
signal damaged(entity: Entity, amount: int)

var trajectory: Array = []
var behaviours: Array[Behaviour] = []
var modifiers: Array[Modifier] = []
# Set by the EntityManager when this entity is added to the battle.
var manager: EntityManager = null

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

# A single stackable damage bonus (e.g. Hubble's buff, a partner bond).
class DamageBonus:
	var amount: float   # additive multiplier, 0.5 = +50% damage
	var time: float     # seconds remaining
	var source: String  # same-source bonuses refresh instead of stacking

	func _init(amount: float, time: float, source: String = "") -> void:
		self.amount = amount
		self.time = time
		self.source = source

# --- Timed combat effects (applied by unit abilities) ---
var damage_bonuses: Array[DamageBonus] = []
var shield_reduction: float = 0.0  # fraction of incoming damage absorbed
var shield_time: float = 0.0
var taunt_time: float = 0.0
var taunt_radius: int = 2
# Whether this entity can move during battle (Vanguards cannot).
var can_move: bool = true
# Set when this unit becomes a corpse: the hex it keeps occupying.
var corpse_hex: Hex = null

# Base sprite scale (32px template art on ~80px hexes). Subclasses multiply
# this by their per-level scale.
const BASE_SCALE := 2.0

@export var animName = "unit1"
# Which weapon animation to play ("unit" or "enemy").
@export var weaponAnimName = "unit"

const weaponRotationSpeed = 1

func _ready() -> void:
	health = max_health
	$Sprite.play(animName)
	$Weapon.play(weaponAnimName)

# Called once when a battle begins. Forwards to any behaviours that implement
# an on_battle_start hook (e.g. Voyager's opening volley).
func on_battle_start(state: EntityManager.EntityState) -> void:
	for behaviour in behaviours:
		if behaviour.has_method("on_battle_start"):
			behaviour.on_battle_start(state)


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	if shield_time > 0.0:
		amount = int(ceil(amount * (1.0 - shield_reduction)))
	health = maxi(0, health - amount)
	damaged.emit(self, amount)
	if health <= 0:
		_die()

func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	health = mini(max_health, health + amount)

# Add (or refresh, if same source) a stackable damage bonus.
func add_damage_bonus(amount: float, time: float, source: String = "") -> void:
	for bonus in damage_bonuses:
		if bonus.source != "" and bonus.source == source:
			bonus.amount = amount
			bonus.time = time
			return
	damage_bonuses.append(DamageBonus.new(amount, time, source))

# Damage after all stackable bonuses (Hubble's buff, partner bonds, ...) applied.
func effective_damage() -> int:
	var total := 0.0
	for bonus in damage_bonuses:
		total += bonus.amount
	return int(round(attack_damage * (1.0 + total)))

# True while this entity is taunting (enemies in range must target it).
func is_taunting() -> bool:
	return taunt_time > 0.0

# Ticks down all timed effects. Called once per frame by the EntityManager.
func tick_timers(delta: float) -> void:
	var i := damage_bonuses.size() - 1
	while i >= 0:
		damage_bonuses[i].time -= delta
		if damage_bonuses[i].time <= 0.0:
			damage_bonuses.remove_at(i)
		i -= 1
	if shield_time > 0.0:
		shield_time -= delta
		if shield_time <= 0.0:
			shield_time = 0.0
			shield_reduction = 0.0
	if taunt_time > 0.0:
		taunt_time -= delta
		if taunt_time <= 0.0:
			taunt_time = 0.0

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
	if not can_move:
		# Vanguards hold their ground: never path, only attack in range.
		trajectory = []
		target = state.oppInRange(self)
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
	# Rotate the weapon
	var targetWeaponAngle = 0
	if target:
		targetWeaponAngle = (target.position - position).angle()
	var diff = targetWeaponAngle - $Weapon.rotation
	var toMove = min(abs(diff), weaponRotationSpeed * delta) * sign(diff)
	$Weapon.rotation += toMove
	
	if is_dead or not can_move:
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
		if vel.x < 0:
			$Sprite.scale.x = -abs($Sprite.scale.x)
		else:
			$Sprite.scale.x = abs($Sprite.scale.x)
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

# Fire a projectile with explicit damage (used by abilities). Does not touch
# the normal attack cooldown.
func fire_ability_projectile(target: Entity, damage: int) -> void:
	if manager and target and not target.is_dead:
		manager.fire_projectile(self, target, damage)

func update_behaviours(state: EntityManager.EntityState, delta: float) -> void:
	for behaviour in behaviours:
		behaviour.update(state, delta)

func process(gameState):
	pass

func _on_attack_cooldown_timeout() -> void:
	attackOffCooldown = true
