class_name ChunkPainter
extends RefCounted
## Builds the look of one terrain chunk. The ground fill and rim line are made at once; the
## rest (soil detail, props, surface decoration) is returned as small steps that Terrain runs a
## few milliseconds per frame, so a new chunk never causes a frame hitch.
##
## Draw order inside the chunk (back to front): props, ground fill, soil, rim light, front.

const PEBBLES_PER_CHUNK := 70
const BOULDERS_PER_CHUNK := 7
const STRATA_MIN_DEPTH := 34.0
const STRATA_MAX_DEPTH := 330.0

var _ctx: ChunkContext
var _spec: StageSpec
var _props: Node2D
var _soil: Node2D
var _front: Node2D


func _init(p_ctx: ChunkContext) -> void:
	_ctx = p_ctx
	_spec = p_ctx.spec


## Creates the holder nodes and the immediate ground; returns the deferred build steps.
## Each step is [holder Node2D, builder Callable(ctx, StageMesh)].
func build(chunk: Node2D) -> Array:
	_props = _holder(chunk)
	var ground := _holder(chunk)
	_soil = _holder(chunk)
	_add_rim(chunk)
	_front = _holder(chunk)
	var steps: Array = [[ground, _build_fill], [_soil, _build_strata], [_soil, _build_pebbles], [_front, _build_boulders]]
	for part: Dictionary in _decor_parts():
		var holder := _props if part["layer"] == "props" else (_soil if part["layer"] == "soil" else _front)
		steps.append([holder, part["build"]])
	return steps


func _holder(chunk: Node2D) -> Node2D:
	var holder := Node2D.new()
	chunk.add_child(holder)
	return holder


func _decor_parts() -> Array:
	match _spec.decor:
		"desert":
			return DecorDesert.parts()
		"arctic":
			return DecorArctic.parts()
		"moon":
			return DecorMoon.parts()
	return DecorMeadow.parts()


# Ground fill


func _build_fill(ctx: ChunkContext, m: StageMesh) -> void:
	var count := ctx.top.size()
	var depths := _spec.ground_depths
	var rows: Array[PackedVector2Array] = []
	var colors: Array[PackedColorArray] = []
	for r in depths.size():
		rows.append(PackedVector2Array())
		colors.append(PackedColorArray())
	for i in count:
		var p := ctx.top[i]
		var lit := ctx.lit_at_normal(_surface_normal(i))
		var mottle := 1.0 + ctx.shape.mottle_at(p.x) * 0.07
		for r in depths.size():
			var c := _spec.ground_colors[r]
			if r == 0:
				c = _spec.shade_color.lerp(_spec.lit_color, lit)
			elif r == 1:
				c = c.lerp(_spec.lit_color, lit * 0.22)
			rows[r].append(Vector2(p.x, p.y + depths[r]))
			colors[r].append(DecorKit.shade(c, mottle))
	m.grid(rows, colors)


## Surface normal at the i-th sample, from the neighbouring samples (uses the extended array).
func _surface_normal(i: int) -> Vector2:
	var t := (_ctx.ext[i + 2] - _ctx.ext[i]).normalized()
	return Vector2(t.y, -t.x)


func _add_rim(chunk: Node2D) -> void:
	var glow := Shapes.line(chunk, _ctx.top, Color(_spec.rim_color, _spec.rim_glow), _spec.rim_width * 4.8)
	glow.position.y = _spec.rim_width * 1.5
	Shapes.line(chunk, _ctx.top, _spec.rim_color, _spec.rim_width)


# Soil detail

## Wavy brush-stroke layers following the surface at several depths.
func _build_strata(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	for k in _spec.strata_count:
		var depth := lerpf(STRATA_MIN_DEPTH, STRATA_MAX_DEPTH, pow(float(k + rng.randf() * 0.6) / _spec.strata_count, 1.4))
		var alpha := lerpf(0.36, 0.12, depth / STRATA_MAX_DEPTH)
		var color := DecorKit.with_alpha(_spec.strata_color, alpha)
		var x := ctx.x0 + rng.randf_range(-200.0, 200.0)
		while x < ctx.x1:
			var length := rng.randf_range(260.0, 760.0)
			var from := maxf(x, ctx.x0)
			var to := minf(x + length, ctx.x1)
			if to - from > 60.0:
				m.lens_line(_strata_points(ctx, from, to, depth, k), rng.randf_range(3.0, 7.0), color)
			x += length + rng.randf_range(40.0, 260.0)


func _strata_points(ctx: ChunkContext, from: float, to: float, depth: float, k: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := maxi(int((to - from) / 40.0), 2)
	for i in steps + 1:
		var x := lerpf(from, to, float(i) / steps)
		var wobble := sin(x * 0.0043 + k * 1.7) * depth * 0.12 + sin(x * 0.013 + k) * 3.0
		pts.append(Vector2(x, ctx.y_at(x) + depth + wobble))
	return pts


## Small stones embedded in the soil band.
func _build_pebbles(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	for i in PEBBLES_PER_CHUNK:
		var x := ctx.random_x(10.0)
		var depth := 12.0 + pow(rng.randf(), 1.6) * 190.0
		var color: Color = _spec.pebble_colors[rng.randi() % _spec.pebble_colors.size()]
		var radius := rng.randf_range(2.6, 7.5) * (1.0 + rng.randf() * float(rng.randf() < 0.12) * 1.4)
		DecorKit.pebble(m, Vector2(x, ctx.y_at(x) + depth), radius, rng, DecorKit.with_alpha(color, 0.95))


## Boulders half-buried in the surface, in front of the rim line.
func _build_boulders(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	for i in BOULDERS_PER_CHUNK:
		var x := ctx.random_x(30.0)
		var size := Vector2(rng.randf_range(8.0, 22.0), rng.randf_range(6.0, 16.0))
		var base := ctx.point_at(x) + Vector2(0.0, 3.0)
		var c_lit := _spec.pebble_colors[mini(1, _spec.pebble_colors.size() - 1)].lerp(_spec.rim_color, 0.25)
		DecorKit.rock(m, base, size, rng, _spec.light_dir, c_lit.lightened(0.1), _spec.pebble_colors[2])
