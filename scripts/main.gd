extends Node2D
## Main game scene - handles gameplay, dancers, and round logic.

## Node references
@onready var dancer_path: Path2D = $GameArea/DancerPath
@onready var dancers_container: Node2D = $GameArea/DancersContainer
@onready var hud: Control = $CanvasLayer/HUD
@onready var timer_bar: ProgressBar = $CanvasLayer/HUD/TopBar/TimerBar
@onready var score_label: Label = $CanvasLayer/HUD/TopBar/ScoreLabel
@onready var level_label: Label = $CanvasLayer/HUD/TopBar/LevelLabel
@onready var rule_text: Label = $CanvasLayer/HUD/RuleCard/VBox/RuleText
@onready var devils_counter: Label = $CanvasLayer/HUD/DevilsCounter
@onready var pause_overlay: ColorRect = $CanvasLayer/PauseOverlay
@onready var resume_button: Button = $CanvasLayer/PauseOverlay/PauseMenu/VBox/ResumeButton
@onready var quit_to_menu_button: Button = $CanvasLayer/PauseOverlay/PauseMenu/VBox/QuitButton
@onready var quit_game_button: Button = $CanvasLayer/PauseOverlay/PauseMenu/VBox/QuitGameButton


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

	## Setup ellipse path for dancers
	_setup_dancer_path()

	## Start the first round
	_start_round()


func _setup_dancer_path() -> void:
	## Create an elliptical path around the center (fire pit area)
	var curve := Curve2D.new()
	var center := Vector2.ZERO
	var radius_x := 350.0
	var radius_y := 200.0
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
	print("[Main] Dancer path created with ", segments, " segments")


func _start_round() -> void:
	print("[Main] Starting round ", GameManager.current_level)

	## Select rules for this level
	RuleSystem.select_rules_for_level(GameManager.current_level)

	## Update HUD
	level_label.text = "Level " + str(GameManager.current_level)
	_update_score_display()

	## Start the timer
	GameManager.start_timer()

	## TODO: Spawn dancers based on level parameters
	_spawn_placeholder_message()


func _spawn_placeholder_message() -> void:
	## Temporary: Show placeholder until dancer system is implemented
	devils_counter.text = "Devils: ?/?"
	print("[Main] Dancer spawning not yet implemented")


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
