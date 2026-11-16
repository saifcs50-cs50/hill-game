class_name UiToggle
extends UiButton
## Full-width settings row: a label on the left and an animated on/off switch on the right.

const TRACK_SIZE := Vector2(112.0, 56.0)
const SLIDE_TIME := 0.16
const OFF_TRACK := Color(1.0, 1.0, 1.0, 0.18)
const KNOB_RADIUS := 22.0

var _slide := 0.0
var _slide_tween: Tween


static func make_toggle(caption_text: String, is_on: bool) -> UiToggle:
	var toggle := UiToggle.new()
	toggle.text = caption_text
	toggle.custom_minimum_size = Vector2(0.0, UiKit.BUTTON_HEIGHT)
	toggle.toggle_mode = true
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.apply_kind(Kind.GHOST, 32)
	toggle.add_theme_stylebox_override("pressed", toggle.get_theme_stylebox("normal"))
	toggle.add_theme_stylebox_override("hover_pressed", toggle.get_theme_stylebox("hover"))
	toggle.set_pressed_no_signal(is_on)
	toggle._slide = 1.0 if is_on else 0.0
	toggle.toggled.connect(toggle._on_toggled)
	return toggle


func _draw() -> void:
	super._draw()
	var track := Rect2(Vector2(size.x - TRACK_SIZE.x - 28.0, (size.y - TRACK_SIZE.y) * 0.5), TRACK_SIZE)
	var box := StyleBoxFlat.new()
	box.bg_color = OFF_TRACK.lerp(UiKit.TEAL, _slide)
	box.set_corner_radius_all(roundi(TRACK_SIZE.y * 0.5))
	draw_style_box(box, track)
	var travel := TRACK_SIZE.x - TRACK_SIZE.y
	var knob := track.position + Vector2(TRACK_SIZE.y * 0.5 + travel * _slide, TRACK_SIZE.y * 0.5)
	draw_circle(knob + Vector2(0.0, 3.0), KNOB_RADIUS, Color(0.0, 0.0, 0.0, 0.25))
	draw_circle(knob, KNOB_RADIUS, UiKit.CREAM)
	var state_text := "ON" if button_pressed else "OFF"
	var font := get_theme_default_font()
	var text_x := track.position.x - 78.0
	draw_string(font, Vector2(text_x, size.y * 0.5 + 10.0), state_text, HORIZONTAL_ALIGNMENT_RIGHT, 64.0, 26, UiKit.TEAL if button_pressed else UiKit.CREAM_DIM)


func _on_toggled(is_on: bool) -> void:
	if _slide_tween != null and _slide_tween.is_valid():
		_slide_tween.kill()
	_slide_tween = UiKit.tween(self)
	_slide_tween.tween_method(_set_slide, _slide, 1.0 if is_on else 0.0, SLIDE_TIME)


func _set_slide(value: float) -> void:
	_slide = value
	queue_redraw()
