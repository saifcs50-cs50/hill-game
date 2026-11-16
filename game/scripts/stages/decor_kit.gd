class_name DecorKit
extends RefCounted
## Small reusable shapes for stage decoration, all written into a StageMesh.


static func shade(color: Color, k: float) -> Color:
	return Color(color.r * k, color.g * k, color.b * k, color.a)


static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


## One grass blade: a thin triangle leaning by `lean`, darker at the root.
static func blade(m: StageMesh, root: Vector2, height: float, lean: float, width: float, c_root: Color, c_tip: Color) -> void:
	m.tri_gradient(root + Vector2(-width * 0.5, 2.0), root + Vector2(width * 0.5, 2.0), root + Vector2(lean, -height), c_root, c_root, c_tip)


## A fan of blades from one root.
static func tuft(m: StageMesh, root: Vector2, count: int, h_min: float, h_max: float, spread: float, rng: RandomNumberGenerator, c_root: Color, c_tip: Color) -> void:
	for i in count:
		var t := (float(i) / maxf(count - 1, 1.0)) * 2.0 - 1.0
		var h := rng.randf_range(h_min, h_max) * (1.0 - 0.35 * absf(t))
		blade(m, root + Vector2(t * 2.0, 0.0), h, t * spread + rng.randf_range(-3.0, 3.0), rng.randf_range(2.6, 4.2), c_root, c_tip)


## A rounded stone lit from spec.light_dir. `size` is the half-width and height.
static func rock(m: StageMesh, base: Vector2, size: Vector2, rng: RandomNumberGenerator, light_dir: Vector2, c_lit: Color, c_shade: Color, sink := 4.0) -> void:
	var count := 8
	var outline := PackedVector2Array()
	var colors := PackedColorArray()
	var center := base + Vector2(0.0, -size.y * 0.35)
	for i in count + 1:
		var a := PI + PI * i / count
		var r := rng.randf_range(0.82, 1.08)
		var p := base + Vector2(cos(a) * size.x * r, sin(a) * size.y * r)
		outline.append(p)
		var dir := (p - center).normalized()
		colors.append(c_shade.lerp(c_lit, clampf(dir.dot(light_dir) * 0.5 + 0.55, 0.0, 1.0)))
	outline.append(base + Vector2(size.x * 0.9, sink))
	colors.append(shade(c_shade, 0.8))
	outline.append(base + Vector2(-size.x * 0.9, sink))
	colors.append(shade(c_shade, 0.8))
	var ic := m.vert(center, c_shade.lerp(c_lit, 0.55))
	var first := m.vertex_count()
	for i in outline.size():
		m.vert(outline[i], colors[i])
	for i in outline.size():
		m.index_tri(ic, first + i, first + (i + 1) % outline.size())


## A small irregular pebble, lighter in the middle.
static func pebble(m: StageMesh, center: Vector2, radius: float, rng: RandomNumberGenerator, color: Color) -> void:
	var pts := PackedVector2Array()
	var count := 6
	var squash := rng.randf_range(0.55, 0.9)
	var turn := rng.randf() * TAU
	for i in count:
		var a := turn + TAU * i / count
		var r := radius * rng.randf_range(0.75, 1.1)
		pts.append(center + Vector2(cos(a) * r, sin(a) * r * squash))
	m.fan(pts, shade(color, 0.78), color.lightened(0.28))


## Pointed star or glint with `points` spikes.
static func star(m: StageMesh, center: Vector2, radius: float, color: Color, points := 4, inner := 0.28, turn := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in points * 2:
		var a := turn + PI * i / points - PI * 0.5
		var r := radius if i % 2 == 0 else radius * inner
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	m.fan(pts, color)


## A conifer made of stacked triangles, darker on the left and lit on the right.
## `snow` (alpha > 0) adds white caps on the tiers.
static func pine(m: StageMesh, foot: Vector2, height: float, tiers: int, c_dark: Color, c_lit: Color, snow := Color(0, 0, 0, 0)) -> void:
	var trunk := Color(c_dark.r * 0.6, c_dark.g * 0.55, c_dark.b * 0.6)
	m.quad(foot + Vector2(-height * 0.035, 4.0), foot + Vector2(height * 0.035, 4.0), foot + Vector2(height * 0.03, -height * 0.2), foot + Vector2(-height * 0.03, -height * 0.2), trunk)
	for t in tiers:
		var f := float(t) / tiers
		var y_base := -height * (0.12 + 0.78 * f * (1.0 - 0.15))
		var y_tip := -height * (0.38 + 0.62 * (f + 1.0 / tiers) * 0.98)
		var half := height * 0.34 * (1.0 - f * 0.78)
		var base_l := foot + Vector2(-half, y_base)
		var base_r := foot + Vector2(half, y_base)
		var tip := foot + Vector2(0.0, y_tip)
		var mid := c_dark.lerp(c_lit, 0.45)
		m.tri_gradient(base_l, base_r, tip, c_dark, c_lit, mid)
		if snow.a > 0.0:
			var cap := 0.5
			var cl := base_l.lerp(tip, cap)
			var cr := base_r.lerp(tip, cap)
			m.tri_gradient(cl + Vector2(-half * 0.05, 0.0), cr + Vector2(half * 0.05, 0.0), tip, snow.darkened(0.12), snow, snow)
			m.ellipse(base_l.lerp(base_r, 0.5) + Vector2(0.0, -2.0), half * 0.9, 2.5, snow.darkened(0.05), with_alpha(snow, 0.0), 8)


## A rounded bush: a tall middle lump with smaller ones at the sides, lit towards the light.
static func bush(m: StageMesh, base: Vector2, radius: float, rng: RandomNumberGenerator, c_dark: Color, c_lit: Color, light_dir: Vector2) -> void:
	var lumps := rng.randi_range(3, 5)
	for i in lumps:
		var f := float(i) / (lumps - 1) - 0.5
		var r := radius * (0.5 + 0.5 * (1.0 - absf(f) * 2.0)) * rng.randf_range(0.9, 1.1)
		var c := base + Vector2(f * radius * 1.7, -r * 0.7)
		m.ellipse(c, r, r * 0.92, c_dark.lerp(c_lit, 0.3), c_dark, 12)
		m.ellipse(c + light_dir * Vector2(r * 0.3, r * 0.35), r * 0.55, r * 0.45, c_lit, with_alpha(c_lit, 0.0), 8)


## A saguaro cactus with two arms; `c_light` is a thin highlight on the right-hand side.
static func cactus(m: StageMesh, foot: Vector2, height: float, c_main: Color, c_light: Color) -> void:
	var w := maxf(height * 0.13, 3.0)
	var arm_w := w * 0.72
	var top_y := foot.y - height + w * 0.5
	m.line(foot + Vector2(0.0, 4.0), Vector2(foot.x, top_y), w, c_main)
	m.ellipse(Vector2(foot.x, top_y), w * 0.5, w * 0.5, c_main, c_main, 8)
	for side: float in [-1.0, 1.0]:
		var y0 := foot.y - height * (0.4 if side < 0.0 else 0.55)
		var reach := height * (0.26 if side < 0.0 else 0.22)
		var rise := height * (0.3 if side < 0.0 else 0.24)
		var elbow := Vector2(foot.x + side * reach, y0)
		var tip := elbow + Vector2(0.0, -rise)
		m.line(Vector2(foot.x, y0), elbow, arm_w, c_main)
		m.line(elbow, tip, arm_w, c_main)
		m.ellipse(elbow, arm_w * 0.5, arm_w * 0.5, c_main, c_main, 8)
		m.ellipse(tip, arm_w * 0.5, arm_w * 0.5, c_main, c_main, 8)
		m.line(elbow + Vector2(arm_w * 0.2, 0.0), tip + Vector2(arm_w * 0.2, 0.0), arm_w * 0.22, c_light)
	m.line(foot + Vector2(w * 0.2, 0.0), Vector2(foot.x + w * 0.2, top_y), w * 0.22, c_light)


## A windmill silhouette: tapered tower, hub and four blades.
static func windmill(m: StageMesh, foot: Vector2, height: float, color: Color) -> void:
	var half_b := height * 0.12
	var half_t := height * 0.06
	var top := foot + Vector2(0.0, -height)
	m.quad(foot + Vector2(-half_b, 4.0), foot + Vector2(half_b, 4.0), top + Vector2(half_t, 0.0), top + Vector2(-half_t, 0.0), color)
	m.tri(top + Vector2(-half_t * 1.3, 0.0), top + Vector2(half_t * 1.3, 0.0), top + Vector2(0.0, -height * 0.14), color)
	var hub := top + Vector2(0.0, -height * 0.02)
	for i in 4:
		var a := 0.35 + PI * 0.5 * i
		var dir := Vector2(cos(a), sin(a))
		var side := Vector2(-dir.y, dir.x)
		m.quad(hub + dir * height * 0.06 + side * height * 0.025, hub + dir * height * 0.58 + side * height * 0.035,
			hub + dir * height * 0.58 - side * height * 0.01, hub + dir * height * 0.06 - side * height * 0.025, color)
	m.ellipse(hub, height * 0.04, height * 0.04, color, color, 8)


## A small farmhouse with a lit window.
static func farmhouse(m: StageMesh, foot: Vector2, width: float, color: Color, window: Color) -> void:
	var h := width * 0.55
	m.quad(foot + Vector2(-width * 0.5, 4.0), foot + Vector2(width * 0.5, 4.0), foot + Vector2(width * 0.5, -h), foot + Vector2(-width * 0.5, -h), color)
	m.tri(foot + Vector2(-width * 0.62, -h + 2.0), foot + Vector2(width * 0.62, -h + 2.0), foot + Vector2(0.0, -h - width * 0.42), color)
	m.quad(foot + Vector2(width * 0.2, -h - width * 0.2), foot + Vector2(width * 0.32, -h - width * 0.1), foot + Vector2(width * 0.32, -h - width * 0.4), foot + Vector2(width * 0.2, -h - width * 0.4), color)
	m.quad(foot + Vector2(-width * 0.1, -h * 0.75), foot + Vector2(width * 0.12, -h * 0.75), foot + Vector2(width * 0.12, -h * 0.35), foot + Vector2(-width * 0.1, -h * 0.35), window)
