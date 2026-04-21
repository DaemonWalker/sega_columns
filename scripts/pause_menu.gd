extends Control
class_name PauseMenu

var _resume_button: Button
var _restart_button: Button
var _quit_button: Button

func _ready() -> void:
    _resume_button = get_node("CenterContainer/VBoxContainer/ResumeButton")
    _restart_button = get_node("CenterContainer/VBoxContainer/RestartButton")
    _quit_button = get_node("CenterContainer/VBoxContainer/QuitButton")

    _resume_button.pressed.connect(_on_resume)
    _restart_button.pressed.connect(_on_restart)
    _quit_button.pressed.connect(_on_quit)

    visible = false

func _input(event: InputEvent) -> void:
    if DemoState.is_demo:
        return

    if not visible and _is_pause_pressed(event):
        open()
        get_viewport().set_input_as_handled()
        return

    if visible and event.is_action_pressed("ui_cancel"):
        close()
        get_viewport().set_input_as_handled()

func _is_pause_pressed(event: InputEvent) -> bool:
    if event.is_action_pressed("ui_cancel"):
        return true
    if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
        return true
    return false

func open() -> void:
    visible = true
    get_tree().paused = true
    _resume_button.grab_focus()

func close() -> void:
    visible = false
    get_tree().paused = false

func _on_resume() -> void:
    close()

func _on_restart() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()

func _on_quit() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func _exit_tree() -> void:
    _resume_button.pressed.disconnect(_on_resume)
    _restart_button.pressed.disconnect(_on_restart)
    _quit_button.pressed.disconnect(_on_quit)
