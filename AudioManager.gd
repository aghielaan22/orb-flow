extends Node

var bgm_player: AudioStreamPlayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	
	var music_stream = load("res://cyberpunk_music.mp3")
	if not music_stream:
		music_stream = load("res://cyberpunk_music.ogg")
		
	if music_stream:
		bgm_player.stream = music_stream
		bgm_player.finished.connect(func(): bgm_player.play()) # Infinite loop
		bgm_player.play()
		print("[AudioManager] Global BGM initialized and looping.")
