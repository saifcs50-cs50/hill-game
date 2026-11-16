class_name PipBar
extends Control
## A row of rounded pips, the first `filled` of them lit. Upgrade levels use 10, vehicle stats 5.

const GAP := 5.0
const OFF_COLOR := Color(1.0, 1.0, 1.0, 0.12)
const FLASH_TIME := 0.5

var total := 10:
	set(value):
		total = maxi(value, 1)
		queue_redraw()
var filled := 0:
	set(value):
		filled = clampi(value, 0, total)
		queue_redraw()
var lit_color := UiKit.TEAL:
	set(value):
		lit_color = value
		queue_redraw()

var _flash := 0.0
var _flash_tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, 16.0)


func configure(pip_count: int, lit_count: int, color: Color) -> void:
	total = pip_count
	filled = lit_count
	lit_color = color


## Brightens the newest lit pip for a moment (after buying a level).
func flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = UiKit.tween(self)
	_flash_tween.tween_method(_set_flash, 1.0, 0.0, FLASH_TIME)


func _draw() -> void:
	var pip_width := (size.x - GAP * (total - 1)) / total
	var radius := roundi(minf(pip_width, size.y) * 0.4)
	for i in total:
		var color := OFF_COLOR
		if i < filled:
			color = lit_color
			if i == filled - 1:
				color = lit_color.lerp(Color.WHITE, _flash * 0.7)
		var box := StyleBoxFlat.new()
		box.bg_color = color
		box.set_corner_radius_all(radius)
		draw_style_box(box, Rect2(i * (pip_width + GAP), 0.0, pip_width, size.y))


func _set_flash(value: float) -> void:
	_flash = value
	queue_redraw()
