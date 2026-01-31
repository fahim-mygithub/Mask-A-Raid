extends Control
## Game over screen - displays final stats and options to restart or quit.

@onready var score_label: Label = $CenterContainer/VBox/StatsContainer/ScoreLabel
@onready var level_label: Label = $CenterContainer/VBox/StatsContainer/LevelLabel
@onready var accuracy_label: Label = $CenterContainer/VBox/StatsContainer/AccuracyLabel
@onready var restart_button: Button = $CenterContainer/VBox/ButtonsContainer/RestartButton
@onready var quit_button: Button = $CenterContainer/VBox/ButtonsContainer/QuitButton


func _ready() -> void:
	print("[GameOver] Screen ready")

	## Display final stats from GameManager
	score_label.text = "Final Score: " + str(GameManager.score)
	level_label.text = "Level Reached: " + str(GameManager.current_level)

	## TODO: Track accuracy when dancer system is implemented
	accuracy_label.text = "Accuracy: --"

	## Connect buttons
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	## Focus restart button
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	print("[GameOver] Restart pressed")
	GameManager.return_to_menu()
	GameManager.start_new_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_pressed() -> void:
	print("[GameOver] Quit to menu pressed")
	GameManager.return_to_menu()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
