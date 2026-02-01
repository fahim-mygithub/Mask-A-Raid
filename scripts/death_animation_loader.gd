extends RefCounted
class_name DeathAnimationLoader
## Loads death animation frames from the sprite sheet

const SPRITE_SHEET_PATH := "res://assets/MaskAssets/DeathFrames/gettingshot_6_frames.png"
const DEAD_BODY_PATH := "res://assets/MaskAssets/DeathFrames/Dead_Body.png"

const FRAME_COUNT := 6
const FRAME_WIDTH := 1333  # 8000 / 6 frames
const FRAME_HEIGHT := 983

static var _sprite_frames: SpriteFrames = null
static var _dead_body_texture: Texture2D = null


static func get_sprite_frames() -> SpriteFrames:
	if _sprite_frames != null:
		return _sprite_frames

	var texture := load(SPRITE_SHEET_PATH) as Texture2D
	if texture == null:
		push_error("[DeathAnimationLoader] Failed to load sprite sheet: ", SPRITE_SHEET_PATH)
		return null

	_sprite_frames = SpriteFrames.new()

	# Remove default animation if it exists
	if _sprite_frames.has_animation("default"):
		_sprite_frames.remove_animation("default")

	# Create "hit" animation (getting shot sequence)
	_sprite_frames.add_animation("hit")
	_sprite_frames.set_animation_speed("hit", 12.0)
	_sprite_frames.set_animation_loop("hit", false)

	# Extract frames from horizontal sprite sheet
	for i in range(FRAME_COUNT):
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(i * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
		_sprite_frames.add_frame("hit", atlas_texture)

	print("[DeathAnimationLoader] Loaded ", FRAME_COUNT, " frames for hit animation")
	return _sprite_frames


static func get_dead_body_texture() -> Texture2D:
	if _dead_body_texture != null:
		return _dead_body_texture

	_dead_body_texture = load(DEAD_BODY_PATH) as Texture2D
	if _dead_body_texture == null:
		push_error("[DeathAnimationLoader] Failed to load dead body texture: ", DEAD_BODY_PATH)

	return _dead_body_texture
