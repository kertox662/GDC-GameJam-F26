class_name DashToBackRow extends AbilityBehaviour

# When enemies get near, dash to the back row. If full, try next row
# until finding one that works.
func _init() -> void:
	cooldown = 10.0

func try_cast(state: EntityManager.EntityState) -> void:
	var enemy = state.oppInRange(owner)
	if enemy == null:
		return
	var grid = state.hexGrid
	# Nearest empty hex, scanning rows from the top (y = 0) downwards.
	var best: Hex = null
	var best_score := INF
	for y in range(grid.height):
		for x in range(grid.width):
			var hex = grid.getHexFromGrid(Vector2i(x, y))
			if hex == null or grid.getOccupied(hex):
				continue
			# Prefer the topmost row, then the hex closest to the owner.
			var score = y * 100.0 + absf(x - owner.currentHex.x)
			if score < best_score:
				best_score = score
				best = hex
	if best == null:
		return
	# Teleport the dash.
	grid.setOccupied(owner.currentHex, false)
	grid.setOccupied(best, true)
	state.unitTiles[owner] = [best]
	owner.currentHex = best
	owner.position = best.position
	owner.trajectory = []
	owner.target = null
