class_name UiKit
extends RefCounted
## Shared look for the menus: dusk palette, panel styles, labels and small drawing helpers.

const INDIGO_DEEP := Color("120f35")
const PURPLE := Color("2f1d63")
const PURPLE_LIGHT := Color("4a2a78")
const DUSK_GLOW := Color("b8416f")
const CREAM := Color("fff6e6")
const CREAM_DIM := Color("c9bce6")
const ORANGE := Color("ff9a4d")
const ORANGE_DEEP := Color("e8662c")
const TEAL := Color("3fe0c5")
const TEAL_DEEP := Color("1aa896")
const RED := Color("e8455a")
const RED_DEEP := Color("a82a40")
const GOLD := Color("ffcf4a")
const INK := Color("1b1238")

const PANEL_FILL := Color(0.09, 0.06, 0.22, 0.76)
const INSET_FILL := Color(0.04, 0.02, 0.13, 0.55)
const BORDER := Color(1.0, 1.0, 1.0, 0.16)
const SHADOW := Color(0.02, 0.0, 0.08, 0.5)

const MARGIN := 48
const BUTTON_HEIGHT := 96
const PANEL_RADIUS := 28
const COIN_PIXELS := 64

static var _coin_texture: ImageTexture


## Rounded translucent panel with a subtle border and a soft drop shadow.
static func panel_style(fill: Color = PANEL_FILL, radius: int = PANEL_RADIUS, padding: int = 18, shadow: bool = true) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.set_border_width_all(2)
	box.border_color = BORDER
	box.set_content_margin_all(padding)
	if shadow:
		box.shadow_color = SHADOW
		box.shadow_size = 16
		box.shadow_offset = Vector2(0.0, 6.0)
	return box


static func panel(fill: Color = PANEL_FILL, radius: int = PANEL_RADIUS, padding: int = 18, shadow: bool = true) -> PanelContainer:
	var container := PanelContainer.new()
	container.add_theme_stylebox_override("panel", panel_style(fill, radius, padding, shadow))
	return container


static func label(caption: String, font_size: int, color: Color = CREAM, outlined: bool = false) -> Label:
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	settings.shadow_size = 1
	settings.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	settings.shadow_offset = Vector2(0.0, 3.0)
	if outlined:
		settings.outline_size = maxi(roundi(font_size / 7.0), 4)
		settings.outline_color = INK
	var node := Label.new()
	node.label_settings = settings
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.text = caption
	return node


static func vbox(separation: int = 8) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


static func hbox(separation: int = 8) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


static func spacer() -> Control:
	var node := Control.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node


static func spacer_fixed(height: float) -> Control:
	var node := Control.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.custom_minimum_size = Vector2(0.0, height)
	return node


## Tween that keeps running at normal speed while Engine.time_scale is slowed (crash slow motion).
static func tween(owner_node: Node) -> Tween:
	var tw := owner_node.create_tween()
	tw.set_ignore_time_scale(true)
	return tw


static func fade_in(node: CanvasItem, duration: float = 0.22) -> void:
	node.modulate.a = 0.0
	tween(node).tween_property(node, "modulate:a", 1.0, duration)


## 12345 -> "12,345".
static func format_int(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += ","
		out += digits[i]
	return ("-" if value < 0 else "") + out


## Small gold coin, drawn once in code.
static func coin_texture() -> ImageTexture:
	if _coin_texture == null:
		_coin_texture = _render_coin()
	return _coin_texture


static func coin_icon(icon_size: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = coin_texture()
	rect.custom_minimum_size = Vector2(icon_size, icon_size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect


## Padlock glyph for locked vehicles and stages, drawn on `canvas` during its _draw().
static func draw_lock(canvas: CanvasItem, center: Vector2, scale_px: float, color: Color) -> void:
	var body := StyleBoxFlat.new()
	body.bg_color = color
	body.set_corner_radius_all(roundi(scale_px * 0.14))
	var rect := Rect2(center + Vector2(-0.4, -0.08) * scale_px, Vector2(0.8, 0.6) * scale_px)
	canvas.draw_style_box(body, rect)
	canvas.draw_arc(center + Vector2(0.0, -0.1) * scale_px, 0.26 * scale_px, PI, TAU, 20, color, scale_px * 0.11, true)
	canvas.draw_line(center + Vector2(-0.26, -0.1) * scale_px, center + Vector2(-0.26, -0.02) * scale_px, color, scale_px * 0.11)
	canvas.draw_line(center + Vector2(0.26, -0.1) * scale_px, center + Vector2(0.26, -0.02) * scale_px, color, scale_px * 0.11)
	canvas.draw_circle(center + Vector2(0.0, 0.2) * scale_px, 0.08 * scale_px, INK)


static func _render_coin() -> ImageTexture:
	var image := Image.create(COIN_PIXELS, COIN_PIXELS, false, Image.FORMAT_RGBA8)
	var radius := COIN_PIXELS * 0.5
	for y in COIN_PIXELS:
		for x in COIN_PIXELS:
			var nx := (x + 0.5 - radius) / radius
			var ny := (y + 0.5 - radius) / radius
			image.set_pixel(x, y, _coin_pixel(nx, ny, radius))
	return ImageTexture.create_from_image(image)


static func _coin_pixel(nx: float, ny: float, radius: float) -> Color:
	var dist := sqrt(nx * nx + ny * ny)
	var alpha := clampf((1.0 - dist) * radius, 0.0, 1.0)
	if alpha <= 0.0:
		return Color(0.0, 0.0, 0.0, 0.0)
	var shade := clampf(ny * 0.5 + 0.5, 0.0, 1.0)
	var color := Color("ffe38a").lerp(Color("f2a91c"), shade)
	if dist > 0.84:
		color = Color("f7c340").lerp(Color("b86f0a"), shade)
	elif dist > 0.72:
		color = Color("d8900f").lerp(Color("ffd96a"), 1.0 - shade)
	var shine := clampf(1.0 - Vector2(nx + 0.38, ny + 0.42).length() * 2.4, 0.0, 1.0)
	color = color.lerp(Color.WHITE, shine * 0.55)
	return Color(color, alpha)
