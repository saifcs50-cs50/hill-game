class_name PageDots
extends Control
## Row of dots for a carousel: the current page is a wide orange pill, owned pages are brighter.

const DOT := 12.0
const ACTIVE_WIDTH := 32.0
const GAP := 10.0

var _count := 0
var _current := 0
var _lit: Array[bool] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, DOT)


func set_state(current: int, lit: Array[bool]) -> void:
	_current = current
	_lit = lit
	_count = lit.size()
	queue_redraw()


func _draw() -> void:
	var total_width := (_count - 1) * (DOT + GAP) + ACTIVE_WIDTH
	var x := (size.x - total_width) * 0.5
	for i in _count:
		var width := ACTIVE_WIDTH if i == _current else DOT
		var color := Color(UiKit.CREAM, 0.7 if _lit[i] else 0.25)
		if i == _current:
			color = UiKit.ORANGE
		var box := StyleBoxFlat.new()
		box.bg_color = color
		box.set_corner_radius_all(roundi(DOT * 0.5))
		draw_style_box(box, Rect2(x, (size.y - DOT) * 0.5, width, DOT))
		x += width + GAP
