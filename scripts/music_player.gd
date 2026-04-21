extends AudioStreamPlayer

func _ready() -> void:
    var stream = load("res://assets/music/bgm.mp3")
    if stream is AudioStreamMP3:
        stream.loop = true
    self.stream = stream
    bus = "Master"
    play()

func _exit_tree() -> void:
    playing = false
    stop()
    stream = null

