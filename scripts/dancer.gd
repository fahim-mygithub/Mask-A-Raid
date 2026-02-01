extends PathFollow2D
class_name Dancer
## A dancer that moves along the ritual path. Can be a devil or innocent.

const SweatAnimationLoaderScript := preload("res://scripts/sweat_animation_loader.gd")
const DeathAnimationLoaderScript := preload("res://scripts/death_animation_loader.gd")
const HitMarkerLoaderScript := preload("res://scripts/hit_marker_loader.gd")

## Signals
signal clicked(dancer: Dancer)
signal hovered(dancer: Dancer, is_hovered: bool)

## Movement
@export var movement_speed: float = 0.08  ## Progress per second (0-1 range)

## Animation
@export var dance_speed_variation: float = 0.2  ## Random variation in dance speed

## State
var is_devil: bool = false
var is_hovered: bool = false
var is_revealed: bool = false
var mask_data: Resource  # MaskData resource

## Visual states
enum VisualState { NORMAL, HOVERED, CLICKED, REVEALED_CORRECT, REVEALED_WRONG }
var visual_state: VisualState = VisualState.NORMAL

## Node references
@onready var body: AnimatedSprite2D = $Body
@onready var mask_container: Node2D = $MaskContainer
@onready var click_area: Area2D = $ClickArea
@onready var sweat_effect: AnimatedSprite2D = $MaskContainer/SweatEffect

## Animation
var _base_scale: Vector2 = Vector2.ONE
var _hover_scale: Vector2 = Vector2(1.08, 1.08)


func _ready() -> void:
	_base_scale = scale
	_hover_scale = _base_scale * 1.08

	## Click area is now used for spear collision, not direct clicking
	## Mouse hover signals kept for visual feedback when targeted by spear
	# click_area.input_event.connect(_on_click_area_input_event)  # Disabled - using spear system
	# click_area.mouse_entered.connect(_on_mouse_entered)  # Disabled - targeting handled by main
	# click_area.mouse_exited.connect(_on_mouse_exited)  # Disabled - targeting handled by main

	# Load dance animation frames (handles oversized spritesheet)
	_load_dance_animation()

	# Load sweat animation
	_load_sweat_animation()

	# Randomize dance animation start frame and speed for variety
	_randomize_dance_animation()

	print("[Dancer] Ready, is_devil=", is_devil)


func _load_dance_animation() -> void:
	if body:
		# Use the runtime loader to handle the oversized spritesheet
		body.sprite_frames = DanceAnimationLoader.get_sprite_frames()


func _load_sweat_animation() -> void:
	if sweat_effect:
		sweat_effect.sprite_frames = SweatAnimationLoaderScript.get_sprite_frames()


func _randomize_dance_animation() -> void:
	if body and body.sprite_frames and body.sprite_frames.has_animation("dance"):
		# Start at a random frame so dancers aren't synchronized
		var frame_count := body.sprite_frames.get_frame_count("dance")
		if frame_count > 0:
			body.frame = randi() % frame_count

		# Add slight speed variation
		var variation := randf_range(-dance_speed_variation, dance_speed_variation)
		body.speed_scale = 1.0 + variation

		# Ensure animation is playing
		body.play("dance")


func _process(delta: float) -> void:
	if is_revealed:
		return

	# Move along path
	progress_ratio += movement_speed * delta
	if progress_ratio >= 1.0:
		progress_ratio -= 1.0


func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_revealed:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			print("[Dancer] Clicked! is_devil=", is_devil)
			set_visual_state(VisualState.CLICKED)
			clicked.emit(self)


func _on_mouse_entered() -> void:
	if is_revealed:
		return

	is_hovered = true
	set_visual_state(VisualState.HOVERED)
	GameManager.set_cursor_hover()
	hovered.emit(self, true)


func _on_mouse_exited() -> void:
	if is_revealed:
		return

	is_hovered = false
	set_visual_state(VisualState.NORMAL)
	GameManager.set_cursor_normal()
	hovered.emit(self, false)


func set_visual_state(state: VisualState) -> void:
	visual_state = state

	match state:
		VisualState.NORMAL:
			scale = _base_scale
			modulate = Color.WHITE
			set_sweating(false)
			if body:
				body.play("dance")
		VisualState.HOVERED:
			scale = _hover_scale
			set_sweating(true)
		VisualState.CLICKED:
			# Brief flash effect
			_play_click_flash()
		VisualState.REVEALED_CORRECT:
			is_revealed = true
			set_sweating(false)
			_play_correct_animation()
		VisualState.REVEALED_WRONG:
			is_revealed = true
			set_sweating(false)
			_play_wrong_animation()


func reveal(was_correct: bool) -> void:
	## Reset cursor since dancer is no longer clickable
	if is_hovered:
		GameManager.set_cursor_normal()

	# Spawn hit marker effect on mask
	_spawn_hit_marker(was_correct)

	if was_correct:
		set_visual_state(VisualState.REVEALED_CORRECT)
	else:
		set_visual_state(VisualState.REVEALED_WRONG)


func _play_click_flash() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)


func _play_correct_animation() -> void:
	# Devil was correctly identified - play hit animation then death sequence
	_play_hit_animation()


func _play_wrong_animation() -> void:
	# Innocent was wrongly hit - freeze in current pose with red flash + shake
	# (Don't play hit animation - just freeze immediately)
	body.pause()

	# Red flash
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

	# Shake effect
	var shake_tween := create_tween()
	var original_pos := position
	for i in range(5):
		var offset := Vector2(randf_range(-10, 10), randf_range(-5, 5))
		shake_tween.tween_property(self, "position", original_pos + offset, 0.05)
	shake_tween.tween_property(self, "position", original_pos, 0.05)


func _play_hit_animation() -> void:
	## Play the "getting shot" animation for devil, then death sequence
	# Load death animation frames
	var death_frames := DeathAnimationLoaderScript.get_sprite_frames()
	if death_frames == null or not death_frames.has_animation("hit"):
		# Fallback to old behavior if animation not available
		_fallback_correct_animation()
		return

	# Switch body to hit animation
	body.sprite_frames = death_frames
	body.play("hit")

	# Wait for hit animation to finish, then play death sequence
	body.animation_finished.connect(_on_hit_animation_finished, CONNECT_ONE_SHOT)


func _on_hit_animation_finished() -> void:
	_play_devil_death_sequence()


func _play_devil_death_sequence() -> void:
	## Devil death: switch to dead body sprite (already drawn fallen), tilt mask, then vanish
	# Load dead body texture
	var dead_body_tex := DeathAnimationLoaderScript.get_dead_body_texture()
	if dead_body_tex:
		# Convert AnimatedSprite2D frame to static dead body
		body.stop()
		body.sprite_frames = null

		# Create a temporary Sprite2D for the dead body
		# Dead_Body.png is already drawn in fallen position, so no rotation needed
		var dead_sprite := Sprite2D.new()
		dead_sprite.texture = dead_body_tex
		dead_sprite.position = body.position + Vector2(-50, 0)  # Shift limbs left
		dead_sprite.scale = body.scale
		add_child(dead_sprite)
		body.visible = false

	# Tilt the mask to the right as it falls off
	var mask_tween := create_tween()
	mask_tween.tween_property(mask_container, "rotation_degrees", randf_range(35, 50), 0.3)

	# Hold on dead pose longer, then fade out and vanish
	var vanish_tween := create_tween()
	vanish_tween.tween_interval(1.2)  # Hold dead pose longer
	vanish_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	vanish_tween.tween_callback(queue_free)


func _fallback_correct_animation() -> void:
	## Fallback if death animation not available
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "scale", _base_scale * 0.5, 0.5)
	tween.chain().tween_callback(queue_free)


func _fallback_wrong_animation() -> void:
	## Fallback if death animation not available
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

	var shake_tween := create_tween()
	var original_pos := position
	for i in range(5):
		var offset := Vector2(randf_range(-10, 10), randf_range(-5, 5))
		shake_tween.tween_property(self, "position", original_pos + offset, 0.05)
	shake_tween.tween_property(self, "position", original_pos, 0.05)


func set_sweating(enabled: bool) -> void:
	## Show/hide sweat effect when targeted by spear
	if not sweat_effect:
		return

	sweat_effect.visible = enabled
	if enabled:
		sweat_effect.play("sweat")
	else:
		sweat_effect.stop()


func _spawn_hit_marker(is_correct: bool) -> void:
	## Spawn hit marker effect on the mask when hit by spear
	var hit_frames := HitMarkerLoaderScript.get_sprite_frames()
	if hit_frames == null:
		return

	var anim_name := "hit_green" if is_correct else "hit_red"
	if not hit_frames.has_animation(anim_name):
		return

	# Create AnimatedSprite2D for hit marker
	var hit_marker := AnimatedSprite2D.new()
	hit_marker.sprite_frames = hit_frames
	hit_marker.position = Vector2.ZERO  # Centered on mask
	hit_marker.scale = Vector2(6.0, 6.0)  # Scale up for visibility
	hit_marker.z_index = 10  # Render above mask

	# Add to mask container so it follows the mask
	mask_container.add_child(hit_marker)

	# Play the animation
	hit_marker.play(anim_name)

	# When animation finishes, fade out and remove
	hit_marker.animation_finished.connect(func():
		var fade_tween := create_tween()
		fade_tween.tween_property(hit_marker, "modulate:a", 0.0, 0.2)
		fade_tween.tween_callback(hit_marker.queue_free)
	)
