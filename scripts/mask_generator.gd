extends RefCounted
class_name MaskGenerator
## Generates and applies masks to dancers.
## Now rule-aware: devils match rule criteria, innocents don't.

const PATTERNS_PATH := "res://assets/MaskAssets/Patterns/"
const MASK_BASE_PATH := "res://assets/MaskAssets/MaskBase.png"

## Pattern categories for rule matching
const STRIPE_PATTERNS := ["Stripe1", "Stripe2", "Stripe3", "Stripe4", "Stripe5", "Stripe6", "Stripe7", "Stripe8"]
const DOT_PATTERNS := ["Dot1", "Dot2", "Dot3", "Dot4"]
const DIAMOND_PATTERNS := ["Diamond1", "Diamond2", "Diamond3", "Diamond4"]
const TRIANGLE_PATTERNS := ["Triangle1", "Triangle2", "Triangle3", "Triangle4", "Triangles"]
const EYE_PATTERNS := ["CircleEyes", "Cross Eyes", "SlitEyes"]

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


## Legacy method - generates random mask without rule awareness (kept for compatibility)
static func generate_mask(_is_devil: bool) -> MaskData:
	if not _patterns_loaded:
		_load_patterns()

	var data := MaskData.new()

	if _available_patterns.size() > 0:
		data.pattern_name = _available_patterns.pick_random()
	else:
		data.pattern_name = ""
		push_warning("[MaskGenerator] No patterns available!")

	# No longer give devils red tint - all masks are white pre-reveal
	data.base_color = Color.WHITE
	data.has_horns = false  # No horns asset exists

	return data


## Generate a mask based on active rule - devils match, innocents don't
static func generate_mask_for_rule(is_devil: bool, rule_id: String) -> MaskData:
	if not _patterns_loaded:
		_load_patterns()

	var data := MaskData.new()
	data.base_color = Color.WHITE  # Never red pre-reveal
	data.pattern_color = Color.WHITE  # Same color for all in rule-based levels
	data.has_horns = false  # No horns asset

	match rule_id:
		"striped_pattern":
			if is_devil:
				data.pattern_name = _get_pattern_from_category(STRIPE_PATTERNS)
			else:
				data.pattern_name = _get_pattern_not_in_category(STRIPE_PATTERNS)
		"dotted_pattern":
			if is_devil:
				data.pattern_name = _get_pattern_from_category(DOT_PATTERNS)
			else:
				data.pattern_name = _get_pattern_not_in_category(DOT_PATTERNS)
		"diamond_pattern":
			if is_devil:
				data.pattern_name = _get_pattern_from_category(DIAMOND_PATTERNS)
			else:
				data.pattern_name = _get_pattern_not_in_category(DIAMOND_PATTERNS)
		"triangle_pattern":
			if is_devil:
				data.pattern_name = _get_pattern_from_category(TRIANGLE_PATTERNS)
			else:
				data.pattern_name = _get_pattern_not_in_category(TRIANGLE_PATTERNS)
		"circle_eyes":
			if is_devil:
				data.pattern_name = _get_pattern_from_category(["CircleEyes"])
			else:
				data.pattern_name = _get_pattern_not_in_category(["CircleEyes"])
		"slit_eyes":
			if is_devil:
				data.pattern_name = _get_pattern_from_category(["SlitEyes"])
			else:
				data.pattern_name = _get_pattern_not_in_category(["SlitEyes"])
		_:
			# Unknown rule - fall back to random pattern
			if _available_patterns.size() > 0:
				data.pattern_name = _available_patterns.pick_random()
			else:
				data.pattern_name = ""
			print("[MaskGenerator] Unknown rule '%s', using random pattern" % rule_id)

	return data


## Get a random pattern from a specific category
static func _get_pattern_from_category(category: Array) -> String:
	# Filter to only patterns that actually exist in our loaded patterns
	var valid_patterns: Array[String] = []
	for pattern in category:
		if pattern in _available_patterns:
			valid_patterns.append(pattern)

	if valid_patterns.size() > 0:
		return valid_patterns.pick_random()

	# Fallback if no patterns from category exist
	push_warning("[MaskGenerator] No patterns found in category, using random")
	if _available_patterns.size() > 0:
		return _available_patterns.pick_random()
	return ""


## Get a random pattern NOT in a specific category
static func _get_pattern_not_in_category(category: Array) -> String:
	var valid_patterns: Array[String] = []
	for pattern in _available_patterns:
		if pattern not in category:
			valid_patterns.append(pattern)

	if valid_patterns.size() > 0:
		return valid_patterns.pick_random()

	# Fallback if all patterns are in the category
	push_warning("[MaskGenerator] All patterns are in excluded category, using random")
	if _available_patterns.size() > 0:
		return _available_patterns.pick_random()
	return ""


## Imposter colors - fully distinct colors for the pattern
const IMPOSTER_COLORS := [
	Color.RED,
	Color.BLUE,
	Color.GREEN,
	Color.ORANGE,
	Color.PURPLE,
	Color.CYAN,
]


## Generate uniform masks for Level 1 - all identical except imposter has different pattern color
static func generate_uniform_mask(is_imposter: bool, shared_pattern: String) -> MaskData:
	var data := MaskData.new()
	data.pattern_name = shared_pattern
	data.base_color = Color.WHITE
	data.has_horns = false

	if is_imposter:
		data.pattern_color = IMPOSTER_COLORS.pick_random()
		print("[MaskGenerator] IMPOSTER mask - pattern: %s, color: %s" % [shared_pattern, data.pattern_color])
	else:
		data.pattern_color = Color.WHITE
		print("[MaskGenerator] Innocent mask - pattern: %s, color: WHITE" % shared_pattern)

	return data


## Get a random pattern for uniform mask generation
static func get_random_pattern() -> String:
	if not _patterns_loaded:
		_load_patterns()

	if _available_patterns.size() > 0:
		return _available_patterns.pick_random()
	return ""


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
			# Use pattern_color for the pattern overlay (allows subtle imposter differences)
			pattern.modulate = mask_data.pattern_color
		else:
			push_warning("[MaskGenerator] Failed to load pattern: ", mask_data.pattern_name)

	# Show/hide horns based on devil status
	if horns:
		horns.visible = mask_data.has_horns


static func get_pattern_count() -> int:
	if not _patterns_loaded:
		_load_patterns()
	return _available_patterns.size()


## Generate masks for a specific tell type (used by level system)
static func generate_masks_for_level(dancer_count: int, devil_indices: Array[int], tell_type: String, pattern_limit: int) -> Array[MaskData]:
	if not _patterns_loaded:
		_load_patterns()

	var masks: Array[MaskData] = []
	var available: Array[String] = []
	for i in range(mini(pattern_limit, _available_patterns.size())):
		available.append(_available_patterns[i])

	match tell_type:
		"color":
			masks = _generate_color_tell(dancer_count, devil_indices, available)
		"pattern":
			masks = _generate_pattern_tell(dancer_count, devil_indices, available)
		"combo":
			masks = _generate_combo_tell(dancer_count, devil_indices, available)
		"category":
			masks = _generate_category_tell(dancer_count, devil_indices, available)
		"unique":
			masks = _generate_unique_tell(dancer_count, devil_indices, available)
		"shared_triangles":
			masks = _generate_shared_category_tell(dancer_count, devil_indices, TRIANGLE_PATTERNS)
		"shared_combo":
			masks = _generate_shared_combo_tell(dancer_count, devil_indices, available)
		"subtle":
			masks = _generate_subtle_tell(dancer_count, devil_indices, available)
		"shared_color":
			masks = _generate_shared_color_tell(dancer_count, devil_indices, available)
		"mixed":
			masks = _generate_shared_category_tell(dancer_count, devil_indices, STRIPE_PATTERNS)
		_:
			masks = _generate_color_tell(dancer_count, devil_indices, available)

	return masks


## Level 1: All same pattern, devils have colored pattern
static func _generate_color_tell(count: int, devils: Array[int], patterns: Array) -> Array[MaskData]:
	var masks: Array[MaskData] = []
	var shared_pattern: String = patterns.pick_random() if patterns.size() > 0 else ""
	var devil_color: Color = IMPOSTER_COLORS.pick_random()

	for i in range(count):
		var data := MaskData.new()
		data.pattern_name = shared_pattern
		data.base_color = Color.WHITE
		data.has_horns = false
		data.pattern_color = devil_color if i in devils else Color.WHITE
		masks.append(data)

	return masks


## Level 2: All same color, devils have different pattern
static func _generate_pattern_tell(count: int, devils: Array[int], patterns: Array) -> Array[MaskData]:
	var masks: Array[MaskData] = []
	if patterns.size() < 2:
		return _generate_color_tell(count, devils, patterns)

	var innocent_pattern: String = patterns[0]
	var devil_pattern: String = patterns[1]

	for i in range(count):
		var data := MaskData.new()
		data.pattern_name = devil_pattern if i in devils else innocent_pattern
		data.base_color = Color.WHITE
		data.pattern_color = Color.WHITE
		data.has_horns = false
		masks.append(data)

	return masks


## Level 3: Mix of colors/patterns, devil has unique combo
static func _generate_combo_tell(count: int, devils: Array[int], patterns: Array) -> Array[MaskData]:
	var masks: Array[MaskData] = []
	var colors: Array[Color] = [Color.WHITE, Color(0.9, 0.9, 1.0), Color(1.0, 0.95, 0.9)]
	var devil_color: Color = IMPOSTER_COLORS.pick_random()
	var devil_pattern: String = patterns.pick_random() if patterns.size() > 0 else ""

	for i in range(count):
		var data := MaskData.new()
		data.base_color = Color.WHITE
		data.has_horns = false
		if i in devils:
			data.pattern_name = devil_pattern
			data.pattern_color = devil_color
		else:
			data.pattern_name = patterns.pick_random() if patterns.size() > 0 else ""
			data.pattern_color = colors.pick_random()
			# Ensure innocents don't match devil combo
			var attempts := 0
			while data.pattern_name == devil_pattern and data.pattern_color == devil_color and attempts < 10:
				data.pattern_name = patterns.pick_random() if patterns.size() > 0 else ""
				data.pattern_color = colors.pick_random()
				attempts += 1
		masks.append(data)

	return masks


## Level 4: Devil uses a specific pattern category (diamonds)
static func _generate_category_tell(count: int, devils: Array[int], patterns: Array) -> Array[MaskData]:
	var masks: Array[MaskData] = []
	var devil_category: Array = DIAMOND_PATTERNS
	var innocent_patterns: Array[String] = []
	for p in patterns:
		if p not in devil_category:
			innocent_patterns.append(p)

	for i in range(count):
		var data := MaskData.new()
		data.base_color = Color.WHITE
		data.pattern_color = Color.WHITE
		data.has_horns = false
		if i in devils:
			var valid: Array[String] = []
			for p in devil_category:
				if p in patterns:
					valid.append(p)
			data.pattern_name = valid.pick_random() if valid.size() > 0 else patterns.pick_random()
		else:
			data.pattern_name = innocent_patterns.pick_random() if innocent_patterns.size() > 0 else patterns.pick_random()
		masks.append(data)

	return masks


## Level 5: Devil has ONE unique attribute
static func _generate_unique_tell(count: int, devils: Array[int], patterns: Array) -> Array[MaskData]:
	var masks: Array[MaskData] = []
	var devil_pattern: String = patterns.pick_random() if patterns.size() > 0 else ""
	var innocent_patterns: Array[String] = []
	for p in patterns:
		if p != devil_pattern:
			innocent_patterns.append(p)

	for i in range(count):
		var data := MaskData.new()
		data.base_color = Color.WHITE
		data.has_horns = false
		if i in devils:
			data.pattern_name = devil_pattern
			data.pattern_color = IMPOSTER_COLORS.pick_random()
		else:
			data.pattern_name = innocent_patterns.pick_random() if innocent_patterns.size() > 0 else patterns.pick_random()
			data.pattern_color = Color.WHITE
		masks.append(data)

	return masks


## Level 6+: Devils share a pattern category (triangles, stripes, etc)
static func _generate_shared_category_tell(count: int, devils: Array[int], category: Array) -> Array[MaskData]:
	var masks: Array[MaskData] = []
	var valid_devil_patterns: Array[String] = []
	for p in _available_patterns:
		if p in category:
			valid_devil_patterns.append(p)

	var innocent_patterns: Array[String] = []
	for p in _available_patterns:
		if p not in category:
			innocent_patterns.append(p)

	for i in range(count):
		var data := MaskData.new()
		data.base_color = Color.WHITE
		data.pattern_color = Color.WHITE
		data.has_horns = false
		if i in devils:
			data.pattern_name = valid_devil_patterns.pick_random() if valid_devil_patterns.size() > 0 else ""
		else:
			data.pattern_name = innocent_patterns.pick_random() if innocent_patterns.size() > 0 else ""
		masks.append(data)

	return masks


## Level 7: Devils share both a pattern AND color
static func _generate_shared_combo_tell(count: int, devils: Array[int], patterns: Array) -> Array[MaskData]:
	var masks: Array[MaskData] = []
	var devil_pattern: String = patterns.pick_random() if patterns.size() > 0 else ""
	var devil_color: Color = IMPOSTER_COLORS.pick_random()

	for i in range(count):
		var data := MaskData.new()
		data.base_color = Color.WHITE
		data.has_horns = false
		if i in devils:
			data.pattern_name = devil_pattern
			data.pattern_color = devil_color
		else:
			data.pattern_name = patterns.pick_random() if patterns.size() > 0 else ""
			data.pattern_color = Color.WHITE
		masks.append(data)

	return masks


## Level 8: Subtle differences (harder to spot)
static func _generate_subtle_tell(count: int, devils: Array[int], patterns: Array) -> Array[MaskData]:
	var masks: Array[MaskData] = []
	var devil_color := Color(0.95, 0.85, 0.85)  # Subtle pink tint

	for i in range(count):
		var data := MaskData.new()
		data.pattern_name = patterns.pick_random() if patterns.size() > 0 else ""
		data.base_color = Color.WHITE
		data.has_horns = false
		data.pattern_color = devil_color if i in devils else Color.WHITE
		masks.append(data)

	return masks


## Level 9: All devils share the same color
static func _generate_shared_color_tell(count: int, devils: Array[int], patterns: Array) -> Array[MaskData]:
	var masks: Array[MaskData] = []
	var devil_color: Color = IMPOSTER_COLORS.pick_random()

	for i in range(count):
		var data := MaskData.new()
		data.pattern_name = patterns.pick_random() if patterns.size() > 0 else ""
		data.base_color = Color.WHITE
		data.has_horns = false
		data.pattern_color = devil_color if i in devils else Color.WHITE
		masks.append(data)

	return masks
