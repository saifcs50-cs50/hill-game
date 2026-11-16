class_name DecorArctic
extends RefCounted
## Arctic night: snowy pines, frosted rock, ice sheen on the flats, drifts, crystals and glints.

const PINE_DARK := Color("0f2c4a")
const PINE_LIT := Color("3f79a0")
const SNOW := Color(0.94, 0.98, 1.0, 0.92)
const ICE_ROCK := Color("5a86b4")
const ICE_ROCK_LIT := Color("c9e6fa")
const CRYSTAL := Color("bfe6ff")
const SHEEN_DEPTH := 18.0
const CAP_DEPTH := 8.0


static func parts() -> Array:
	return [
		{"layer": "props", "build": Callable(DecorArctic, "pines")},
		{"layer": "props", "build": Callable(DecorArctic, "outcrops")},
		{"layer": "soil", "build": Callable(DecorArctic, "crystals")},
		{"layer": "front", "build": Callable(DecorArctic, "sheen")},
		{"layer": "front", "build": Callable(DecorArctic, "shards")},
		{"layer": "front", "build": Callable(DecorArctic, "drifts")},
		{"layer": "front", "build": Callable(DecorArctic, "glints")},
	]


static func pines(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0 + rng.randf_range(40.0, 300.0)
	while x < ctx.x1 - 60.0:
		var open := ctx.shape.open_ice(x)
		if open > 0.35 or rng.randf() < 0.3:
			var height := rng.randf_range(100.0, 230.0)
			DecorKit.pine(m, Vector2(x, ctx.y_at(x) + 12.0), height, 5, PINE_DARK, PINE_LIT, SNOW)
			if rng.randf() < 0.5:
				DecorKit.pine(m, Vector2(x + rng.randf_range(30.0, 60.0), ctx.y_at(x + 45.0) + 12.0), height * 0.62, 4, PINE_DARK.lightened(0.04), PINE_LIT, SNOW)
		x += rng.randf_range(300.0, 800.0)


## Frosted boulders and ice spires behind the track.
static func outcrops(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0 + rng.randf_range(300.0, 900.0)
	while x < ctx.x1 - 120.0:
		var foot := Vector2(x, ctx.y_at(x) + 12.0)
		if rng.randf() < 0.5:
			var size := Vector2(rng.randf_range(40.0, 80.0), rng.randf_range(30.0, 60.0))
			DecorKit.rock(m, foot, size, rng, ctx.spec.light_dir, ICE_ROCK_LIT, ICE_ROCK, 10.0)
			m.ellipse(foot + Vector2(0.0, -size.y * 0.95), size.x * 0.6, 5.0, SNOW, DecorKit.with_alpha(SNOW, 0.0), 10)
		else:
			for i in rng.randi_range(2, 4):
				_spire(m, foot + Vector2(i * 20.0 - 30.0, 0.0), rng.randf_range(60.0, 150.0), rng)
		x += rng.randf_range(900.0, 1900.0)


static func _spire(m: StageMesh, foot: Vector2, height: float, rng: RandomNumberGenerator) -> void:
	var half := height * rng.randf_range(0.1, 0.16)
	var lean := rng.randf_range(-0.2, 0.2) * height
	var tip := foot + Vector2(lean, -height)
	m.tri_gradient(foot + Vector2(-half, 6.0), foot + Vector2(half, 6.0), tip, Color("2d5c92"), Color("9fd4f4"), Color("e4f6ff"))
	m.tri_gradient(foot + Vector2(0.0, 6.0), foot + Vector2(half, 6.0), tip, DecorKit.with_alpha(Color("7ec0ee"), 0.0), Color("d8f0ff"), Color("ffffff"))


## Ice crystals frozen into the soil band.
static func crystals(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	for i in 34:
		var x := ctx.random_x(10.0)
		var c := Vector2(x, ctx.y_at(x) + 20.0 + pow(rng.randf(), 1.5) * 220.0)
		var s := rng.randf_range(4.0, 11.0)
		var tilt := rng.randf_range(-0.5, 0.5)
		var top := c + Vector2(tilt * s, -s * 1.6)
		var bottom := c + Vector2(-tilt * s, s * 1.2)
		var left := c + Vector2(-s * 0.55, 0.0)
		var right := c + Vector2(s * 0.55, 0.0)
		var alpha := rng.randf_range(0.45, 0.85)
		m.tri_gradient(left, top, right, DecorKit.with_alpha(CRYSTAL, alpha * 0.5), DecorKit.with_alpha(Color.WHITE, alpha), DecorKit.with_alpha(CRYSTAL, alpha * 0.8))
		m.tri_gradient(left, right, bottom, DecorKit.with_alpha(CRYSTAL, alpha * 0.5), DecorKit.with_alpha(CRYSTAL, alpha * 0.8), DecorKit.with_alpha(Color("6fa8dc"), alpha * 0.6))


## A glassy band just under the surface that glows on the flat icy stretches.
static func sheen(ctx: ChunkContext, m: StageMesh) -> void:
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	var c_upper := PackedColorArray()
	var c_lower := PackedColorArray()
	for p in ctx.top:
		var flat := 1.0 - ctx.shape.open_ice(p.x)
		upper.append(p + Vector2(0.0, 2.0))
		lower.append(p + Vector2(0.0, SHEEN_DEPTH + flat * 14.0))
		c_upper.append(Color(0.8, 0.95, 1.0, 0.18 + flat * 0.5))
		c_lower.append(Color(0.6, 0.85, 1.0, 0.0))
	var rows: Array[PackedVector2Array] = [upper, lower]
	var colors: Array[PackedColorArray] = [c_upper, c_lower]
	m.grid(rows, colors)
	_reflections(ctx, m)


## Faint aurora colours mirrored in the ice of the flat stretches.
static func _reflections(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0
	while x < ctx.x1:
		if ctx.shape.open_ice(x) < 0.3 and rng.randf() < 0.55:
			var color: Color = SkyBuilder.AURORA_COLORS[rng.randi() % 3]
			var top := ctx.point_at(x) + Vector2(0.0, rng.randf_range(14.0, 26.0))
			var pts := PackedVector2Array([top, top + Vector2(rng.randf_range(-4.0, 4.0), 36.0), top + Vector2(rng.randf_range(-6.0, 6.0), rng.randf_range(70.0, 150.0))])
			m.lens_line(pts, rng.randf_range(8.0, 20.0), DecorKit.with_alpha(color, 0.1))
		x += rng.randf_range(28.0, 70.0)


## Little clusters of translucent ice shards pushing up through the snow.
static func shards(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0 + rng.randf_range(100.0, 500.0)
	while x < ctx.x1 - 60.0:
		var root := ctx.point_at(x) + Vector2(0.0, 5.0)
		for i in rng.randi_range(2, 4):
			var h := rng.randf_range(16.0, 46.0)
			var w := h * rng.randf_range(0.14, 0.24)
			var tip := root + Vector2(i * 9.0 - 14.0 + rng.randf_range(-3.0, 3.0), -h)
			var foot := root + Vector2(i * 9.0 - 14.0, 0.0)
			m.tri_gradient(foot + Vector2(-w, 0.0), foot + Vector2(w, 0.0), tip, Color(0.45, 0.72, 0.95, 0.55), Color(0.8, 0.95, 1.0, 0.7), Color(1.0, 1.0, 1.0, 0.85))
		x += rng.randf_range(700.0, 1500.0)


## Soft snow drifts piled along the surface.
static func drifts(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0 - 30.0
	while x < ctx.x1 + 30.0:
		var width := rng.randf_range(50.0, 130.0)
		var at := ctx.point_at(clampf(x, ctx.x0, ctx.x1)) + Vector2(0.0, CAP_DEPTH * 0.3)
		m.ellipse(at, width, rng.randf_range(4.0, 8.0), SNOW, DecorKit.with_alpha(SNOW, 0.0), 12)
		x += width * rng.randf_range(0.9, 1.7)
	for i in 14:
		var tx := ctx.random_x(10.0)
		DecorKit.tuft(m, ctx.point_at(tx) + Vector2(0.0, 2.0), 5, 9.0, 20.0, 10.0, rng, Color("6c8fb4"), Color("e6f6ff"))


## Sparkles on the snow and diagonal glints on the ice.
static func glints(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	for i in 26:
		var x := ctx.random_x(6.0)
		var p := ctx.point_at(x) + Vector2(0.0, -rng.randf_range(1.0, 7.0))
		DecorKit.star(m, p, rng.randf_range(3.0, 6.5), DecorKit.with_alpha(Color.WHITE, rng.randf_range(0.6, 0.95)), 4, 0.2)
	var x := ctx.x0
	while x < ctx.x1:
		var flat := 1.0 - ctx.shape.open_ice(x)
		if flat > 0.55 and rng.randf() < 0.7:
			var p := ctx.point_at(x) + Vector2(0.0, rng.randf_range(4.0, 20.0))
			var len := rng.randf_range(14.0, 30.0)
			m.line(p, p + Vector2(len, -len * 0.45), 1.8, DecorKit.with_alpha(Color.WHITE, 0.6), 0.6, DecorKit.with_alpha(Color.WHITE, 0.0))
		x += 22.0
