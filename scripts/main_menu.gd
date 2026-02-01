extends Control
## Main menu screen - entry point for the game.

@onready var title_image: TextureRect = $TitleImage
@onready var play_button: Button = $ContentContainer/VBoxContainer/PlayButton
@onready var options_button: Button = $ContentContainer/VBoxContainer/OptionsButton
@onready var instructions_button: Button = $ContentContainer/VBoxContainer/InstructionsButton
@onready var quit_button: Button = $ContentContainer/VBoxContainer/QuitButton
@onready var options_menu: Control = $OptionsMenu
@onready var instructions_popup: ColorRect = $InstructionsPopup


func _ready() -> void:
	print("[MainMenu] Ready")

	## Ensure we're in MENU state
	if GameManager.current_state != GameManager.State.MENU:
		GameManager.return_to_menu()

	## Play menu music
	AudioManager.play_menu_music()

	## Setup options menu
	options_menu.visible = false
	options_menu.back_pressed.connect(_on_options_back)

	## Focus the play button for keyboard navigation
	play_button.grab_focus()


func _on_play_pressed() -> void:
	print("[MainMenu] Play pressed")
	## Stop menu music
	AudioManager.stop_menu_music()
	## Start the game through GameManager
	GameManager.start_new_game()
	## Change to the main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_options_pressed() -> void:
	print("[MainMenu] Options pressed")
	options_menu.visible = true


func _on_options_back() -> void:
	print("[MainMenu] Options closed")
	options_menu.visible = false
	options_button.grab_focus()


func _on_instructions_pressed() -> void:
	print("[MainMenu] Instructions pressed")
	instructions_popup.visible = true


func _on_instructions_close() -> void:
	print("[MainMenu] Instructions closed")
	instructions_popup.visible = false
	instructions_button.grab_focus()


func _on_quit_pressed() -> void:
	print("[MainMenu] Quit pressed")
	get_tree().quit()
