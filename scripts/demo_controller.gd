extends Node
class_name DemoController

const ACTION_INTERVAL := 0.12

var _game_manager: GameManager
var _action_timer: float = 0.0
var _target_column: int = -1
var _target_cycle_count: int = 0

var _last_active: ActiveColumn = null
var _current_plan: PlacementResult = null

@onready var _demo_label: Label = get_node("../UI/DemoLabel")

func _ready() -> void:
	_game_manager = get_node("../StateMachine")
	if DemoState.is_demo:
		_game_manager.is_demo_mode = true
		if _demo_label != null:
			_demo_label.visible = true

func _process(delta: float) -> void:
	if not DemoState.is_demo:
		return

	if Input.is_anything_pressed():
		_exit_demo()
		return

	var state := _game_manager.get_state()
	if state != GameManager.State.FALLING and state != GameManager.State.LOCKING:
		_game_manager.stop_soft_drop()
		return

	if _game_manager.get_level() >= 8:
		_game_manager.stop_soft_drop()
	else:
		_game_manager.start_soft_drop()

	_action_timer -= delta
	if _action_timer > 0:
		return

	var active := _game_manager.get_active_column()
	var grid := _game_manager.get_grid()

	if active != _last_active:
		_last_active = active
		_current_plan = null

	if _current_plan == null:
		var results := HintCalculator.calculate(grid, active)
		_current_plan = _select_best_result(results)
		if _current_plan != null:
			_target_column = _current_plan.column
			_target_cycle_count = _current_plan.cycle_count
		else:
			_target_column = _find_safe_column(grid, active)
			_target_cycle_count = 0

	if _target_cycle_count > 0:
		_game_manager.cycle_active_column()
		_action_timer = ACTION_INTERVAL
		_current_plan = null
		return

	var current_col := active.grid_pos.x
	if current_col < _target_column:
		_game_manager.try_move(1)
		_action_timer = ACTION_INTERVAL
		return
	elif current_col > _target_column:
		_game_manager.try_move(-1)
		_action_timer = ACTION_INTERVAL
		return

func _select_best_result(results: Array[PlacementResult]) -> PlacementResult:
	if results.is_empty():
		return null
	var best_count: int = results.map(func(r): return r.total_cleared_count).max()
	var best_results := results.filter(func(r): return r.total_cleared_count == best_count)
	best_results.sort_custom(func(a, b):
		if a.column != b.column:
			return a.column < b.column
		return a.permutation_index < b.permutation_index
	)
	return best_results[0]

func _find_safe_column(grid: Grid, active: ActiveColumn) -> int:
	var best_col := active.grid_pos.x
	var best_height := GameManager.ROWS

	for col in range(GameManager.COLS):
		if not BoardUtils.can_move_to(grid, col, active.grid_pos.y):
			continue

		var height := 0
		for r in range(GameManager.ROWS - 1, -1, -1):
			if grid.get_cell(col, r) != JewelData.JewelType.EMPTY:
				height = r + 1
				break

		if height < best_height:
			best_height = height
			best_col = col
		elif height == best_height:
			if abs(col - active.grid_pos.x) < abs(best_col - active.grid_pos.x):
				best_col = col

	return best_col

func _exit_demo() -> void:
	DemoState.is_demo = false
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
