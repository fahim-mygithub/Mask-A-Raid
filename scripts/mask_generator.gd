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
