extends CanvasLayer
## Accessible large touch controls, pause menu and non-punitive maths dialog.

const LevelData = preload("res://scripts/level_data.gd")
const FloatingJoystickScript = preload("res://scripts/virtual_joystick.gd")

var game
var menu: Control
var hud: Control
var pause_overlay: ColorRect
var math_overlay: ColorRect
var status: Label
var counters: Label
var hearts: Label
var current_hero: Label
var joystick: Node2D
var modal_visible := false
var _touch_controls: Array = []
var _progress: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build_menu()
	_build_hud()
	_build_pause()
	_build_math()
	menu.visible = true
	hud.visible = false
	pause_overlay.visible = false
	math_overlay.visible = false

func _panel_style(color: Color = Color("194866"), border: Color = Color("86dbc9")) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(22)
	s.border_color = border
	s.set_border_width_all(3)
	s.shadow_color = Color(0.02,0.12,0.2,0.35)
	s.shadow_size = 7
	return s

func _make_button(text: String, width: float = 300.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 58)
	b.add_theme_font_size_override("font_size", 23)
	b.add_theme_color_override("font_color", Color("f8faed"))
	b.add_theme_stylebox_override("normal",_panel_style(Color("28647d"),Color("88d3c1")))
	b.add_theme_stylebox_override("hover",_panel_style(Color("348c94"),Color("d5f1b5")))
	b.add_theme_stylebox_override("pressed",_panel_style(Color("173e59"),Color("f6d28f")))
	return b

func _screen() -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(c)
	return c

func _background(target: Control) -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/environments/meadow.jpg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	target.add_child(bg)
	var veil := ColorRect.new()
	veil.color = Color(0.02,0.12,0.2,0.42)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	target.add_child(veil)

func _build_menu() -> void:
	menu = _screen()
	_background(menu)
	var card := PanelContainer.new()
	card.position = Vector2(389, 45)
	card.size = Vector2(502, 626)
	card.add_theme_stylebox_override("panel",_panel_style(Color(0.06,0.21,0.32,0.93)))
	menu.add_child(card)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 13)
	card.add_child(stack)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/ui/icon.png")
	logo.custom_minimum_size = Vector2(154,154)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stack.add_child(logo)
	var title := Label.new()
	title.text = "MILO & LILO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",47)
	title.add_theme_color_override("font_color",Color("ffe6a5"))
	stack.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "TAJNA IZGUBLJENOG SVJETLA"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size",17)
	stack.add_child(subtitle)
	for config in [["▶ Nova pustolovina","new"],["↻ Nastavi","continue"],["☷ Odabir razine","levels"],["⚙ Postavke","settings"]]:
		var b := _make_button(config[0])
		stack.add_child(b)
		match config[1]:
			"new": b.pressed.connect(_confirm_new_game)
			"continue": b.pressed.connect(func(): game.continue_game())
			"levels": b.pressed.connect(_show_level_selection)
			"settings": b.pressed.connect(_show_settings)
	var foot := Label.new()
	foot.text = "Bez oglasa • Bez interneta • Za male istraživače"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size",14)
	stack.add_child(foot)

func _build_hud() -> void:
	hud = _screen()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := ColorRect.new()
	top.color = Color(0.035,0.13,0.20,0.77)
	top.position = Vector2.ZERO
	top.size = Vector2(1280,91)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	status = Label.new()
	status.position = Vector2(28,12)
	status.size = Vector2(930,35)
	status.add_theme_font_size_override("font_size",23)
	status.add_theme_color_override("font_color",Color("fff0bc"))
	hud.add_child(status)
	counters = Label.new()
	counters.position = Vector2(30,54)
	counters.add_theme_font_size_override("font_size",18)
	hud.add_child(counters)
	hearts = Label.new()
	hearts.position = Vector2(980,22)
	hearts.add_theme_font_size_override("font_size",29)
	hearts.add_theme_color_override("font_color",Color("ffa8ba"))
	hud.add_child(hearts)
	current_hero = Label.new()
	current_hero.position = Vector2(959, 61)
	current_hero.add_theme_font_size_override("font_size", 17)
	current_hero.add_theme_color_override("font_color", Color("fff0bc"))
	current_hero.text = "MILO"
	hud.add_child(current_hero)
	var pause := _make_button("Ⅱ",58)
	pause.position = Vector2(1196,19)
	pause.custom_minimum_size = Vector2(55,55)
	pause.mouse_filter = Control.MOUSE_FILTER_STOP
	pause.pressed.connect(func(): game.toggle_pause())
	hud.add_child(pause)
	# Three fixed buttons + one floating, gesture-driven left joystick.
	for info in [
		["switch", "switch_hero", Vector2(887, 617)],
		["action", "action", Vector2(1009, 615)],
		["jump", "jump", Vector2(1146, 573)]]:
		var b := TouchScreenButton.new()
		b.texture_normal = load("res://assets/ui/%s.png" % info[0])
		b.action = info[1]
		b.position = info[2] - Vector2(43, 43)
		b.scale = Vector2(0.64, 0.64)
		b.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
		var circle := CircleShape2D.new()
		circle.radius = 86.0
		b.shape = circle
		add_child(b)
		_touch_controls.append(b)
		b.visible = false
	joystick = FloatingJoystickScript.new()
	add_child(joystick)
	joystick.set_enabled(false)

func _build_pause() -> void:
	pause_overlay = _modal_backdrop()
	var box := _modal_card(pause_overlay,Vector2(400,160),Vector2(480,410))
	_add_heading(box,"PAUZA")
	for info in [["▶ Nastavi",0],["↺ Ponovi razinu",1],["⌂ Glavni izbornik",2]]:
		var b := _make_button(info[0],360)
		box.add_child(b)
		match info[1]:
			0: b.pressed.connect(func():game.toggle_pause())
			1: b.pressed.connect(func():hide_pause();game.restart_level())
			2: b.pressed.connect(func():hide_pause();game.return_to_menu())

func _build_math() -> void:
	math_overlay = _modal_backdrop()

func _modal_backdrop() -> ColorRect:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02,0.08,0.16,0.83)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	return backdrop

func _modal_card(backdrop: Control,at: Vector2,size: Vector2) -> VBoxContainer:
	var pane := PanelContainer.new()
	pane.position = at
	pane.size = size
	pane.add_theme_stylebox_override("panel",_panel_style(Color("184a67")))
	backdrop.add_child(pane)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation",19)
	pane.add_child(box)
	return box

func _add_heading(box: VBoxContainer,title: String) -> void:
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size",36)
	heading.add_theme_color_override("font_color",Color("ffe6aa"))
	box.add_child(heading)

func show_menu(data: Dictionary) -> void:
	_progress = data
	menu.visible = true
	hud.visible = false
	pause_overlay.visible = false
	math_overlay.visible = false
	modal_visible = false
	for b in _touch_controls: b.visible = false
	joystick.set_enabled(false)

func show_game(stage: int,data: Dictionary) -> void:
	_progress = data
	menu.visible = false
	hud.visible = true
	pause_overlay.visible = false
	math_overlay.visible = false
	modal_visible = false
	for b in _touch_controls: b.visible = true
	joystick.set_enabled(true)
	show_status(LevelData.GOALS[stage])

func show_status(message: String) -> void:
	if status == null: return
	status.text = message
	counters.text = "✦ %d novčića    ◆ %d / 3 kristala    ▤ %d / 3 karte" % [int(_progress.get("coins",0)), _progress.get("crystals",[]).size(),_progress.get("maps",[]).size()]

func update_hero_name(name: String) -> void:
	current_hero.text = "IGRA: " + name.to_upper()

func update_hearts(hp: int) -> void:
	hearts.text = "♥".repeat(maxi(0,hp)) + "♡".repeat(maxi(0,3-hp))

func show_pause() -> void:
	pause_overlay.visible = true
	modal_visible = true
	for b in _touch_controls: b.visible = false
	joystick.set_enabled(false)

func hide_pause() -> void:
	pause_overlay.visible = false
	modal_visible = false
	for b in _touch_controls: b.visible = true
	joystick.set_enabled(true)

func show_math(question: String,answers: Array,correct: int) -> void:
	for n in math_overlay.get_children(): n.queue_free()
	math_overlay.visible = true
	modal_visible = true
	for b in _touch_controls: b.visible = false
	joystick.set_enabled(false)
	var box := _modal_card(math_overlay,Vector2(310,135),Vector2(660,430))
	_add_heading(box,"Čarobna zagonetka ✨")
	_add_heading(box,question)
	var answer_row := HBoxContainer.new()
	answer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	answer_row.add_theme_constant_override("separation",20)
	box.add_child(answer_row)
	var hint := Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size",22)
	for val in answers:
		var b := _make_button(str(val),118)
		answer_row.add_child(b)
		b.pressed.connect(func():
			if val == correct:
				game.answer_math(true)
			else:
				hint.text = "Pokušaj ponovno. Izbroji polako! 💛"
		)
	box.add_child(hint)

func hide_math() -> void:
	math_overlay.visible = false
	modal_visible = false
	for b in _touch_controls: b.visible = true
	joystick.set_enabled(true)

func show_victory(data: Dictionary) -> void:
	for n in math_overlay.get_children(): n.queue_free()
	math_overlay.visible = true
	modal_visible = true
	for b in _touch_controls: b.visible = false
	joystick.set_enabled(false)
	var box := _modal_card(math_overlay,Vector2(275,145),Vector2(730,450))
	_add_heading(box,"☀ SVJETLO SE VRATILO! ☀")
	_add_heading(box,"Milo i Lilo spasili su otok!")
	var lbl := Label.new()
	lbl.text = "Pronađeno %d kristala i %d novčića.\nMožeš ponovno istražiti skrivene staze!" % [data["crystals"].size(), data["coins"]]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size",21)
	box.add_child(lbl)
	var b := _make_button("⌂ Glavni izbornik",370)
	box.add_child(b)
	b.pressed.connect(func():math_overlay.visible=false;game.return_to_menu())

func _show_level_selection() -> void:
	var bg := _modal_backdrop()
	var box := _modal_card(bg,Vector2(345,44),Vector2(590,630))
	_add_heading(box,"Odaberi otok")
	for i in LevelData.TITLES.size():
		var unlocked: bool = i <= int(_progress["unlocked"])
		var b := _make_button(("✓ " if _progress["completed"].has(i) else "★ ")+ LevelData.TITLES[i] if unlocked else "🔒 " + LevelData.TITLES[i],430)
		b.disabled = not unlocked
		box.add_child(b)
		b.pressed.connect(func():bg.queue_free();game.load_level(i))
	var back := _make_button("Natrag",280)
	box.add_child(back)
	back.pressed.connect(func():bg.queue_free())

func _show_settings() -> void:
	var bg := _modal_backdrop()
	var box := _modal_card(bg,Vector2(395,145),Vector2(490,440))
	_add_heading(box,"Postavke")
	var note := Label.new()
	note.text = "Igra je potpuno offline.\nUpravljanje: pomični joystick, povuci gore za skok.\nDesno: skok, akcija i promjena lika."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)
	for kind in ["music","sfx"]:
		var setting_name := "Glazba" if kind == "music" else "Efekti"
		var b := _make_button(setting_name + (": uključeno" if _progress[kind] else ": isključeno"),360)
		box.add_child(b)
		b.pressed.connect(func():
			_progress[kind] = not _progress[kind]
			b.text = setting_name + (": uključeno" if _progress[kind] else ": isključeno")
			game.set_language(str(_progress["language"]))
		)
	var back := _make_button("Natrag",280)
	box.add_child(back)
	back.pressed.connect(func():bg.queue_free())

func _confirm_new_game() -> void:
	if int(_progress.get("coins", 0)) == 0 and _progress.get("completed", []).is_empty():
		game.start_new()
		return
	var bg := _modal_backdrop()
	var box := _modal_card(bg, Vector2(370, 173), Vector2(540, 370))
	_add_heading(box, "Nova pustolovina?")
	var note := Label.new()
	note.text = "Prethodni napredak bit će izbrisan."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)
	var yes := _make_button("Da, kreni ispočetka", 350)
	box.add_child(yes)
	yes.pressed.connect(func(): bg.queue_free(); game.start_new())
	var no := _make_button("Ne, sačuvaj napredak", 350)
	box.add_child(no)
	no.pressed.connect(func(): bg.queue_free())
