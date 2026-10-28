extends Node2D
## Floating, multitouch-safe left-hand joystick with an optional upward swipe jump.
## The right-side dedicated jump button remains available for precise platforming.

const DEAD_ZONE := 26.0
const RADIUS := 68.0
const SWIPE_JUMP := 78.0

var enabled := false
var _finger := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO
var _direction := 0
var _swiped := false
var _jump_hold := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	set_physics_process(true)

func set_enabled(value: bool) -> void:
	enabled = value
	visible = value
	if not value:
		_release_touch()
	queue_redraw()

func _is_left_play_area(pos: Vector2) -> bool:
	var screen := get_viewport_rect().size
	return pos.x < screen.x * 0.48 and pos.y > screen.y * 0.23

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _finger < 0 and _is_left_play_area(event.position):
			_finger = event.index
			_origin = event.position
			_knob = _origin
			_swiped = false
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _finger:
			_release_touch()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _finger:
		_update_drag(event.position)
		get_viewport().set_input_as_handled()

func _update_drag(pos: Vector2) -> void:
	var displacement := pos - _origin
	_knob = _origin + displacement.limit_length(RADIUS)
	var next_direction := 0
	if displacement.x > DEAD_ZONE:
		next_direction = 1
	elif displacement.x < -DEAD_ZONE:
		next_direction = -1
	_set_direction(next_direction)
	if not _swiped and displacement.y < -SWIPE_JUMP:
		_swiped = true
		Input.action_press("jump")
		_jump_hold = 0.13
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _jump_hold > 0.0:
		_jump_hold -= delta
		if _jump_hold <= 0.0:
			Input.action_release("jump")

func _set_direction(next_direction: int) -> void:
	if next_direction == _direction:
		return
	if _direction < 0:
		Input.action_release("move_left")
	elif _direction > 0:
		Input.action_release("move_right")
	_direction = next_direction
	if _direction < 0:
		Input.action_press("move_left")
	elif _direction > 0:
		Input.action_press("move_right")

func _release_touch() -> void:
	_set_direction(0)
	_finger = -1
	_swiped = false
	_knob = Vector2.ZERO
	if _jump_hold > 0.0:
		Input.action_release("jump")
		_jump_hold = 0.0
	queue_redraw()

func _draw() -> void:
	if not enabled:
		return
	var center := _origin if _finger >= 0 else Vector2(156, 590)
	var opacity := 0.70 if _finger >= 0 else 0.28
	draw_circle(center, RADIUS + 16, Color(0.07, 0.19, 0.28, opacity * 0.60))
	draw_arc(center, RADIUS + 6, 0.0, TAU, 56, Color(0.86, 0.98, 1.0, opacity), 3.0, true)
	var knob_pos := _knob if _finger >= 0 else center
	draw_circle(knob_pos, 33, Color(0.71, 0.91, 0.96, opacity * 0.88))
	draw_circle(knob_pos, 19, Color(1.0, 1.0, 1.0, opacity * 0.55))
	# A visual cue: upward swipe is an optional jump gesture.
	if _finger < 0:
		draw_line(center + Vector2(0, -84), center + Vector2(0, -111), Color(1, 1, 1, 0.45), 3.0)
		draw_line(center + Vector2(0, -111), center + Vector2(-9, -100), Color(1, 1, 1, 0.45), 3.0)
		draw_line(center + Vector2(0, -111), center + Vector2(9, -100), Color(1, 1, 1, 0.45), 3.0)
