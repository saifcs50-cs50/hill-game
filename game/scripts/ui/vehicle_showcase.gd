class_name VehicleShowcase
extends Control
## Spotlit stage that shows one vehicle: a soft glow, a ground shadow and the vehicle art.
##
## make_art() is the only place that knows what a vehicle looks like here. It returns a Node2D
## laid out like the in-game vehicle: origin at the chassis centre, +x forward (facing right),
## tyres resting on y = ART_GROUND_Y, everything inside ART_BOUNDS. It currently returns simple
## placeholder silhouettes; `Vehicle.build_art(vehicle_id)` builds the full in-game art and
## follows the same layout. The showcase scales, places, bobs and darkens it (when locked) by itself.

const ART_BOUNDS := Rect2(-150.0, -105.0, 300.0, 185.0)
const ART_GROUND_Y := 70.0
const FILL := 0.9
const BOB_HEIGHT := 4.0
const BOB_TIME := 1.1
const SLIDE_DISTANCE := 90.0
const SLIDE_TIME := 0.28
const DEFAULT_EDGE := [2, 7]
const LOCKED_TINT := Color(0.46, 0.4, 0.64)
const WINDOW := Color("bfeff2")
const TYRE := Color("17151f")
const RIM := Color("d9cde8")
const SLATE := Color("1c2230")
const LIGHT := Color("fff1d6")
const TAIL := Color("ff4d5e")

## Placeholder silhouettes, in art coordinates (origin at the chassis centre).
const PLACEHOLDERS := {
	"hatchback": {
		"color": Color("19b8b0"), "wheel_x": 62.0, "wheel_r": 28.0,
		"body": [Vector2(-98, 20), Vector2(-100, -8), Vector2(-76, -20), Vector2(-46, -24), Vector2(-22, -58),
			Vector2(44, -58), Vector2(70, -24), Vector2(98, -16), Vector2(106, 20)],
		"window": [Vector2(-14, -50), Vector2(40, -50), Vector2(58, -28), Vector2(-26, -28)],
		"extra": [],
	},
	"pickup": {
		"color": Color("f47c4e"), "wheel_x": 74.0, "wheel_r": 32.0,
		"body": [Vector2(-114, 20), Vector2(-114, -32), Vector2(-100, -32), Vector2(-100, -14), Vector2(-62, -14),
			Vector2(-62, -34), Vector2(-48, -64), Vector2(14, -64), Vector2(40, -34), Vector2(98, -28),
			Vector2(112, -8), Vector2(112, 20)],
		"edge": [5, 10],
		"window": [Vector2(-38, -58), Vector2(8, -58), Vector2(28, -36), Vector2(-42, -36)],
		"extra": [],
	},
	"monster": {
		"color": Color("ff5d73"), "wheel_x": 74.0, "wheel_r": 48.0,
		"body": [Vector2(-92, -2), Vector2(-92, -36), Vector2(-66, -46), Vector2(-36, -48), Vector2(-18, -80),
			Vector2(38, -80), Vector2(58, -48), Vector2(90, -40), Vector2(98, -2), Vector2(84, 8), Vector2(-80, 8)],
		"window": [Vector2(-8, -72), Vector2(32, -72), Vector2(46, -50), Vector2(-14, -50)],
		"extra": [],
	},
	"supercar": {
		"color": Color("ffc93c"), "wheel_x": 76.0, "wheel_r": 24.0,
		"body": [Vector2(-108, 22), Vector2(-112, 0), Vector2(-72, -12), Vector2(-30, -20), Vector2(4, -46),
			Vector2(40, -46), Vector2(70, -18), Vector2(112, -6), Vector2(118, 18), Vector2(106, 26)],
		"window": [Vector2(2, -40), Vector2(36, -40), Vector2(56, -22), Vector2(-14, -22)],
		"extra": [{"poly": [Vector2(-114, -14), Vector2(-114, -36), Vector2(-92, -36), Vector2(-92, -30),
			Vector2(-106, -30), Vector2(-106, -14)], "color": SLATE}],
	},
}

var _vehicle_id := ""
var _owned := true
var _holder := Node2D.new()
var _art: Node2D
var _bob_tween: Tween
var _glow := Shapes.glow_texture(256, Color(1.0, 0.68, 0.42, 0.55))


## The art seam described in the class comment. Placeholder silhouettes for now.
static func make_art(vehicle_id: String) -> Node2D:
	var spec: Dictionary = PLACEHOLDERS.get(vehicle_id, PLACEHOLDERS["hatchback"])
	return _build_placeholder(spec)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	add_child(_holder)
	resized.connect(_fit)


## Shows a vehicle. `slide` is -1 or 1 to slide in from the left or right, 0 for no animation.
func show_vehicle(vehicle_id: String, owned: bool, slide: int = 0) -> void:
	if _art != null:
		_art.queue_free()
	_vehicle_id = vehicle_id
	_art = make_art(vehicle_id)
	_holder.add_child(_art)
	set_owned(owned)
	_fit()
	_animate_in(slide)


func set_owned(owned: bool) -> void:
	_owned = owned
	if _art != null:
		_art.modulate = Color.WHITE if owned else LOCKED_TINT
	queue_redraw()


func _draw() -> void:
	var ground := _ground_point()
	var radius := minf(size.x, size.y * 1.6) * 0.5
	draw_texture_rect(_glow, Rect2(ground + Vector2(-radius, -radius * 1.05), Vector2(radius, radius) * 2.0), false)
	draw_set_transform(ground + Vector2(0.0, 6.0), 0.0, Vector2(1.0, 0.16))
	draw_circle(Vector2.ZERO, size.x * 0.34, Color(0.02, 0.0, 0.08, 0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not _owned:
		UiKit.draw_lock(self, Vector2(size.x - 52.0, 52.0), 54.0, Color(UiKit.CREAM, 0.9))


func _ground_point() -> Vector2:
	return _holder.position + Vector2(0.0, ART_GROUND_Y * _holder.scale.y)


func _fit() -> void:
	var fit := minf(size.x / ART_BOUNDS.size.x, size.y / ART_BOUNDS.size.y) * FILL
	_holder.scale = Vector2.ONE * fit
	_holder.position = size * 0.5 - ART_BOUNDS.get_center() * fit
	queue_redraw()


func _animate_in(slide: int) -> void:
	if _bob_tween != null and _bob_tween.is_valid():
		_bob_tween.kill()
	if slide != 0:
		_art.position.x = slide * SLIDE_DISTANCE
		_art.modulate.a = 0.0
		var slide_tween := UiKit.tween(self).set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		slide_tween.tween_property(_art, "position:x", 0.0, SLIDE_TIME)
		slide_tween.tween_property(_art, "modulate:a", 1.0, SLIDE_TIME)
	_bob_tween = UiKit.tween(self).set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(_art, "position:y", -BOB_HEIGHT, BOB_TIME)
	_bob_tween.tween_property(_art, "position:y", BOB_HEIGHT * 0.3, BOB_TIME)


static func _build_placeholder(spec: Dictionary) -> Node2D:
	var art := Node2D.new()
	var color: Color = spec["color"]
	var wheel_x: float = spec["wheel_x"]
	var wheel_r: float = spec["wheel_r"]
	var wheel_y := ART_GROUND_Y - wheel_r
	Shapes.poly(art, Shapes.rounded(PackedVector2Array(spec["body"]), 12.0), color)
	var edge: Array = spec.get("edge", DEFAULT_EDGE)
	var top_edge := PackedVector2Array(spec["body"]).slice(edge[0], edge[1])
	Shapes.line(art, top_edge, color.lightened(0.35), 4.0)
	Shapes.poly(art, Shapes.rounded(PackedVector2Array(spec["window"]), 6.0), WINDOW)
	for extra: Dictionary in spec["extra"]:
		Shapes.poly(art, Shapes.rounded(PackedVector2Array(extra["poly"]), 3.0), extra["color"])
	var body_pts := PackedVector2Array(spec["body"])
	Shapes.poly(art, Shapes.circle(4.5, body_pts[body_pts.size() - 2] + Vector2(-8, 4)), LIGHT)
	Shapes.poly(art, Shapes.circle(4.0, body_pts[0] + Vector2(6, -14)), TAIL)
	for side: float in [-1.0, 1.0]:
		var center := Vector2(wheel_x * side, wheel_y)
		Shapes.poly(art, Shapes.circle(wheel_r + 7.0, center), SLATE)
		_add_wheel(art, center, wheel_r)
	return art


static func _add_wheel(art: Node2D, center: Vector2, wheel_r: float) -> void:
	Shapes.poly(art, Shapes.circle(wheel_r, center, 40), TYRE)
	Shapes.poly(art, Shapes.circle(wheel_r * 0.58, center, 32), RIM)
	Shapes.poly(art, Shapes.circle(wheel_r * 0.2, center, 16), SLATE)
