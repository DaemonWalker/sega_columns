extends RefCounted
class_name BoardUtils

const COLS := GameManager.COLS
const ROWS := GameManager.ROWS
const CELL_SIZE := GameManager.CELL_SIZE


static func grid_to_local(col: int, row: int) -> Vector2:
    var offset_x := -(COLS * CELL_SIZE) / 2.0 + CELL_SIZE / 2.0
    var offset_y := -(ROWS * CELL_SIZE) / 2.0 + CELL_SIZE / 2.0
    return Vector2(offset_x + col * CELL_SIZE, offset_y + row * CELL_SIZE)


static func can_move_to(grid: Grid, col: int, row_top: int) -> bool:
    if col < 0 or col >= COLS:
        return false
    for i in range(3):
        var r := row_top + i
        if r >= ROWS:
            return false
        if r >= 0 and grid.get_cell(col, r) != JewelData.JewelType.EMPTY:
            return false
    return true
