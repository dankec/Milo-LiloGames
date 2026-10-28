extends Node2D
## Top-level state coordinator. Gameplay is on World; UI is on a separate canvas.

const World = preload("res://scripts/world.gd")
const SaveManager = preload("res://scripts/save_manager.gd")
const AudioManager = preload("res://scripts/audio_manager.gd")
const UserInterface = preload("res://scripts/ui.gd")
const LevelData = preload("res://scripts/level_data.gd")

var world
var ui
var sounds
var progress: Dictionary
var current_level := 0
var in_game := false

func _ready() -> void:
	_register_inputs()
	progress = SaveManager.load_save()
	sounds = AudioManager.new()
	add_child(sounds)
	sounds.configure(progress)
	sounds.play_theme("meadow")
	ui = UserInterface.new()
	add_child(ui)
	ui.game = self
	ui.show_menu(progress)

func _register_inputs() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE],
		"action": [KEY_J, KEY_ENTER],
		"switch_hero": [KEY_TAB, KEY_K],
		"pause_game": [KEY_ESCAPE]
	}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

func start_new() -> void:
	progress = SaveManager.fresh()
	SaveManager.save(progress)
	load_level(0)

func continue_game() -> void:
	load_level(int(progress["unlocked"]))

func load_level(level: int) -> void:
	get_tree().paused = false
	if is_instance_valid(world):
		world.queue_free()
		remove_child(world)
	current_level = clampi(level, 0, 4)
	world = World.new()
	world.setup(current_level, progress)
	world.hud_changed.connect(_message)
	world.math_requested.connect(_math_requested)
	world.level_finished.connect(_next_level)
	world.game_finished.connect(_victory)
	world.player_damaged.connect(_update_hearts)
	world.sound_requested.connect(func(name: String): sounds.play_effect(name))
	add_child(world)
	# Keep overlay above World regardless of child ordering.
	in_game = true
	sounds.configure(progress)
	sounds.play_theme(LevelData.THEMES[current_level])
	ui.show_game(current_level, progress)
	ui.update_hearts(3)

func _message(message: String) -> void:
	if is_instance_valid(ui): ui.show_status(message)

func _update_hearts(health: int) -> void:
	ui.update_hearts(health)

func _math_requested(question: String, answers: Array, correct: int) -> void:
	get_tree().paused = true
	ui.show_math(question, answers, correct)

func answer_math(success: bool) -> void:
	get_tree().paused = false
	ui.hide_math()
	if success and is_instance_valid(world): world.math_correct()

func _next_level() -> void:
	if current_level < 4:
		if not progress["completed"].has(current_level): progress["completed"].append(current_level)
		progress["unlocked"] = maxi(int(progress["unlocked"]), current_level + 1)
		SaveManager.save(progress)
		load_level(current_level + 1)

func _victory() -> void:
	if not progress["completed"].has(4): progress["completed"].append(4)
	SaveManager.save(progress)
	get_tree().paused = true
	ui.show_victory(progress)

func toggle_pause() -> void:
	if not in_game: return
	# A visible pause dialog is itself modal. It must be dismissible, while
	# the mathematics and victory dialogs remain protected from Escape.
	if get_tree().paused:
		if not ui.pause_overlay.visible:
			return
		get_tree().paused = false
		ui.hide_pause()
	elif not ui.modal_visible:
		get_tree().paused = true
		ui.show_pause()

func return_to_menu() -> void:
	get_tree().paused = false
	in_game = false
	if is_instance_valid(world):
		world.queue_free()
		remove_child(world)
	ui.show_menu(progress)
	sounds.play_theme("meadow")

func restart_level() -> void:
	load_level(current_level)

func set_language(value: String) -> void:
	progress["language"] = value
	SaveManager.save(progress)
	sounds.configure(progress)
	if not sounds.music_player.playing and progress.get("music",true): sounds.music_player.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and in_game:
		toggle_pause()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and in_game:
		toggle_pause()
