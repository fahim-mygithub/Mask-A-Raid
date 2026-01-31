# Level Progression Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement 10-level progression with transitions, pattern scaling, and win screen.

**Architecture:** LevelConfig holds all level data. Main.gd queries config for spawning. Transition overlays handle level flow. Win screen after level 10.

**Tech Stack:** Godot 4.6, GDScript, Scene-based UI overlays

---

## Task 1: Create LevelConfig Data

**Files:**
- Create: `scripts/level_config.gd`

**Step 1: Create level configuration class**

```gdscript
extends RefCounted
class_name LevelConfig
## Static level configuration data for all 10 levels.

## Level data structure
const LEVELS: Array[Dictionary] = [
	{}, # Index 0 unused (levels start at 1)
	# Level 1: Spot the Odd One
	{
		"name": "Spot the Odd One",
		"dancers": 5,
		"devils": 1,
		"speed": 0.8,
		"pattern_count": 1,
		"tell_type": "color",
		"tip": "One mask has a different COLOR!",
		"show_rule": false,
	},
	# Level 2: Pattern Recognition
	{
		"name": "Pattern Recognition",
		"dancers": 5,
		"devils": 1,
		"speed": 0.85,
		"pattern_count": 2,
		"tell_type": "pattern",
		"tip": "Look for a different PATTERN!",
		"show_rule": false,
	},
	# Level 3: Sharp Eyes
	{
		"name": "Sharp Eyes",
		"dancers": 6,
		"devils": 1,
		"speed": 1.0,
		"pattern_count": 3,
		"tell_type": "combo",
		"tip": "Find the UNIQUE combination!",
		"show_rule": false,
	},
	# Level 4: New Patterns
	{
		"name": "New Patterns",
		"dancers": 6,
		"devils": 1,
		"speed": 1.0,
		"pattern_count": 4,
		"tell_type": "category",
		"tip": "One uses a different pattern type!",
		"show_rule": false,
	},
	# Level 5: Combination Lock
	{
		"name": "Combination Lock",
		"dancers": 7,
		"devils": 1,
		"speed": 1.0,
		"pattern_count": 5,
		"tell_type": "unique",
		"tip": "Find the ONE unique attribute!",
		"show_rule": false,
	},
	# Level 6: Double Trouble
	{
		"name": "Double Trouble",
		"dancers": 8,
		"devils": 2,
		"speed": 1.0,
		"pattern_count": 6,
		"tell_type": "shared_triangles",
		"tip": "Both devils have TRIANGLE patterns!",
		"show_rule": true,
		"rule_text": "Devils have TRIANGLE patterns",
	},
	# Level 7: Trust Issues
	{
		"name": "Trust Issues",
		"dancers": 8,
		"devils": 2,
		"speed": 1.1,
		"pattern_count": 6,
		"tell_type": "shared_combo",
		"tip": "Devils share a color AND pattern!",
		"show_rule": true,
		"rule_text": "Devils share the same style",
	},
	# Level 8: Growing Crowd
	{
		"name": "Growing Crowd",
		"dancers": 9,
		"devils": 2,
		"speed": 1.1,
		"pattern_count": 7,
		"tell_type": "subtle",
		"tip": "Differences are getting subtle...",
		"show_rule": false,
	},
	# Level 9: Triple Threat
	{
		"name": "Triple Threat",
		"dancers": 9,
		"devils": 3,
		"speed": 1.15,
		"pattern_count": 8,
		"tell_type": "shared_color",
		"tip": "THREE devils with the same COLOR!",
		"show_rule": true,
		"rule_text": "Devils share the same COLOR",
	},
	# Level 10: The Final Dance
	{
		"name": "The Final Dance",
		"dancers": 10,
		"devils": 3,
		"speed": 1.2,
		"pattern_count": 24,  # All patterns
		"tell_type": "mixed",
		"tip": "Use everything you've learned!",
		"show_rule": true,
		"rule_text": "Devils have STRIPE patterns",
	},
]

const MAX_LEVEL: int = 10

static func get_level(level_num: int) -> Dictionary:
	if level_num < 1 or level_num > MAX_LEVEL:
		push_error("[LevelConfig] Invalid level: %d" % level_num)
		return LEVELS[1]
	return LEVELS[level_num]

static func get_level_name(level_num: int) -> String:
	return get_level(level_num).get("name", "Unknown")

static func is_final_level(level_num: int) -> bool:
	return level_num >= MAX_LEVEL
```

**Step 2: Verify file created**

Run: Launch Godot editor to check for parse errors

---

## Task 2: Create Level Transition Overlay Scene

**Files:**
- Create: `scenes/level_transition.tscn`
- Create: `scripts/level_transition.gd`

**Step 1: Create the transition script**

```gdscript
extends CanvasLayer
class_name LevelTransition
## Handles level complete and level intro overlays.

signal continue_pressed
signal start_pressed

@onready var complete_panel: PanelContainer = $CompletePanel
@onready var intro_panel: PanelContainer = $IntroPanel
@onready var countdown_label: Label = $CountdownLabel

@onready var devils_found_label: Label = $CompletePanel/VBox/DevilsFoundLabel
@onready var time_bonus_label: Label = $CompletePanel/VBox/TimeBonusLabel
@onready var score_label: Label = $CompletePanel/VBox/ScoreLabel
@onready var continue_button: Button = $CompletePanel/VBox/ContinueButton

@onready var level_number_label: Label = $IntroPanel/VBox/LevelNumberLabel
@onready var level_name_label: Label = $IntroPanel/VBox/LevelNameLabel
@onready var find_label: Label = $IntroPanel/VBox/FindLabel
@onready var tip_label: Label = $IntroPanel/VBox/TipLabel
@onready var rule_label: Label = $IntroPanel/VBox/RuleLabel
@onready var start_button: Button = $IntroPanel/VBox/StartButton

var auto_continue_timer: float = 0.0
const AUTO_CONTINUE_DELAY: float = 3.0


func _ready() -> void:
	hide_all()
	continue_button.pressed.connect(_on_continue_pressed)
	start_button.pressed.connect(_on_start_pressed)


func _process(delta: float) -> void:
	if auto_continue_timer > 0.0:
		auto_continue_timer -= delta
		if auto_continue_timer <= 0.0:
			_on_continue_pressed()


func hide_all() -> void:
	complete_panel.visible = false
	intro_panel.visible = false
	countdown_label.visible = false


func show_level_complete(devils_found: int, total_devils: int, time_bonus: int, level_score: int) -> void:
	hide_all()
	devils_found_label.text = "Devils Found: %d/%d" % [devils_found, total_devils]
	time_bonus_label.text = "Time Bonus: +%d" % time_bonus
	score_label.text = "Score: +%d" % level_score
	complete_panel.visible = true
	continue_button.grab_focus()
	auto_continue_timer = AUTO_CONTINUE_DELAY


func show_level_intro(level_num: int, config: Dictionary) -> void:
	hide_all()
	level_number_label.text = "LEVEL %d" % level_num
	level_name_label.text = "\"%s\"" % config.get("name", "")
	find_label.text = "Find: %d imposter%s" % [config.get("devils", 1), "s" if config.get("devils", 1) > 1 else ""]
	tip_label.text = config.get("tip", "")

	if config.get("show_rule", false):
		rule_label.text = config.get("rule_text", "")
		rule_label.visible = true
	else:
		rule_label.visible = false

	intro_panel.visible = true
	start_button.grab_focus()


func show_countdown() -> void:
	hide_all()
	countdown_label.visible = true

	var tween := create_tween()
	countdown_label.text = "3"
	tween.tween_interval(1.0)
	tween.tween_callback(func(): countdown_label.text = "2")
	tween.tween_interval(1.0)
	tween.tween_callback(func(): countdown_label.text = "1")
	tween.tween_interval(1.0)
	tween.tween_callback(func(): countdown_label.text = "GO!")
	tween.tween_interval(0.5)
	tween.tween_callback(func(): hide_all())


func _on_continue_pressed() -> void:
	auto_continue_timer = 0.0
	continue_pressed.emit()


func _on_start_pressed() -> void:
	start_pressed.emit()
```

**Step 2: Create the scene via MCP**

Use Godot MCP to create scene structure.

---

## Task 3: Create Win Screen Scene

**Files:**
- Create: `scenes/you_win.tscn`
- Create: `scripts/you_win.gd`

**Step 1: Create the win screen script**

```gdscript
extends Control
## Victory screen shown after completing Level 10.

@onready var score_label: Label = $CenterContainer/VBox/ScoreLabel
@onready var play_again_button: Button = $CenterContainer/VBox/ButtonsContainer/PlayAgainButton
@onready var menu_button: Button = $CenterContainer/VBox/ButtonsContainer/MenuButton


func _ready() -> void:
	print("[YouWin] Victory screen ready")
	score_label.text = "Final Score: %d" % GameManager.score

	play_again_button.pressed.connect(_on_play_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	play_again_button.grab_focus()


func _on_play_again_pressed() -> void:
	print("[YouWin] Play again pressed")
	GameManager.return_to_menu()
	GameManager.start_new_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_menu_pressed() -> void:
	print("[YouWin] Menu pressed")
	GameManager.return_to_menu()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

---

## Task 4: Update MaskGenerator for Tell Types

**Files:**
- Modify: `scripts/mask_generator.gd`

**Step 1: Add tell-type generation methods**

Add these methods to support different level tell types:

```gdscript
## Generate masks for a specific tell type
static func generate_masks_for_level(dancer_count: int, devil_indices: Array[int], tell_type: String, pattern_limit: int) -> Array[MaskData]:
	if not _patterns_loaded:
		_load_patterns()

	var masks: Array[MaskData] = []
	var available := _available_patterns.slice(0, mini(pattern_limit, _available_patterns.size()))

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


static func _generate_combo_tell(count: int, devils: Array[int], patterns: Array) -> Array[MaskData]:
	var masks: Array[MaskData] = []
	var colors := [Color.WHITE, Color(0.9, 0.9, 1.0), Color(1.0, 0.95, 0.9)]
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
			while data.pattern_name == devil_pattern and data.pattern_color == devil_color:
				data.pattern_name = patterns.pick_random() if patterns.size() > 0 else ""
				data.pattern_color = colors.pick_random()
		masks.append(data)

	return masks


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
			var valid := devil_category.filter(func(p): return p in patterns)
			data.pattern_name = valid.pick_random() if valid.size() > 0 else patterns.pick_random()
		else:
			data.pattern_name = innocent_patterns.pick_random() if innocent_patterns.size() > 0 else patterns.pick_random()
		masks.append(data)

	return masks


static func _generate_unique_tell(count: int, devils: Array[int], patterns: Array) -> Array[MaskData]:
	var masks: Array[MaskData] = []
	var devil_pattern: String = patterns.pick_random() if patterns.size() > 0 else ""
	var innocent_patterns := patterns.filter(func(p): return p != devil_pattern)

	for i in range(count):
		var data := MaskData.new()
		data.base_color = Color.WHITE
		data.pattern_color = Color.WHITE
		data.has_horns = false
		if i in devils:
			data.pattern_name = devil_pattern
			data.pattern_color = IMPOSTER_COLORS.pick_random()
		else:
			data.pattern_name = innocent_patterns.pick_random() if innocent_patterns.size() > 0 else patterns.pick_random()
		masks.append(data)

	return masks


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


static func _generate_subtle_tell(count: int, devils: Array[int], patterns: Array) -> Array[MaskData]:
	var masks: Array[MaskData] = []
	var devil_color := Color(0.95, 0.9, 0.9)  # Very subtle pink

	for i in range(count):
		var data := MaskData.new()
		data.pattern_name = patterns.pick_random() if patterns.size() > 0 else ""
		data.base_color = Color.WHITE
		data.has_horns = false
		data.pattern_color = devil_color if i in devils else Color.WHITE
		masks.append(data)

	return masks


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
```

---

## Task 5: Update Main.gd for Level System

**Files:**
- Modify: `scripts/main.gd`

**Step 1: Integrate LevelConfig and transitions**

Replace spawn logic and add transition handling. Key changes:

1. Add transition overlay node reference
2. Use LevelConfig for level parameters
3. Add transition flow between levels
4. Check for win condition at level 10

---

## Task 6: Create Scene Files with MCP

**Files:**
- Create: `scenes/level_transition.tscn`
- Create: `scenes/you_win.tscn`

Use Godot MCP tools to create the UI scenes.

---

## Task 7: Integration and Testing

**Step 1: Run game and test each level**

- Level 1: Color tell works
- Level 2: Pattern tell works
- Level 3: Combo tell works
- Levels 4-10: Progression and transitions work
- Level 10 complete: Win screen appears

**Step 2: Commit all changes**

```bash
git add .
git commit -m "Add 10-level progression with transitions and win screen"
git push origin main
```

---

## Execution Summary

| Task | Description | Est. Complexity |
|------|-------------|-----------------|
| 1 | LevelConfig data | Simple |
| 2 | Transition overlay | Medium |
| 3 | Win screen | Simple |
| 4 | MaskGenerator tell types | Medium |
| 5 | Main.gd integration | Medium |
| 6 | Create scenes with MCP | Simple |
| 7 | Test and commit | Simple |
