extends CanvasLayer
class_name LevelTransition
## Handles smooth level transitions with animated overlays.

signal continue_pressed
signal countdown_finished
signal victory_splash_finished
signal defeat_splash_finished

@onready var background: ColorRect = $Background
@onready var complete_panel: PanelContainer = $CompletePanel
@onready var intro_panel: PanelContainer = $IntroPanel
@onready var countdown_label: Label = $CountdownLabel
@onready var countdown_sound: AudioStreamPlayer = $CountdownSound

## Splash effect nodes
@onready var screen_flash: ColorRect = $ScreenFlash
@onready var red_vignette: ColorRect = $RedVignette
@onready var victory_splash: TextureRect = $VictorySplash
@onready var defeat_splash: TextureRect = $DefeatSplash
@onready var particle_container: Control = $ParticleContainer
@onready var crack_container: Control = $CrackContainer

## Sound effect nodes
@onready var thud_sound: AudioStreamPlayer = $ThudSound
@onready var cheer_sound: AudioStreamPlayer = $CheerSound
@onready var devil_cry_sound: AudioStreamPlayer = $DevilCrySound
@onready var devil_laugh_sound: AudioStreamPlayer = $DevilLaughSound
@onready var hurt_sound: AudioStreamPlayer = $HurtSound

@onready var complete_title: Label = $CompletePanel/VBox/CompleteTitle
@onready var devils_found_label: Label = $CompletePanel/VBox/DevilsFoundLabel
@onready var time_bonus_label: Label = $CompletePanel/VBox/TimeBonusLabel
@onready var score_label: Label = $CompletePanel/VBox/ScoreLabel

@onready var level_number_label: Label = $IntroPanel/VBox/LevelNumberLabel
@onready var level_name_label: Label = $IntroPanel/VBox/LevelNameLabel
@onready var find_label: Label = $IntroPanel/VBox/FindLabel
@onready var tip_label: Label = $IntroPanel/VBox/TipLabel
@onready var rule_container: PanelContainer = $IntroPanel/VBox/RuleContainer
@onready var rule_label: Label = $IntroPanel/VBox/RuleContainer/RuleLabel

var auto_continue_timer: float = 0.0
const AUTO_CONTINUE_DELAY: float = 2.5

## Particle tracking
var active_particles: Array[ColorRect] = []


func _ready() -> void:
	hide_all()


func _process(delta: float) -> void:
	if auto_continue_timer > 0.0:
		auto_continue_timer -= delta
		if auto_continue_timer <= 0.0:
			_on_continue_pressed()


func hide_all() -> void:
	background.visible = false
	complete_panel.visible = false
	intro_panel.visible = false
	countdown_label.visible = false
	victory_splash.visible = false
	defeat_splash.visible = false
	screen_flash.visible = false
	red_vignette.visible = false
	_clear_particles()
	_clear_cracks()


func show_level_complete(devils_found: int, total_devils: int, time_bonus: int, level_score: int) -> void:
	hide_all()
	background.visible = true
	complete_title.text = "LEVEL COMPLETE!"
	devils_found_label.text = "Devils Found: %d/%d" % [devils_found, total_devils]
	time_bonus_label.text = "Time Bonus: +%d" % time_bonus
	score_label.text = "Score: +%d" % level_score
	complete_panel.visible = true
	auto_continue_timer = AUTO_CONTINUE_DELAY


## Show smooth level intro with automatic countdown (no start button)
func show_level_intro(level_num: int, config: Dictionary) -> void:
	hide_all()
	background.visible = true
	background.modulate.a = 0.8

	## Setup level info
	level_number_label.text = "LEVEL %d" % level_num
	level_name_label.text = "\"%s\"" % config.get("name", "")

	## Show tip/rule for this level
	find_label.visible = false
	if config.get("show_rule", false):
		tip_label.text = "Rule: " + config.get("rule_text", "")
		tip_label.visible = true
	else:
		tip_label.text = config.get("tip", "")
		tip_label.visible = true
	rule_container.visible = false

	## Show intro panel with level info
	intro_panel.visible = true

	## Auto-start countdown after showing level info
	_start_smooth_countdown()


## Smooth countdown: Show level info → 2 → 1 → GO!
func _start_smooth_countdown() -> void:
	var tween := create_tween()

	## Show level info for 1.5 seconds
	tween.tween_interval(1.5)

	## Transition to countdown
	tween.tween_callback(func():
		intro_panel.visible = false
		countdown_label.visible = true
		countdown_label.text = "2"
	)

	## Countdown: 2 → 1 → GO!
	tween.tween_interval(0.7)
	tween.tween_callback(func(): countdown_label.text = "1")
	tween.tween_interval(0.7)
	tween.tween_callback(func():
		countdown_label.text = "GO!"
		if countdown_sound:
			countdown_sound.play()
	)
	tween.tween_interval(0.4)
	tween.tween_callback(_on_countdown_finished)


## Legacy method for manual start (kept for compatibility)
func show_countdown() -> void:
	hide_all()
	background.visible = true
	countdown_label.visible = true
	countdown_label.text = "2"

	var tween := create_tween()
	tween.tween_interval(0.7)
	tween.tween_callback(func(): countdown_label.text = "1")
	tween.tween_interval(0.7)
	tween.tween_callback(func():
		countdown_label.text = "GO!"
		if countdown_sound:
			countdown_sound.play()
	)
	tween.tween_interval(0.4)
	tween.tween_callback(_on_countdown_finished)


func _on_continue_pressed() -> void:
	auto_continue_timer = 0.0
	hide_all()
	continue_pressed.emit()


func _on_countdown_finished() -> void:
	hide_all()
	countdown_finished.emit()


## ============== VICTORY SPLASH ==============

func show_victory_splash() -> void:
	## Victory stamp effect - slams in from above with screen shake
	print("[LevelTransition] Victory splash starting")
	hide_all()
	background.visible = true
	background.modulate.a = 0.6

	var viewport_size := get_viewport().get_visible_rect().size
	var center := viewport_size / 2

	## Setup initial state - above screen, scaled up
	victory_splash.visible = true
	victory_splash.modulate.a = 1.0
	victory_splash.pivot_offset = victory_splash.size / 2
	victory_splash.scale = Vector2(1.5, 1.5)
	victory_splash.position = Vector2(center.x - victory_splash.size.x / 2, -victory_splash.size.y)

	var target_pos := Vector2(center.x - victory_splash.size.x / 2, center.y - victory_splash.size.y / 2)

	var tween := create_tween()

	## Slam in (0.15s)
	tween.set_parallel(true)
	tween.tween_property(victory_splash, "position", target_pos, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(victory_splash, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	## Impact effects
	tween.set_parallel(false)
	tween.tween_callback(_play_impact_effects)

	## Hold with subtle pulse (0.8s)
	tween.tween_callback(_start_ember_particles)
	tween.tween_property(victory_splash, "scale", Vector2(1.02, 1.02), 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(victory_splash, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	## Fade out (0.3s)
	tween.tween_property(victory_splash, "modulate:a", 0.0, 0.3)
	tween.tween_property(background, "modulate:a", 0.0, 0.2)

	## Emit signal when done
	tween.tween_callback(func():
		print("[LevelTransition] Victory splash finished")
		_clear_particles()
		victory_splash_finished.emit()
	)


func _play_impact_effects() -> void:
	## Screen shake
	_do_screen_shake()

	## Subtle flash (toned down from 0.8 to 0.25)
	screen_flash.visible = true
	screen_flash.modulate.a = 0.25
	var flash_tween := create_tween()
	flash_tween.tween_property(screen_flash, "modulate:a", 0.0, 0.15)
	flash_tween.tween_callback(func(): screen_flash.visible = false)

	## Play sounds
	if thud_sound:
		thud_sound.play()

	## Delay cheer and devil cry slightly (layered victory sounds)
	await get_tree().create_timer(0.15).timeout
	if cheer_sound:
		cheer_sound.play()
	if devil_cry_sound:
		devil_cry_sound.play()


func _do_screen_shake() -> void:
	var original_offset := offset
	var shake_tween := create_tween()
	for i in range(4):
		var shake_offset := Vector2(randf_range(-8, 8), randf_range(-8, 8))
		shake_tween.tween_property(self, "offset", original_offset + shake_offset, 0.03)
	shake_tween.tween_property(self, "offset", original_offset, 0.03)


func _start_ember_particles() -> void:
	## Spawn ember particles from bottom that float upward
	var viewport_size := get_viewport().get_visible_rect().size

	for i in range(12):
		var particle := ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color(1.0, randf_range(0.4, 0.8), 0.0, 1.0)  # Orange/yellow

		## Random position along bottom third
		particle.position = Vector2(
			randf_range(100, viewport_size.x - 100),
			randf_range(viewport_size.y * 0.7, viewport_size.y)
		)

		particle_container.add_child(particle)
		active_particles.append(particle)

		## Animate upward with fade
		var particle_tween := create_tween()
		var drift := randf_range(-50, 50)
		var rise_distance := randf_range(200, 400)
		var duration := randf_range(0.8, 1.5)

		particle_tween.set_parallel(true)
		particle_tween.tween_property(particle, "position:y", particle.position.y - rise_distance, duration)
		particle_tween.tween_property(particle, "position:x", particle.position.x + drift, duration)
		particle_tween.tween_property(particle, "modulate:a", 0.0, duration)
		particle_tween.set_parallel(false)
		particle_tween.tween_callback(particle.queue_free)


func _clear_particles() -> void:
	for particle in active_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	active_particles.clear()


## ============== DEFEAT SPLASH ==============

func show_defeat_splash() -> void:
	## Defeat descend effect - slowly falls in with red vignette
	print("[LevelTransition] Defeat splash starting")
	hide_all()
	background.visible = true
	background.modulate.a = 0.7

	var viewport_size := get_viewport().get_visible_rect().size
	var center := viewport_size / 2

	## Setup initial state - above screen, slightly rotated
	defeat_splash.visible = true
	defeat_splash.modulate.a = 0.0
	defeat_splash.pivot_offset = defeat_splash.size / 2
	defeat_splash.scale = Vector2.ONE
	defeat_splash.rotation_degrees = -5.0
	defeat_splash.position = Vector2(center.x - defeat_splash.size.x / 2, -defeat_splash.size.y)

	var target_pos := Vector2(center.x - defeat_splash.size.x / 2, center.y - defeat_splash.size.y / 2)

	## Red vignette fade in
	red_vignette.visible = true
	red_vignette.modulate.a = 0.0

	var tween := create_tween()

	## Descend in (0.5s) with fade in
	tween.set_parallel(true)
	tween.tween_property(defeat_splash, "position", target_pos, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(defeat_splash, "modulate:a", 1.0, 0.3)
	tween.tween_property(defeat_splash, "rotation_degrees", 0.0, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(red_vignette, "modulate:a", 0.25, 0.5)

	## Settle bounce (0.15s)
	tween.set_parallel(false)
	tween.tween_property(defeat_splash, "position:y", target_pos.y - 10, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(defeat_splash, "position:y", target_pos.y, 0.07).set_ease(Tween.EASE_IN)

	## Play devil laugh and create screen cracks
	tween.tween_callback(func():
		if devil_laugh_sound:
			devil_laugh_sound.play()
		_create_screen_cracks()
	)

	## Hold with breathing effect (1.0s)
	tween.tween_property(defeat_splash, "scale", Vector2(0.98, 0.98), 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(defeat_splash, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	## Play hurt sound during hold
	tween.tween_callback(func():
		if hurt_sound:
			hurt_sound.play()
	)

	## Vignette pulse (subtle)
	tween.tween_property(red_vignette, "modulate:a", 0.35, 0.3)
	tween.tween_property(red_vignette, "modulate:a", 0.25, 0.3)

	## Fade to black (0.35s)
	tween.set_parallel(true)
	tween.tween_property(defeat_splash, "modulate:a", 0.0, 0.35)
	tween.tween_property(red_vignette, "modulate:a", 0.0, 0.35)
	tween.tween_property(background, "modulate:a", 1.0, 0.35)  # Fade to solid black

	## Emit signal when done
	tween.set_parallel(false)
	tween.tween_callback(func():
		print("[LevelTransition] Defeat splash finished")
		_clear_cracks()
		defeat_splash_finished.emit()
	)


func _create_screen_cracks() -> void:
	## Create simple crack lines radiating from center
	var viewport_size := get_viewport().get_visible_rect().size
	var center := viewport_size / 2

	for i in range(5):
		var crack := Line2D.new()
		crack.width = 2.0
		crack.default_color = Color(0.8, 0.8, 0.8, 0.7)

		## Random angle from center
		var angle := randf_range(0, TAU)
		var length := randf_range(150, 250)

		crack.add_point(center)
		crack.add_point(center)  # Start at center, will animate outward

		crack_container.add_child(crack)

		## Animate crack extending outward
		var end_point := center + Vector2(cos(angle), sin(angle)) * length
		var crack_tween := create_tween()
		crack_tween.tween_method(func(t: float):
			crack.set_point_position(1, center.lerp(end_point, t))
		, 0.0, 1.0, 0.3)


func _clear_cracks() -> void:
	for child in crack_container.get_children():
		child.queue_free()
