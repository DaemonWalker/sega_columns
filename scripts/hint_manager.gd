extends Node2D
class_name HintManager

var mode: int = HintMode.Mode.MAX_CLEARED

var _markers: Array[Sprite2D] = []

const REFRESH_COOLDOWN_MS := 100
var _last_refresh_time: int = 0
var _cache_key: String = ""
var _cached_positions: Array[Vector2i] = []

func refresh(grid: Grid, active: ActiveColumn, state: int) -> void:
	if state != GameManager.State.FALLING and state != GameManager.State.LOCKING:
		clear_hints()
		return

	var now := Time.get_ticks_msec()
	if now - _last_refresh_time < REFRESH_COOLDOWN_MS:
		return
	_last_refresh_time = now

	var key := _make_cache_key(grid, active)
	if key == _cache_key and not _cached_positions.is_empty():
		if _markers.is_empty():
			for pos in _cached_positions:
				create_marker(pos)
		return

	var results := HintCalculator.calculate(grid, active)
	var positions := select_positions(results)

	clear_hints()
	for pos in positions:
		create_marker(pos)

	_cache_key = key
	_cached_positions = positions.duplicate()

func clear_hints() -> void:
	for m in _markers:
		m.queue_free()
	_markers.clear()
	_cached_positions.clear()
	_cache_key = ""

func select_positions(results: Array[PlacementResult]) -> Array[Vector2i]:
	var set: Array[Vector2i] = []
	if results.is_empty():
		return set

	match mode:
		HintMode.Mode.ALL_MATCHES:
			for r in results:
				for pos in r.matched_board_jewels:
					if not set.has(pos):
						set.append(pos)

		HintMode.Mode.RANDOM_MATCH:
			var match_results := results.filter(func(r): return r.total_cleared_count > 0)
			if match_results.size() > 0:
				var idx := randi() % match_results.size()
				for pos in match_results[idx].matched_board_jewels:
					if not set.has(pos):
						set.append(pos)

		HintMode.Mode.MAX_SCORE:
			var best_score: int = results.map(func(r): return r.total_score).max()
			var best_score_results := results.filter(func(r): return r.total_score == best_score)
			var best_score_result := pick_one(best_score_results)
			if best_score_result != null:
				for pos in best_score_result.matched_board_jewels:
					if not set.has(pos):
						set.append(pos)

		HintMode.Mode.MAX_CLEARED:
			var best_count: int = results.map(func(r): return r.total_cleared_count).max()
			var best_count_results := results.filter(func(r): return r.total_cleared_count == best_count)
			var best_count_result := pick_one(best_count_results)
			if best_count_result != null:
				for pos in best_count_result.matched_board_jewels:
					if not set.has(pos):
						set.append(pos)

	return set

static func pick_one(results: Array) -> PlacementResult:
	if results.is_empty():
		return null
	results.sort_custom(func(a, b):
		if a.column != b.column:
			return a.column < b.column
		return a.permutation_index < b.permutation_index
	)
	return results[0]

func create_marker(grid_pos: Vector2i) -> void:
	var marker := Sprite2D.new()
	marker.position = BoardUtils.grid_to_local(grid_pos.x, grid_pos.y)
	marker.scale = Vector2.ONE
	marker.texture = null
	marker.z_index = 1
	marker.draw.connect(func(): on_marker_draw(marker))
	add_child(marker)
	_markers.append(marker)

	var tween := marker.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_loops()
	tween.tween_property(marker, "modulate", Color(1, 1, 1, 0.75), 0.35)
	tween.tween_property(marker, "modulate", Color(1, 1, 1, 0.25), 0.35)

func on_marker_draw(marker: Sprite2D) -> void:
	marker.draw_rect(Rect2(-GameManager.CELL_SIZE / 2 + 2, -GameManager.CELL_SIZE / 2 + 2, GameManager.CELL_SIZE - 4, GameManager.CELL_SIZE - 4), Color(1, 1, 0.6, 1), false, 3)

func _make_cache_key(grid: Grid, active: ActiveColumn) -> String:
	var parts: Array[String] = []
	parts.append(str(active.grid_pos.x))
	parts.append(str(active.grid_pos.y))
	parts.append("%d,%d,%d" % [active.jewels[0], active.jewels[1], active.jewels[2]])
	parts.append(str(mode))
	for c in range(GameManager.COLS):
		for r in range(GameManager.ROWS):
			var t: int = grid.get_cell(c, r)
			if t != JewelData.JewelType.EMPTY:
				parts.append("%d:%d=%d" % [c, r, t])
	return "|".join(parts)

func _exit_tree() -> void:
	clear_hints()
