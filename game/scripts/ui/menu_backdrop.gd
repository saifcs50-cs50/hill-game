class_name MenuBackdrop
extends Control
## Full-screen dusk behind every menu: a soft vertical gradient, a few stars, a warm glow near
## the horizon and layered ridges along the bottom.

const SKY_STOPS := [
	[0.0, Color("100d30")],
	[0.5, Color("2b1b5c")],
	[0.82, Color("4f2a78")],
	[1.0, Color("8a3a74")],
]
const RIDGES := [
	[0.84, 40.0, 0.0034, 0.3, Color(0.34, 0.16, 0.4, 0.9)],
	[0.89, 32.0, 0.0046, 2.2, Color(0.21, 0.1, 0.33, 0.95)],
	[0.945, 24.0, 0.0062, 4.4, Color(0.12, 0.06, 0.24, 1.0)],
]
const STAR_COUNT := 80
const STAR_SEED := 7
const RIDGE_STEP := 16.0

var _glow := Shapes.glow_texture(512, Color(1.0, 0.55, 0.36, 0.42))


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _draw() -> void:
	_draw_sky()
	_draw_stars()
	var glow_radius := size.x * 0.42
	draw_texture_rect(_glow, Rect2(Vector2(size.x * 0.74 - glow_radius, size.y * 0.9 - glow_radius), Vector2.ONE * glow_radius * 2.0), false)
	for ridge: Array in RIDGES:
		_draw_ridge(ridge)


func _draw_sky() -> void:
	for i in SKY_STOPS.size() - 1:
		var top: Array = SKY_STOPS[i]
		var bottom: Array = SKY_STOPS[i + 1]
		var y0: float = (top[0] as float) * size.y
		var y1: float = (bottom[0] as float) * size.y
		draw_polygon(
			PackedVector2Array([Vector2(0.0, y0), Vector2(size.x, y0), Vector2(size.x, y1), Vector2(0.0, y1)]),
			PackedColorArray([top[1], top[1], bottom[1], bottom[1]]))


func _draw_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = STAR_SEED
	for i in STAR_COUNT:
		var at := Vector2(rng.randf() * size.x, rng.randf() * size.y * 0.6)
		var fade := 1.0 - at.y / (size.y * 0.7)
		draw_circle(at, rng.randf_range(0.8, 2.0), Color(1.0, 0.95, 0.85, rng.randf_range(0.25, 0.8) * fade))


func _draw_ridge(ridge: Array) -> void:
	var base: float = (ridge[0] as float) * size.y
	var amplitude: float = ridge[1]
	var frequency: float = ridge[2]
	var phase: float = ridge[3]
	var pts := PackedVector2Array()
	var x := 0.0
	while x < size.x + RIDGE_STEP:
		pts.append(Vector2(x, base + sin(x * frequency + phase) * amplitude + sin(x * frequency * 2.7 + phase * 1.6) * amplitude * 0.4))
		x += RIDGE_STEP
	pts.append(Vector2(x, size.y))
	pts.append(Vector2(0.0, size.y))
	draw_colored_polygon(pts, ridge[4])
