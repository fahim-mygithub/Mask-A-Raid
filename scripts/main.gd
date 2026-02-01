extends Node2D
## Main game scene - handles gameplay, dancers, and round logic.

## Preload scenes and scripts
const DancerScene := preload("res://scenes/dancer.tscn")
const LevelTransitionScene := preload("res://scenes/level_transition.tscn")
const FireAnimationLoaderScript := preload("res://scripts/autoload/fire_animation_loader.gd")
const SpearScene := preload("res://scenes/spear.tscn")
const BallistaScene := preload("res://scenes/ballista.tscn")
const DevilIconTexture := preload("res://assets/MaskAssets/hitmarkers/Transparent_Mask.png")
const CrossOutTexture := preload("res://assets/MaskAssets/hitmarkers/RedSpearImpact005.png")

## Node references
@onready var background: Sprite2D = $Background
@onready var trees_layer: Sprite2D = $TreesLayer
@onready var level_music: AudioStreamPlayer = $LevelMusic
@onready var win_sound: AudioStreamPlayer = $WinSound
@onready var lose_sound: AudioStreamPlayer = $LoseSound
@onready var dancer_path: Path2D = $GameArea/DancerPath
@onready var dancers_container: Node2D = $GameArea/DancersContainer
@onready var fire_pit: Node2D = $GameArea/FirePit
@onready var hud: Control = $CanvasLayer/HUD
@onready var timer_label: Label = $CanvasLayer/HUD/TimerLabel
@onready var score_label: Label = $CanvasLayer/HUD/TopBar/ScoreLabel
@onready var level_label: Label = $CanvasLayer/HUD/TopBar/LevelLabel
@onready var rule_corner_box: Control = $CanvasLayer/HUD/RuleCornerBox
@onready var rule_title: Label = $CanvasLayer/HUD/RuleCornerBox/TextureRect/ContentMargin/VBox/RuleTitle
@onready var rule_text: Label = $CanvasLayer/HUD/RuleCornerBox/TextureRect/ContentMargin/VBox/RuleText
@onready var devils_corner_box: Control = $CanvasLayer/HUD/DevilsCornerBox
@onready var devils_counter: Label = $CanvasLayer/HUD/DevilsCornerBox/TextureRect/ContentMargin/VBox/DevilsCounter
@onready var icon_container: Control = $CanvasLayer/HUD/DevilsCornerBox/IconContainer
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

## Devil icons UI
var devil_icons: Array[TextureRect] = []

## Current level config
var current_config: Dictionary = {}

## Game state
var is_transitioning: bool = false
var level_start_score: int = 0

## Stored values for victory transition
var pending_time_bonus: int = 0
var pending_level_score: int = 0

## Ballista targeting system
var ballista: Ballista = null


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

	## Hide quit game button on web (get_tree().quit() doesn't work on web)
	if OS.has_feature("web"):
		quit_game_button.visible = false

	## Connect viewport resize signal
	get_viewport().size_changed.connect(_on_viewport_resized)

	## Setup background to fill viewport
	_setup_background()

	## Setup ellipse path for dancers
	_setup_dancer_path()

	## Setup animated fire
	_setup_fire_animation()

	## Create level transition overlay
	_setup_level_transition()

	## Setup ballista targeting system
	_setup_ballista()

	## Show first level intro
	_show_level_intro()


func _process(_delta: float) -> void:
	## Update dancer z-index based on Y position for depth effect
	## Dancers at top (negative Y, behind fire) have lower z_index
	## Dancers at bottom (positive Y, in front of fire) have higher z_index
	for dancer in dancers:
		if is_instance_valid(dancer):
			## Map dancer's local Y position to z_index
			## Y ranges roughly from -130 to +130 (radius_y)
			## Map to z_index range of -5 to +5, with fire at 0
			var local_y := dancer.position.y
			dancer.z_index = int(local_y / 25.0)


func _setup_level_transition() -> void:
	level_transition = LevelTransitionScene.instantiate()
	add_child(level_transition)
	level_transition.continue_pressed.connect(_on_transition_continue)
	level_transition.countdown_finished.connect(_on_countdown_finished)
	level_transition.victory_splash_finished.connect(_on_victory_splash_finished)
	level_transition.defeat_splash_finished.connect(_on_defeat_splash_finished)


func _setup_ballista() -> void:
	ballista = BallistaScene.instantiate()

	## Position at bottom center of viewport
	var viewport_size := get_viewport_rect().size
	ballista.position = Vector2(viewport_size.x / 2, viewport_size.y - 40)

	## Connect signals
	ballista.spear_fired.connect(_on_ballista_fired)

	add_child(ballista)
	print("[Main] Ballista setup complete")


func _setup_background() -> void:
	## Scale background to fill viewport while maintaining aspect ratio
	var viewport_size := get_viewport_rect().size
	var texture_size := background.texture.get_size()

	## Calculate scale to cover the entire viewport
	var scale_x := viewport_size.x / texture_size.x
	var scale_y := viewport_size.y / texture_size.y
	var bg_scale: float = maxf(scale_x, scale_y)

	background.scale = Vector2(bg_scale, bg_scale)

	## Scale trees layer to match
	if trees_layer and trees_layer.texture:
		var trees_size := trees_layer.texture.get_size()
		var trees_scale_x := viewport_size.x / trees_size.x
		var trees_scale_y := viewport_size.y / trees_size.y
		var trees_scale: float = maxf(trees_scale_x, trees_scale_y)
		trees_layer.scale = Vector2(trees_scale, trees_scale)

	print("[Main] Background scaled to: ", bg_scale)


func _setup_fire_animation() -> void:
	## Create AnimatedSprite2D for the fire
	var fire_sprite := AnimatedSprite2D.new()
	fire_sprite.name = "FireSprite"
	fire_sprite.sprite_frames = FireAnimationLoaderScript.get_sprite_frames()
	fire_sprite.animation = "fire"
	fire_sprite.play()

	## Scale fire to match concept art proportions
	fire_sprite.scale = Vector2(0.7, 0.7)

	## Position fire higher up (negative Y) to sit at the fire pit center
	## Compensate for game area being at 68% viewport height
	fire_sprite.position = Vector2(0, -115)

	## Fire z_index at 0 - dancers will dynamically go behind/in front based on Y
	fire_sprite.z_index = 0

	## Make fire semi-transparent so dancers are visible through it
	fire_sprite.modulate.a = 0.7

	## Add to fire pit
	fire_pit.add_child(fire_sprite)
	print("[Main] Fire animation started")


func _on_viewport_resized() -> void:
	var viewport_size := get_viewport_rect().size
	var game_area: Node2D = $GameArea
	game_area.position = Vector2(viewport_size.x / 2, viewport_size.y * 0.68)
	_setup_background()
	## Reposition ballista
	if ballista:
		ballista.position = Vector2(viewport_size.x / 2, viewport_size.y - 40)
	print("[Main] Viewport resized to: ", viewport_size)


func _setup_dancer_path() -> void:
	var viewport_size := get_viewport_rect().size
	var game_area: Node2D = $GameArea
	## Position game area lower to match the painted ground oval
	game_area.position = Vector2(viewport_size.x / 2, viewport_size.y * 0.68)

	var curve := Curve2D.new()
	var center := Vector2.ZERO
	## Wider ellipse to match the painted ground oval
	var radius_x := viewport_size.x * 0.38
	var radius_y := viewport_size.y * 0.18
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
	## Disable ballista during transitions
	if ballista:
		ballista.set_enabled(false)
	current_config = LevelConfig.get_level(GameManager.current_level)
	level_transition.show_level_intro(GameManager.current_level, current_config)

	## Update HUD
	level_label.text = "Level " + str(GameManager.current_level)
	_update_score_display()

	## Always show rule corner box with level tip
	rule_corner_box.visible = true
	if current_config.get("show_rule", false):
		rule_title.text = "Rule:"
		rule_text.text = current_config.get("rule_text", "")
	else:
		## Show tip when no specific rule
		rule_title.text = "Tip:"
		rule_text.text = current_config.get("tip", "Find the imposters!")


func _on_countdown_finished() -> void:
	is_transitioning = false
	## Enable ballista for gameplay
	if ballista:
		ballista.set_enabled(true)
	_start_round()


func _start_round() -> void:
	print("[Main] Starting round ", GameManager.current_level)

	## Store score at level start for calculating level score
	level_start_score = GameManager.score

	## Clear existing dancers
	_clear_dancers()

	## Spawn dancers using level config
	_spawn_dancers()

	## Start the timer and music
	GameManager.start_timer()
	_start_level_music()

	## Start fire crackle ambient
	AudioManager.start_fire_ambient()


func _clear_dancers() -> void:
	for dancer in dancers:
		if is_instance_valid(dancer):
			dancer.queue_free()
	dancers.clear()
	devils_remaining = 0
	total_devils = 0
	_clear_devil_icons()


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
	_setup_devil_icons(devil_count)

	## Give dancers reference to ballista for targeting
	if ballista:
		ballista.dancers = dancers

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
		_cross_out_next_icon()

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
	## Legacy text counter (hidden, kept for compatibility)
	devils_counter.text = "Left: " + str(devils_remaining)


func _setup_devil_icons(count: int) -> void:
	## Clear any existing icons
	_clear_devil_icons()

	## Icon settings - icons in top-right semi-circle area
	var icon_size := Vector2(70, 70)
	var container_size := icon_container.size

	## Constrain to stay within visible area (semi-circle in top-right)
	var margin_right := 20.0  # Keep away from right edge
	var margin_top := 30.0  # Keep away from top
	var min_x := 60.0  # Don't go too far left (stay in corner)
	var max_x := container_size.x - icon_size.x - margin_right
	var min_y := margin_top
	var max_y := 120.0  # Stay in upper portion

	for i in range(count):
		var icon := TextureRect.new()
		icon.texture = DevilIconTexture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = icon_size
		icon.size = icon_size

		## Random position constrained to semi-circle area
		var rand_x := randf_range(min_x, max_x)
		var rand_y := randf_range(min_y, max_y)
		icon.position = Vector2(rand_x, rand_y)

		## Random slight rotation for organic look
		icon.rotation_degrees = randf_range(-10, 10)

		icon_container.add_child(icon)
		devil_icons.append(icon)

	print("[Main] Setup ", count, " devil icons")


func _cross_out_next_icon() -> void:
	## Find first icon without a cross-out overlay and add one
	for icon in devil_icons:
		if icon.get_child_count() == 0:
			var cross := TextureRect.new()
			cross.texture = CrossOutTexture
			cross.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cross.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cross.size = Vector2(56, 56)  # Smaller than icon (70x70)
			cross.position = Vector2(7, 7)  # Center on the 70x70 icon
			icon.add_child(cross)
			print("[Main] Crossed out devil icon")
			return


func _clear_devil_icons() -> void:
	## Remove all devil icons from container
	for icon in devil_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	devil_icons.clear()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause") and not is_transitioning:
		_toggle_pause()


func _toggle_pause() -> void:
	if GameManager.current_state == GameManager.State.PLAYING:
		## Disable ballista when pausing
		if ballista:
			ballista.set_enabled(false)
		## Stop ambient sounds while paused
		AudioManager.stop_fire_ambient()
		AudioManager.stop_nervous_loop()
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
	## Re-enable ballista
	if ballista:
		ballista.set_enabled(true)
	## Resume fire ambient
	AudioManager.start_fire_ambient()
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
	## Format time as M:SS
	var total_seconds := int(time_remaining)
	@warning_ignore("integer_division")
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]

	## Change color to red in last 10 seconds
	if time_remaining <= 10.0:
		timer_label.modulate = Color.RED
	else:
		timer_label.modulate = Color.WHITE


func _on_score_changed(_new_score: int) -> void:
	_update_score_display()


func _update_score_display() -> void:
	score_label.text = "Score: " + str(GameManager.score)


func _on_timer_expired() -> void:
	print("[Main] Timer expired - round failed")
	is_transitioning = true
	_stop_level_music()
	## Stop ambient sounds
	AudioManager.stop_fire_ambient()
	AudioManager.stop_nervous_loop()
	## Play through AudioManager so sound persists across scene change
	AudioManager.play_sfx_from_path("res://assets/sound/bongoselect_WRONG.wav")
	## Reveal remaining devils
	for dancer in dancers:
		if is_instance_valid(dancer) and dancer.is_devil and not dancer.is_revealed:
			dancer.reveal(true)
	## Wait a moment to see revealed devils, then show defeat splash
	await get_tree().create_timer(1.5).timeout
	level_transition.show_defeat_splash()


func _on_defeat_splash_finished() -> void:
	GameManager.end_game()
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")


func _on_level_complete() -> void:
	is_transitioning = true
	_stop_level_music()
	## Stop ambient sounds
	AudioManager.stop_fire_ambient()
	AudioManager.stop_nervous_loop()

	## Calculate scores and store for after splash
	pending_time_bonus = int(GameManager.time_remaining * 25)
	pending_level_score = GameManager.score - level_start_score + pending_time_bonus

	## Add time bonus
	GameManager.add_score(pending_time_bonus)

	## Show victory splash first (sounds handled by level_transition)
	level_transition.show_victory_splash()


func _on_victory_splash_finished() -> void:
	## Check if this was the final level
	if LevelConfig.is_final_level(GameManager.current_level):
		print("[Main] Game complete! You win!")
		get_tree().change_scene_to_file("res://scenes/you_win.tscn")
	else:
		## Show level complete overlay with stored scores
		level_transition.show_level_complete(total_devils, total_devils, pending_time_bonus, pending_level_score)


func _on_transition_continue() -> void:
	## Advance to next level
	GameManager.current_level += 1
	print("[Main] Advancing to level ", GameManager.current_level)

	## Show next level intro
	_show_level_intro()


## Music control
func _start_level_music() -> void:
	if level_music:
		level_music.seek(0.0)  ## Restart from beginning
		level_music.play()
		print("[Main] Level music started")


func _stop_level_music() -> void:
	if level_music and level_music.playing:
		level_music.stop()
		print("[Main] Level music stopped")


## ============== BALLISTA TARGETING SYSTEM ==============

func _on_ballista_fired(target_position: Vector2, arc_points: Array) -> void:
	## Spawn spear and launch along the arc
	var spear: Spear = SpearScene.instantiate()
	add_child(spear)
	spear.hit_dancer.connect(_on_spear_hit_dancer)
	spear.missed.connect(_on_spear_missed)
	spear.launch_along_arc(arc_points)
	print("[Main] Ballista fired spear toward ", target_position)


func _on_spear_hit_dancer(dancer: Dancer) -> void:
	## Guard against accessing freed dancer (race condition with reveal animation)
	if not is_instance_valid(dancer):
		return
	if dancer.is_revealed or is_transitioning:
		return

	var was_correct := dancer.is_devil
	dancer.reveal(was_correct)

	if was_correct:
		print("[Main] Spear hit devil!")
		GameManager.on_correct_guess()
		devils_remaining -= 1
		_update_devils_counter()
		_cross_out_next_icon()

		## Check win condition
		if devils_remaining <= 0:
			print("[Main] All devils found!")
			GameManager.stop_timer()
			_on_level_complete()
	else:
		print("[Main] Spear hit innocent dancer!")
		GameManager.on_wrong_guess()
		## Play devil laugh when hitting innocent
		AudioManager.play_sfx_from_path("res://assets/sound/misc_effects/devilLAUGH.wav")


func _on_spear_missed() -> void:
	print("[Main] Spear missed!")
