extends RefCounted
class_name Grid

const COLS := GameManager.COLS
const ROWS := GameManager.ROWS
const SIZE := COLS * ROWS

var _data: PackedInt32Array

func _init():
    _data.resize(SIZE)
    _data.fill(JewelData.JewelType.EMPTY)

func get_cell(col: int, row: int) -> int:
    return _data[row * COLS + col]

func set_cell(col: int, row: int, value: int) -> void:
    _data[row * COLS + col] = value

func get_cellv(pos: Vector2i) -> int:
    return _data[pos.y * COLS + pos.x]

func set_cellv(pos: Vector2i, value: int) -> void:
    _data[pos.y * COLS + pos.x] = value

func duplicate() -> Grid:
    var copy := Grid.new()
    copy._data = _data.duplicate()
    return copy

func fill(value: int) -> void:
    _data.fill(value)
