extends Node2D
## Main game scene - handles gameplay, dancers, and round logic.

## Preload dancer scene
const DancerScene := preload("res://scenes/dancer.tscn")

## Node references
@onready var dancer_path: Path2D = $GameArea/DancerPath
@onready var dancers_container: Node2D = $GameArea/DancersContainer
@onready var hud: Control = $CanvasLayer/HUD
@onready var timer_bar: ProgressBar = $CanvasLayer/HUD/TopBar/TimerBar
@onready var score_label: Label = $CanvasLayer/HUD/TopBar/ScoreLabel
@onready var level_label: Label = $CanvasLayer/HUD/TopBar/LevelLabel
@onready var rule_card: Control = $CanvasLayer/HUD/RuleCard
@onready var rule_text: Label = $CanvasLayer/HUD/RuleCard/VBox/RuleText
@onready var devils_counter: Label = $CanvasLayer/HUD/DevilsCounter
@onready var pause_overlay: ColorRect = $CanvasLayer/PauseOverlay
@onready var resume_button: Button = $CanvasLayer/PauseOverlay/PauseMenu/VBox/ResumeButton
@onready var quit_to_menu_button: Button = $CanvasLayer/PauseOverlay/PauseMenu/VBox/QuitButton
@onready var quit_game_button: Button = $CanvasLayer/PauseOverlay/PauseMenu/VBox/QuitGameButton

## Dancer tracking
var dancers: Array[Dancer] = []
var devils_remaining: int = 0
var total_devils: int = 0


func _ready() -> void:
	print("[Main] Game scene ready")

	## Connect GameManager signals
	GameManager.timer_tick.connect(_on_timer_tick)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.timer_expired.connect(_on_timer_expired)
	GameManager.round_won.connect(_on_round_won)
	GameManager.game_over.connect(_on_game_over)
	RuleSystem.rules_changed.connect(_on_rules_changed)

	## Connect pause buttons
	resume_button.pressed.connect(_on_resume_pressed)
	quit_to_menu_button.pressed.connect(_on_quit_to_menu_pressed)
	quit_game_button.pressed.connect(_on_quit_game_pressed)

	## Connect viewport resize signal
	get_viewport().size_changed.connect(_on_viewport_resized)

	## Setup ellipse path for dancers
	_setup_dancer_path()

	## Start the first round
	_start_round()


func _on_viewport_resized() -> void:
	## Re-center game area when viewport changes
	var viewport_size := get_viewport_rect().size
	var game_area: Node2D = $GameArea
	game_area.position = viewport_size / 2
	print("[Main] Viewport resized to: ", viewport_size)


func _setup_dancer_path() -> void:
	## Center the game area based on viewport size
	var viewport_size := get_viewport_rect().size
	var game_area: Node2D = $GameArea
	game_area.position = viewport_size / 2

	## Create an elliptical path around the center (fire pit area)
	## Scale ellipse to fit viewport (roughly 40% of viewport width/height)
	var curve := Curve2D.new()
	var center := Vector2.ZERO
	var radius_x := viewport_size.x * 0.28
	var radius_y := viewport_size.y * 0.25
	var segments := 32

	for i in range(segments):
		var angle := (float(i) / segments) * TAU
		var point := Vector2(
			center.x + cos(angle) * radius_x,
			center.y + sin(angle) * radius_y
		)
		curve.add_point(point)

	## Close the loop
	curve.add_point(curve.get_point_position(0))
	dancer_path.curve = curve
	print("[Main] Dancer path created - viewport: ", viewport_size, " ellipse: ", radius_x, "x", radius_y)


func _start_round() -> void:
	print("[Main] Starting round ", GameManager.current_level)

	## Clear existing dancers
	_clear_dancers()

	## Level 1 has no rules (pure spot-the-difference)
	## Later levels use the rule system
	if GameManager.current_level == 1:
		RuleSystem.clear_rules()
		rule_card.visible = false
	else:
		RuleSystem.select_rules_for_level(GameManager.current_level)
		rule_card.visible = true

	## Update HUD
	level_label.text = "Level " + str(GameManager.current_level)
	_update_score_display()

	## Spawn dancers
	_spawn_dancers()

	## Start the timer
	GameManager.start_timer()


func _clear_dancers() -> void:
	for dancer in dancers:
		if is_instance_valid(dancer):
			dancer.queue_free()
	dancers.clear()
	devils_remaining = 0
	total_devils = 0


func _spawn_dancers() -> void:
	var dancer_count := _get_dancer_count_for_level()
	var devil_count := _get_devil_count_for_level()

	## Determine which dancers are devils (random selection)
	var devil_indices: Array[int] = []
	while devil_indices.size() < devil_count:
		var idx := randi() % dancer_count
		if idx not in devil_indices:
			devil_indices.append(idx)

	## Level 1: Uniform masks (spot the difference by color)
	## Later levels: Rule-based pattern differences
	var is_level_1 := GameManager.current_level == 1
	var shared_pattern := ""
	var visual_rule := ""

	if is_level_1:
		shared_pattern = MaskGenerator.get_random_pattern()
		print("[Main] Level 1 - Uniform masks with pattern: ", shared_pattern)
	else:
		visual_rule = _get_visual_rule_from_active()
		print("[Main] Using visual rule for masks: ", visual_rule)

	## Spawn dancers evenly distributed around the path
	for i in range(dancer_count):
		var dancer: Dancer = DancerScene.instantiate()
		dancer.is_devil = i in devil_indices

		## Generate mask data
		var mask_data: MaskData
		if is_level_1:
			mask_data = MaskGenerator.generate_uniform_mask(dancer.is_devil, shared_pattern)
		else:
			mask_data = MaskGenerator.generate_mask_for_rule(dancer.is_devil, visual_rule)
		dancer.mask_data = mask_data

		## Connect signals
		dancer.clicked.connect(_on_dancer_clicked)
		dancer.hovered.connect(_on_dancer_hovered)

		## Add to path FIRST (PathFollow2D must be child of Path2D before setting progress_ratio)
		dancer_path.add_child(dancer)
		dancers.append(dancer)

		## Now set progress_ratio (after in scene tree)
		dancer.progress_ratio = float(i) / dancer_count

		## Apply mask after adding to tree
		MaskGenerator.apply_mask_to_dancer(dancer, mask_data)

	## Track devils
	total_devils = devil_count
	devils_remaining = devil_count
	_update_devils_counter()

	print("[Main] Spawned ", dancer_count, " dancers, ", devil_count, " devils")


## Get the first visual rule from active rules (for mask generation)
func _get_visual_rule_from_active() -> String:
	var active := RuleSystem.get_active_rules()
	for rule_id in active:
		var rule_data: Dictionary = RuleSystem.get_rule_by_id(rule_id)
		if rule_data.get("type", "") == "visual":
			return rule_id
	# Default to striped_pattern if no visual rule active
	return "striped_pattern"


func _get_dancer_count_for_level() -> int:
	## Level 1: 5 dancers (4 innocents + 1 imposter)
	if GameManager.current_level == 1:
		return 5
	## Later levels: Start with 6, increase by 1 every 2 levels, max 12
	return mini(6 + ((GameManager.current_level - 2) / 2), 12)


func _get_devil_count_for_level() -> int:
	## Level 1: Exactly 1 imposter
	if GameManager.current_level == 1:
		return 1
	## Later levels: About 30% devils, minimum 1
	var count := _get_dancer_count_for_level()
	return maxi(1, int(count * 0.3))


func _on_dancer_clicked(dancer: Dancer) -> void:
	if dancer.is_revealed:
		return

	var was_correct := dancer.is_devil
	dancer.reveal(was_correct)

	if was_correct:
		print("[Main] Correct! Found a devil!")
		GameManager.on_correct_guess()
		devils_remaining -= 1
		_update_devils_counter()

		## Check win condition
		if devils_remaining <= 0:
			print("[Main] All devils found!")
			GameManager.stop_timer()
			GameManager.advance_level()
	else:
		print("[Main] Wrong! That was an innocent dancer!")
		GameManager.on_wrong_guess()


func _on_dancer_hovered(dancer: Dancer, is_hovered: bool) -> void:
	## Could add UI feedback here (e.g., cursor change, tooltip)
	pass


func _update_devils_counter() -> void:
	var found := total_devils - devils_remaining
	devils_counter.text = "Devils: " + str(found) + "/" + str(total_devils)


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()


func _toggle_pause() -> void:
	if GameManager.current_state == GameManager.State.PLAYING:
		GameManager.pause_game()
		pause_overlay.visible = true
		get_tree().paused = true
		resume_button.grab_focus()
		print("[Main] Game paused")
	elif GameManager.current_state == GameManager.State.PAUSED:
		_resume_game()


func _resume_game() -> void:
	GameManager.resume_game()
	pause_overlay.visible = false
	get_tree().paused = false
	print("[Main] Game resumed")


func _on_resume_pressed() -> void:
	_resume_game()


func _on_quit_to_menu_pressed() -> void:
	print("[Main] Quit to menu pressed")
	get_tree().paused = false
	GameManager.return_to_menu()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_quit_game_pressed() -> void:
	print("[Main] Quit game pressed")
	get_tree().paused = false
	get_tree().quit()


func _on_timer_tick(time_remaining: float) -> void:
	## Update timer bar
	var progress := (time_remaining / GameManager.round_duration) * 100.0
	timer_bar.value = progress

	## Change color based on urgency
	if progress < 25:
		timer_bar.modulate = Color.RED
	elif progress < 50:
		timer_bar.modulate = Color.YELLOW
	else:
		timer_bar.modulate = Color.GREEN


func _on_score_changed(new_score: int) -> void:
	_update_score_display()


func _update_score_display() -> void:
	score_label.text = "Score: " + str(GameManager.score)


func _on_rules_changed(active_rules: Array) -> void:
	var descriptions := RuleSystem.get_rule_descriptions()
	if descriptions.is_empty():
		rule_text.text = "No rules active"
	else:
		rule_text.text = "\n".join(descriptions)


func _on_timer_expired() -> void:
	print("[Main] Timer expired - round failed")
	## TODO: Handle round failure (show remaining devils, restart or game over)
	_on_game_over()


func _on_round_won() -> void:
	print("[Main] Round won!")
	## TODO: Show victory animation, then start next round
	_start_round()


func _on_game_over() -> void:
	print("[Main] Game over!")
	GameManager.end_game()
	## TODO: Transition to game over screen
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")
