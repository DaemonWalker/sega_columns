extends Control
class_name LeaderboardMenu

var _tab_container: TabContainer
var _score_list: VBoxContainer
var _cleared_list: VBoxContainer
var _back_button: Button
var _font: FontFile

func _ready() -> void:
	_font = load("res://assets/fonts/PressStart2P-Regular.ttf")

	_tab_container = get_node("MarginContainer/VBoxContainer/TabContainer")
	_back_button = get_node("MarginContainer/VBoxContainer/BackButton")

	_score_list = get_node("MarginContainer/VBoxContainer/TabContainer/Score/VBoxContainer")
	_cleared_list = get_node("MarginContainer/VBoxContainer/TabContainer/Cleared/VBoxContainer")

	_back_button.pressed.connect(on_back_pressed)
	_back_button.grab_focus()

	refresh_lists()

func refresh_lists() -> void:
	for child in _score_list.get_children():
		child.queue_free()
	for child in _cleared_list.get_children():
		child.queue_free()

	var score_entries := LeaderboardManager.get_score_entries()
	if score_entries.is_empty():
		add_empty_row(_score_list, "No records yet")
	else:
		add_header_row(_score_list, "Score", "Date")
		for i in range(score_entries.size()):
			var entry: Dictionary = score_entries[i]
			add_data_row(_score_list, i + 1, entry["value"], entry["timestamp"])

	var cleared_entries := LeaderboardManager.get_cleared_entries()
	if cleared_entries.is_empty():
		add_empty_row(_cleared_list, "No records yet")
	else:
		add_header_row(_cleared_list, "Cleared", "Date")
		for i in range(cleared_entries.size()):
			var entry: Dictionary = cleared_entries[i]
			add_data_row(_cleared_list, i + 1, entry["value"], entry["timestamp"])

func add_header_row(container: VBoxContainer, value_header: String, time_header: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)

	var rank := _create_label("#", 0.5)
	hbox.add_child(rank)

	var value := _create_label(value_header, 1.0)
	hbox.add_child(value)

	var time := _create_label(time_header, 1.5)
	hbox.add_child(time)

	container.add_child(hbox)

	var sep := HSeparator.new()
	container.add_child(sep)

func add_data_row(container: VBoxContainer, rank: int, value: int, timestamp: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)

	var rank_label := _create_label(str(rank), 0.5)
	hbox.add_child(rank_label)

	var value_label := _create_label(str(value), 1.0)
	hbox.add_child(value_label)

	var time_label := _create_label(_format_timestamp(timestamp), 1.5)
	hbox.add_child(time_label)

	container.add_child(hbox)

func add_empty_row(container: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", 20)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(label)

func _create_label(text: String, stretch_ratio: float) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", 18)
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_stretch_ratio = stretch_ratio
	return label

func _format_timestamp(timestamp: String) -> String:
	var parts := timestamp.split("T")
	if parts.size() != 2:
		return timestamp
	var date := parts[0]
	var time := parts[1]
	var time_parts := time.split(":")
	if time_parts.size() >= 2:
		time = time_parts[0] + ":" + time_parts[1]
	return date + " " + time

func on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func _exit_tree() -> void:
	_back_button.pressed.disconnect(on_back_pressed)
