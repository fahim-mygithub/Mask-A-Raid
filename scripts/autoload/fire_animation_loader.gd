extends Node
class_name FireAnimationLoader
## Loads fire animation frames and creates a boomerang-style SpriteFrames resource.
## Frames play: 1→2→3→4→5→6→7→6→5→4→3→2→(loop)

const FIRE_FRAME_COUNT := 7
const FIRE_PATH_TEMPLATE := "res://assets/ingame_scene_assets/fire_%d.png"
const ANIMATION_FPS := 12.0

static var _sprite_frames: SpriteFrames = null


static func get_sprite_frames() -> SpriteFrames:
	if _sprite_frames != null:
		return _sprite_frames

	_sprite_frames = SpriteFrames.new()

	## Remove default animation
	if _sprite_frames.has_animation("default"):
		_sprite_frames.remove_animation("default")

	## Create fire animation
	_sprite_frames.add_animation("fire")
	_sprite_frames.set_animation_speed("fire", ANIMATION_FPS)
	_sprite_frames.set_animation_loop("fire", true)

	## Load frames 1-7 (forward)
	var textures: Array[Texture2D] = []
	for i in range(1, FIRE_FRAME_COUNT + 1):
		var path := FIRE_PATH_TEMPLATE % i
		var texture := load(path) as Texture2D
		if texture:
			textures.append(texture)
		else:
			push_warning("[FireAnimationLoader] Failed to load: " + path)

	## Add frames in boomerang order: 1,2,3,4,5,6,7,6,5,4,3,2
	## Forward: 1→7
	for i in range(textures.size()):
		_sprite_frames.add_frame("fire", textures[i])

	## Backward: 6→2 (skip 7 and 1 to avoid duplicates at transition)
	for i in range(textures.size() - 2, 0, -1):
		_sprite_frames.add_frame("fire", textures[i])

	print("[FireAnimationLoader] Created boomerang animation with %d frames" % _sprite_frames.get_frame_count("fire"))
	return _sprite_frames
