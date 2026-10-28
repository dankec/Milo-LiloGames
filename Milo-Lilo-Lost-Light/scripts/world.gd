extends Node2D
## A hand-authored offline level; collisions use Godot physics, art is drawn in canvas.

signal sound_requested(name: String)
signal hud_changed(message: String)
signal math_requested(question: String, answers: Array, correct: int)
signal level_finished
signal game_finished
signal player_damaged(health: int)

const SaveManager = preload("res://scripts/save_manager.gd")
const Avatar = preload("res://scripts/avatar.gd")
const LevelData = preload("res://scripts/level_data.gd")

var stage := 0
var data: Dictionary
var save_data: Dictionary
var heroes: Array = []
var selected := 0
var cam: Camera2D
var items: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var gate_open := false
var gate_collision: StaticBody2D
var local_key := false
var berry_active := false
var berry_done := false
var berry_clock := 0.0
var berry_count := 0
var berry_retry := 0.0
var boss_hp := 5
var boss_x := 2140.0
var chest_open := false
var flash_text := ""
var flash_time := 0.0
var _clock := 0.0
var _message := ""
var audio: AudioStreamPlayer
var checkpoint_x := 145.0
var checkpoint_activated := false
var attack_cooldown := 0.0

func setup(which: int, progress: Dictionary) -> void:
	stage = clampi(which, 0, 4)
	save_data = progress
	data = LevelData.get_level(stage)

func _ready() -> void:
	var bg: String = data["theme"]
	var back := Sprite2D.new()
	back.texture = load("res://assets/environments/%s.jpg" % bg)
	back.position = Vector2(800, 450)
	back.z_index = -15
	add_child(back)
	var back2 := Sprite2D.new()
	back2.texture = back.texture
	back2.position = Vector2(2400, 450)
	back2.z_index = -15
	add_child(back2)
	_make_platform(0.0, 650.0, float(data["width"]), 140.0)
	for p in data["platforms"]:
		_make_platform(float(p.x), float(p.y), float(p.w), float(p.h))
	for i in data["coins"].size():
		_add_item("coin", data["coins"][i], "coin_%d" % i)
	if stage == 1:
		_add_item("key", data["key"], "key")
	if stage >= 1 and stage <= 3:
		_add_item("map", data["map"], "map_%d" % stage)
		_add_item("crystal", data["crystal"], "crystal_%d" % stage)
	for g in data["gifts"]:
		_add_item("gift", Vector2(g.x, g.y), str(g.ability))
	if stage == 3:
		for i in data["berries"].size():
			_add_item("berry", data["berries"][i], "berry_%d" % i)
	for e in data["enemies"]:
		enemies.append({"x":float(e.x), "base":float(e.x), "y":float(e.y), "hp":int(e.hp), "dir":1.0, "stun":0.0})
	if stage == 4:
		boss_hp = 6
	chest_open = save_data.get("treasure", []).has(stage)
	checkpoint_x = clampf(float(save_data.get("checkpoints", {}).get(str(stage), 145.0)), 145.0, 1430.0)
	checkpoint_activated = checkpoint_x > 145.0
	_make_gate()
	for i in 2:
		var hero = Avatar.new()
		hero.configure("milo" if i == 0 else "lilo", i == 0)
		hero.position = Vector2(checkpoint_x + 82 * i, 584)
		if hero.hero_id == "milo" and save_data["abilities"].has("double_jump"):
			hero.double_jump = true
		if save_data["abilities"].has("shield"):
			hero.shield_charges = 1
		hero.hurt.connect(_on_hurt)
		hero.fell.connect(_on_fell.bind(hero))
		hero.shielded.connect(func(): flash("Čarobni štit je zaustavio udarac!"))
		add_child(hero)
		heroes.append(hero)
	heroes[0].partner = heroes[1]
	heroes[1].partner = heroes[0]
	cam = Camera2D.new()
	cam.position = heroes[0].position
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 5.0
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(data["width"])
	cam.limit_bottom = 720
	add_child(cam)
	cam.make_current()
	hud_changed.emit(data["goal"])

func _make_platform(x: float, y: float, w: float, h: float) -> void:
	var body := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	col.shape = rect
	body.position = Vector2(x + w / 2.0, y + h / 2.0)
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_child(col)
	add_child(body)

func _make_gate() -> void:
	gate_collision = StaticBody2D.new()
	gate_collision.position = Vector2(float(data["gate_x"]), 560)
	gate_collision.collision_layer = 1
	var shape := RectangleShape2D.new()
	shape.size = Vector2(42, 180)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	gate_collision.add_child(collision)
	add_child(gate_collision)

func _add_item(kind: String, at: Vector2, identity: String) -> void:
	var already := false
	if kind == "coin":
		already = save_data.get("collected", []).has("%d:%s" % [stage, identity])
	if kind == "map":
		already = save_data["maps"].has(identity)
	if kind == "crystal":
		already = save_data["crystals"].has(identity)
	if kind == "gift":
		already = save_data["abilities"].has(identity)
	if kind == "berry":
		already = true
	items.append({"kind":kind, "pos":at, "id":identity, "taken":already})

func active_player():
	return heroes[selected]

func _process(delta: float) -> void:
	_clock += delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	flash_time = maxf(0.0, flash_time - delta)
	var player = active_player()
	if not is_instance_valid(player):
		return
	cam.global_position = Vector2(clampf(player.global_position.x, 640, float(data["width"]) - 640), 360)
	if not checkpoint_activated and player.position.x >= 1190.0:
		checkpoint_activated = true
		checkpoint_x = 1260.0
		save_data["checkpoints"][str(stage)] = checkpoint_x
		SaveManager.save(save_data)
		flash("Kontrolna točka! Ovdje nastavljaš nakon pada.")
	if Input.is_action_just_pressed("switch_hero"):
		switch_hero()
	if Input.is_action_just_pressed("action"):
		interact()
	for item in items:
		if item.taken:
			continue
		if item.kind == "berry" and not berry_active:
			continue
		var pickup_radius := 175.0 if item.kind == "coin" and save_data["abilities"].has("magnet") else 49.0
		if player.position.distance_to(item.pos) < pickup_radius:
			_pickup(item)
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		enemy.stun = maxf(0.0, float(enemy.stun) - delta)
		if enemy.stun > 0.0:
			continue
		var dx: float = player.position.x - float(enemy.x)
		var direction: float = signf(dx) if absf(dx) < 230 else float(enemy.dir)
		enemy.x += direction * (77.0 + stage * 12.0) * delta
		if absf(float(enemy.x) - float(enemy.base)) > 112:
			enemy.dir = -float(enemy.dir)
			enemy.x = clampf(float(enemy.x), float(enemy.base) - 112.0, float(enemy.base) + 112.0)
		if absf(dx) < 51 and absf(player.position.y - float(enemy.y)) < 60:
			player.take_hit()
	if stage == 3 and not berry_done:
		if not berry_active and player.position.x > 1310 and berry_retry <= 0:
			_start_berries()
		if berry_active:
			berry_clock -= delta
			if berry_clock <= 0:
				berry_active = false
				berry_retry = 7.0
				berry_count = 0
				for item in items:
					if item.kind == "berry": item.taken = true
				flash("Vrijeme je isteklo! Pokušaj ponovno.")
		elif berry_retry > 0:
			berry_retry = maxf(0.0, berry_retry - delta)
	if stage == 4 and boss_hp > 0 and player.position.x > 1970:
		boss_x += sin(_clock * 3.0) * 48.0 * delta
		if absf(player.position.x - boss_x) < 77 and absf(player.position.y - 571) < 70:
			player.take_hit()
	if player.position.x > float(data["exit_x"]):
		if stage == 4:
			if boss_hp <= 0 and save_data["crystals"].size() >= 3:
				game_finished.emit()
			else:
				flash("Nedostaju kristali ili čuvar još spava!")
				player.position.x = float(data["exit_x"]) - 85
		else:
			if stage == 0 or save_data["crystals"].has("crystal_%d" % stage):
				level_finished.emit()
			else:
				flash("Najprije pronađi kristal svjetlosti!")
				player.position.x = float(data["exit_x"]) - 90
	queue_redraw()

func _start_berries() -> void:
	berry_active = true
	berry_clock = 27.0
	berry_count = 0
	for item in items:
		if item.kind == "berry": item.taken = false
	flash("Bobice! Skupi svih 6 prije isteka vremena!")

func _pickup(item: Dictionary) -> void:
	item.taken = true
	match item.kind:
		"coin":
			sound_requested.emit("coin")
			var coin_key := "%d:%s" % [stage, str(item.id)]
			if not save_data["collected"].has(coin_key):
				save_data["collected"].append(coin_key)
				save_data["coins"] += 1
			if int(save_data["coins"]) % 5 == 0: flash("Bravo! %d novčića" % save_data["coins"])
		"key":
			sound_requested.emit("chest")
			local_key = true
			flash("Pronašao si zlatni ključ!")
		"map":
			if not save_data["maps"].has(item.id): save_data["maps"].append(item.id)
			if save_data["maps"].size() >= 3:
				flash("Karta je cijela! Blago je kod završnog svjetionika!")
			else:
				flash("Otkriven novi dio tajne karte!")
		"crystal":
			sound_requested.emit("win")
			if not save_data["crystals"].has(item.id): save_data["crystals"].append(item.id)
			flash("Kristal svjetlosti pronađen! ✨")
		"gift":
			if not save_data["abilities"].has(item.id): save_data["abilities"].append(item.id)
			if item.id == "double_jump": heroes[0].double_jump = true
			if item.id == "shield":
				for hero in heroes: hero.shield_charges = 1
			if item.id == "magnet":
				flash("Magnet privlači novčiće iz daljine!")
			else:
				flash("Nova sposobnost: %s!" % item.id.replace("_", " "))
		"berry":
			berry_count += 1
			if berry_count >= 6:
				berry_done = true
				berry_active = false
				flash("Sjajno! Sve bobice su prikupljene!")
				_try_unlock_gate()
	SaveManager.save(save_data)
	hud_changed.emit(data["goal"])

func switch_hero() -> void:
	sound_requested.emit("switch")
	selected = 1 - selected
	for i in heroes.size(): heroes[i].active = i == selected
	flash("Sada igra %s!" % ("Milo" if selected == 0 else "Lilo"))

func interact() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.32
	var p = active_player()
	var enemy_hit := false
	p.attack()
	sound_requested.emit("hit")
	if stage == 4 and absf(p.position.x - boss_x) < 125 and boss_hp > 0:
		boss_hp -= 2 if p.hero_id == "lilo" else 1
		flash("Čuvar svjetionika: %d energije" % maxi(0, boss_hp))
		enemy_hit = true
		if boss_hp <= 0: flash("Čuvar je postao prijatelj! Svjetionik je slobodan!")
	for enemy in enemies:
		if enemy.hp > 0 and absf(float(enemy.x) - p.position.x) < 104 and absf(float(enemy.y) - p.position.y) < 98:
			enemy.hp -= 1
			enemy.stun = 0.7
			enemy_hit = true
			if enemy.hp <= 0: save_data["coins"] += 2
	if enemy_hit:
		SaveManager.save(save_data)
		return
	if absf(p.position.x - float(data["chest"].x)) < 110 and not chest_open:
		if stage == 4 and save_data["maps"].size() < 3:
			flash("Za tajno blago pronađi sva tri dijela karte!")
			return
		chest_open = true
		if not save_data["treasure"].has(stage): save_data["treasure"].append(stage)
		sound_requested.emit("chest")
		var reward := 30 if stage == 4 else 10
		save_data["coins"] += reward
		flash("Tajno blago pronađeno! +30 novčića!" if stage == 4 else "Škrinja! +10 novčića!")
		SaveManager.save(save_data)
		hud_changed.emit(data["goal"])
		return

	if absf(p.position.x - float(data["gate_x"])) < 135 and not gate_open:
		_try_unlock_gate()

func _try_unlock_gate() -> void:
	match stage:
		0:
			math_requested.emit("Koliko je 4 + 3?", [5, 7, 9], 7)
		1:
			if local_key:
				math_requested.emit("Koliko je 9 − 4?", [6, 4, 5], 5)
			else: flash("Potraži zlatni ključ lijevo od vrata!")
		2:
			if active_player().hero_id == "lilo": _open_gate()
			else: flash("Za teška vrata potreban je Lilo!")
		3:
			if berry_done: _open_gate()
			else: flash("Prvo sakupi šest mjesečevih bobica!")
		4:
			if save_data["crystals"].size() >= 3: _open_gate()
			else: flash("Za prolaz su potrebna tri kristala!")

func math_correct() -> void:
	_open_gate()
	flash("Točno! Čarobna vrata su otvorena!")

func _open_gate() -> void:
	if gate_open: return
	gate_open = true
	if is_instance_valid(gate_collision): gate_collision.queue_free()
	flash("Prolaz je otvoren!")

func flash(message: String) -> void:
	flash_text = message
	flash_time = 3.6
	hud_changed.emit(message)

func _respawn(p) -> void:
	p.position = Vector2(checkpoint_x, 560)
	p.velocity = Vector2.ZERO
	p.health = 3
	p.invulnerable = 2.0
	flash("Pokušaj ponovno od kontrolne točke! ♥♥♥")
	player_damaged.emit(3)

func _on_fell(p) -> void:
	_respawn(p)

func _on_hurt() -> void:
	var p = active_player()
	if p.health <= 0:
		_respawn(p)
	sound_requested.emit("hurt")
	player_damaged.emit(p.health)

func _draw() -> void:
	if data.is_empty(): return
	var level_w: float = float(data["width"])
	# Soft decorated ground and raised platforms.
	draw_rect(Rect2(0, 650, level_w, 90), Color("3f7156") if stage != 2 else Color("455471"))
	draw_rect(Rect2(0, 650, level_w, 16), Color("8fca72") if stage != 2 else Color("8f9dc6"))
	for x in range(0, int(level_w), 54):
		var y: float = 679 + sin(float(x) / 60.0) * 10
		draw_circle(Vector2(x + 12, y), 3.0, Color("7ebf78") if stage != 2 else Color("6676a6"))
	for p in data["platforms"]:
		var rect := Rect2(float(p.x), float(p.y), float(p.w), float(p.h))
		draw_rect(rect, Color("607d63") if stage != 2 else Color("687595"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 9)), Color("b4d789") if stage != 2 else Color("a2b0d7"))
		for k in range(int(rect.size.x / 28)):
			draw_circle(rect.position + Vector2(14 + k * 28, 20), 5, Color(1, 1, 1, 0.10))
	# Sparkles and flowers.
	for x in range(105, int(level_w), 155):
		var shift := sin(float(x) * 0.07 + _clock) * 3.0
		if stage == 2 or stage == 3:
			draw_circle(Vector2(x, 630 + shift), 4.5, Color(0.52, 0.91, 1.0, 0.7))
		else:
			draw_line(Vector2(x, 653), Vector2(x, 630 + shift), Color("39785c"), 3)
			draw_circle(Vector2(x, 628 + shift), 7, Color("f8df83") if x % 2 == 0 else Color("ff9dad"))
	# Gate with visible glowing lock.
	if not gate_open:
		var gx: float = float(data["gate_x"])
		draw_rect(Rect2(gx - 24, 469, 48, 181), Color("26364d"))
		draw_rect(Rect2(gx - 17, 478, 34, 167), Color("796caf"))
		draw_circle(Vector2(gx, 538), 16 + sin(_clock * 3.0) * 2, Color("f6de9b"))
		draw_string(ThemeDB.fallback_font, Vector2(gx - 24, 443), "✦", HORIZONTAL_ALIGNMENT_CENTER, 48, 39, Color("fff1bb"))
	# End portal.
	var ex: float = float(data["exit_x"]) + 35.0
	draw_arc(Vector2(ex, 553), 55, PI, TAU, 32, Color("ffedaf"), 11, true)
	draw_circle(Vector2(ex, 576), 25 + 2 * sin(_clock * 4), Color(0.5, 0.95, 0.94, 0.65))
	for item in items:
		if item.taken: continue
		var p: Vector2 = item.pos + Vector2(0, sin(_clock * 3.5 + float(item.pos.x) * 0.01) * 6.0)
		match item.kind:
			"coin":
				draw_circle(p, 14, Color("dd9d38"));draw_circle(p, 11, Color("ffdf66"));draw_circle(p + Vector2(-4,-4), 3, Color("fff9c6"))
			"key":
				draw_circle(p, 13, Color("ffdb70"));draw_circle(p, 7, Color("917146"));draw_line(p + Vector2(9,9),p + Vector2(29,29),Color("ffdb70"),8)
			"map":
				draw_rect(Rect2(p - Vector2(21,17),Vector2(42,34)), Color("f8dda4"));draw_line(p - Vector2(14,11),p + Vector2(13,8), Color("b98057"),4)
			"crystal":
				var points := PackedVector2Array([p + Vector2(0,-31),p + Vector2(23,-5),p + Vector2(0,29),p + Vector2(-23,-5)])
				draw_colored_polygon(points, Color("76edff"));draw_line(p + Vector2(0,-31),p + Vector2(0,29),Color.WHITE,3)
			"gift":
				draw_rect(Rect2(p - Vector2(21,22),Vector2(42,44)), Color("ff959b"));draw_rect(Rect2(p.x-5,p.y-22,10,44),Color("ffe89b"))
			"berry":
				draw_circle(p, 13,Color("b874e4"));draw_circle(p+Vector2(-4,-5),4,Color("ead3ff"));draw_line(p+Vector2(0,-12),p+Vector2(7,-20),Color("5ebc73"),3)
	for enemy in enemies:
		if int(enemy.hp) <= 0: continue
		var p := Vector2(float(enemy.x),float(enemy.y) + sin(_clock * 6.0) * 4.0)
		draw_circle(p, 29, Color("a47bcc") if stage != 3 else Color("60659a"))
		draw_circle(p + Vector2(-10,-5), 5, Color.WHITE)
		draw_circle(p + Vector2(10,-5), 5, Color.WHITE)
		draw_circle(p + Vector2(-10,-5), 2.4, Color("32364b"))
		draw_circle(p + Vector2(10,-5), 2.4, Color("32364b"))
		draw_arc(p + Vector2(0,3), 11, 0.1, PI-0.1, 15, Color("563a6a"), 3)
	if stage == 4 and boss_hp > 0:
		var bp := Vector2(boss_x, 555 + 6 * sin(_clock*2))
		draw_circle(bp, 65, Color("514c91"))
		draw_circle(bp + Vector2(-23,-6),10,Color("f5f1ca"))
		draw_circle(bp + Vector2(23,-6),10,Color("f5f1ca"))
		draw_arc(bp + Vector2(0,15), 24,0.0,PI,20,Color("f5d3a3"),5)
		draw_rect(Rect2(bp + Vector2(-56,-85),Vector2(112 * float(boss_hp)/6.0,8)),Color("f7b871"))
	var chest: Vector2 = data["chest"]
	draw_rect(Rect2(chest - Vector2(34,30),Vector2(68,33)),Color("8c5a42"))
	draw_rect(Rect2(chest - Vector2(34,30),Vector2(68,10)),Color("f4c56c"))
	draw_rect(Rect2(chest - Vector2(6,25),Vector2(12,27)),Color("fbe5a1"))
	if chest_open: draw_arc(chest - Vector2(0,31),34,PI,TAU,12,Color("f7e5c1"),5)
