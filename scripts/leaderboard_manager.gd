extends Node

const SAVE_PATH := "user://leaderboard.json"
const MAX_ENTRIES := 10

var _score_entries: Array[Dictionary] = []
var _cleared_entries: Array[Dictionary] = []

func _ready() -> void:
    load_data()

func add_score_entry(score: int) -> void:
    var entry := {
        "value": score,
        "timestamp": Time.get_datetime_string_from_system(false)
    }
    _score_entries.append(entry)
    _score_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return b["value"] < a["value"]
    )
    if _score_entries.size() > MAX_ENTRIES:
        _score_entries.resize(MAX_ENTRIES)
    save_data()

func add_cleared_entry(count: int) -> void:
    var entry := {
        "value": count,
        "timestamp": Time.get_datetime_string_from_system(false)
    }
    _cleared_entries.append(entry)
    _cleared_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return b["value"] < a["value"]
    )
    if _cleared_entries.size() > MAX_ENTRIES:
        _cleared_entries.resize(MAX_ENTRIES)
    save_data()

func get_score_entries() -> Array[Dictionary]:
    return _score_entries.duplicate()

func get_cleared_entries() -> Array[Dictionary]:
    return _cleared_entries.duplicate()

func save_data() -> void:
    var dict := {
        "score_entries": _score_entries,
        "cleared_entries": _cleared_entries
    }
    var json := JSON.stringify(dict)
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(json)
        file.close()

func load_data() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var text := file.get_as_text()
    file.close()
    if text.strip_edges().is_empty():
        return
    var parsed = JSON.parse_string(text)
    if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
        return
    var se = parsed.get("score_entries", [])
    var ce = parsed.get("cleared_entries", [])
    if typeof(se) == TYPE_ARRAY:
        _score_entries.assign(se)
    if typeof(ce) == TYPE_ARRAY:
        _cleared_entries.assign(ce)
