extends Node2D
class_name GridLines

@export var cols: int = 6
@export var rows: int = 13
@export var cell_size: float = 48.0
@export var line_color: Color = Color(0.2, 0.2, 0.25)

func _draw() -> void:
    var width := cols * cell_size
    var height := rows * cell_size
    var offset := Vector2(-width / 2.0, -height / 2.0)

    for c in range(cols + 1):
        var x := offset.x + c * cell_size
        draw_line(Vector2(x, offset.y), Vector2(x, offset.y + height), line_color, 1.0)

    for r in range(rows + 1):
        var y := offset.y + r * cell_size
        draw_line(Vector2(offset.x, y), Vector2(offset.x + width, y), line_color, 1.0)
