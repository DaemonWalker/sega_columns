extends Node
class_name GameManager

const COLS := 6
const ROWS := 13
const CELL_SIZE := 48.0
const LOCK_DELAY := 0.5
const CLEAR_DELAY := 0.25
const COLLAPSE_DELAY := 0.12

enum State {
	FALLING,
	LOCKING,
	CHECKING,
	CLEARING,
	COLLAPSING,
	GAME_OVER
}

var _game_board: Node2D
var _board_layer: TileMapLayer
var _active_container: Node2D
var _fall_timer: Timer
var _lock_timer: Timer
var _clear_timer: Timer
var _collapse_timer: Timer
var _sfx_player: AudioStreamPlayer

var _score_label: Label
var _level_label: Label
var _jewels_label: Label
var _game_over_label: Label
var _next_preview_container: Node2D
var _hint_manager: HintManager

var _grid: Grid = Grid.new()
var _active_column: ActiveColumn
var _active_jewels: Array[Jewel] = []
var _next_column: ActiveColumn
var _next_jewels: Array[Jewel] = []

var _state: int = State.FALLING
var _score: int = 0
var _level: int = 0
var _jewels_cleared_count: int = 0
var _chain_count: int = 0
var _fall_interval: float = 0.8

var _display_score: float = 0.0
var _display_jewels_cleared_count: float = 0.0
var _target_score: int = 0
var _target_jewels_cleared_count: int = 0

var _chain_label: Label
var _is_soft_dropping: bool = false
var _jewels_to_remove: Array[Vector2i] = []

var _jewel_pool: Array[Jewel] = []

var is_demo_mode: bool = false

const STICK_MOVE_COOLDOWN := 0.18
var _stick_move_timer: float = 0.0

var _sfx_clear: AudioStreamWAV
var _sfx_cycle: AudioStreamWAV
var _sfx_lock: AudioStreamWAV

func _ready() -> void:
	_game_board = get_node("../GameBoard")
	_board_layer = get_node("../GameBoard/BoardLayer")
	_active_container = get_node("../GameBoard/ActiveColumnContainer")
	_fall_timer = get_node("FallTimer")
	_lock_timer = get_node("LockTimer")
	_clear_timer = get_node("ClearTimer")
	_collapse_timer = get_node("CollapseTimer")
	_sfx_player = get_node("SfxPlayer")

	_chain_label = get_node("../UI/ChainLabel")

	_score_label = get_node("../UI/ScoreValue")
	_level_label = get_node("../UI/LevelValue")
	_jewels_label = get_node("../UI/JewelsValue")
	_game_over_label = get_node("../UI/GameOverLabel")
	_next_preview_container = get_node("../UI/NextPreview")
	_hint_manager = get_node("../GameBoard/HintLayer")
	_hint_manager.mode = SettingsManager.instance.current.hint_mode

	_lock_timer.wait_time = LOCK_DELAY
	_clear_timer.wait_time = CLEAR_DELAY
	_collapse_timer.wait_time = COLLAPSE_DELAY
	_fall_timer.wait_time = _fall_interval

	_fall_timer.timeout.connect(on_fall_timer_timeout)
	_lock_timer.timeout.connect(on_lock_timer_timeout)
	_clear_timer.timeout.connect(on_clear_timer_timeout)
	_collapse_timer.timeout.connect(on_collapse_timer_timeout)

	_display_score = 0.0
	_display_jewels_cleared_count = 0.0
	_target_score = 0
	_target_jewels_cleared_count = 0

	setup_sfx()
	setup_tile_set()
	_board_layer.position = Vector2(-(COLS * CELL_SIZE) / 2.0, -(ROWS * CELL_SIZE) / 2.0)

	init_grid()

	_next_column = ActiveColumn.new()
	for i in range(3):
		var j := Jewel.new()
		j.setup(_next_column.jewels[i], Vector2i(-1, -1))
		j.scale = Vector2.ONE * 0.25
		_next_preview_container.add_child(j)
		_next_jewels.append(j)
	update_next_preview()

	spawn_active_column()
	update_ui()
	_fall_timer.start()

func setup_tile_set() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(int(CELL_SIZE), int(CELL_SIZE))

	var types := [
		JewelData.JewelType.RED, JewelData.JewelType.BLUE, JewelData.JewelType.GREEN,
		JewelData.JewelType.YELLOW, JewelData.JewelType.PURPLE, JewelData.JewelType.ORANGE, JewelData.JewelType.MAGIC
	]

	for i in range(types.size()):
		var source := TileSetAtlasSource.new()
		source.texture_region_size = Vector2i(int(CELL_SIZE), int(CELL_SIZE))
		var tex := JewelData.get_texture(types[i])
		var img := tex.get_image()
		if img != null:
			img.resize(int(CELL_SIZE), int(CELL_SIZE), Image.INTERPOLATE_LANCZOS)
			source.texture = ImageTexture.create_from_image(img)
		else:
			source.texture = tex
		source.create_tile(Vector2i.ZERO)
		tile_set.add_source(source, i)

	_board_layer.tile_set = tile_set

func init_grid() -> void:
	_grid.fill(JewelData.JewelType.EMPTY)
	_board_layer.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()

func _exit_tree() -> void:
	_fall_timer.stop()
	_lock_timer.stop()
	_clear_timer.stop()
	_collapse_timer.stop()

	_fall_timer.timeout.disconnect(on_fall_timer_timeout)
	_lock_timer.timeout.disconnect(on_lock_timer_timeout)
	_clear_timer.timeout.disconnect(on_clear_timer_timeout)
	_collapse_timer.timeout.disconnect(on_collapse_timer_timeout)

	for j in _active_jewels:
		if is_instance_valid(j):
			j.queue_free()
	_active_jewels.clear()

	for j in _next_jewels:
		if is_instance_valid(j):
			j.queue_free()
	_next_jewels.clear()

	for j in _jewel_pool:
		if is_instance_valid(j):
			j.queue_free()
	_jewel_pool.clear()

func _process(delta: float) -> void:
	update_rolling_numbers(delta)

	if is_demo_mode:
		return

	if _state != State.FALLING and _state != State.LOCKING:
		return

	_stick_move_timer -= delta
	if _stick_move_timer > 0:
		return

	if Input.is_action_pressed("move_left"):
		_handle_move(-1)
	elif Input.is_action_pressed("move_right"):
		_handle_move(1)
	elif Input.is_action_pressed("cycle"):
		_handle_cycle()

func _unhandled_input(event: InputEvent) -> void:
	if is_demo_mode:
		return

	if _state == State.GAME_OVER:
		if event.is_action_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return

	if _state != State.FALLING and _state != State.LOCKING:
		return

	if event is InputEventJoypadMotion:
		return

	if event.is_action_pressed("move_left"):
		_handle_move(-1)
	elif event.is_action_pressed("move_right"):
		_handle_move(1)
	elif event.is_action_pressed("cycle"):
		_handle_cycle()
	elif event.is_action_pressed("soft_drop"):
		start_soft_drop()
	elif event.is_action_released("soft_drop"):
		stop_soft_drop()

func _handle_move(dir: int) -> void:
	try_move(dir)
	_stick_move_timer = STICK_MOVE_COOLDOWN


func _handle_cycle() -> void:
	_active_column.cycle()
	update_active_column_visuals()
	play_sfx(_sfx_cycle)
	_stick_move_timer = STICK_MOVE_COOLDOWN
	if _state == State.LOCKING:
		_lock_timer.start(LOCK_DELAY)


func _acquire_jewel() -> Jewel:
	if _jewel_pool.is_empty():
		return Jewel.new()
	var j: Jewel = _jewel_pool.pop_back()
	j.visible = true
	j.modulate = Color.WHITE
	j.scale = Vector2.ONE * 0.25
	j.is_clearing = false
	j.queue_redraw()
	return j

func _release_jewel(j: Jewel) -> void:
	if not is_instance_valid(j):
		return
	if j.get_parent() != null:
		j.get_parent().remove_child(j)
	_jewel_pool.append(j)

func start_soft_drop() -> void:
	if not _is_soft_dropping:
		_is_soft_dropping = true
		_fall_timer.wait_time = 0.05
		_fall_timer.stop()
		_fall_timer.start()

func stop_soft_drop() -> void:
	if _is_soft_dropping:
		_is_soft_dropping = false
		_fall_timer.wait_time = _fall_interval
		_fall_timer.stop()
		_fall_timer.start()

func spawn_active_column() -> void:
	_hint_manager.clear_hints()

	if _is_soft_dropping:
		_is_soft_dropping = false
		_fall_timer.wait_time = _fall_interval

	_active_column = _next_column

	for child in _active_container.get_children():
		child.queue_free()
	_active_jewels.clear()

	for i in range(3):
		var j := Jewel.new()
		j.setup(_active_column.jewels[i], Vector2i(_active_column.grid_pos.x, _active_column.grid_pos.y + i))
		j.scale = Vector2.ONE * 0.25
		_active_container.add_child(j)
		_active_jewels.append(j)

	_next_column = ActiveColumn.new()
	update_next_preview()

	_chain_count = 0
	update_active_column_visuals()
	_state = State.FALLING
	_fall_timer.start()

func update_next_preview() -> void:
	for i in range(3):
		var j := _next_jewels[i]
		j.jewel_type = _next_column.jewels[i]
		j.setup(j.jewel_type, Vector2i(-1, -1))
		j.position = Vector2(0, (i - 1) * Jewel.SIZE)

func update_active_column_visuals() -> void:
	for i in range(3):
		var j := _active_jewels[i]
		j.jewel_type = _active_column.jewels[i]
		j.setup(j.jewel_type, Vector2i(_active_column.grid_pos.x, _active_column.grid_pos.y + i))
		j.position = grid_to_local(_active_column.grid_pos.x, _active_column.grid_pos.y + i)
		j.visible = (_active_column.grid_pos.y + i) >= 0

	_hint_manager.refresh(_grid, _active_column, _state)

func try_move(dir: int) -> void:
	var new_col := _active_column.grid_pos.x + dir
	if can_move_to(new_col, _active_column.grid_pos.y):
		_active_column.grid_pos = Vector2i(new_col, _active_column.grid_pos.y)
		update_active_column_visuals()
		if _state == State.LOCKING:
			if not is_active_bottomed():
				_state = State.FALLING
				_lock_timer.stop()
				_fall_timer.start()
			else:
				_lock_timer.start(LOCK_DELAY)

func can_move_to(col: int, row_top: int) -> bool:
	return BoardUtils.can_move_to(_grid, col, row_top)

func is_active_bottomed() -> bool:
	var col := _active_column.grid_pos.x
	var row_top := _active_column.grid_pos.y
	for i in range(3):
		var r := row_top + i
		if r >= ROWS - 1:
			return true
		if r + 1 >= 0 and _grid.get_cell(col, r + 1) != JewelData.JewelType.EMPTY:
			return true
	return false

func on_fall_timer_timeout() -> void:
	if _state != State.FALLING:
		return
	var next_row := _active_column.grid_pos.y + 1
	if can_move_to(_active_column.grid_pos.x, next_row):
		_active_column.grid_pos = Vector2i(_active_column.grid_pos.x, next_row)
		update_active_column_visuals()
		_fall_timer.start()
	else:
		_state = State.LOCKING
		_lock_timer.start(LOCK_DELAY)

func on_lock_timer_timeout() -> void:
	if _state != State.LOCKING:
		return

	if _active_column.grid_pos.y < 0:
		enter_game_over()
		return

	play_sfx(_sfx_lock)
	write_active_to_grid()
	_state = State.CHECKING
	check_matches()

func write_active_to_grid() -> void:
	for i in range(3):
		var c := _active_column.grid_pos.x
		var r := _active_column.grid_pos.y + i
		if r < 0:
			continue
		var type: int = _active_column.jewels[i]
		_grid.set_cell(c, r, type)
		_board_layer.set_cell(Vector2i(c, r), JewelData.TILE_SOURCE_IDS[type], Vector2i.ZERO)

	for j in _active_jewels:
		j.queue_free()
	_active_jewels.clear()

	_hint_manager.clear_hints()

func check_matches() -> void:
	var to_remove := find_matches()
	if to_remove.is_empty():
		spawn_active_column()
		return
	_state = State.CLEARING
	_jewels_to_remove = to_remove.duplicate()
	_clear_timer.start(CLEAR_DELAY)

func on_clear_timer_timeout() -> void:
	if _state != State.CLEARING:
		return
	play_sfx(_sfx_clear)
	var count := _jewels_to_remove.size()
	_jewels_cleared_count += count
	var chain_multiplier := 1 << _chain_count
	_score += count * 10 * (_level + 1) * chain_multiplier
	if _chain_count > 0:
		show_chain_effect(chain_multiplier)
	_chain_count += 1
	update_level()
	update_ui()

	var temp_jewels: Array[Jewel] = []

	for pos in _jewels_to_remove:
		var c := pos.x
		var r := pos.y
		var type: int = _grid.get_cellv(pos)
		_grid.set_cellv(pos, JewelData.JewelType.EMPTY)
		_board_layer.erase_cell(pos)

		var j := _acquire_jewel()
		j.setup(type, pos)
		j.scale = Vector2.ONE * 0.25
		j.position = grid_to_local(c, r)
		_game_board.add_child(j)
		temp_jewels.append(j)
		j.play_clear(CLEAR_DELAY)

	await get_tree().create_timer(CLEAR_DELAY + 0.05).timeout

	if not is_instance_valid(self):
		return

	for j in temp_jewels:
		if is_instance_valid(j):
			_release_jewel(j)

	_state = State.COLLAPSING
	apply_gravity()

func apply_gravity() -> void:
	var any_moved := false
	var temp_jewels: Array[Dictionary] = []

	for c in range(COLS):
		var write_row := ROWS - 1
		for r in range(ROWS - 1, -1, -1):
			if _grid.get_cell(c, r) != JewelData.JewelType.EMPTY:
				if write_row != r:
					var type: int = _grid.get_cell(c, r)
					_grid.set_cell(c, write_row, type)
					_grid.set_cell(c, r, JewelData.JewelType.EMPTY)
					_board_layer.erase_cell(Vector2i(c, r))

					var j := _acquire_jewel()
					j.setup(type, Vector2i(c, write_row))
					j.scale = Vector2.ONE * 0.25
					j.position = grid_to_local(c, r)
					_game_board.add_child(j)
					j.animate_fall(grid_to_local(c, write_row), COLLAPSE_DELAY)
					temp_jewels.append({"jewel": j, "target_pos": Vector2i(c, write_row)})
					any_moved = true
				write_row -= 1

	if temp_jewels.size() > 0:
		await get_tree().create_timer(COLLAPSE_DELAY + 0.05).timeout

	if not is_instance_valid(self):
		return

	for item in temp_jewels:
		var j: Jewel = item["jewel"]
		var target_pos: Vector2i = item["target_pos"]
		if is_instance_valid(j):
			_board_layer.set_cell(target_pos, JewelData.TILE_SOURCE_IDS[j.jewel_type], Vector2i.ZERO)
			_release_jewel(j)

	_collapse_timer.start(COLLAPSE_DELAY + 0.05 if any_moved else 0.05)

func on_collapse_timer_timeout() -> void:
	if _state != State.COLLAPSING:
		return
	_state = State.CHECKING
	check_matches()

func find_matches() -> Array[Vector2i]:
	var dirs := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]
	var to_remove: Dictionary = {}
	for c in range(COLS):
		for r in range(ROWS):
			var t: int = _grid.get_cell(c, r)
			if t == JewelData.JewelType.EMPTY:
				continue
			for d in dirs:
				var pc: int = c - d.x
				var pr: int = r - d.y
				if pc >= 0 and pc < COLS and pr >= 0 and pr < ROWS and _grid.get_cell(pc, pr) == t:
					continue
				var line: Array[Vector2i] = []
				var nc := c
				var nr := r
				while nc >= 0 and nc < COLS and nr >= 0 and nr < ROWS and _grid.get_cell(nc, nr) == t:
					line.append(Vector2i(nc, nr))
					nc += d.x
					nr += d.y
				if line.size() >= 3:
					for pos in line:
						to_remove[pos] = true
	var result: Array[Vector2i] = []
	result.assign(to_remove.keys())
	return result

func update_level() -> void:
	var new_level := _jewels_cleared_count / 35
	if new_level > _level:
		_level = new_level
		_fall_interval = maxf(0.05, 0.8 - _level * 0.07)
		if not _is_soft_dropping:
			_fall_timer.wait_time = _fall_interval

func show_chain_effect(chain_multiplier: int) -> void:
	_chain_label.text = "x%d CHAIN!" % chain_multiplier
	_chain_label.visible = true
	_chain_label.modulate = Color(1, 1, 1, 1)
	_chain_label.scale = Vector2.ONE

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_chain_label, "scale", Vector2.ONE * 1.5, 0.12)
	tween.tween_property(_chain_label, "scale", Vector2.ONE, 0.2)

	var fade_tween := create_tween()
	fade_tween.tween_interval(1.2)
	fade_tween.tween_property(_chain_label, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(func(): _chain_label.visible = false)

func update_ui() -> void:
	_target_score = _score
	_target_jewels_cleared_count = _jewels_cleared_count
	_level_label.text = str(_level)

func update_rolling_numbers(delta: float) -> void:
	var dt := delta
	var speed := 14.0

	if _display_score < _target_score:
		_display_score += (_target_score - _display_score) * dt * speed
		if _target_score - _display_score < 0.5:
			_display_score = _target_score
		_score_label.text = str(int(round(_display_score)))

	if _display_jewels_cleared_count < _target_jewels_cleared_count:
		_display_jewels_cleared_count += (_target_jewels_cleared_count - _display_jewels_cleared_count) * dt * speed
		if _target_jewels_cleared_count - _display_jewels_cleared_count < 0.5:
			_display_jewels_cleared_count = _target_jewels_cleared_count
		_jewels_label.text = str(int(round(_display_jewels_cleared_count)))

func enter_game_over() -> void:
	_state = State.GAME_OVER
	_fall_timer.stop()
	_lock_timer.stop()
	_hint_manager.clear_hints()
	_game_over_label.text = "GAME OVER\nPress Accept to Restart"
	_game_over_label.visible = true

	_display_score = _score
	_display_jewels_cleared_count = _jewels_cleared_count
	_score_label.text = str(_score)
	_jewels_label.text = str(_jewels_cleared_count)

	LeaderboardManager.add_score_entry(_score)
	LeaderboardManager.add_cleared_entry(_jewels_cleared_count)

func setup_sfx() -> void:
	_sfx_cycle = generate_tone(880.0, 0.08, 0.4)
	_sfx_lock = generate_tone(330.0, 0.12, 0.5)
	_sfx_clear = generate_clear_sound()

func play_sfx(stream: AudioStreamWAV) -> void:
	_sfx_player.stream = stream
	_sfx_player.play()

static func generate_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	const SAMPLE_RATE := 44100
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var envelope := 1.0 - (i / float(samples))
		var sample := volume * sin(TAU * frequency * i / SAMPLE_RATE) * envelope
		var value := int(sample * 32767)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

static func generate_clear_sound() -> AudioStreamWAV:
	const SAMPLE_RATE := 44100
	var duration := 0.25
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var freqs := [523.25, 659.25, 783.99]
	for i in range(samples):
		var envelope := maxf(0.0, 1.0 - (i / (SAMPLE_RATE * 0.15)))
		var sample := 0.0
		for f in freqs:
			sample += 0.15 * sin(TAU * f * i / SAMPLE_RATE) * envelope
		var value := int(sample * 32767)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

func get_state() -> int:
	return _state

func get_level() -> int:
	return _level

func get_active_column() -> ActiveColumn:
	return _active_column

func get_grid() -> Grid:
	return _grid.duplicate()

func cycle_active_column() -> void:
	if _state != State.FALLING and _state != State.LOCKING:
		return
	_active_column.cycle()
	update_active_column_visuals()
	play_sfx(_sfx_cycle)
	if _state == State.LOCKING:
		_lock_timer.start(LOCK_DELAY)

static func grid_to_local(col: int, row: int) -> Vector2:
	return BoardUtils.grid_to_local(col, row)
