extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var settings: Dictionary = {}
var current_theme := ""

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -13.0
	add_child(music_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -7.0
	add_child(sfx_player)
	music_player.finished.connect(func():
		if settings.get("music",true) and music_player.stream != null:
			music_player.play()
	)

func configure(progress: Dictionary) -> void:
	settings = progress
	music_player.stream_paused = not settings.get("music",true)

func play_theme(theme: String) -> void:
	if theme == current_theme: return
	current_theme = theme
	var path := "res://assets/audio/%s.ogg" % theme
	music_player.stop()
	music_player.stream = load(path)
	if settings.get("music",true): music_player.play()

func play_effect(effect: String) -> void:
	if not settings.get("sfx",true): return
	var path := "res://assets/audio/sfx_%s.wav" % effect
	sfx_player.stream = load(path)
	sfx_player.play()
