class_name Shapes
extends RefCounted
## Helpers for building code-drawn art.


static func circle(radius: float, center := Vector2.ZERO, segments := 36) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * i / segments
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts


static func rounded(pts: PackedVector2Array, radius: float, seg := 5) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var p := pts[i]
		var a := pts[(i - 1 + n) % n]
		var b := pts[(i + 1) % n]
		var start := p + (a - p).normalized() * minf(radius, p.distance_to(a) * 0.5)
		var end := p + (b - p).normalized() * minf(radius, p.distance_to(b) * 0.5)
		for k in range(seg + 1):
			var t := float(k) / seg
			out.append(start.lerp(p, t).lerp(p.lerp(end, t), t))
	return out


static func poly(parent: Node, pts: PackedVector2Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = color
	p.antialiased = true
	parent.add_child(p)
	return p


static func line(parent: Node, pts: PackedVector2Array, color: Color, width: float) -> Line2D:
	var l := Line2D.new()
	l.points = pts
	l.default_color = color
	l.width = width
	l.antialiased = true
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(l)
	return l


static func gradient(offsets: Array[float], colors: Array[Color]) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	return g


static func glow_texture(size: int, color: Color) -> GradientTexture2D:
	var clear := Color(color.r, color.g, color.b, 0.0)
	var tex := GradientTexture2D.new()
	tex.gradient = gradient([0.0, 1.0], [color, clear])
	tex.width = size
	tex.height = size
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


static func additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m
