class_name DecorDesert
extends RefCounted
## Late-afternoon desert: sandstone buttes and arches, saguaros, wind ripples and dry grass.

const ROCK_SHADE := Color("7d3f2e")
const ROCK_MID := Color("a85a3a")
const ROCK_LIT := Color("e08c54")
const CACTUS := Color("2f6b50")
const CACTUS_LIGHT := Color("6fb27a")
const GRASS_ROOT := Color("8a6a30")
const GRASS_TIP := Color("f0d68a")


static func parts() -> Array:
	return [
		{"layer": "props", "build": Callable(DecorDesert, "formations")},
		{"layer": "props", "build": Callable(DecorDesert, "cacti")},
		{"layer": "soil", "build": Callable(DecorDesert, "ripples")},
		{"layer": "front", "build": Callable(DecorDesert, "dry_grass")},
		{"layer": "front", "build": Callable(DecorDesert, "barrels")},
	]


## Sandstone buttes, arches and hoodoos standing behind the dunes.
static func formations(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0 + rng.randf_range(200.0, 900.0)
	while x < ctx.x1 - 250.0:
		var foot := Vector2(x, ctx.y_at(x) + 14.0)
		var roll := rng.randf()
		if roll < 0.45:
			_butte(m, foot, rng.randf_range(150.0, 300.0), rng.randf_range(110.0, 230.0), rng)
		elif roll < 0.7:
			_arch(m, foot, rng.randf_range(80.0, 140.0), rng)
		else:
			for i in rng.randi_range(2, 3):
				_hoodoo(m, foot + Vector2(i * rng.randf_range(34.0, 52.0) - 40.0, 0.0), rng.randf_range(70.0, 150.0), rng)
		x += rng.randf_range(1100.0, 2200.0)


static func _rock_band(m: StageMesh, xl_b: float, xr_b: float, xl_t: float, xr_t: float, y_b: float, y_t: float, k: float) -> void:
	var shade := DecorKit.shade(ROCK_SHADE.lerp(ROCK_MID, k), 1.0)
	var lit := ROCK_MID.lerp(ROCK_LIT, k)
	m.quad_gradient(Vector2(xl_b, y_b), Vector2(xr_b, y_b), Vector2(xr_t, y_t), Vector2(xl_t, y_t), shade, lit, lit, shade)


static func _butte(m: StageMesh, foot: Vector2, width: float, height: float, rng: RandomNumberGenerator) -> void:
	var bands := rng.randi_range(4, 6)
	var y := foot.y
	var half := width * 0.5
	for b in bands:
		var band_h := height / bands * rng.randf_range(0.7, 1.3)
		var flare := 1.0 + 0.35 * pow(1.0 - float(b) / bands, 3.0)
		var next_flare := 1.0 + 0.35 * pow(1.0 - float(b + 1) / bands, 3.0)
		var k := rng.randf_range(0.2, 0.9)
		_rock_band(m, foot.x - half * flare, foot.x + half * flare, foot.x - half * next_flare, foot.x + half * next_flare, y, y - band_h, k)
		var crack := foot.x + rng.randf_range(-half, half) * 0.8
		m.line(Vector2(crack, y), Vector2(crack + rng.randf_range(-4.0, 4.0), y - band_h), 2.0, DecorKit.with_alpha(ROCK_SHADE, 0.45))
		y -= band_h
	var cap := half * (1.0 + 0.02)
	m.quad(Vector2(foot.x - cap, y + 3.0), Vector2(foot.x + cap, y + 3.0), Vector2(foot.x + cap * 0.97, y - 6.0), Vector2(foot.x - cap * 0.97, y - 6.0), ROCK_LIT.lightened(0.12))


static func _hoodoo(m: StageMesh, foot: Vector2, height: float, rng: RandomNumberGenerator) -> void:
	var half := height * rng.randf_range(0.1, 0.16)
	var cap := half * 1.5
	var neck := half * 0.7
	var y_neck := foot.y - height * 0.7
	m.quad_gradient(foot + Vector2(-half * 1.3, 0.0), foot + Vector2(half * 1.3, 0.0), Vector2(foot.x + neck, y_neck), Vector2(foot.x - neck, y_neck), ROCK_SHADE, ROCK_MID, ROCK_MID.lerp(ROCK_LIT, 0.5), ROCK_SHADE)
	m.quad_gradient(Vector2(foot.x - cap, y_neck), Vector2(foot.x + cap, y_neck), Vector2(foot.x + cap, foot.y - height), Vector2(foot.x - cap, foot.y - height), ROCK_SHADE.lerp(ROCK_MID, 0.4), ROCK_LIT, ROCK_LIT, ROCK_MID)


static func _arch(m: StageMesh, foot: Vector2, radius: float, rng: RandomNumberGenerator) -> void:
	var inner := radius * rng.randf_range(0.5, 0.68)
	var pillar := radius * 0.55
	var center := Vector2(foot.x, foot.y - pillar)
	for side: float in [-1.0, 1.0]:
		var xo := foot.x + side * radius
		var xi := foot.x + side * inner
		var shade := ROCK_SHADE if side < 0.0 else ROCK_MID
		var lit := ROCK_MID if side < 0.0 else ROCK_LIT
		m.quad_gradient(Vector2(xo, foot.y), Vector2(xi, foot.y), Vector2(xi, center.y), Vector2(xo, center.y), shade, lit, lit, shade)
	var steps := 16
	for i in steps:
		var a0 := PI + PI * i / steps
		var a1 := PI + PI * (i + 1) / steps
		var c0 := ROCK_SHADE.lerp(ROCK_LIT, float(i) / steps)
		var c1 := ROCK_SHADE.lerp(ROCK_LIT, float(i + 1) / steps)
		m.quad_gradient(center + Vector2(cos(a0), sin(a0)) * radius, center + Vector2(cos(a0), sin(a0)) * inner,
			center + Vector2(cos(a1), sin(a1)) * inner, center + Vector2(cos(a1), sin(a1)) * radius, c0, c0, c1, c1)


## Saguaros behind the dunes.
static func cacti(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0 + rng.randf_range(100.0, 400.0)
	while x < ctx.x1 - 80.0:
		var height := rng.randf_range(70.0, 140.0)
		DecorKit.cactus(m, Vector2(x, ctx.y_at(x) + 8.0), height, CACTUS, CACTUS_LIGHT)
		if rng.randf() < 0.4:
			DecorKit.cactus(m, Vector2(x + rng.randf_range(40.0, 70.0), ctx.y_at(x + 50.0) + 8.0), height * 0.6, CACTUS.darkened(0.1), CACTUS_LIGHT)
		x += rng.randf_range(420.0, 1100.0)


## Fine wind ripples on the dune faces: pale crests with darker shadows under them.
static func ripples(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var light := Color("fff0c0")
	var dark := Color("9a5a2c")
	var x := ctx.x0 - 60.0
	while x < ctx.x1:
		var length := rng.randf_range(80.0, 240.0)
		var depth := rng.randf_range(7.0, 40.0)
		var pts := PackedVector2Array()
		for i in 7:
			var px := clampf(x + length * i / 6.0, ctx.x0, ctx.x1)
			pts.append(Vector2(px, ctx.y_at(px) + depth + sin(px * 0.05 + x) * 2.0))
		m.lens_line(pts, rng.randf_range(2.0, 3.6), DecorKit.with_alpha(light, 0.3))
		var shadow := pts.duplicate()
		for i in shadow.size():
			shadow[i] += Vector2(0.0, 3.5)
		m.lens_line(shadow, 2.4, DecorKit.with_alpha(dark, 0.26))
		x += length * rng.randf_range(0.5, 1.2)


static func dry_grass(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0 + rng.randf_range(10.0, 80.0)
	while x < ctx.x1 - 20.0:
		DecorKit.tuft(m, ctx.point_at(x) + Vector2(0.0, 2.0), rng.randi_range(5, 9), 14.0, 34.0, rng.randf_range(8.0, 16.0), rng, GRASS_ROOT, GRASS_TIP)
		x += rng.randf_range(110.0, 330.0)
	for i in 70:
		var gx := ctx.random_x(4.0)
		DecorKit.blade(m, ctx.point_at(gx), rng.randf_range(5.0, 10.0), rng.randf_range(-3.0, 4.0), 2.6, GRASS_ROOT, GRASS_TIP.darkened(0.1))


static func barrels(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0 + rng.randf_range(200.0, 900.0)
	while x < ctx.x1 - 60.0:
		var base := ctx.point_at(x) + Vector2(0.0, 4.0)
		var radius := rng.randf_range(9.0, 15.0)
		var c := base + Vector2(0.0, -radius * 0.9)
		m.ellipse(c, radius * 0.85, radius, CACTUS.lerp(CACTUS_LIGHT, 0.35), CACTUS, 12)
		for k in 3:
			var ox := (k - 1) * radius * 0.4
			m.lens_line(PackedVector2Array([c + Vector2(ox, radius * 0.9), c + Vector2(ox * 1.3, 0.0), c + Vector2(ox, -radius * 0.9)]), 1.6, DecorKit.with_alpha(CACTUS.darkened(0.3), 0.7))
		DecorKit.star(m, c + Vector2(0.0, -radius), radius * 0.4, Color("ff7a8a"), 5, 0.5, rng.randf() * TAU)
		x += rng.randf_range(600.0, 1500.0)
