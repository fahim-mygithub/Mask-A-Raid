extends Control
class_name TorchButton
## A menu button with animated torches on both sides.
## Torches light up when the button is hovered.

signal pressed

@export var button_text: String = "BUTTON":
	set(value):
		button_text = value
		if button:
			button.text = value

@export var button_theme: Theme
@export var button_font: Font
@export var button_font_size: int = 28
@export var torch_scale: float = 0.22

@onready var left_torch: AnimatedSprite2D = $LeftTorch
@onready var button: Button = $Button
@onready var right_torch: AnimatedSprite2D = $RightTorch


func _ready() -> void:
	# Load torch animations
	var torch_frames := TorchAnimationLoader.get_sprite_frames()

	if left_torch:
		left_torch.sprite_frames = torch_frames
		left_torch.scale = Vector2(torch_scale, torch_scale)
		left_torch.play("idle")

	if right_torch:
		right_torch.sprite_frames = torch_frames
		right_torch.scale = Vector2(torch_scale, torch_scale)
		right_torch.flip_h = true
		right_torch.play("idle")

	# Apply button properties
	button.text = button_text
	if button_theme:
		button.theme = button_theme
	if button_font:
		button.add_theme_font_override("font", button_font)
	button.add_theme_font_size_override("font_size", button_font_size)

	# Connect signals
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	button.pressed.connect(_on_button_pressed)


func _on_mouse_entered() -> void:
	left_torch.play("burn")
	right_torch.play("burn")


func _on_mouse_exited() -> void:
	left_torch.play("idle")
	right_torch.play("idle")


func _on_button_pressed() -> void:
	pressed.emit()
