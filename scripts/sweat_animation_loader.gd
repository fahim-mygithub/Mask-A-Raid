extends RefCounted
class_name SweatAnimationLoader
## Loads sweat animation frames from spritesheet using AtlasTexture.
## Spritesheet: 11000x983 pixels, 11 frames horizontally.

const SPRITESHEET_PATH := "res://assets/MaskAssets/sweating_11_frames.png"
const FRAME_COUNT := 11
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
	_sprite_frames.add_animation("sweat")
	_sprite_frames.set_animation_loop("sweat", true)
	_sprite_frames.set_animation_speed("sweat", 10.0)  ## 10 FPS for smooth dripping

	var spritesheet: Texture2D = load(SPRITESHEET_PATH)
	if not spritesheet:
		push_error("[SweatAnimationLoader] Failed to load spritesheet: ", SPRITESHEET_PATH)
		_is_loaded = true
		return

	var loaded_count := 0

	## Extract each frame using AtlasTexture
	for i in range(FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = spritesheet
		atlas.region = Rect2(i * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)

		_sprite_frames.add_frame("sweat", atlas)
		loaded_count += 1

	print("[SweatAnimationLoader] Loaded ", loaded_count, " sweat animation frames")
	_is_loaded = true
