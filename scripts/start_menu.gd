extends Control
class_name StartMenu

var _start_button: Button
var _options_button: Button
var _leaderboard_button: Button
var _quit_button: Button
var _demo_button: Button
var _idle_timer: Timer

func _ready() -> void:
    _start_button = get_node("CenterContainer/VBoxContainer/StartButton")
    _options_button = get_node("CenterContainer/VBoxContainer/OptionsButton")
    _leaderboard_button = get_node("CenterContainer/VBoxContainer/LeaderboardButton")
    _quit_button = get_node("CenterContainer/VBoxContainer/QuitButton")
    _demo_button = get_node("CenterContainer/VBoxContainer/DemoButton")

    _start_button.pressed.connect(on_start_pressed)
    _options_button.pressed.connect(on_options_pressed)
    _leaderboard_button.pressed.connect(on_leaderboard_pressed)
    _quit_button.pressed.connect(on_quit_pressed)
    _demo_button.pressed.connect(on_demo_pressed)

    _start_button.grab_focus()

    _idle_timer = Timer.new()
    _idle_timer.wait_time = 15.0
    _idle_timer.one_shot = true
    _idle_timer.timeout.connect(on_idle_timeout)
    add_child(_idle_timer)
    _idle_timer.start()

    DemoState.is_demo = false

func on_start_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/single_player.tscn")

func on_options_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/options_menu.tscn")

func on_leaderboard_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/leaderboard.tscn")

func _input(event: InputEvent) -> void:
    if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
        _idle_timer.stop()
        _idle_timer.start()

func on_demo_pressed() -> void:
    DemoState.is_demo = true
    get_tree().change_scene_to_file("res://scenes/single_player.tscn")

func on_idle_timeout() -> void:
    get_tree().change_scene_to_file("res://scenes/leaderboard.tscn")

func on_quit_pressed() -> void:
    get_tree().quit()

func _exit_tree() -> void:
    _start_button.pressed.disconnect(on_start_pressed)
    _options_button.pressed.disconnect(on_options_pressed)
    _leaderboard_button.pressed.disconnect(on_leaderboard_pressed)
    _quit_button.pressed.disconnect(on_quit_pressed)
    _demo_button.pressed.disconnect(on_demo_pressed)
    if _idle_timer != null:
        _idle_timer.timeout.disconnect(on_idle_timeout)
