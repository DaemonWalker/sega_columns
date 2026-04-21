extends RefCounted
class_name ActiveColumn

var jewels: Array[int] = []
var grid_pos := Vector2i(2, -2)

func _init():
    reset()

func reset() -> void:
    jewels.clear()
    for i in range(3):
        jewels.append(JewelData.random_type())
    grid_pos = Vector2i(2, -2)

func cycle() -> void:
    var last = jewels[2]
    jewels[2] = jewels[1]
    jewels[1] = jewels[0]
    jewels[0] = last

func get_positions() -> Array[Vector2i]:
    return [
        Vector2i(grid_pos.x, grid_pos.y),
        Vector2i(grid_pos.x, grid_pos.y + 1),
        Vector2i(grid_pos.x, grid_pos.y + 2)
    ]
