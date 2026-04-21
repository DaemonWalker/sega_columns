extends RefCounted
class_name JewelData

enum JewelType {
    EMPTY = -1,
    RED,
    BLUE,
    GREEN,
    YELLOW,
    PURPLE,
    ORANGE,
    MAGIC
}

const COLORS := {
    JewelType.RED: Color(0.92, 0.25, 0.2),
    JewelType.BLUE: Color(0.2, 0.5, 0.92),
    JewelType.GREEN: Color(0.25, 0.78, 0.3),
    JewelType.YELLOW: Color(0.95, 0.85, 0.2),
    JewelType.PURPLE: Color(0.75, 0.25, 0.85),
    JewelType.ORANGE: Color(0.95, 0.55, 0.15),
    JewelType.MAGIC: Color(0.4, 0.9, 0.9)
}

const TEXTURES := {
    JewelType.RED: preload("res://assets/jewels/jewel_red.png"),
    JewelType.BLUE: preload("res://assets/jewels/jewel_blue.png"),
    JewelType.GREEN: preload("res://assets/jewels/jewel_green.png"),
    JewelType.YELLOW: preload("res://assets/jewels/jewel_yellow.png"),
    JewelType.PURPLE: preload("res://assets/jewels/jewel_purple.png"),
    JewelType.ORANGE: preload("res://assets/jewels/jewel_orange.png"),
    JewelType.MAGIC: preload("res://assets/jewels/jewel_magic.png")
}

const TILE_SOURCE_IDS := {
    JewelType.RED: 0,
    JewelType.BLUE: 1,
    JewelType.GREEN: 2,
    JewelType.YELLOW: 3,
    JewelType.PURPLE: 4,
    JewelType.ORANGE: 5,
    JewelType.MAGIC: 6
}

static var _types := [
    JewelType.RED, JewelType.BLUE, JewelType.GREEN,
    JewelType.YELLOW, JewelType.PURPLE, JewelType.ORANGE
]

static func random_type() -> int:
    return _types[randi() % _types.size()]

static func get_color(type: int) -> Color:
    return COLORS.get(type, Color.WHITE)

static func get_texture(type: int) -> Texture2D:
    return TEXTURES.get(type, null)
