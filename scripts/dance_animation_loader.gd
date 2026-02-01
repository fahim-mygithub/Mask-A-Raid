extends RefCounted
class_name DanceAnimationLoader
## Loads dance animation frames from pre-split individual frame images.
## Frames are stored in DancingFrames/ folder (split from original spritesheet).

const FRAMES_DIR := "res://assets/MaskAssets/DancingFrames/"
const FRAME_COUNT := 26

static var _sprite_frames: SpriteFrames = null
static var _is_loaded: bool = false


static func get_sprite_frames() -> SpriteFrames:
	if not _is_loaded:
		_load_frames()
	return _sprite_frames


static func _load_frames() -> void:
	_sprite_frames = SpriteFrames.new()
	_sprite_frames.add_animation("dance")
	_sprite_frames.set_animation_loop("dance", true)
	_sprite_frames.set_animation_speed("dance", 12.0)

	var loaded_count := 0

	# Load each frame as a separate texture (works in web exports)
	for i in range(FRAME_COUNT):
		var frame_path := FRAMES_DIR + "frame_%02d.png" % i
		var texture: Texture2D = load(frame_path)
		if texture:
			_sprite_frames.add_frame("dance", texture)
			loaded_count += 1
		else:
			push_warning("[DanceAnimationLoader] Failed to load frame: ", frame_path)

	if loaded_count > 0:
		print("[DanceAnimationLoader] Loaded ", loaded_count, " animation frames")
	else:
		push_error("[DanceAnimationLoader] No frames loaded!")

	_is_loaded = true
