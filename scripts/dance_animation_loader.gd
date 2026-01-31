extends RefCounted
class_name DanceAnimationLoader
## Loads dance animation frames from oversized spritesheets by splitting them at runtime.
## This works around OpenGL's 16384px texture size limit.

const SPRITESHEET_PATH := "res://assets/MaskAssets/spritesheet_dancing_limbs.png"
const FRAME_COUNT := 26
const FRAME_WIDTH := 1000
const FRAME_HEIGHT := 983

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

	# Load the full image from disk (not as a GPU texture)
	var image := Image.load_from_file(ProjectSettings.globalize_path(SPRITESHEET_PATH))
	if not image:
		push_error("[DanceAnimationLoader] Failed to load spritesheet from: ", SPRITESHEET_PATH)
		_is_loaded = true
		return

	print("[DanceAnimationLoader] Loaded spritesheet: ", image.get_width(), "x", image.get_height())

	# Extract each frame as a separate ImageTexture
	for i in range(FRAME_COUNT):
		var frame_image := Image.create(FRAME_WIDTH, FRAME_HEIGHT, false, image.get_format())
		var src_rect := Rect2i(i * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
		frame_image.blit_rect(image, src_rect, Vector2i.ZERO)

		var frame_texture := ImageTexture.create_from_image(frame_image)
		_sprite_frames.add_frame("dance", frame_texture)

	print("[DanceAnimationLoader] Created ", FRAME_COUNT, " animation frames")
	_is_loaded = true
