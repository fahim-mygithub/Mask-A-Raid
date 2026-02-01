extends Control
class_name CornerBox

@export var flipped: bool = false
@export var box_scale: float = 1.5

@onready var texture_rect: TextureRect = $TextureRect
@onready var content_container: MarginContainer = $TextureRect/ContentMargin
@onready var title_label: Label = $TextureRect/ContentMargin/VBox/TitleLabel
@onready var detail_label: Label = $TextureRect/ContentMargin/VBox/DetailLabel

func _ready() -> void:
	_apply_flip()

func _apply_flip() -> void:
	if flipped and texture_rect:
		texture_rect.flip_h = true
		# Adjust content margins for flipped version
		if content_container:
			content_container.add_theme_constant_override("margin_left", 60)
			content_container.add_theme_constant_override("margin_right", 20)

func set_title(text: String) -> void:
	if title_label:
		title_label.text = text

func set_detail(text: String) -> void:
	if detail_label:
		detail_label.text = text

func set_content(title: String, detail: String) -> void:
	set_title(title)
	set_detail(detail)
