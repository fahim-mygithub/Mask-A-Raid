class_name Graphics
extends RefCounted
## Fluent/chainable drawing API for Godot 4.x
## Usage: Draw.create(node).fill_style(Color.RED).fill_circle(100, 100, 50)

var _target: CanvasItem
var _fill_color: Color = Color.WHITE
var _line_color: Color = Color.WHITE
var _line_width: float = 1.0

func _init(target: CanvasItem) -> void:
	_target = target


# Style methods (chainable)

func fill_style(color: Color) -> Graphics:
	_fill_color = color
	return self


func line_style(color: Color, width: float = 1.0) -> Graphics:
	_line_color = color
	_line_width = width
	return self


# Shape methods (chainable)

func fill_circle(x: float, y: float, radius: float) -> Graphics:
	_target.draw_circle(Vector2(x, y), radius, _fill_color)
	return self


func stroke_circle(x: float, y: float, radius: float) -> Graphics:
	_target.draw_arc(Vector2(x, y), radius, 0, TAU, 64, _line_color, _line_width)
	return self


func fill_rect(x: float, y: float, width: float, height: float) -> Graphics:
	_target.draw_rect(Rect2(x, y, width, height), _fill_color, true)
	return self


func stroke_rect(x: float, y: float, width: float, height: float) -> Graphics:
	_target.draw_rect(Rect2(x, y, width, height), _line_color, false, _line_width)
	return self


func fill_triangle(x1: float, y1: float, x2: float, y2: float, x3: float, y3: float) -> Graphics:
	var points := PackedVector2Array([Vector2(x1, y1), Vector2(x2, y2), Vector2(x3, y3)])
	_target.draw_polygon(points, PackedColorArray([_fill_color]))
	return self


func fill_polygon(points: PackedVector2Array) -> Graphics:
	_target.draw_polygon(points, PackedColorArray([_fill_color]))
	return self


func stroke_polygon(points: PackedVector2Array, closed: bool = true) -> Graphics:
	_target.draw_polyline(points, _line_color, _line_width)
	if closed and points.size() > 1:
		_target.draw_line(points[points.size() - 1], points[0], _line_color, _line_width)
	return self


func line_between(x1: float, y1: float, x2: float, y2: float) -> Graphics:
	_target.draw_line(Vector2(x1, y1), Vector2(x2, y2), _line_color, _line_width)
	return self


func polyline(points: PackedVector2Array) -> Graphics:
	_target.draw_polyline(points, _line_color, _line_width)
	return self


# Utility methods

func clear() -> Graphics:
	# Request redraw - actual clearing happens via Godot's draw cycle
	_target.queue_redraw()
	return self
