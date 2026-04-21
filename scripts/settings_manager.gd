extends Node

static var instance: SettingsManager = null
const SAVE_PATH := "user://settings.json"

var game_actions := [
	["move_left", "Move Left"],
	["move_right", "Move Right"],
	["cycle", "Cycle Jewel"],
	["soft_drop", "Soft Drop"]
]

var current := GameSettings.new()

func _ready() -> void:
	instance = self
	ensure_input_actions_exist()
	load_settings()
	apply_all_settings()

func _exit_tree() -> void:
	instance = null

func ensure_input_actions_exist() -> void:
	for action_data in game_actions:
		var action := action_data[0] as String
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.5)

	if not FileAccess.file_exists(SAVE_PATH):
		set_default_bindings()

func set_default_bindings() -> void:
	current.input_bindings.clear()
	for action_data in game_actions:
		var action := action_data[0] as String
		reset_action_binding(action)

func reset_action_binding(action: String) -> void:
	match action:
		"move_left":
			clear_and_bind(action, [
				_create_key_event(KEY_LEFT),
				_create_joypad_button_event(JOY_BUTTON_DPAD_LEFT),
				_create_joypad_motion_event(JOY_AXIS_LEFT_X, -1.0)
			])
		"move_right":
			clear_and_bind(action, [
				_create_key_event(KEY_RIGHT),
				_create_joypad_button_event(JOY_BUTTON_DPAD_RIGHT),
				_create_joypad_motion_event(JOY_AXIS_LEFT_X, 1.0)
			])
		"cycle":
			clear_and_bind(action, [
				_create_key_event(KEY_UP),
				_create_key_event(KEY_SPACE),
				_create_joypad_button_event(JOY_BUTTON_A),
				_create_joypad_button_event(JOY_BUTTON_DPAD_UP)
			])
		"soft_drop":
			clear_and_bind(action, [
				_create_key_event(KEY_DOWN),
				_create_joypad_button_event(JOY_BUTTON_DPAD_DOWN),
				_create_joypad_motion_event(JOY_AXIS_LEFT_Y, 1.0)
			])
	current.input_bindings[action] = serialize_events(InputMap.action_get_events(action))

func _create_key_event(physical_keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = physical_keycode
	ev.physical_keycode = physical_keycode
	return ev

func _create_joypad_button_event(button_index: int) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button_index
	return ev

func _create_joypad_motion_event(axis: int, axis_value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = axis_value
	return ev

func clear_and_bind(action: String, events: Array) -> void:
	InputMap.action_erase_events(action)
	for ev in events:
		InputMap.action_add_event(action, ev)

func apply_all_settings() -> void:
	apply_display_settings()
	apply_resolution()
	apply_input_bindings()

func apply_display_settings() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if current.vsync else DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_mode(current.window_mode)

func apply_resolution() -> void:
	var res := get_resolution(current.resolution_index)
	if res != Vector2i.ZERO:
		DisplayServer.window_set_size(res)

func get_resolution(index: int) -> Vector2i:
	match index:
		0: return Vector2i(1152, 648)
		1: return Vector2i(1280, 720)
		2: return Vector2i(1920, 1080)
		3: return Vector2i(2560, 1440)
		_: return Vector2i(1152, 648)

func apply_input_bindings() -> void:
	for action_data in game_actions:
		var action := action_data[0] as String
		if not current.input_bindings.has(action):
			continue
		InputMap.action_erase_events(action)
		var events := parse_events(current.input_bindings[action])
		for ev in events:
			if ev != null:
				InputMap.action_add_event(action, ev)

static func serialize_events(events: Array[InputEvent]) -> String:
	var parts: Array[String] = []
	for ev in events:
		if ev is InputEventKey:
			parts.append("K|%d" % ev.physical_keycode)
		elif ev is InputEventJoypadButton:
			parts.append("JB|%d" % ev.button_index)
		elif ev is InputEventJoypadMotion:
			parts.append("JM|%d|%.1f" % [ev.axis, ev.axis_value])
	return ";".join(parts)

func parse_events(data: String) -> Array:
	var list := []
	if data.strip_edges().is_empty():
		return list
	for part in data.split(";"):
		var tokens := part.split("|")
		if tokens.size() < 2:
			continue
		match tokens[0]:
			"K":
				var ev := InputEventKey.new()
				ev.keycode = int(tokens[1])
				ev.physical_keycode = int(tokens[1])
				list.append(ev)
			"JB":
				var ev := InputEventJoypadButton.new()
				ev.button_index = int(tokens[1])
				list.append(ev)
			"JM":
				if tokens.size() == 3:
					var ev := InputEventJoypadMotion.new()
					ev.axis = int(tokens[1])
					ev.axis_value = float(tokens[2])
					list.append(ev)
	return list

func save_settings() -> void:
	var bind_dict := {}
	for kv in current.input_bindings:
		bind_dict[kv] = current.input_bindings[kv]

	var dict := {
		"difficulty": current.difficulty,
		"resolution_index": current.resolution_index,
		"window_mode": current.window_mode,
		"vsync": current.vsync,
		"hint_mode": current.hint_mode,
		"input_bindings": bind_dict
	}

	var json := JSON.stringify(dict)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(json)
		file.close()

func _reset_to_defaults() -> void:
	current = GameSettings.new()
	set_default_bindings()
	save_settings()

func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_reset_to_defaults()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_reset_to_defaults()
		return

	var text := file.get_as_text()
	file.close()
	if text.strip_edges().is_empty():
		_reset_to_defaults()
		return

	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or parsed.is_empty():
		_reset_to_defaults()
		return

	current.difficulty = parsed.get("difficulty", "normal")
	current.resolution_index = parsed.get("resolution_index", 0)
	current.window_mode = parsed.get("window_mode", DisplayServer.WINDOW_MODE_WINDOWED)
	current.vsync = parsed.get("vsync", true)
	current.hint_mode = parsed.get("hint_mode", HintMode.Mode.MAX_CLEARED)

	current.input_bindings.clear()
	var bind_dict: Dictionary = parsed.get("input_bindings", {})
	if typeof(bind_dict) == TYPE_DICTIONARY:
		for kv in bind_dict:
			current.input_bindings[kv] = str(bind_dict[kv])

	if current.input_bindings.is_empty():
		_reset_to_defaults()

class GameSettings:
	var difficulty := "normal"
	var resolution_index := 0
	var window_mode := DisplayServer.WINDOW_MODE_WINDOWED
	var vsync := true
	var hint_mode := HintMode.Mode.MAX_CLEARED
	var input_bindings: Dictionary = {}
