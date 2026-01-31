extends Control
## Victory screen shown after completing Level 10.

@onready var score_label: Label = $CenterContainer/VBox/ScoreLabel
@onready var levels_label: Label = $CenterContainer/VBox/LevelsLabel
@onready var play_again_button: Button = $CenterContainer/VBox/ButtonsContainer/PlayAgainButton
@onready var menu_button: Button = $CenterContainer/VBox/ButtonsContainer/MenuButton


func _ready() -> void:
	print("[YouWin] Victory screen ready")
	score_label.text = "Final Score: %d" % GameManager.score
	levels_label.text = "Levels Completed: %d" % GameManager.current_level

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
