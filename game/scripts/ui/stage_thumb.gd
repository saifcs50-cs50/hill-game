class_name StageThumb
extends Control
## Small painted preview of a stage: sky gradient, sun or planet, stars and layered ridges.
## Everything is drawn in code, clipped to a rounded rectangle.

const RADIUS := 20.0
const CORNER_STEPS := 8
const RIDGE_STEP := 10.0
const STAR_COUNT := 36
const LOCK_DIM := Color(0.05, 0.02, 0.12, 0.58)

## sky: top, middle, bottom colours. ridges: colour, base height (0..1), amplitude, frequency, phase.
const LOOKS := {
	"meadow": {
		"sky": [Color("2b1b5a"), Color("8a4a80"), Color("f47c4e")],
		"sun": {"at": Vector2(0.7, 0.58), "radius": 26.0, "color": Color("ffe3a0")},
		"stars": 0.5,
		"ridges": [
			[Color("a8527e"), 0.62, 14.0, 0.016, 0.4],
			[Color("5a2e6c"), 0.72, 12.0, 0.022, 2.0],
			[Color("2f7d62"), 0.84, 9.0, 0.03, 4.1],
		],
	},
	"desert": {
		"sky": [Color("4a2a78"), Color("c45a62"), Color("ffb066")],
		"sun": {"at": Vector2(0.3, 0.52), "radius": 34.0, "color": Color("ffeab8")},
		"stars": 0.2,
		"ridges": [
			[Color("e0944f"), 0.64, 12.0, 0.012, 1.0],
			[Color("bd6a3b"), 0.76, 14.0, 0.018, 3.0],
			[Color("8f4a2e"), 0.88, 9.0, 0.026, 5.2],
		],
	},
	"arctic": {
		"sky": [Color("0b1a45"), Color("1b4d7e"), Color("7fd6e0")],
		"sun": {},
		"stars": 0.8,
		"aurora": true,
		"ridges": [
			[Color("a9cfe6"), 0.66, 12.0, 0.014, 0.8],
			[Color("d7ecf8"), 0.77, 11.0, 0.02, 2.6],
			[Color("f1f9ff"), 0.88, 7.0, 0.03, 4.4],
		],
	},
	"moon": {
		"sky": [Color("05040f"), Color("120e2b"), Color("2a2150")],
		"sun": {"at": Vector2(0.72, 0.3), "radius": 24.0, "color": Color("4d8fe0"), "earth": true},
		"stars": 1.0,
		"ridges": [
			[Color("6c6678"), 0.7, 8.0, 0.02, 0.2],
			[Color("8b8794"), 0.8, 7.0, 0.028, 2.4],
			[Color("a8a4b2"), 0.9, 5.0, 0.04, 4.0],
		],
	},
}

var stage_id := "meadow":
	set(value):
		stage_id = value
		queue_redraw()
var locked := false:
	set(value):
		locked = value
		queue_redraw()

var _glow := Shapes.glow_texture(128, Color(1.0, 0.85, 0.6, 0.5))


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var look: Dictionary = LOOKS.get(stage_id, LOOKS["meadow"])
	var frame := _rounded_rect(Rect2(Vector2.ZERO, size), RADIUS)
	_draw_sky(frame, look["sky"])
	_draw_stars(look["stars"])
	if look.get("aurora", false):
		_draw_aurora(frame)
	_draw_sun(look["sun"])
	for ridge: Array in look["ridges"]:
		_draw_ridge(frame, ridge)
	if locked:
		draw_colored_polygon(frame, LOCK_DIM)
		UiKit.draw_lock(self, size * 0.5, minf(size.y * 0.5, 72.0), Color(UiKit.CREAM, 0.92))


func _draw_sky(frame: PackedVector2Array, stops: Array) -> void:
	var colors := PackedColorArray()
	for point in frame:
		var t := clampf(point.y / size.y, 0.0, 1.0)
		var color: Color = (stops[0] as Color).lerp(stops[1], t * 2.0) if t < 0.5 else (stops[1] as Color).lerp(stops[2], (t - 0.5) * 2.0)
		colors.append(color)
	draw_polygon(frame, colors)


func _draw_stars(amount: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in STAR_COUNT:
		var at := Vector2(rng.randf_range(RADIUS, size.x - RADIUS), rng.randf_range(8.0, size.y * 0.55))
		var radius := rng.randf_range(0.8, 1.9)
		var alpha := rng.randf_range(0.3, 0.9) * amount
		draw_circle(at, radius, Color(1.0, 0.97, 0.9, alpha))


func _draw_sun(sun: Dictionary) -> void:
	if sun.is_empty():
		return
	var at: Vector2 = (sun["at"] as Vector2) * size
	var radius: float = sun["radius"]
	var color: Color = sun["color"]
	if sun.get("earth", false):
		draw_circle(at, radius, color)
		draw_circle(at + Vector2(-6.0, -4.0), radius * 0.35, Color("3fb37f"))
		draw_circle(at + Vector2(8.0, 8.0), radius * 0.25, Color("3fb37f"))
		return
	draw_texture_rect(_glow, Rect2(at - Vector2.ONE * radius * 3.0, Vector2.ONE * radius * 6.0), false)
	draw_circle(at, radius, color)


func _draw_aurora(frame: PackedVector2Array) -> void:
	for band in 2:
		var pts := PackedVector2Array()
		var base := size.y * (0.22 + band * 0.13)
		for step in range(0, int(size.x) + 1, int(RIDGE_STEP)):
			pts.append(Vector2(step, base + sin(step * 0.03 + band * 1.7) * 14.0))
		for step in range(int(size.x), -1, -int(RIDGE_STEP)):
			pts.append(Vector2(step, base + 22.0 + sin(step * 0.03 + band * 1.7 + 0.6) * 10.0))
		var tint := Color(0.25, 0.88, 0.77, 0.3) if band == 0 else Color(0.5, 0.45, 0.95, 0.24)
		_fill_clipped(pts, frame, tint)


func _draw_ridge(frame: PackedVector2Array, ridge: Array) -> void:
	var color: Color = ridge[0]
	var base: float = ridge[1] * size.y
	var amplitude: float = ridge[2]
	var frequency: float = ridge[3]
	var phase: float = ridge[4]
	var pts := PackedVector2Array()
	for step in range(0, int(size.x) + int(RIDGE_STEP), int(RIDGE_STEP)):
		var x := minf(step, size.x)
		pts.append(Vector2(x, base + sin(x * frequency + phase) * amplitude + sin(x * frequency * 2.3 + phase * 1.7) * amplitude * 0.35))
	pts.append(Vector2(size.x, size.y))
	pts.append(Vector2(0.0, size.y))
	_fill_clipped(pts, frame, color)


func _fill_clipped(pts: PackedVector2Array, frame: PackedVector2Array, color: Color) -> void:
	for piece in Geometry2D.intersect_polygons(pts, frame):
		draw_colored_polygon(piece, color)


func _rounded_rect(rect: Rect2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [
		[rect.position + Vector2(radius, radius), PI],
		[Vector2(rect.end.x - radius, rect.position.y + radius), PI * 1.5],
		[rect.end - Vector2(radius, radius), 0.0],
		[Vector2(rect.position.x + radius, rect.end.y - radius), PI * 0.5],
	]
	for corner: Array in corners:
		for step in CORNER_STEPS + 1:
			var angle: float = (corner[1] as float) + (PI * 0.5) * step / CORNER_STEPS
			pts.append((corner[0] as Vector2) + Vector2(cos(angle), sin(angle)) * radius)
	return pts
