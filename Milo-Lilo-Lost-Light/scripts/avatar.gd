extends CharacterBody2D
## Physically simulated, switchable playable hero with a companion AI.

signal hurt
signal fell
signal shielded

var hero_id := "milo"
var active := false
var partner
var double_jump := false
var invulnerable := 0.0
var speed := 300.0
var jump_power := -525.0
var health := 3
var shield_charges := 0
var _coyote := 0.0
var _jump_buffer := 0.0
var _air_jumps := 0
var _anim_time := 0.0
var _facing := 1
var _attack_anim := 0.0
var _frames: Dictionary = {}
var sprite: Sprite2D

func configure(which: String, is_active: bool) -> void:
	hero_id = which
	active = is_active
	speed = 355.0 if which == "milo" else 270.0
	jump_power = -560.0 if which == "milo" else -480.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CapsuleShape2D.new()
	shape.radius = 25.0
	shape.height = 83.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	sprite = Sprite2D.new()
	sprite.scale = Vector2(0.60, 0.60)
	sprite.position = Vector2(0, -10)
	add_child(sprite)
	for state in ["idle", "run1", "run2", "jump", "fall", "attack", "hurt", "celebrate"]:
		_frames[state] = load("res://assets/characters/%s_%s.png" % [hero_id, state])
	_refresh_sprite("idle")

func _physics_process(delta: float) -> void:
	_anim_time += delta
	invulnerable = maxf(0.0, invulnerable - delta)
	_attack_anim = maxf(0.0, _attack_anim - delta)
	if is_on_floor():
		_coyote = 0.12
		_air_jumps = 0
	else:
		_coyote = maxf(0.0, _coyote - delta)
	velocity.y += 1120.0 * delta
	var direction := 0.0
	if active:
		direction = Input.get_axis("move_left", "move_right")
		if Input.is_action_just_pressed("jump"):
			_jump_buffer = 0.15
		_jump_buffer = maxf(0.0, _jump_buffer - delta)
		if _jump_buffer > 0.0 and (_coyote > 0.0 or (double_jump and _air_jumps < 1)):
			velocity.y = jump_power
			if _coyote <= 0.0:
				_air_jumps += 1
			_coyote = 0.0
			_jump_buffer = 0.0
	elif is_instance_valid(partner):
		var dx: float = partner.global_position.x - global_position.x
		if absf(dx) > 105.0:
			direction = signf(dx)
		if absf(dx) > 520.0:
			global_position = partner.global_position + Vector2(-64.0 * partner._facing, -12)
			velocity = Vector2.ZERO
		if partner.global_position.y < global_position.y - 75.0 and is_on_floor() and absf(dx) > 80.0:
			velocity.y = jump_power
	velocity.x = move_toward(velocity.x, direction * speed, (1950.0 if is_on_floor() else 1150.0) * delta)
	if absf(direction) > 0.1:
		_facing = int(signf(direction))
	move_and_slide()
	if position.y > 900.0:
		fell.emit()
	var pose := "idle"
	if invulnerable > 0.8:
		pose = "hurt"
	elif _attack_anim > 0.0:
		pose = "attack"
	elif not is_on_floor():
		pose = "jump" if velocity.y < 0 else "fall"
	elif absf(velocity.x) > 35.0:
		pose = "run1" if int(_anim_time * 10.0) % 2 == 0 else "run2"
	_refresh_sprite(pose)
	sprite.flip_h = _facing < 0
	sprite.modulate = Color(1, 1, 1, 0.55) if invulnerable > 0.0 and int(_anim_time * 12.0) % 2 == 0 else Color.WHITE
	sprite.scale = Vector2(0.64, 0.64) if active else Vector2(0.58, 0.58)

func _refresh_sprite(pose: String) -> void:
	if is_instance_valid(sprite):
		sprite.texture = _frames.get(pose, null)

func attack() -> void:
	_attack_anim = 0.25

func take_hit() -> void:
	if invulnerable > 0.0:
		return
	if shield_charges > 0:
		shield_charges -= 1
		invulnerable = 1.0
		shielded.emit()
		return
	invulnerable = 1.4
	health = maxi(0, health - 1)
	velocity.y = -230.0
	hurt.emit()
