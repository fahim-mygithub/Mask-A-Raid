extends Control
## Options menu - handles sound and window settings.

signal back_pressed

@onready var music_slider: HSlider = $PanelContainer/VBox/SettingsContainer/MusicRow/MusicSlider
@onready var music_value_label: Label = $PanelContainer/VBox/SettingsContainer/MusicRow/MusicValue
@onready var sfx_slider: HSlider = $PanelContainer/VBox/SettingsContainer/SFXRow/SFXSlider
@onready var sfx_value_label: Label = $PanelContainer/VBox/SettingsContainer/SFXRow/SFXValue
@onready var window_dropdown: OptionButton = $PanelContainer/VBox/SettingsContainer/WindowRow/WindowDropdown
@onready var back_button: Button = $PanelContainer/VBox/BackButton

## Window size presets
const WINDOW_PRESETS := [
	{"name": "1280 x 720", "size": Vector2i(1280, 720), "fullscreen": false},
	{"name": "1920 x 1080", "size": Vector2i(1920, 1080), "fullscreen": false},
	{"name": "Fullscreen", "size": Vector2i.ZERO, "fullscreen": true},
]


func _ready() -> void:
	print("[OptionsMenu] Ready")

	## Setup window dropdown
	_setup_window_dropdown()

	## Initialize sliders from current AudioManager values
	## Convert dB to linear (0-100 scale)
	var music_linear := db_to_linear(AudioManager.music_volume) * 100.0
	var sfx_linear := db_to_linear(AudioManager.sfx_volume) * 100.0

	music_slider.value = music_linear
	sfx_slider.value = sfx_linear
	_update_music_label(music_linear)
	_update_sfx_label(sfx_linear)

	## Connect signals
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	window_dropdown.item_selected.connect(_on_window_selected)
	back_button.pressed.connect(_on_back_pressed)

	## Focus back button
	back_button.grab_focus()


func _setup_window_dropdown() -> void:
	window_dropdown.clear()
	for preset in WINDOW_PRESETS:
		window_dropdown.add_item(preset["name"])

	## Select current window mode
	var current_fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if current_fullscreen:
		window_dropdown.select(2)  ## Fullscreen
	else:
		var current_size := DisplayServer.window_get_size()
		if current_size == Vector2i(1920, 1080):
			window_dropdown.select(1)
		else:
			window_dropdown.select(0)  ## Default to 1280x720


func _on_music_slider_changed(value: float) -> void:
	## Convert linear (0-100) to dB
	var volume_db := linear_to_db(value / 100.0)
	if value <= 0:
		volume_db = -80.0  ## Essentially mute
	AudioManager.set_music_volume(volume_db)
	_update_music_label(value)


func _on_sfx_slider_changed(value: float) -> void:
	## Convert linear (0-100) to dB
	var volume_db := linear_to_db(value / 100.0)
	if value <= 0:
		volume_db = -80.0
	AudioManager.set_sfx_volume(volume_db)
	_update_sfx_label(value)


func _update_music_label(value: float) -> void:
	music_value_label.text = str(int(value)) + "%"


func _update_sfx_label(value: float) -> void:
	sfx_value_label.text = str(int(value)) + "%"


func _on_window_selected(index: int) -> void:
	var preset: Dictionary = WINDOW_PRESETS[index]
	print("[OptionsMenu] Window preset selected: ", preset["name"])

	if preset["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var window_size: Vector2i = preset["size"]
		print("[OptionsMenu] Setting window size to: ", window_size)
		DisplayServer.window_set_size(window_size)
		## Center the window
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		var centered_pos: Vector2i = (screen_size - window_size) / 2
		DisplayServer.window_set_position(centered_pos)
		print("[OptionsMenu] Window size after set: ", DisplayServer.window_get_size())


func _on_back_pressed() -> void:
	print("[OptionsMenu] Back pressed")
	back_pressed.emit()
