extends RefCounted
class_name HitMarkerLoader
## Loads hit marker animation frames for spear impact feedback

const HITMARKERS_DIR := "res://assets/MaskAssets/hitmarkers/"

# Green frames: 001-005 (devil hit - correct)
const GREEN_FRAME_START := 1
const GREEN_FRAME_END := 5

# Red frames: 002-005 (innocent hit - wrong) - Note: 001 is missing
const RED_FRAME_START := 2
const RED_FRAME_END := 5

const ANIMATION_FPS := 15.0

static var _sprite_frames: SpriteFrames = null
static var _is_loaded: bool = false


static func get_sprite_frames() -> SpriteFrames:
	if not _is_loaded:
		_load_frames()
	return _sprite_frames


static func _load_frames() -> void:
	_sprite_frames = SpriteFrames.new()

	# Remove default animation if it exists
	if _sprite_frames.has_animation("default"):
		_sprite_frames.remove_animation("default")

	# Create green hit animation (devil - correct hit)
	_sprite_frames.add_animation("hit_green")
	_sprite_frames.set_animation_speed("hit_green", ANIMATION_FPS)
	_sprite_frames.set_animation_loop("hit_green", false)

	var green_loaded := 0
	for i in range(GREEN_FRAME_START, GREEN_FRAME_END + 1):
		var frame_path := HITMARKERS_DIR + "GreenSpearImpact%03d.png" % i
		var texture: Texture2D = load(frame_path)
		if texture:
			_sprite_frames.add_frame("hit_green", texture)
			green_loaded += 1
		else:
			push_warning("[HitMarkerLoader] Failed to load: ", frame_path)

	# Create red hit animation (innocent - wrong hit)
	_sprite_frames.add_animation("hit_red")
	_sprite_frames.set_animation_speed("hit_red", ANIMATION_FPS)
	_sprite_frames.set_animation_loop("hit_red", false)

	var red_loaded := 0
	for i in range(RED_FRAME_START, RED_FRAME_END + 1):
		var frame_path := HITMARKERS_DIR + "RedSpearImpact%03d.png" % i
		var texture: Texture2D = load(frame_path)
		if texture:
			_sprite_frames.add_frame("hit_red", texture)
			red_loaded += 1
		else:
			push_warning("[HitMarkerLoader] Failed to load: ", frame_path)

	print("[HitMarkerLoader] Loaded ", green_loaded, " green frames, ", red_loaded, " red frames")
	_is_loaded = true
