extends Node2D
class_name Spear
## A throwable spear projectile that follows a pre-calculated arc path.
## Features 2.5D depth effect with scale growth during flight.

signal hit_dancer(dancer: Dancer)
signal missed

## Flight configuration
@export var flight_duration: float = 0.5  ## Seconds to complete arc
@export var start_scale: float = 1.0  ## Large when at ballista (close to player)
@export var end_scale: float = 0.3  ## Small at target (far from player, into screen)

## State
enum State { FLYING, HIT, MISSED }
var state: State = State.FLYING

## Arc flight data
var arc_points: Array = []  ## Pre-calculated arc points
var flight_time: float = 0.0

## 2.5D depth - collision only active in final portion
var collision_active_threshold: float = 0.5  ## Enable collision at 50% of flight

## Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea

## Stuck-in-dancer effect
var stuck_dancer: Dancer = null
var stuck_offset: Vector2 = Vector2.ZERO

## Base sprite scale (from scene)
var _base_sprite_scale: Vector2


func _ready() -> void:
	if sprite:
		_base_sprite_scale = sprite.scale

	if hit_area:
		hit_area.area_entered.connect(_on_area_entered)
		# Disable collision initially (spear is "far away")
		hit_area.monitoring = false


func _process(delta: float) -> void:
	match state:
		State.FLYING:
			_update_flying(delta)
		State.HIT:
			_update_stuck()
		State.MISSED:
			pass  # Fading out, handled by tween


func _update_flying(delta: float) -> void:
	if arc_points.is_empty():
		_on_miss()
		return

	flight_time += delta
	var t := clampf(flight_time / flight_duration, 0.0, 1.0)

	if t >= 1.0:
		# Reached target without hitting anyone
		_on_miss()
		return

	# Get position along arc using interpolation
	var arc_index := t * (arc_points.size() - 1)
	var index_low := int(arc_index)
	var index_high := mini(index_low + 1, arc_points.size() - 1)
	var index_t := arc_index - index_low

	var current_pos: Vector2 = arc_points[index_low].lerp(arc_points[index_high], index_t)
	global_position = current_pos

	# Rotate to face movement direction (tangent of arc)
	if index_high < arc_points.size() - 1:
		var next_pos: Vector2 = arc_points[index_high]
		var direction := (next_pos - current_pos).normalized()
		if direction.length() > 0.1:
			rotation = direction.angle() + PI / 2  # Adjust for spear pointing up

	# Scale grows as spear "approaches" target (2.5D effect)
	var scale_t := _ease_out_quad(t)
	var current_scale := lerpf(start_scale, end_scale, scale_t)
	if sprite:
		sprite.scale = _base_sprite_scale * current_scale

	# Enable collision when spear reaches dancer plane
	if t >= collision_active_threshold and hit_area and not hit_area.monitoring:
		hit_area.monitoring = true
		print("[Spear] Collision enabled at t=", t)


func _update_stuck() -> void:
	# Follow the dancer we're stuck in
	if stuck_dancer and is_instance_valid(stuck_dancer):
		global_position = stuck_dancer.global_position + stuck_offset


func _ease_out_quad(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)


func launch_along_arc(points: Array) -> void:
	## Launch spear along pre-calculated arc points
	arc_points = points

	if arc_points.is_empty():
		print("[Spear] Error: No arc points provided")
		_on_miss()
		return

	# Start at first arc point
	global_position = arc_points[0]

	# Initial small scale
	if sprite:
		sprite.scale = _base_sprite_scale * start_scale

	# Initial rotation toward second point
	if arc_points.size() > 1:
		var direction: Vector2 = (arc_points[1] - arc_points[0]).normalized()
		rotation = direction.angle() + PI / 2

	flight_time = 0.0
	state = State.FLYING

	print("[Spear] Launched along arc with ", arc_points.size(), " points")


func _on_area_entered(area: Area2D) -> void:
	if state != State.FLYING:
		return

	# Check if we hit a dancer
	var parent := area.get_parent()
	if parent is Dancer:
		var dancer := parent as Dancer
		if not dancer.is_revealed:
			_on_hit_dancer(dancer)


func _on_hit_dancer(dancer: Dancer) -> void:
	print("[Spear] Hit dancer! is_devil=", dancer.is_devil)
	state = State.HIT

	## Play layered hit sounds (spear impact + hurt reaction)
	AudioManager.play_sfx_layered([
		"res://assets/sound/spear/spear_hit.wav",
		"res://assets/sound/spear/hurt.wav"
	])

	# Disable further collision (deferred to avoid signal blocking)
	if hit_area:
		hit_area.set_deferred("monitoring", false)

	# Stick to dancer briefly at full scale
	stuck_dancer = dancer
	stuck_offset = global_position - dancer.global_position

	# Ensure full scale when stuck
	if sprite:
		sprite.scale = _base_sprite_scale * end_scale

	# Brief delay before emitting hit signal (for "stick" effect)
	var tween := create_tween()
	tween.tween_interval(0.15)
	tween.tween_callback(func():
		hit_dancer.emit(dancer)
		_fade_out()
	)


func _on_miss() -> void:
	print("[Spear] Missed target")
	state = State.MISSED

	## Play miss sound (spear hitting ground)
	AudioManager.play_sfx_from_path("res://assets/sound/spear/spear_miss.wav")

	if hit_area:
		hit_area.monitoring = false

	missed.emit()
	_fade_out()


func _fade_out() -> void:
	## Quick fade and remove
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
