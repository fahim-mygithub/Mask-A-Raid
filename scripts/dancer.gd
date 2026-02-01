extends PathFollow2D
class_name Dancer
## A dancer that moves along the ritual path. Can be a devil or innocent.

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

## Animation
var _base_scale: Vector2 = Vector2.ONE
var _hover_scale: Vector2 = Vector2(1.08, 1.08)


func _ready() -> void:
	_base_scale = scale
	_hover_scale = _base_scale * 1.08

	# Connect click area signals
	click_area.input_event.connect(_on_click_area_input_event)
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)

	# Load dance animation frames (handles oversized spritesheet)
	_load_dance_animation()

	# Randomize dance animation start frame and speed for variety
	_randomize_dance_animation()

	print("[Dancer] Ready, is_devil=", is_devil)


func _load_dance_animation() -> void:
	if body:
		# Use the runtime loader to handle the oversized spritesheet
		body.sprite_frames = DanceAnimationLoader.get_sprite_frames()


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
			if body:
				body.play("dance")
		VisualState.HOVERED:
			scale = _hover_scale
		VisualState.CLICKED:
			# Brief flash effect
			_play_click_flash()
		VisualState.REVEALED_CORRECT:
			is_revealed = true
			if body:
				body.pause()
			_play_correct_animation()
		VisualState.REVEALED_WRONG:
			is_revealed = true
			if body:
				body.pause()
			_play_wrong_animation()


func reveal(was_correct: bool) -> void:
	## Reset cursor since dancer is no longer clickable
	if is_hovered:
		GameManager.set_cursor_normal()
	if was_correct:
		set_visual_state(VisualState.REVEALED_CORRECT)
	else:
		set_visual_state(VisualState.REVEALED_WRONG)


func _play_click_flash() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)


func _play_correct_animation() -> void:
	# Fade out and shrink
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "scale", _base_scale * 0.5, 0.5)
	tween.chain().tween_callback(queue_free)


func _play_wrong_animation() -> void:
	# Red flash and shake
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
