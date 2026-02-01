@tool
extends SceneTree
## Tool script to split the dancing limbs spritesheet into individual frames.
## Run with: Godot_v4.6-stable_win64_console.exe --headless --script res://scripts/tools/split_spritesheet.gd

const SPRITESHEET_PATH := "res://assets/MaskAssets/spritesheet_dancing_limbs.png"
const OUTPUT_DIR := "res://assets/MaskAssets/DancingFrames/"
const FRAME_COUNT := 26
const FRAME_WIDTH := 1000
const FRAME_HEIGHT := 983


func _init() -> void:
	print("=== Spritesheet Splitter ===")

	# Create output directory
	var dir := DirAccess.open("res://assets/MaskAssets/")
	if dir and not dir.dir_exists("DancingFrames"):
		dir.make_dir("DancingFrames")
		print("Created DancingFrames directory")

	# Load the spritesheet as raw image data
	var abs_path := ProjectSettings.globalize_path(SPRITESHEET_PATH)
	print("Loading spritesheet from: ", abs_path)

	var image := Image.load_from_file(abs_path)
	if not image:
		push_error("Failed to load spritesheet!")
		quit(1)
		return

	print("Loaded image: ", image.get_width(), "x", image.get_height())

	# Split into individual frames
	for i in range(FRAME_COUNT):
		var frame_image := Image.create(FRAME_WIDTH, FRAME_HEIGHT, false, image.get_format())
		var src_rect := Rect2i(i * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
		frame_image.blit_rect(image, src_rect, Vector2i.ZERO)

		var output_path := ProjectSettings.globalize_path(OUTPUT_DIR + "frame_%02d.png" % i)
		var error := frame_image.save_png(output_path)
		if error != OK:
			push_error("Failed to save frame %d: %s" % [i, error])
		else:
			print("Saved frame_%02d.png" % i)

	print("=== Done! Split %d frames ===" % FRAME_COUNT)
	quit(0)
