extends Node
## Factory autoload for creating Graphics instances
## Register as autoload "Draw" in project settings
## Usage: Draw.create(self).fill_style(Color.RED).fill_circle(100, 100, 50)


func create(target: CanvasItem) -> Graphics:
	return Graphics.new(target)
