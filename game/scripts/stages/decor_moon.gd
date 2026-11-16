class_name DecorMoon
extends RefCounted
## Moonscape: boulders, rubble, a lander now and then, and fine regolith specks.

const GREY_LIT := Color("d4d3e2")
const GREY_MID := Color("8b8a9c")
const GREY_DARK := Color("4a495a")
const GOLD := Color("c9a14a")
const LANDER_CHANCE := 0.22


static func parts() -> Array:
	return [
		{"layer": "props", "build": Callable(DecorMoon, "boulders")},
		{"layer": "props", "build": Callable(DecorMoon, "lander")},
		{"layer": "soil", "build": Callable(DecorMoon, "specks")},
		{"layer": "front", "build": Callable(DecorMoon, "rubble")},
	]


## Large boulders and ridges of rock behind the track.
static func boulders(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0 + rng.randf_range(100.0, 500.0)
	while x < ctx.x1 - 100.0:
		var foot := Vector2(x, ctx.y_at(x) + 10.0)
		var size := Vector2(rng.randf_range(38.0, 110.0), rng.randf_range(28.0, 80.0))
		DecorKit.rock(m, foot, size, rng, ctx.spec.light_dir, GREY_LIT, GREY_DARK, 12.0)
		if rng.randf() < 0.6:
			var near := foot + Vector2(size.x * rng.randf_range(0.8, 1.4), 2.0)
			DecorKit.rock(m, Vector2(near.x, ctx.y_at(near.x) + 8.0), size * 0.55, rng, ctx.spec.light_dir, GREY_LIT, GREY_DARK.darkened(0.15), 10.0)
		x += rng.randf_range(500.0, 1300.0)


static func lander(ctx: ChunkContext, m: StageMesh) -> void:
	if TerrainShape.hash01(ctx.index * 31 + 9) > LANDER_CHANCE:
		return
	var rng := ctx.rng
	var x := ctx.x0 + rng.randf_range(600.0, 1900.0)
	var foot := Vector2(x, ctx.y_at(x) + 6.0)
	var foil := GOLD
	var dark := GREY_DARK
	var body := foot + Vector2(0.0, -62.0)
	for side: float in [-1.0, 1.0]:
		var leg_top := body + Vector2(side * 26.0, 8.0)
		var leg_foot := foot + Vector2(side * 56.0, 0.0)
		m.line(leg_top, leg_foot, 4.0, dark.lightened(0.15))
		m.line(foot + Vector2(side * 38.0, -10.0), body + Vector2(side * 10.0, 14.0), 2.5, dark.lightened(0.1))
		m.ellipse(leg_foot + Vector2(0.0, 2.0), 11.0, 3.5, GREY_MID, dark, 8)
	var pts := PackedVector2Array([body + Vector2(-34.0, 12.0), body + Vector2(-42.0, -14.0), body + Vector2(-22.0, -30.0), body + Vector2(22.0, -30.0), body + Vector2(42.0, -14.0), body + Vector2(34.0, 12.0)])
	m.fan(pts, foil.darkened(0.25), foil.lightened(0.15))
	var top := body + Vector2(0.0, -46.0)
	m.fan(PackedVector2Array([top + Vector2(-18.0, 16.0), top + Vector2(-22.0, -4.0), top + Vector2(-8.0, -16.0), top + Vector2(10.0, -16.0), top + Vector2(22.0, -4.0), top + Vector2(18.0, 16.0)]), GREY_MID.darkened(0.1), GREY_LIT)
	m.quad(top + Vector2(-8.0, -6.0), top + Vector2(8.0, -6.0), top + Vector2(8.0, 4.0), top + Vector2(-8.0, 4.0), Color("1a2238"))
	m.line(top + Vector2(10.0, -14.0), top + Vector2(24.0, -34.0), 1.6, GREY_LIT)
	m.ellipse(top + Vector2(24.0, -35.0), 6.0, 2.5, GREY_LIT, GREY_MID, 8)


static func specks(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	for i in 110:
		var x := ctx.random_x(4.0)
		var depth := 6.0 + pow(rng.randf(), 1.3) * 300.0
		var tone := rng.randf_range(0.5, 1.15)
		var c := Color(0.62 * tone, 0.61 * tone, 0.7 * tone, rng.randf_range(0.25, 0.6))
		var r := rng.randf_range(0.9, 2.4)
		m.ellipse(Vector2(x, ctx.y_at(x) + depth), r, r * 0.8, c, c, 5)
	for i in 4:
		var x := ctx.random_x(60.0)
		var c := Vector2(x, ctx.y_at(x) + rng.randf_range(40.0, 150.0))
		var rx := rng.randf_range(24.0, 60.0)
		m.ellipse(c, rx, rx * 0.22, DecorKit.with_alpha(GREY_DARK, 0.35), DecorKit.with_alpha(GREY_DARK, 0.0), 12)
		m.ellipse(c + Vector2(0.0, -rx * 0.12), rx * 0.8, rx * 0.1, DecorKit.with_alpha(GREY_LIT, 0.2), DecorKit.with_alpha(GREY_LIT, 0.0), 12)


## Loose stones and dust piles on the surface.
static func rubble(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	for i in 26:
		var x := ctx.random_x(6.0)
		var s := rng.randf_range(3.0, 9.0)
		var base := ctx.point_at(x) + Vector2(0.0, 2.0)
		DecorKit.rock(m, base, Vector2(s * 1.4, s), rng, ctx.spec.light_dir, GREY_LIT, GREY_DARK, 2.0)
	var x := ctx.x0
	while x < ctx.x1:
		var width := rng.randf_range(40.0, 120.0)
		m.ellipse(ctx.point_at(clampf(x, ctx.x0, ctx.x1)) + Vector2(0.0, 2.0), width, rng.randf_range(2.5, 5.0), DecorKit.with_alpha(GREY_LIT, 0.35), DecorKit.with_alpha(GREY_LIT, 0.0), 10)
		x += width * rng.randf_range(1.0, 2.2)
