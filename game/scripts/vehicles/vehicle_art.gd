class_name VehicleArt
extends RefCounted
## Shared drawing helpers for the vehicle specs. Everything is built from Polygon2D and Line2D;
## shapes that share a colour are merged into one node to keep the node count low.

const INK := Color("120d1f")
const SLATE := Color("1c2230")
const WELL := Color("0b1622")
const GLASS_DARK := Color("162338")
const CREAM := Color("fff1d6")
const CHROME := Color("c9d2e0")
const LAMP := Color("fff3c4")
const TAIL := Color("ff3b4e")
const DUMMY := Color("f7c62f")
const DUMMY_DARK := Color("e39a16")
const HEAD_OFFSET := Vector2(3.0, -27.0)
const HEAD_RADIUS := 13.0
const GLOW_SEGMENTS := 12
const ARC_STEPS := 10

static var _additive: CanvasItemMaterial


static func additive() -> CanvasItemMaterial:
	if _additive == null:
		_additive = Shapes.additive()
	return _additive


## A filled polygon with corners rounded by `radius`.
static func soft(parent: Node, pts: PackedVector2Array, color: Color, radius := 4.0) -> Polygon2D:
	return Shapes.poly(parent, Shapes.rounded(pts, radius), color)


## A polygon whose colour fades from `top` to `bottom` over its height.
static func shaded(parent: Node, pts: PackedVector2Array, top: Color, bottom: Color) -> Polygon2D:
	var node := Shapes.poly(parent, pts, Color.WHITE)
	var low := pts[0].y
	var high := pts[0].y
	for p in pts:
		low = minf(low, p.y)
		high = maxf(high, p.y)
	var span := maxf(high - low, 1.0)
	var colors := PackedColorArray()
	for p in pts:
		colors.append(top.lerp(bottom, (p.y - low) / span))
	node.vertex_colors = colors
	return node


## Several shapes of one colour in a single node.
static func merged(parent: Node, shapes: Array[PackedVector2Array], color: Color) -> Polygon2D:
	var verts := PackedVector2Array()
	var groups: Array = []
	for shape in shapes:
		var first := verts.size()
		verts.append_array(shape)
		var ids := PackedInt32Array()
		for k in shape.size():
			ids.append(first + k)
		groups.append(ids)
	var node := Shapes.poly(parent, verts, color)
	node.polygons = groups
	return node


static func stroke(parent: Node, pts: PackedVector2Array, color: Color, width: float, closed := false) -> Line2D:
	var node := Shapes.line(parent, pts, color, width)
	node.closed = closed
	return node


static func rect(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])


## A thin quad from `a` to `b`, used where a Line2D's round caps are not wanted.
static func bar(a: Vector2, b: Vector2, width: float) -> PackedVector2Array:
	var side := (b - a).normalized().orthogonal() * width * 0.5
	return PackedVector2Array([a + side, b + side, b - side, a - side])


static func arc(center: Vector2, radius: float, from_angle: float, to_angle: float, steps := ARC_STEPS) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		var a := lerpf(from_angle, to_angle, float(i) / steps)
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts


## A soft additive glow, bright at the centre and clear at the edge.
static func glow(parent: Node, center: Vector2, radius: float, color: Color) -> Polygon2D:
	var verts := PackedVector2Array([center])
	var colors := PackedColorArray([color])
	var groups: Array = []
	for i in GLOW_SEGMENTS:
		var a := TAU * i / GLOW_SEGMENTS
		verts.append(center + Vector2(cos(a), sin(a)) * radius)
		colors.append(Color(color, 0.0))
		groups.append(PackedInt32Array([0, 1 + i, 1 + (i + 1) % GLOW_SEGMENTS]))
	var node := Shapes.poly(parent, verts, Color.WHITE)
	node.polygons = groups
	node.vertex_colors = colors
	node.antialiased = false
	node.material = additive()
	return node


## A forward light cone, fading with distance.
static func beam(parent: Node, from: Vector2, length: float, spread: float) -> Polygon2D:
	var near := Color(1.0, 0.92, 0.66, 0.22)
	var far := Color(1.0, 0.92, 0.66, 0.0)
	var node := Shapes.poly(parent, PackedVector2Array([from + Vector2(0, -2), from + Vector2(length, -spread), from + Vector2(length, spread * 1.8), from + Vector2(0, 4)]), Color.WHITE)
	node.vertex_colors = PackedColorArray([near, far, far, near])
	node.material = additive()
	return node


## A window: dark interior (draw the dummy after this), then call glass_sheen on top of it.
static func window_interior(parent: Node, pts: PackedVector2Array) -> Polygon2D:
	return shaded(parent, pts, Color("22344f"), GLASS_DARK)


## Translucent tint and two reflection streaks over a window. `streak` is where the
## streaks start along the window's top edge and `drop` is how far they slant down.
static func glass_sheen(parent: Node, pts: PackedVector2Array, streak: Vector2, drop: Vector2, width: float) -> void:
	var tint := Color(0.55, 0.78, 1.0, 0.22)
	Shapes.poly(parent, pts, tint)
	var a := streak
	var b := streak + drop
	var shapes: Array[PackedVector2Array] = [
		PackedVector2Array([a, a + Vector2(width, 0.0), b + Vector2(width, 0.0), b]),
		PackedVector2Array([a + Vector2(width * 1.7, 0.0), a + Vector2(width * 2.1, 0.0), b + Vector2(width * 2.1, 0.0), b + Vector2(width * 1.7, 0.0)]),
	]
	merged(parent, shapes, Color(1.0, 1.0, 1.0, 0.2))


## A headlight: lens, bright core, halo.
static func headlight(parent: Node, center: Vector2, size: Vector2, halo: float) -> void:
	soft(parent, rect(center.x - size.x * 0.5, center.y - size.y * 0.5, center.x + size.x * 0.5, center.y + size.y * 0.5), Color("e9e4d6"), minf(size.x, size.y) * 0.4)
	soft(parent, rect(center.x - size.x * 0.3, center.y - size.y * 0.3, center.x + size.x * 0.4, center.y + size.y * 0.3), LAMP, minf(size.x, size.y) * 0.3)
	glow(parent, center + Vector2(size.x * 0.4, 0.0), halo, Color(1.0, 0.93, 0.7, 0.55))


static func taillight(parent: Node, center: Vector2, size: Vector2, halo: float) -> void:
	soft(parent, rect(center.x - size.x * 0.5, center.y - size.y * 0.5, center.x + size.x * 0.5, center.y + size.y * 0.5), Color("a1182a"), minf(size.x, size.y) * 0.4)
	soft(parent, rect(center.x - size.x * 0.35, center.y - size.y * 0.35, center.x + size.x * 0.35, center.y + size.y * 0.35), TAIL, minf(size.x, size.y) * 0.3)
	glow(parent, center - Vector2(size.x * 0.3, 0.0), halo, Color(1.0, 0.25, 0.3, 0.4))


## A mud-splash band along the bottom of a panel: a ragged edge that fades upward.
static func dirt(parent: Node, x0: float, x1: float, bottom: float, height: float, color: Color, seed_value := 1) -> Polygon2D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var verts := PackedVector2Array()
	var colors := PackedColorArray()
	var steps := maxi(int((x1 - x0) / 9.0), 2)
	for i in steps + 1:
		var x := lerpf(x0, x1, float(i) / steps)
		verts.append(Vector2(x, bottom - height * rng.randf_range(0.45, 1.0)))
		colors.append(Color(color, 0.0))
	for i in range(steps, -1, -1):
		verts.append(Vector2(lerpf(x0, x1, float(i) / steps), bottom))
		colors.append(color)
	var node := Shapes.poly(parent, verts, Color.WHITE)
	node.vertex_colors = colors
	return node


## A small chrome door handle.
static func handle(parent: Node, center: Vector2, length: float, color: Color) -> void:
	var half := length * 0.5
	soft(parent, rect(center.x - half, center.y - 1.6, center.x + half, center.y + 1.6), color, 1.4)


## A side mirror on a short stalk, facing forward.
static func mirror(parent: Node, stalk: Vector2, color: Color) -> void:
	Shapes.line(parent, PackedVector2Array([stalk, stalk + Vector2(5.0, -3.0)]), SLATE, 3.0)
	soft(parent, PackedVector2Array([stalk + Vector2(2, -9), stalk + Vector2(11, -9), stalk + Vector2(12, 0), stalk + Vector2(3, 0)]), color, 2.5)
	Shapes.poly(parent, PackedVector2Array([stalk + Vector2(5, -7), stalk + Vector2(10, -7), stalk + Vector2(10.5, -2), stalk + Vector2(5.5, -2)]), Color("9fc4e8"))


## A round number plate: coloured disc, dark ring, and the digits.
static func roundel(parent: Node, center: Vector2, radius: float, disc: Color, ink: Color, text: String) -> void:
	Shapes.poly(parent, Shapes.circle(radius + 1.6, center, 24), Color(ink, 0.9))
	Shapes.poly(parent, Shapes.circle(radius, center, 24), disc)
	digits(parent, text, center, radius * 1.15, ink)


const SEGMENTS := {
	"0": "abcdef", "1": "bc", "2": "abdeg", "3": "abcdg", "4": "bcfg",
	"5": "acdfg", "6": "acdefg", "7": "abc", "8": "abcdefg", "9": "abcdfg",
}


## Seven-segment digits centred on `center`, `height` tall, in one merged node.
static func digits(parent: Node, text: String, center: Vector2, height: float, color: Color) -> void:
	var half_w := height * 0.22
	var half_h := height * 0.5
	var thick := maxf(height * 0.17, 1.5)
	var advance := half_w * 2.0 + thick * 1.6
	var x0 := center.x - advance * (text.length() - 1) * 0.5
	var shapes: Array[PackedVector2Array] = []
	for n in text.length():
		var cx := x0 + advance * n
		var cy := center.y
		var table := {
			"a": [Vector2(-half_w, -half_h), Vector2(half_w, -half_h)],
			"b": [Vector2(half_w, -half_h), Vector2(half_w, 0.0)],
			"c": [Vector2(half_w, 0.0), Vector2(half_w, half_h)],
			"d": [Vector2(-half_w, half_h), Vector2(half_w, half_h)],
			"e": [Vector2(-half_w, 0.0), Vector2(-half_w, half_h)],
			"f": [Vector2(-half_w, -half_h), Vector2(-half_w, 0.0)],
			"g": [Vector2(-half_w, 0.0), Vector2(half_w, 0.0)],
		}
		for segment: String in SEGMENTS.get(text[n], ""):
			var ends: Array = table[segment]
			var a: Vector2 = ends[0] + Vector2(cx, cy)
			var b: Vector2 = ends[1] + Vector2(cx, cy)
			shapes.append(bar(a, b, thick))
	if not shapes.is_empty():
		merged(parent, shapes, color)


## The crash-test dummy, drawn around its torso centre. Returns the node it was added to.
## Seated, its legs are left out (they are hidden in the car); a loose dummy has them.
static func add_dummy(parent: Node2D, at: Vector2) -> Node2D:
	var node := Node2D.new()
	node.position = at
	parent.add_child(node)
	draw_dummy(node, false)
	return node


static func draw_dummy(parent: Node, with_legs: bool) -> void:
	if with_legs:
		Shapes.line(parent, PackedVector2Array([Vector2(-6, 14), Vector2(22, 17), Vector2(27, 42)]), DUMMY_DARK, 9.0)
		Shapes.poly(parent, Shapes.circle(5.0, Vector2(27, 43), 10), SLATE)
	Shapes.poly(parent, Shapes.rounded(PackedVector2Array([Vector2(-14, 16), Vector2(8, 16), Vector2(11, -12), Vector2(-9, -15)]), 6.0), DUMMY_DARK)
	Shapes.poly(parent, Shapes.circle(5.5, Vector2.ZERO, 16), SLATE)
	Shapes.poly(parent, Shapes.circle(2.5, Vector2.ZERO, 12), DUMMY)
	Shapes.line(parent, PackedVector2Array([Vector2(-8, -13), Vector2(7, 15)]), Color(SLATE, 0.75), 3.0)
	Shapes.line(parent, PackedVector2Array([Vector2(2, -14), Vector2(2, -19)]), SLATE, 7.0)
	Shapes.poly(parent, Shapes.circle(HEAD_RADIUS, HEAD_OFFSET), DUMMY)
	Shapes.line(parent, arc(HEAD_OFFSET, HEAD_RADIUS - 3.0, PI * 1.1, PI * 1.55, 6), Color(1, 1, 1, 0.5), 2.0)
	var marker := HEAD_OFFSET + Vector2(4.0, 0.0)
	Shapes.poly(parent, Shapes.circle(7.0, marker, 24), CREAM)
	for quarter in [0.0, PI]:
		var pie := PackedVector2Array([marker])
		for k in 9:
			var a: float = quarter + (PI * 0.5) * k / 8.0
			pie.append(marker + Vector2(cos(a), sin(a)) * 7.0)
		Shapes.poly(parent, pie, SLATE)
	Shapes.line(parent, PackedVector2Array([Vector2(1, -8), Vector2(18, 1), Vector2(34, -3)]), DUMMY, 6.5)
	Shapes.poly(parent, Shapes.circle(4.5, Vector2(35, -3), 14), SLATE)


## A wheel: tread-block tyre, sidewall, rim with spokes, hub and bolts. `style` keys:
## tread (block count), depth, skew, tyre, side, rim (radius ratio), rim_color, dish_color,
## spokes, spoke_width, bolts, bolt_at (bolt circle as a ratio of the rim radius), hub_color.
static func draw_wheel(wheel: Node2D, radius: float, style: Dictionary) -> void:
	var depth: float = style.get("depth", 4.0)
	var tyre: Color = style.get("tyre", Color("17151f"))
	var side: Color = style.get("side", Color("24212f"))
	var rim_radius: float = radius * float(style.get("rim", 0.58))
	Shapes.poly(wheel, _tread_outline(radius, depth, int(style.get("tread", 18)), float(style.get("skew", 0.0))), tyre)
	Shapes.poly(wheel, Shapes.circle(radius - depth - 0.5, Vector2.ZERO, 36), side)
	Shapes.line(wheel, arc(Vector2.ZERO, radius * 0.8, 0.0, TAU, 28), Color(1, 1, 1, 0.07), 2.0)
	Shapes.line(wheel, arc(Vector2.ZERO, rim_radius + (radius - depth - rim_radius) * 0.5, PI * 1.05, PI * 1.45, 8), Color(1, 1, 1, 0.14), 2.0)
	var rim_color: Color = style.get("rim_color", Color("e8e2d6"))
	var dish_color: Color = style.get("dish_color", rim_color.darkened(0.45))
	Shapes.poly(wheel, Shapes.circle(rim_radius, Vector2.ZERO, 32), rim_color)
	Shapes.poly(wheel, Shapes.circle(rim_radius * 0.82, Vector2.ZERO, 28), dish_color)
	_draw_spokes(wheel, rim_radius, int(style.get("spokes", 5)), float(style.get("spoke_width", 3.4)), rim_color)
	var hub_color: Color = style.get("hub_color", rim_color.darkened(0.2))
	Shapes.poly(wheel, Shapes.circle(rim_radius * 0.26, Vector2.ZERO, 14), hub_color)
	_draw_bolts(wheel, rim_radius, int(style.get("bolts", 5)), float(style.get("bolt_at", 0.5)))
	Shapes.line(wheel, arc(Vector2.ZERO, rim_radius - 1.0, PI * 1.15, PI * 1.5, 6), Color(1, 1, 1, 0.45), 1.6)


static func _tread_outline(radius: float, depth: float, blocks: int, skew: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var step := TAU / blocks
	var inner := radius - depth
	for i in blocks:
		var a := step * i
		for entry: Array in [[0.04, inner], [0.16 + skew, radius], [0.68 + skew, radius], [0.82, inner]]:
			var angle: float = a + step * float(entry[0])
			var r: float = entry[1]
			pts.append(Vector2(cos(angle), sin(angle)) * r)
	return pts


static func _draw_spokes(wheel: Node, rim_radius: float, count: int, width: float, color: Color) -> void:
	if count <= 0:
		return
	var shapes: Array[PackedVector2Array] = []
	for i in count:
		var dir := Vector2.from_angle(TAU * i / count)
		shapes.append(bar(dir * rim_radius * 0.18, dir * rim_radius * 0.8, width))
	merged(wheel, shapes, color)


static func _draw_bolts(wheel: Node, rim_radius: float, count: int, at: float) -> void:
	if count <= 0:
		return
	var shapes: Array[PackedVector2Array] = []
	for i in count:
		var angle := TAU * i / count + PI / count
		shapes.append(Shapes.circle(maxf(rim_radius * 0.07, 1.4), Vector2.from_angle(angle) * rim_radius * at, 8))
	merged(wheel, shapes, Color("2a2638"))
