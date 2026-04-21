extends RefCounted
class_name HintCalculator

const COLS := GameManager.COLS
const ROWS := GameManager.ROWS

static func calculate(grid: Grid, active: ActiveColumn) -> Array[PlacementResult]:
	var results: Array[PlacementResult] = []
	var original_types: Array[int] = active.jewels.duplicate()
	var current_top_row := active.grid_pos.y
	var permutations := get_unique_permutations(original_types)

	for col in range(COLS):
		if not BoardUtils.can_move_to(grid, col, current_top_row):
			continue

		var landing_row := current_top_row
		while BoardUtils.can_move_to(grid, col, landing_row + 1):
			landing_row += 1

		for p_index in range(permutations.size()):
			var perm: Array[int] = permutations[p_index]
			var result := simulate_placement(grid, col, landing_row, p_index, perm)
			if result != null:
				result.cycle_count = calculate_cycle_count(original_types, perm)
				results.append(result)

	return results

static func get_unique_permutations(original: Array[int]) -> Array:
	var result: Array = []
	var seen := {}

	for i in range(3):
		var perm := original.duplicate()
		for _j in range(i):
			var last = perm[2]
			perm[2] = perm[1]
			perm[1] = perm[0]
			perm[0] = last
		var key := "%d,%d,%d" % [perm[0], perm[1], perm[2]]
		if not seen.has(key):
			seen[key] = true
			result.append(perm)

	return result

static func calculate_cycle_count(original: Array[int], target: Array[int]) -> int:
	for i in range(3):
		var cycled := original.duplicate()
		for _j in range(i):
			var last = cycled[2]
			cycled[2] = cycled[1]
			cycled[1] = cycled[0]
			cycled[0] = last
		if cycled[0] == target[0] and cycled[1] == target[1] and cycled[2] == target[2]:
			return i
	return 0

static func simulate_placement(grid: Grid, col: int, landing_row: int, perm_index: int, types: Array[int]) -> PlacementResult:
	var sim_grid: Grid = grid.duplicate()
	var active_cells := {}

	for i in range(3):
		var r := landing_row + i
		if r < 0:
			continue
		sim_grid.set_cell(col, r, types[i])
		active_cells[Vector2i(col, r)] = true

	var first_matches := find_matches(sim_grid)
	if first_matches.is_empty():
		return null

	var result := PlacementResult.new()
	result.column = col
	result.permutation_index = perm_index
	result.landing_row = landing_row
	result.total_cleared_count = 0
	result.total_score = 0

	for pos in first_matches:
		if not active_cells.has(pos):
			result.matched_board_jewels.append(pos)

	var chain_round := 0
	var total_cleared := 0
	var total_score := 0

	while true:
		var matches := find_matches(sim_grid)
		if matches.is_empty():
			break

		var count := matches.size()
		total_cleared += count
		total_score += count * (1 << chain_round)
		chain_round += 1

		for pos in matches:
			sim_grid.set_cellv(pos, JewelData.JewelType.EMPTY)
		apply_gravity(sim_grid)

	result.total_cleared_count = total_cleared
	result.total_score = total_score
	return result

static func find_matches(grid: Grid) -> Array[Vector2i]:
	var dirs := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]
	var to_remove: Dictionary = {}

	for c in range(COLS):
		for r in range(ROWS):
			var t: int = grid.get_cell(c, r)
			if t == JewelData.JewelType.EMPTY:
				continue
			for d in dirs:
				var pc: int = c - d.x
				var pr: int = r - d.y
				if pc >= 0 and pc < COLS and pr >= 0 and pr < ROWS and grid.get_cell(pc, pr) == t:
					continue
				var line: Array[Vector2i] = []
				var nc := c
				var nr := r
				while nc >= 0 and nc < COLS and nr >= 0 and nr < ROWS and grid.get_cell(nc, nr) == t:
					line.append(Vector2i(nc, nr))
					nc += d.x
					nr += d.y
				if line.size() >= 3:
					for pos in line:
						to_remove[pos] = true

	var result: Array[Vector2i] = []
	result.assign(to_remove.keys())
	return result

static func apply_gravity(grid: Grid) -> void:
	for c in range(COLS):
		var write_row := ROWS - 1
		for r in range(ROWS - 1, -1, -1):
			if grid.get_cell(c, r) != JewelData.JewelType.EMPTY:
				if write_row != r:
					grid.set_cell(c, write_row, grid.get_cell(c, r))
					grid.set_cell(c, r, JewelData.JewelType.EMPTY)
				write_row -= 1
