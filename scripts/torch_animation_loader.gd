extends RefCounted
class_name TorchAnimationLoader
## Loads torch animation frames for menu button hover effect.
## TorchNoFlame = unlit, TorchFlame001-005 = burning animation.

const TORCH_PATH := "res://assets/title_screen-assets/torch/"
const FLAME_FRAME_COUNT := 5

static var _sprite_frames: SpriteFrames = null
static var _is_loaded: bool = false


static func get_sprite_frames() -> SpriteFrames:
	if not _is_loaded:
		_load_frames()
	return _sprite_frames


static func _load_frames() -> void:
	_sprite_frames = SpriteFrames.new()

	# Idle animation (unlit torch)
	_sprite_frames.add_animation("idle")
	_sprite_frames.set_animation_loop("idle", false)
	_sprite_frames.set_animation_speed("idle", 1.0)

	var no_flame: Texture2D = load(TORCH_PATH + "TorchNoFlame.png")
	if no_flame:
		_sprite_frames.add_frame("idle", no_flame)
	else:
		push_error("[TorchAnimationLoader] Failed to load TorchNoFlame.png")

	# Burn animation (flame frames)
	_sprite_frames.add_animation("burn")
	_sprite_frames.set_animation_loop("burn", true)
	_sprite_frames.set_animation_speed("burn", 8.0)  # 8 FPS for flickering effect

	var loaded_count := 0
	for i in range(1, FLAME_FRAME_COUNT + 1):
		var frame_path := TORCH_PATH + "TorchFlame%03d.png" % i
		var frame_tex: Texture2D = load(frame_path)
		if frame_tex:
			_sprite_frames.add_frame("burn", frame_tex)
			loaded_count += 1
		else:
			push_error("[TorchAnimationLoader] Failed to load: ", frame_path)

	print("[TorchAnimationLoader] Loaded ", loaded_count, " flame frames")
	_is_loaded = true
