extends Node2D
class_name Ballista
## Artillery-style spear launcher with charge-based arc targeting.

signal spear_fired(target_position: Vector2, arc_points: Array)
signal target_changed(dancer: Dancer)

const SpearScene := preload("res://scenes/spear.tscn")

## Charge configuration
@export var charge_time: float = 1.2  ## Seconds to reach full charge
@export var min_range: float = 100.0  ## Minimum arc range
@export var max_range: float = 450.0  ## Maximum arc range (reaches dancer circle)
@export var arc_height_ratio: float = 0.4  ## Arc peak height as ratio of distance

## Visual configuration
@export var arc_segments: int = 20  ## Number of segments in dashed arc
@export var arc_color: Color = Color(0.6, 0.5, 0.3, 0.7)  ## Tan/tribal color
@export var target_color: Color = Color(0.8, 0.3, 0.2, 0.8)  ## Red when on target
@export var target_radius: float = 30.0  ## Ground target cursor size

## State
enum State { IDLE, AIMING, COOLDOWN }
var state: State = State.IDLE

## Aiming data
var aim_direction: Vector2 = Vector2.UP  ## Direction toward mouse
var charge_progress: float = 0.0  ## 0.0 to 1.0
var current_range: float = 0.0  ## Current arc range based on charge
var target_position: Vector2 = Vector2.ZERO  ## Where spear will land
var targeted_dancer: Dancer = null  ## Dancer under target cursor

## Cooldown
var cooldown_timer: float = 0.0
@export var cooldown_duration: float = 1.0

## Node references
@onready var spear_sprite: Sprite2D = $SpearSprite

## Spear positioning
var spear_base_position: Vector2 = Vector2.ZERO
var spear_pullback_distance: float = 30.0  ## How far spear pulls back when charged
@export var horizontal_shift_range: float = 200.0  ## Max left/right shift based on cursor

## Dancers reference (set by main)
var dancers: Array[Dancer] = []


func _ready() -> void:
	if spear_sprite:
		spear_base_position = spear_sprite.position


func _process(delta: float) -> void:
	match state:
		State.IDLE:
			_update_idle()
		State.AIMING:
			_update_aiming(delta)
		State.COOLDOWN:
			_update_cooldown(delta)

	queue_redraw()


func _update_idle() -> void:
	## Spear points toward mouse but no charging
	_update_aim_direction()
	_rotate_spear_to_aim()
	_shift_spear_horizontal()


func _update_aiming(delta: float) -> void:
	## Update aim direction
	_update_aim_direction()
	_rotate_spear_to_aim()
	_shift_spear_horizontal()

	## Increase charge
	charge_progress = minf(charge_progress + delta / charge_time, 1.0)

	## Calculate current range based on charge
	current_range = lerpf(min_range, max_range, charge_progress)

	## Calculate target position
	target_position = global_position + aim_direction * current_range

	## Update spear pull-back (along with horizontal shift)
	_update_spear_pullback()

	## Check for dancer under target
	_check_target_dancer()


func _update_cooldown(delta: float) -> void:
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		state = State.IDLE
		if spear_sprite:
			spear_sprite.visible = true
		print("[Ballista] Ready to fire")


func _update_aim_direction() -> void:
	var mouse_pos := get_global_mouse_position()
	var to_mouse := mouse_pos - global_position

	## Only aim upward (toward dancers, not below ballista)
	if to_mouse.y < 0:
		aim_direction = to_mouse.normalized()
	else:
		## If mouse is below, aim straight up
		aim_direction = Vector2.UP


func _rotate_spear_to_aim() -> void:
	if spear_sprite:
		## Rotate spear to point in aim direction
		spear_sprite.rotation = aim_direction.angle() + PI / 2


func _shift_spear_horizontal() -> void:
	## Shift spear left/right based on mouse X relative to ballista center
	if not spear_sprite:
		return

	var mouse_pos := get_global_mouse_position()
	var viewport_size := get_viewport_rect().size

	## Calculate horizontal offset based on mouse X position
	## Mouse at center = no shift, mouse at edges = max shift
	var center_x := viewport_size.x / 2
	var relative_x := (mouse_pos.x - center_x) / center_x  ## -1 to 1
	relative_x = clampf(relative_x, -1.0, 1.0)

	var horizontal_offset := relative_x * horizontal_shift_range
	spear_sprite.position.x = spear_base_position.x + horizontal_offset


func _update_spear_pullback() -> void:
	if spear_sprite:
		## Pull spear back along its axis based on charge (Y only, X is handled by horizontal shift)
		var pullback_y := spear_pullback_distance * charge_progress
		spear_sprite.position.y = spear_base_position.y + pullback_y


func _check_target_dancer() -> void:
	var new_target: Dancer = null

	for dancer in dancers:
		if is_instance_valid(dancer) and not dancer.is_revealed:
			var dist := dancer.global_position.distance_to(target_position)
			if dist < 70.0:  ## Dancer hitbox radius
				new_target = dancer
				break

	if new_target != targeted_dancer:
		## Clear old highlight
		if targeted_dancer and is_instance_valid(targeted_dancer) and not targeted_dancer.is_revealed:
			targeted_dancer.set_visual_state(Dancer.VisualState.NORMAL)

		## Set new highlight
		targeted_dancer = new_target
		if targeted_dancer:
			targeted_dancer.set_visual_state(Dancer.VisualState.HOVERED)

		target_changed.emit(targeted_dancer)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_start_aiming()
			else:
				_release_fire()


func _start_aiming() -> void:
	if state == State.COOLDOWN:
		return

	state = State.AIMING
	charge_progress = 0.0
	current_range = min_range
	print("[Ballista] Started aiming")


func _release_fire() -> void:
	if state != State.AIMING:
		return

	## Clear targeting
	if targeted_dancer and is_instance_valid(targeted_dancer) and not targeted_dancer.is_revealed:
		targeted_dancer.set_visual_state(Dancer.VisualState.NORMAL)

	## Calculate arc points for the spear to follow
	var arc_points := _calculate_arc_points(global_position, target_position)

	## Fire signal with target and arc
	spear_fired.emit(target_position, arc_points)

	## Start cooldown
	state = State.COOLDOWN
	cooldown_timer = cooldown_duration
	charge_progress = 0.0
	targeted_dancer = null

	## Hide spear during cooldown
	if spear_sprite:
		spear_sprite.visible = false
		spear_sprite.position = spear_base_position

	print("[Ballista] Fired at ", target_position)


func _calculate_arc_points(from: Vector2, to: Vector2) -> Array:
	## Generate points along the parabolic arc
	var points: Array = []
	var distance := from.distance_to(to)
	var arc_height := distance * arc_height_ratio

	## Control point for quadratic bezier (peak of arc)
	var midpoint := (from + to) / 2
	var control := midpoint + Vector2(0, -arc_height)

	for i in range(arc_segments + 1):
		var t := float(i) / float(arc_segments)
		var q0 := from.lerp(control, t)
		var q1 := control.lerp(to, t)
		var point := q0.lerp(q1, t)
		points.append(point)

	return points


func _draw() -> void:
	if state != State.AIMING:
		return

	## Draw dashed arc trajectory
	var arc_points := _calculate_arc_points(global_position, target_position)
	_draw_dashed_arc(arc_points)

	## Draw target cursor at endpoint
	_draw_target_cursor()


func _draw_dashed_arc(points: Array) -> void:
	if points.size() < 2:
		return

	var g = Draw.create(self)
	g.line_style(arc_color, 3.0)

	## Draw dashed line (every other segment)
	for i in range(points.size() - 1):
		if i % 2 == 0:  ## Dash pattern
			var from_local: Vector2 = to_local(points[i])
			var to_local_pt: Vector2 = to_local(points[i + 1])
			g.line_between(from_local.x, from_local.y, to_local_pt.x, to_local_pt.y)


func _draw_target_cursor() -> void:
	var g = Draw.create(self)
	var cursor_local: Vector2 = to_local(target_position)

	## Color changes if targeting a dancer
	var color := target_color if targeted_dancer else arc_color

	## Outer circle
	g.line_style(color, 2.0)
	g.stroke_circle(cursor_local.x, cursor_local.y, target_radius)

	## Inner crosshair
	var cross_size := target_radius * 0.5
	g.line_between(cursor_local.x - cross_size, cursor_local.y, cursor_local.x + cross_size, cursor_local.y)
	g.line_between(cursor_local.x, cursor_local.y - cross_size, cursor_local.x, cursor_local.y + cross_size)

	## Center dot
	g.fill_style(color)
	g.fill_circle(cursor_local.x, cursor_local.y, 4)


func set_enabled(enabled: bool) -> void:
	set_process(enabled)
	set_process_input(enabled)
	if not enabled and state == State.AIMING:
		## Cancel aiming
		if targeted_dancer and is_instance_valid(targeted_dancer):
			targeted_dancer.set_visual_state(Dancer.VisualState.NORMAL)
		targeted_dancer = null
		state = State.IDLE
		charge_progress = 0.0
		if spear_sprite:
			spear_sprite.position = spear_base_position
