extends RefCounted
class_name MaskGenerator
## Generates and applies masks to dancers.

const PATTERNS_PATH := "res://assets/MaskAssets/Patterns/"
const MASK_BASE_PATH := "res://assets/MaskAssets/MaskBase.png"

## Devil mask tint color (red-ish)
const DEVIL_COLOR := Color(1.0, 0.6, 0.6)

static var _available_patterns: Array[String] = []
static var _patterns_loaded: bool = false


static func _load_patterns() -> void:
	if _patterns_loaded:
		return

	_available_patterns.clear()
	var dir := DirAccess.open(PATTERNS_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var lower_name := file_name.to_lower()
				if lower_name.ends_with(".png"):
					# Store the basename without extension
					_available_patterns.append(file_name.get_basename())
			file_name = dir.get_next()
		dir.list_dir_end()

	_patterns_loaded = true
	print("[MaskGenerator] Loaded ", _available_patterns.size(), " patterns: ", _available_patterns)


static func generate_mask(is_devil: bool) -> MaskData:
	if not _patterns_loaded:
		_load_patterns()

	var data := MaskData.new()

	if _available_patterns.size() > 0:
		data.pattern_name = _available_patterns.pick_random()
	else:
		data.pattern_name = ""
		push_warning("[MaskGenerator] No patterns available!")

	# Devils get a red tint
	data.base_color = DEVIL_COLOR if is_devil else Color.WHITE
	data.has_horns = is_devil

	return data


static func apply_mask_to_dancer(dancer: Node, mask_data: MaskData) -> void:
	var mask_base: Sprite2D = dancer.get_node_or_null("MaskContainer/MaskBase")
	var pattern: Sprite2D = dancer.get_node_or_null("MaskContainer/Pattern")
	var horns: Sprite2D = dancer.get_node_or_null("MaskContainer/Horns")

	if not mask_base:
		push_error("[MaskGenerator] MaskBase node not found on dancer")
		return

	# Load and apply base mask
	var base_texture := load(MASK_BASE_PATH) as Texture2D
	if base_texture:
		mask_base.texture = base_texture
		mask_base.modulate = mask_data.base_color
	else:
		push_error("[MaskGenerator] Failed to load MaskBase.png")

	# Load and apply pattern overlay
	if pattern and mask_data.pattern_name != "":
		# Try both .PNG and .png extensions
		var pattern_path := PATTERNS_PATH + mask_data.pattern_name + ".PNG"
		var pattern_texture := load(pattern_path) as Texture2D
		if not pattern_texture:
			pattern_path = PATTERNS_PATH + mask_data.pattern_name + ".png"
			pattern_texture = load(pattern_path) as Texture2D

		if pattern_texture:
			pattern.texture = pattern_texture
			pattern.modulate = mask_data.base_color
		else:
			push_warning("[MaskGenerator] Failed to load pattern: ", mask_data.pattern_name)

	# Show/hide horns based on devil status
	if horns:
		horns.visible = mask_data.has_horns


static func get_pattern_count() -> int:
	if not _patterns_loaded:
		_load_patterns()
	return _available_patterns.size()
