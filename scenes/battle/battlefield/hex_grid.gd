class_name HexGrid extends Node2D

@export var width = 6
@export var height = 7
@export var hexRadius = 40
@export var borderWidth = 0.5
var GRID_COLOUR: Color = Color.from_hsv(0.6, 0.6, 0.1, 0.1)
const BASE_RADIUS = 10

var hexScene: PackedScene = load("res://scenes/battle/battlefield/hex.tscn")


var gridPositions: Dictionary[Hex, Vector2i] = {}
var hexes: Dictionary[Vector2i, Hex] = {}
var adjacencies = {} # Dictionary[Vector2i, Array[Vector2i]]
var occupied: Dictionary[Hex, bool] = {}

var current_highlighted_tile: Hex = null
# When false, mouse hover highlighting is ignored (e.g. while dragging a unit,
# so the game manager can paint its own placement highlights).
var highlight_enabled: bool = true

signal mouse_entered_tile(Hex)

func _ready() -> void:
	for x in range(width):
		for y in range(height):
			var hex: Hex = hexScene.instantiate()
			hex.position = Vector2(
				x * (sqrt(3) * BASE_RADIUS - borderWidth) + (y%2) * (sqrt(3)/2 * BASE_RADIUS - borderWidth),
				y * (BASE_RADIUS*1.5 - borderWidth * 2 / sqrt(3))) * hexScale()
			hex.modulate = GRID_COLOUR
			
			hex.on_mouse_entered.connect(handle_mouse_enters_hex)
			hex.on_mouse_exited.connect(handle_mouse_exits_hex)
			$Hexes.add_child(hex)
			
			gridPositions[hex] = Vector2i(x,y)
			hexes[Vector2i(x,y)] = hex
			hex.scale = hexScale()
			var adjacent = [Vector2i(x,y-1), Vector2i(x-1,y), Vector2i(x+1,y), Vector2i(x,y+1)]
			if y % 2 == 0:
				adjacent.push_back(Vector2i(x-1,y-1))
				adjacent.push_back(Vector2i(x-1,y+1))
			else:
				adjacent.push_back(Vector2i(x+1,y-1))
				adjacent.push_back(Vector2i(x+1,y+1))
			for i in range(5, -1, -1):
				var p = adjacent[i]
				if p.x < 0 or p.y < 0 or p.x >= width or p.y >= height:
					adjacent.pop_at(i)
			adjacencies[Vector2i(x,y)] = adjacent
			occupied[hex] = false
	
func hexScale() -> Vector2:
	return Vector2(hexRadius / BASE_RADIUS, hexRadius / BASE_RADIUS)

func distance(h1: Hex, h2: Hex) -> int:
	var p1 = gridPositions.get(h1)
	var p2 = gridPositions.get(h2)
	
	if not p1 or not p2:
		return 10000
	return hexDist(p1, p2)

func pathToRange(start: Hex, end: Hex, range: int) -> Array[Vector2i]:
	var startPos = gridPositions[start]
	var endPos = gridPositions[end]
	
	var seen: Dictionary[Vector2i, bool] = {}
	var queue = [[startPos]]
	
	while not queue.is_empty():
		var next = queue.pop_front()
		var lastPos = next[-1]
		if seen.get(lastPos, false):
			continue
		
		if hexDist(lastPos, endPos) <= range:
			return next as Array[Vector2i]
		
		seen[lastPos] = true
		for adj in adjacencies[lastPos]:
			if seen.get(adj, false) or occupied.get(hexes[adj], false): # Skip seen or occupied hexes
				continue
			var toAdd = next.duplicate()
			toAdd.push_back(adj)
			queue.push_back(toAdd)
	return []

func setOccupied(hex: Hex, state: bool):
	occupied[hex] = state
	if state:
		hex.modulate = Color.DARK_RED
	else:
		hex.modulate = GRID_COLOUR

func getOccupied(hex: Hex):
	return occupied.get(hex, false)

func getHexFromGrid(pos: Vector2i):
	return hexes.get(pos)

# Returns the hex whose centre is closest to the given position or null if outside
func get_hex_at_position(local_pos: Vector2) -> Hex:
	var best: Hex = null
	var best_dist := INF
	for hex in hexes.values():
		var d = hex.position.distance_squared_to(local_pos)
		if d < best_dist:
			best_dist = d
			best = hex
	if best and best_dist > pow(hexRadius * 1.5, 2):
		return null
	return best

func current_selected_hex():
	return current_highlighted_tile

func hexDist(h1: Vector2i, h2: Vector2i) -> int:
	var q1 = h1.x - h1.y / 2
	var q2 = h2.x - h2.y / 2
	var dq = q2 - q1
	var dy = h2.y - h1.y
	
	return max(abs(dq), abs(dy), abs(dq + dy))

func handle_mouse_enters_hex(hex: Hex):
	if not highlight_enabled:
		return
	if current_highlighted_tile:
		if current_highlighted_tile.modulate != Color.DARK_RED:
			current_highlighted_tile.modulate = GRID_COLOUR
	current_highlighted_tile = hex
	if current_highlighted_tile and current_highlighted_tile.modulate != Color.DARK_RED:
		current_highlighted_tile.modulate = Color.SANDY_BROWN

func handle_mouse_exits_hex(hex: Hex):
	if not highlight_enabled:
		return
	if current_highlighted_tile == hex:
		if current_highlighted_tile.modulate != Color.DARK_RED:
			current_highlighted_tile.modulate = GRID_COLOUR
		#current_highlighted_tile.modulate = GRID_COLOUR
		current_highlighted_tile = null
