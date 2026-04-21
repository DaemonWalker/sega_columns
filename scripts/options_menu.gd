extends Control
class_name OptionsMenu

var _difficulty_option: OptionButton
var _hint_mode_label: Label
var _hint_mode_option: OptionButton
var _resolution_label: Label
var _resolution_option: OptionButton
var _window_mode_option: OptionButton
var _v_sync_check: CheckButton
var _bindings_container: VBoxContainer
var _back_button: Button

var _listening_button: Button = null
var _listening_action: String = ""
var _listening_index: int = -1

var _resolutions := [
	Vector2i(1152, 648),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

var _resolution_labels := [
	"1152 x 648",
	"1280 x 720",
	"1920 x 1080",
    "2560 x 1440"
]

var _window_modes := [
	DisplayServer.WINDOW_MODE_WINDOWED,
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	DisplayServer.WINDOW_MODE_FULLSCREEN
]

var _window_mode_labels := [
	"Windowed",
	"Fullscreen",
    "Borderless Windowed"
]

var _difficulties := [
    "normal"
]

var _difficulty_labels := [
    "Normal"
]

var _hint_mode_labels := [
	"Off",
	"All Matches",
	"Random Match",
	"Max Score",
    "Max Cleared"
]

func _ready() -> void:
	_difficulty_option = get_node("MarginContainer/VBoxContainer/TabContainer/Game/VBoxContainer/DifficultyOption")
	_hint_mode_label = get_node("MarginContainer/VBoxContainer/TabContainer/Game/VBoxContainer/HintModeLabel")
	_hint_mode_option = get_node("MarginContainer/VBoxContainer/TabContainer/Game/VBoxContainer/HintModeOption")
	_resolution_label = get_node("MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/ResolutionLabel")
	_resolution_option = get_node("MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/ResolutionOption")
	_window_mode_option = get_node("MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/WindowModeOption")
	_v_sync_check = get_node("MarginContainer/VBoxContainer/TabContainer/Display/VBoxContainer/VSyncCheck")
	_bindings_container = get_node("MarginContainer/VBoxContainer/TabContainer/Controls/ScrollContainer/BindingsVBox")
	_back_button = get_node("MarginContainer/VBoxContainer/BackButton")

	_difficulty_option.clear()
	for i in range(_difficulty_labels.size()):
		_difficulty_option.add_item(_difficulty_labels[i], i)
	var diff_index := _difficulties.find(SettingsManager.instance.current.difficulty)
	_difficulty_option.select(diff_index if diff_index >= 0 else 0)
	_difficulty_option.item_selected.connect(on_difficulty_selected)

	_hint_mode_option.clear()
	for i in range(_hint_mode_labels.size()):
		_hint_mode_option.add_item(_hint_mode_labels[i], i)
	_hint_mode_option.select(SettingsManager.instance.current.hint_mode)
	_hint_mode_option.item_selected.connect(on_hint_mode_selected)

	_resolution_option.clear()
	for i in range(_resolution_labels.size()):
		_resolution_option.add_item(_resolution_labels[i], i)
	_resolution_option.select(SettingsManager.instance.current.resolution_index)
	_resolution_option.item_selected.connect(on_resolution_selected)

	_window_mode_option.clear()
	for i in range(_window_mode_labels.size()):
		_window_mode_option.add_item(_window_mode_labels[i], i)
	var current_mode_index := _window_modes.find(SettingsManager.instance.current.window_mode)
	_window_mode_option.select(current_mode_index if current_mode_index >= 0 else 0)
	_window_mode_option.item_selected.connect(on_window_mode_selected)

	_v_sync_check.button_pressed = SettingsManager.instance.current.vsync
	_v_sync_check.toggled.connect(on_v_sync_toggled)

	build_controls_list()

	_back_button.pressed.connect(on_back_pressed)

	_back_button.grab_focus()

	update_resolution_controls()

func update_resolution_controls() -> void:
	var show_resolution := _window_mode_option.selected != 2
	_resolution_label.visible = show_resolution
	_resolution_option.visible = show_resolution

func on_resolution_selected(index: int) -> void:
	SettingsManager.instance.current.resolution_index = index
	DisplayServer.window_set_size(_resolutions[index])
	SettingsManager.instance.save_settings()

func on_window_mode_selected(index: int) -> void:
	var mode: int = _window_modes[index]
	SettingsManager.instance.current.window_mode = mode
	DisplayServer.window_set_mode(mode)
	SettingsManager.instance.save_settings()
	update_resolution_controls()

func on_v_sync_toggled(toggled: bool) -> void:
	SettingsManager.instance.current.vsync = toggled
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if toggled else DisplayServer.VSYNC_DISABLED)
	SettingsManager.instance.save_settings()

func on_difficulty_selected(index: int) -> void:
	SettingsManager.instance.current.difficulty = _difficulties[index]
	SettingsManager.instance.save_settings()

func on_hint_mode_selected(index: int) -> void:
	SettingsManager.instance.current.hint_mode = index
	SettingsManager.instance.save_settings()

func on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func save_game_settings() -> void:
	SettingsManager.instance.save_settings()

func build_controls_list() -> void:
	for child in _bindings_container.get_children():
		child.queue_free()

	for action_data in SettingsManager.instance.game_actions:
		var action := action_data[0] as String
		var display := action_data[1] as String

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)

		var label := Label.new()
		label.text = display
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)

		var btn_hbox := HBoxContainer.new()
		btn_hbox.add_theme_constant_override("separation", 8)

		var events := InputMap.action_get_events(action)
		for i in range(4):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(150, 0)
			if i < events.size():
				var event_text := events[i].as_text()
				if event_text.strip_edges().is_empty():
					event_text = "Space"
				btn.text = event_text
			else:
				btn.text = "+"
			btn.pressed.connect(func(): start_listening(btn, action, i))
			btn_hbox.add_child(btn)

		var reset_btn := Button.new()
		reset_btn.text = "Reset"
		reset_btn.custom_minimum_size = Vector2(80, 0)
		reset_btn.pressed.connect(func(): on_reset_action(action))
		btn_hbox.add_child(reset_btn)

		row.add_child(btn_hbox)
		_bindings_container.add_child(row)

func start_listening(btn: Button, action: String, index: int) -> void:
	stop_listening()
	_listening_button = btn
	_listening_action = action
	_listening_index = index
	btn.text = "Press key... (Del=clear)"

func _input(event: InputEvent) -> void:
	if _listening_button == null or _listening_action.is_empty() or _listening_index < 0:
		return

	if event.is_action_pressed("ui_cancel"):
		stop_listening()
		build_controls_list()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed:
		if event.physical_keycode in [KEY_CTRL, KEY_ALT, KEY_SHIFT, KEY_META, KEY_ESCAPE]:
			return

		if event.physical_keycode == KEY_DELETE or event.physical_keycode == KEY_BACKSPACE:
			_remove_event_at_index(_listening_action, _listening_index)
			stop_listening()
			build_controls_list()
			get_viewport().set_input_as_handled()
			return

		_add_or_replace_event(_listening_action, _listening_index, event)
		stop_listening()
		build_controls_list()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		_add_or_replace_event(_listening_action, _listening_index, event)
		stop_listening()
		build_controls_list()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
		var clamped := InputEventJoypadMotion.new()
		clamped.axis = event.axis
		clamped.axis_value = 1.0 if event.axis_value > 0 else -1.0
		_add_or_replace_event(_listening_action, _listening_index, clamped)
		stop_listening()
		build_controls_list()
		get_viewport().set_input_as_handled()

func _add_or_replace_event(action: String, index: int, event: InputEvent) -> void:
	var events := InputMap.action_get_events(action)
	for i in range(events.size() - 1, -1, -1):
		if _events_equal(events[i], event):
			events.remove_at(i)
	if index > events.size():
		index = events.size()
	if index < events.size():
		events[index] = event
	else:
		events.append(event)
	while events.size() > 4:
		events.remove_at(events.size() - 1)

	InputMap.action_erase_events(action)
	for ev in events:
		InputMap.action_add_event(action, ev)
	save_binding(action)

func _remove_event_at_index(action: String, index: int) -> void:
	var events := InputMap.action_get_events(action)
	if index >= 0 and index < events.size():
		events.remove_at(index)
		InputMap.action_erase_events(action)
		for ev in events:
			InputMap.action_add_event(action, ev)
		save_binding(action)

func _events_equal(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.keycode == b.keycode
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and a.axis_value == b.axis_value
	return false

func save_binding(action: String) -> void:
	var events := InputMap.action_get_events(action)
	SettingsManager.instance.current.input_bindings[action] = SettingsManager.serialize_events(events)
	SettingsManager.instance.save_settings()

func stop_listening() -> void:
	_listening_button = null
	_listening_action = ""
	_listening_index = -1

func on_reset_action(action: String) -> void:
	SettingsManager.instance.reset_action_binding(action)
	build_controls_list()

func _exit_tree() -> void:
	_difficulty_option.item_selected.disconnect(on_difficulty_selected)
	_hint_mode_option.item_selected.disconnect(on_hint_mode_selected)
	_resolution_option.item_selected.disconnect(on_resolution_selected)
	_window_mode_option.item_selected.disconnect(on_window_mode_selected)
	_v_sync_check.toggled.disconnect(on_v_sync_toggled)
	_back_button.pressed.disconnect(on_back_pressed)
