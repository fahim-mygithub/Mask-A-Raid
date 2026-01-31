extends CanvasLayer
class_name LevelTransition
## Handles level complete and level intro overlays.

signal continue_pressed
signal start_pressed
signal countdown_finished

@onready var background: ColorRect = $Background
@onready var complete_panel: PanelContainer = $CompletePanel
@onready var intro_panel: PanelContainer = $IntroPanel
@onready var countdown_label: Label = $CountdownLabel

@onready var complete_title: Label = $CompletePanel/VBox/CompleteTitle
@onready var devils_found_label: Label = $CompletePanel/VBox/DevilsFoundLabel
@onready var time_bonus_label: Label = $CompletePanel/VBox/TimeBonusLabel
@onready var score_label: Label = $CompletePanel/VBox/ScoreLabel
@onready var continue_button: Button = $CompletePanel/VBox/ContinueButton

@onready var level_number_label: Label = $IntroPanel/VBox/LevelNumberLabel
@onready var level_name_label: Label = $IntroPanel/VBox/LevelNameLabel
@onready var find_label: Label = $IntroPanel/VBox/FindLabel
@onready var tip_label: Label = $IntroPanel/VBox/TipLabel
@onready var rule_container: PanelContainer = $IntroPanel/VBox/RuleContainer
@onready var rule_label: Label = $IntroPanel/VBox/RuleContainer/RuleLabel
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
	continue_button.grab_focus()
	auto_continue_timer = AUTO_CONTINUE_DELAY


func show_level_intro(level_num: int, config: Dictionary) -> void:
	hide_all()
	background.visible = true
	level_number_label.text = "LEVEL %d" % level_num
	level_name_label.text = "\"%s\"" % config.get("name", "")

	var devil_count: int = config.get("devils", 1)
	find_label.text = "Find: %d imposter%s" % [devil_count, "s" if devil_count > 1 else ""]
	tip_label.text = config.get("tip", "")

	if config.get("show_rule", false):
		rule_label.text = config.get("rule_text", "")
		rule_container.visible = true
	else:
		rule_container.visible = false

	intro_panel.visible = true
	start_button.grab_focus()


func show_countdown() -> void:
	hide_all()
	background.visible = true
	countdown_label.visible = true
	countdown_label.text = "3"

	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func(): countdown_label.text = "2")
	tween.tween_interval(0.8)
	tween.tween_callback(func(): countdown_label.text = "1")
	tween.tween_interval(0.8)
	tween.tween_callback(func(): countdown_label.text = "GO!")
	tween.tween_interval(0.4)
	tween.tween_callback(_on_countdown_finished)


func _on_continue_pressed() -> void:
	auto_continue_timer = 0.0
	hide_all()
	continue_pressed.emit()


func _on_start_pressed() -> void:
	hide_all()
	show_countdown()


func _on_countdown_finished() -> void:
	hide_all()
	countdown_finished.emit()
