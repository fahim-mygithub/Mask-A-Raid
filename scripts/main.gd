extends Node2D
## Main game scene - handles gameplay, dancers, and round logic.

## Preload scenes
const DancerScene := preload("res://scenes/dancer.tscn")
const LevelTransitionScene := preload("res://scenes/level_transition.tscn")

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

## Level transition overlay
var level_transition: LevelTransition = null

## Dancer tracking
var dancers: Array[Dancer] = []
var devils_remaining: int = 0
var total_devils: int = 0

## Current level config
var current_config: Dictionary = {}

## Game state
var is_transitioning: bool = false
var level_start_score: int = 0


func _ready() -> void:
	print("[Main] Game scene ready")

	## Connect GameManager signals
	GameManager.timer_tick.connect(_on_timer_tick)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.timer_expired.connect(_on_timer_expired)

	## Connect pause buttons
	resume_button.pressed.connect(_on_resume_pressed)
	quit_to_menu_button.pressed.connect(_on_quit_to_menu_pressed)
	quit_game_button.pressed.connect(_on_quit_game_pressed)

	## Connect viewport resize signal
	get_viewport().size_changed.connect(_on_viewport_resized)

	## Setup ellipse path for dancers
	_setup_dancer_path()

	## Create level transition overlay
	_setup_level_transition()

	## Show first level intro
	_show_level_intro()


func _setup_level_transition() -> void:
	level_transition = LevelTransitionScene.instantiate()
	add_child(level_transition)
	level_transition.continue_pressed.connect(_on_transition_continue)
	level_transition.countdown_finished.connect(_on_countdown_finished)


func _on_viewport_resized() -> void:
	var viewport_size := get_viewport_rect().size
	var game_area: Node2D = $GameArea
	game_area.position = viewport_size / 2
	print("[Main] Viewport resized to: ", viewport_size)


func _setup_dancer_path() -> void:
	var viewport_size := get_viewport_rect().size
	var game_area: Node2D = $GameArea
	game_area.position = viewport_size / 2

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

	curve.add_point(curve.get_point_position(0))
	dancer_path.curve = curve
	print("[Main] Dancer path created - viewport: ", viewport_size, " ellipse: ", radius_x, "x", radius_y)


func _show_level_intro() -> void:
	is_transitioning = true
	current_config = LevelConfig.get_level(GameManager.current_level)
	level_transition.show_level_intro(GameManager.current_level, current_config)

	## Update HUD
	level_label.text = "Level " + str(GameManager.current_level)
	_update_score_display()

	## Show/hide rule card based on config
	if current_config.get("show_rule", false):
		rule_card.visible = true
		rule_text.text = current_config.get("rule_text", "")
	else:
		rule_card.visible = false


func _on_countdown_finished() -> void:
	is_transitioning = false
	_start_round()


func _start_round() -> void:
	print("[Main] Starting round ", GameManager.current_level)

	## Store score at level start for calculating level score
	level_start_score = GameManager.score

	## Clear existing dancers
	_clear_dancers()

	## Spawn dancers using level config
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
	var dancer_count: int = current_config.get("dancers", 5)
	var devil_count: int = current_config.get("devils", 1)
	var speed_mult: float = current_config.get("speed", 1.0)
	var pattern_count: int = current_config.get("pattern_count", 24)
	var tell_type: String = current_config.get("tell_type", "color")

	## Determine which dancers are devils (random selection)
	var devil_indices: Array[int] = []
	while devil_indices.size() < devil_count:
		var idx := randi() % dancer_count
		if idx not in devil_indices:
			devil_indices.append(idx)

	## Generate all masks using the tell type system
	var masks := MaskGenerator.generate_masks_for_level(dancer_count, devil_indices, tell_type, pattern_count)

	print("[Main] Level %d - %d dancers, %d devils, tell: %s" % [GameManager.current_level, dancer_count, devil_count, tell_type])

	## Spawn dancers evenly distributed around the path
	for i in range(dancer_count):
		var dancer: Dancer = DancerScene.instantiate()
		dancer.is_devil = i in devil_indices
		dancer.movement_speed = 0.08 * speed_mult

		## Apply pre-generated mask
		if i < masks.size():
			dancer.mask_data = masks[i]
		else:
			dancer.mask_data = MaskData.new()

		## Connect signals
		dancer.clicked.connect(_on_dancer_clicked)
		dancer.hovered.connect(_on_dancer_hovered)

		## Add to path
		dancer_path.add_child(dancer)
		dancers.append(dancer)

		## Set position on path
		dancer.progress_ratio = float(i) / dancer_count

		## Apply mask visuals
		MaskGenerator.apply_mask_to_dancer(dancer, dancer.mask_data)

	## Track devils
	total_devils = devil_count
	devils_remaining = devil_count
	_update_devils_counter()

	print("[Main] Spawned ", dancer_count, " dancers, ", devil_count, " devils")


func _on_dancer_clicked(dancer: Dancer) -> void:
	if dancer.is_revealed or is_transitioning:
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
			_on_level_complete()
	else:
		print("[Main] Wrong! That was an innocent dancer!")
		GameManager.on_wrong_guess()


func _on_dancer_hovered(_dancer: Dancer, _is_hovered: bool) -> void:
	pass


func _update_devils_counter() -> void:
	var found := total_devils - devils_remaining
	devils_counter.text = "Devils: " + str(found) + "/" + str(total_devils)


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause") and not is_transitioning:
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
	var progress := (time_remaining / GameManager.round_duration) * 100.0
	timer_bar.value = progress

	if progress < 25:
		timer_bar.modulate = Color.RED
	elif progress < 50:
		timer_bar.modulate = Color.YELLOW
	else:
		timer_bar.modulate = Color.GREEN


func _on_score_changed(_new_score: int) -> void:
	_update_score_display()


func _update_score_display() -> void:
	score_label.text = "Score: " + str(GameManager.score)


func _on_timer_expired() -> void:
	print("[Main] Timer expired - round failed")
	is_transitioning = true
	## Reveal remaining devils
	for dancer in dancers:
		if dancer.is_devil and not dancer.is_revealed:
			dancer.reveal(true)
	## Wait a moment then go to game over
	await get_tree().create_timer(2.0).timeout
	GameManager.end_game()
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")


func _on_level_complete() -> void:
	is_transitioning = true

	## Calculate scores
	var time_bonus := int(GameManager.time_remaining * 25)
	var level_score := GameManager.score - level_start_score + time_bonus

	## Add time bonus
	GameManager.add_score(time_bonus)

	## Check if this was the final level
	if LevelConfig.is_final_level(GameManager.current_level):
		print("[Main] Game complete! You win!")
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://scenes/you_win.tscn")
	else:
		## Show level complete overlay
		level_transition.show_level_complete(total_devils, total_devils, time_bonus, level_score)


func _on_transition_continue() -> void:
	## Advance to next level
	GameManager.current_level += 1
	print("[Main] Advancing to level ", GameManager.current_level)

	## Show next level intro
	_show_level_intro()
