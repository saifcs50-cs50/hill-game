class_name UiButton
extends Button
## Thumb-sized rounded button with a press squash. Use set_rows() for a title with an optional
## coin price underneath, set_enabled() to dim it, and `glyph` for the arrow icons.

enum Kind { PRIMARY, SECONDARY, GHOST, DANGER, ACTIVE }

const PRESS_SCALE := 0.94
const PRESS_TIME := 0.06
const RELEASE_TIME := 0.22
const RADIUS := 26
const LIP := 6
const SIDE_PADDING := 24
const GLYPH_WIDTH := 10.0
const GLYPH_BACK_X := 46.0
const DISABLED_FILL := Color(0.26, 0.22, 0.4, 0.7)
const DISABLED_TEXT := Color(0.79, 0.74, 0.9, 0.5)
const PALETTES := {
	Kind.PRIMARY: {"fill": UiKit.ORANGE, "lip": UiKit.ORANGE_DEEP, "text": UiKit.INK},
	Kind.SECONDARY: {"fill": UiKit.TEAL, "lip": UiKit.TEAL_DEEP, "text": UiKit.INK},
	Kind.GHOST: {"fill": Color(1.0, 1.0, 1.0, 0.1), "lip": Color(1.0, 1.0, 1.0, 0.2), "text": UiKit.CREAM},
	Kind.DANGER: {"fill": UiKit.RED, "lip": UiKit.RED_DEEP, "text": UiKit.CREAM},
	Kind.ACTIVE: {"fill": Color(0.25, 0.88, 0.77, 0.14), "lip": UiKit.TEAL, "text": UiKit.TEAL},
}

## "left" or "right" draws a chevron; "back" draws a chevron at the left edge beside the text.
var glyph := "":
	set(value):
		glyph = value
		apply_kind(_kind, _font_size)

var _kind: Kind = Kind.PRIMARY
var _font_size := 34
var _content: VBoxContainer
var _title: Label
var _price_row: HBoxContainer
var _price: Label
var _coin: TextureRect
var _scale_tween: Tween


static func create(caption: String, kind: Kind = Kind.PRIMARY, min_height: float = UiKit.BUTTON_HEIGHT, font_size: int = 34) -> UiButton:
	var button := UiButton.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0.0, min_height)
	button.apply_kind(kind, font_size)
	return button


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	resized.connect(_update_pivot)


## Restyles the button (colours, lip, fonts). Safe to call again when the button changes role.
func apply_kind(kind: Kind, font_size: int = 34) -> void:
	_kind = kind
	_font_size = font_size
	var palette: Dictionary = PALETTES[kind]
	var fill: Color = palette["fill"]
	var lip: Color = palette["lip"]
	var normal := _box(fill, lip)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", _box(fill.lightened(0.08), lip))
	add_theme_stylebox_override("pressed", _box(fill.darkened(0.12), lip, true))
	add_theme_stylebox_override("hover_pressed", _box(fill.darkened(0.12), lip, true))
	add_theme_stylebox_override("disabled", normal if kind == Kind.ACTIVE else _disabled_box())
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_font_size_override("font_size", font_size)
	_refresh_colors()
	queue_redraw()


## Dims or enables the button. Use this instead of setting `disabled` so the rows dim too.
func set_enabled(enabled: bool) -> void:
	disabled = not enabled
	_refresh_colors()
	queue_redraw()


## Title with an optional price (a coin and the amount) under it. price < 0 hides the price.
func set_rows(title: String, price: int = -1, title_size: int = 26, price_size: int = 32) -> void:
	text = ""
	if _content == null:
		_build_content()
	_title.text = title
	_title.label_settings.font_size = title_size
	_price_row.visible = price >= 0
	_price.text = UiKit.format_int(price) if price >= 0 else ""
	_price.label_settings.font_size = price_size
	_refresh_colors()


## Appends an extra line under the title/price rows (for example a small subtitle).
func add_row(row: Control) -> void:
	if _content == null:
		_build_content()
	_content.add_child(row)


## The visible caption, whichever way it was set.
func caption() -> String:
	return _title.text if _title != null else text


func _draw() -> void:
	if glyph.is_empty():
		return
	var color := _text_color()
	var reach := minf(size.y, UiKit.BUTTON_HEIGHT) * 0.2
	var center := size * 0.5 - Vector2(0.0, LIP * 0.5)
	if glyph == "back":
		center.x = GLYPH_BACK_X
	var direction := 1.0 if glyph == "right" else -1.0
	var tip := center + Vector2(direction * reach * 0.6, 0.0)
	var upper := center + Vector2(-direction * reach * 0.6, -reach)
	var lower := center + Vector2(-direction * reach * 0.6, reach)
	draw_polyline(PackedVector2Array([upper, tip, lower]), color, GLYPH_WIDTH, true)
	for point in [upper, tip, lower]:
		draw_circle(point, GLYPH_WIDTH * 0.5, color)


func _build_content() -> void:
	_content = VBoxContainer.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.offset_bottom = -LIP
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_theme_constant_override("separation", -4)
	add_child(_content)
	_title = UiKit.label("", 26)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_title)
	_price_row = UiKit.hbox(8)
	_price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coin = UiKit.coin_icon(32.0)
	_price_row.add_child(_coin)
	_price = UiKit.label("", 32)
	_price_row.add_child(_price)
	_content.add_child(_price_row)


func _refresh_colors() -> void:
	var color := _text_color()
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color", "font_focus_color"]:
		add_theme_color_override(state, color)
	if _title == null:
		return
	_title.label_settings.font_color = color
	_price.label_settings.font_color = color
	var shadow_alpha := 0.0 if _kind == Kind.PRIMARY or _kind == Kind.SECONDARY or disabled else 0.35
	_title.label_settings.shadow_color.a = shadow_alpha
	_price.label_settings.shadow_color.a = shadow_alpha
	_coin.modulate.a = 0.45 if disabled and _kind != Kind.ACTIVE else 1.0


func _text_color() -> Color:
	if disabled and _kind != Kind.ACTIVE:
		return DISABLED_TEXT
	var palette: Dictionary = PALETTES[_kind]
	return palette["text"]


func _box(fill: Color, lip: Color, pressed: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(RADIUS)
	box.set_content_margin_all(8)
	box.content_margin_left = SIDE_PADDING
	box.content_margin_right = SIDE_PADDING
	box.border_color = lip
	if _kind == Kind.GHOST or _kind == Kind.ACTIVE:
		box.set_border_width_all(3 if _kind == Kind.ACTIVE else 2)
	else:
		box.border_width_bottom = 2 if pressed else LIP
		box.shadow_color = UiKit.SHADOW
		box.shadow_size = 8
		box.shadow_offset = Vector2(0.0, 5.0)
	if glyph == "back":
		box.content_margin_left = GLYPH_BACK_X + 28.0
	return box


func _disabled_box() -> StyleBoxFlat:
	var box := _box(DISABLED_FILL, Color.TRANSPARENT)
	box.set_border_width_all(0)
	box.shadow_size = 0
	return box


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _on_down() -> void:
	_scale_to(PRESS_SCALE, PRESS_TIME, Tween.TRANS_QUAD)


func _on_up() -> void:
	_scale_to(1.0, RELEASE_TIME, Tween.TRANS_BACK)


func _scale_to(target: float, duration: float, transition: Tween.TransitionType) -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = UiKit.tween(self)
	_scale_tween.set_trans(transition).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(self, "scale", Vector2.ONE * target, duration)
