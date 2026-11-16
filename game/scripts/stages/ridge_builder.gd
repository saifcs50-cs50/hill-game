class_name RidgeBuilder
extends RefCounted
## Builds one parallax ridge as a periodic strip (two periods wide) with trees or rocks on it
## and a sun-side rim light. The silhouette is a sum of whole-number harmonics of the period,
## so the strip wraps seamlessly.

const SAMPLE := 16.0
const HARMONIC_RATIOS: Array[float] = [1.0, 1.9, 3.7, 7.3]
const HARMONIC_WEIGHTS: Array[float] = [1.0, 0.55, 0.28, 0.12]
const BOTTOM_DEPTH := 1300.0
const TREE_SPACING := 130.0


## cfg: a "ridge" layer dictionary from StageSpec. light_side is +1 (sun on the right) or -1.
static func build(cfg: Dictionary, period: float, light_side: float) -> StageMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(float(cfg["factor"]) * 100000.0) + 17
	var harmonics := _harmonics(float(cfg["freq"]), period, rng)
	var kind: String = cfg["kind"]
	var amp: float = cfg["amp"]
	var count := int(2.0 * period / SAMPLE)
	var crest := PackedVector2Array()
	for i in count + 1:
		var x := i * SAMPLE
		crest.append(Vector2(x, -_shape(kind, _signal(x, period, harmonics)) * amp))
	var m := StageMesh.new()
	_fill(m, crest, cfg)
	var glow: Color = cfg["glow"]
	if glow.a > 0.0:
		_rim(m, crest, glow, light_side)
	_props(m, crest, cfg, period, rng)
	return m


static func _harmonics(freq: float, period: float, rng: RandomNumberGenerator) -> Array:
	var base := maxf(roundf(freq * period), 1.0)
	var out := []
	for i in HARMONIC_RATIOS.size():
		out.append([roundf(base * HARMONIC_RATIOS[i]), HARMONIC_WEIGHTS[i], rng.randf() * TAU])
	return out


## Periodic signal in about -1..1.
static func _signal(x: float, period: float, harmonics: Array) -> float:
	var v := 0.0
	var total := 0.0
	for h: Array in harmonics:
		v += float(h[1]) * sin(TAU * float(h[0]) * x / period + float(h[2]))
		total += float(h[1])
	return v / total * 1.25


static func _shape(kind: String, v: float) -> float:
	match kind:
		"jagged", "crag":
			return 1.0 - absf(v) * (1.7 if kind == "crag" else 1.6)
		"dune":
			return pow(clampf(0.5 + 0.5 * v, 0.0, 1.0), 1.6) * 2.0 - 1.0
		"mesa":
			return smoothstep(-0.05, 0.12, v) * 1.6 + smoothstep(0.38, 0.5, v) * 0.5 - 0.8
	return v


static func _fill(m: StageMesh, crest: PackedVector2Array, cfg: Dictionary) -> void:
	var top: Color = cfg["top"]
	var bottom: Color = cfg["bottom"]
	var mid := top.lerp(bottom, 0.55)
	var rows: Array[PackedVector2Array] = [PackedVector2Array(), PackedVector2Array(), PackedVector2Array()]
	var colors: Array[PackedColorArray] = [PackedColorArray(), PackedColorArray(), PackedColorArray()]
	var depth_mid := float(cfg["amp"]) * 1.4 + 90.0
	for p in crest:
		rows[0].append(p)
		rows[1].append(Vector2(p.x, p.y + depth_mid))
		rows[2].append(Vector2(p.x, BOTTOM_DEPTH))
		colors[0].append(top)
		colors[1].append(mid)
		colors[2].append(bottom)
	m.grid(rows, colors)


## Rim light along the crest, strongest on slopes that face the sun.
static func _rim(m: StageMesh, crest: PackedVector2Array, glow: Color, light_side: float) -> void:
	var width := 3.0
	var prev_a := -1
	var prev_b := -1
	for i in crest.size():
		var a := crest[maxi(i - 1, 0)]
		var b := crest[mini(i + 1, crest.size() - 1)]
		var slope := (b.y - a.y) / maxf(b.x - a.x, 0.001) * light_side
		var alpha := clampf(0.3 + slope * 1.6, 0.0, 1.0) * glow.a
		var c := DecorKit.with_alpha(glow, alpha)
		var ia := m.vert(crest[i] + Vector2(0.0, -width * 0.2), c)
		var ib := m.vert(crest[i] + Vector2(0.0, width), DecorKit.with_alpha(glow, 0.0))
		if prev_a >= 0:
			m.index_tri(prev_a, prev_b, ib)
			m.index_tri(prev_a, ib, ia)
		prev_a = ia
		prev_b = ib


static func _props(m: StageMesh, crest: PackedVector2Array, cfg: Dictionary, period: float, rng: RandomNumberGenerator) -> void:
	var props: String = cfg["props"]
	if props == "":
		return
	var top: Color = cfg["top"]
	var glow: Color = cfg["glow"]
	if props == "windmill":
		_farm(m, crest, period, top)
		return
	var slots := int(period / TREE_SPACING)
	var placed: Array = []
	for s in slots:
		var roll := rng.randf()
		if roll > 0.18:
			placed.append([(s + rng.randf() * 0.7) * period / slots, roll])
	for copy in 2:
		for item: Array in placed:
			var x: float = float(item[0]) + copy * period
			var roll: float = item[1]
			var foot := Vector2(x, _crest_y(crest, x) + 6.0)
			_prop(m, props, foot, 46.0 + roll * 70.0, top, glow)


static func _crest_y(crest: PackedVector2Array, x: float) -> float:
	var f := clampf(x / SAMPLE, 0.0, float(crest.size() - 1) - 0.001)
	var i := int(f)
	return lerpf(crest[i].y, crest[i + 1].y, f - i)


static func _prop(m: StageMesh, props: String, foot: Vector2, height: float, top: Color, glow: Color) -> void:
	match props:
		"pines":
			DecorKit.pine(m, foot, height, 3, top, top.lerp(glow, 0.12))
		"snow_pines":
			DecorKit.pine(m, foot, height, 3, top, top.lerp(glow, 0.3), Color(0.92, 0.97, 1.0, 0.85))
		"cacti":
			DecorKit.cactus(m, foot, height * 0.55, top, top.lerp(glow, 0.2))


## One windmill and a farmhouse per period, set on the ridge.
static func _farm(m: StageMesh, crest: PackedVector2Array, period: float, top: Color) -> void:
	var color := top.darkened(0.12)
	var window := Color("ffc977")
	for copy in 2:
		var x := period * 0.3 + copy * period
		DecorKit.windmill(m, Vector2(x, _crest_y(crest, x) + 4.0), 92.0, color)
		var hx := period * 0.3 + 120.0 + copy * period
		DecorKit.farmhouse(m, Vector2(hx, _crest_y(crest, hx) + 4.0), 36.0, color, window)
		var tx := period * 0.74 + copy * period
		DecorKit.pine(m, Vector2(tx, _crest_y(crest, tx) + 6.0), 70.0, 3, color, color.lightened(0.05))
