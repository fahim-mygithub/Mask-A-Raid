extends CanvasLayer
class_name LevelTransition
## Handles smooth level transitions with animated overlays.

signal continue_pressed
signal countdown_finished

@onready var background: ColorRect = $Background
@onready var complete_panel: PanelContainer = $CompletePanel
@onready var intro_panel: PanelContainer = $IntroPanel
@onready var countdown_label: Label = $CountdownLabel

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
	tween.tween_callback(func(): countdown_label.text = "GO!")
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
	tween.tween_callback(func(): countdown_label.text = "GO!")
	tween.tween_interval(0.4)
	tween.tween_callback(_on_countdown_finished)


func _on_continue_pressed() -> void:
	auto_continue_timer = 0.0
	hide_all()
	continue_pressed.emit()


func _on_countdown_finished() -> void:
	hide_all()
	countdown_finished.emit()
