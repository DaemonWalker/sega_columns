extends Sprite2D
class_name Jewel

var jewel_type: int = JewelData.JewelType.EMPTY
var grid_pos := Vector2i(-1, -1)
var is_clearing := false

const SIZE := 48.0
const RADIUS := 80.0

func setup(type: int, pos: Vector2i) -> void:
    jewel_type = type
    grid_pos = pos
    texture = JewelData.get_texture(type)
    queue_redraw()

func set_grid_pos(pos: Vector2i) -> void:
    grid_pos = pos

func _draw() -> void:
    if is_clearing:
        draw_circle(Vector2.ZERO, RADIUS, Color(1, 1, 1, 0.35))

func play_clear(duration: float = 0.2) -> void:
    is_clearing = true
    queue_redraw()
    var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.tween_property(self, "scale", Vector2.ZERO, duration)
    await tween.finished

func animate_fall(target_local_pos: Vector2, duration: float = 0.1) -> void:
    var tween := create_tween().set_trans(Tween.TRANS_LINEAR)
    tween.tween_property(self, "position", target_local_pos, duration)
    await tween.finished
