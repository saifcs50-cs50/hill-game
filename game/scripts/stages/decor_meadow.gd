class_name DecorMeadow
extends RefCounted
## Golden-hour meadow: trees behind the ground, rim-lit grass, tufts, flowers and bushes.

const TREE_GAP_MIN := 380.0
const TREE_GAP_MAX := 900.0
const FLOWER_COLORS: Array[Color] = [Color("fff1d6"), Color("ff8fb1"), Color("ffd45a"), Color("b8a0ff")]
const TREE_DARK := Color("2f1b4a")
const TREE_LIT := Color("8a4f80")
const BLADE_ROOT := Color("5a2f4a")
const BLADE_BACK_ROOT := Color("2c1a46")
const BLADE_BACK_TIP := Color("84507f")


static func parts() -> Array:
	return [
		{"layer": "props", "build": Callable(DecorMeadow, "trees")},
		{"layer": "front", "build": Callable(DecorMeadow, "grass_back")},
		{"layer": "front", "build": Callable(DecorMeadow, "grass_front")},
		{"layer": "front", "build": Callable(DecorMeadow, "tufts")},
		{"layer": "front", "build": Callable(DecorMeadow, "flowers")},
		{"layer": "front", "build": Callable(DecorMeadow, "bushes")},
		{"layer": "front", "build": Callable(DecorMeadow, "fence")},
	]


static func trees(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0 + rng.randf_range(60.0, 500.0)
	while x < ctx.x1 - 60.0:
		var foot := Vector2(x, ctx.y_at(x) + 10.0)
		var height := rng.randf_range(95.0, 200.0)
		if rng.randf() < 0.65:
			DecorKit.pine(m, foot, height, 4, TREE_DARK, TREE_LIT)
		else:
			_round_tree(m, foot, height * 0.8, rng)
		x += rng.randf_range(TREE_GAP_MIN, TREE_GAP_MAX)


static func _round_tree(m: StageMesh, foot: Vector2, height: float, rng: RandomNumberGenerator) -> void:
	var trunk := Color("3a2038")
	m.quad(foot + Vector2(-5.0, 4.0), foot + Vector2(5.0, 4.0), foot + Vector2(3.5, -height * 0.55), foot + Vector2(-3.5, -height * 0.55), trunk)
	var radius := height * 0.3
	for i in 4:
		var c := foot + Vector2(rng.randf_range(-0.55, 0.55) * radius, -height * 0.62 - rng.randf_range(-0.3, 0.4) * radius)
		var r := radius * rng.randf_range(0.7, 1.0)
		m.ellipse(c, r, r * 0.88, TREE_DARK.lerp(TREE_LIT, 0.3), TREE_DARK, 12)
		m.ellipse(c + Vector2(r * 0.3, -r * 0.2), r * 0.55, r * 0.45, TREE_LIT, DecorKit.with_alpha(TREE_LIT, 0.0), 10)


## The dark back row of the grass fringe.
static func grass_back(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	for i in ctx.top.size() - 1:
		var a := ctx.top[i]
		var b := ctx.top[i + 1]
		for k in 3:
			var p := a.lerp(b, rng.randf())
			DecorKit.blade(m, p, rng.randf_range(6.0, 13.0), rng.randf_range(-3.0, 5.0), 3.6, BLADE_BACK_ROOT, BLADE_BACK_TIP)


## The rim-lit front row of the grass fringe.
static func grass_front(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var rim := ctx.spec.rim_color
	for i in ctx.top.size() - 1:
		var a := ctx.top[i]
		var b := ctx.top[i + 1]
		for k in 4:
			var p := a.lerp(b, rng.randf())
			var tip := rim.lerp(Color("ff9a8a"), 0.5 * float(rng.randf() < 0.18))
			DecorKit.blade(m, p, rng.randf_range(7.0, 17.0), rng.randf_range(-4.0, 6.0), rng.randf_range(2.4, 3.6), BLADE_ROOT, tip)


## Taller tufts that catch the low sun.
static func tufts(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var rim := ctx.spec.rim_color
	var x := ctx.x0 + rng.randf_range(10.0, 90.0)
	while x < ctx.x1 - 20.0:
		var root := ctx.point_at(x) + Vector2(0.0, 2.0)
		DecorKit.tuft(m, root, rng.randi_range(5, 9), 18.0, 36.0, rng.randf_range(7.0, 14.0), rng, BLADE_ROOT, rim.lightened(0.15))
		x += rng.randf_range(90.0, 190.0)


static func flowers(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0 + rng.randf_range(30.0, 200.0)
	while x < ctx.x1 - 40.0:
		var color := FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()]
		for k in rng.randi_range(2, 4):
			var fx := x + rng.randf_range(-40.0, 40.0)
			_flower(m, ctx.point_at(fx) + Vector2(0.0, 2.0), rng.randf_range(16.0, 32.0), color, rng)
		x += rng.randf_range(230.0, 520.0)


static func _flower(m: StageMesh, root: Vector2, height: float, color: Color, rng: RandomNumberGenerator) -> void:
	var lean := rng.randf_range(-7.0, 7.0)
	var head := root + Vector2(lean, -height)
	m.polyline(PackedVector2Array([root, root + Vector2(lean * 0.3, -height * 0.5), head]), 1.8, Color("8a5a38"), Color("c98a4a"))
	m.ellipse(head, 10.0, 10.0, DecorKit.with_alpha(color, 0.22), DecorKit.with_alpha(color, 0.0), 10)
	DecorKit.star(m, head, rng.randf_range(4.2, 6.0), color, 5, 0.55, rng.randf() * TAU)
	m.ellipse(head, 1.8, 1.8, Color("ffb347"), Color("ffb347"), 6)


static func bushes(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	var x := ctx.x0 + rng.randf_range(100.0, 700.0)
	while x < ctx.x1 - 80.0:
		DecorKit.bush(m, ctx.point_at(x) + Vector2(0.0, 6.0), rng.randf_range(20.0, 34.0), rng, Color("2b1946"), Color("7a4a86"), ctx.spec.light_dir)
		x += rng.randf_range(500.0, 1300.0)


## A short rustic fence now and then, following the ground.
static func fence(ctx: ChunkContext, m: StageMesh) -> void:
	var rng := ctx.rng
	if rng.randf() > 0.55:
		return
	var wood := Color("2a1740")
	var rail := DecorKit.with_alpha(wood, 0.9)
	var posts := rng.randi_range(5, 9)
	var x := ctx.x0 + rng.randf_range(300.0, 1500.0)
	var spacing := 46.0
	var prev_top := Vector2.ZERO
	var prev_mid := Vector2.ZERO
	for i in posts:
		var px := x + i * spacing
		if px > ctx.x1 - 10.0:
			break
		var foot := ctx.point_at(px) + Vector2(0.0, 3.0)
		var h := 30.0 + rng.randf_range(-3.0, 3.0)
		m.quad(foot + Vector2(-2.6, 0.0), foot + Vector2(2.6, 0.0), foot + Vector2(2.2, -h), foot + Vector2(-2.2, -h), wood)
		m.quad(foot + Vector2(0.6, 0.0), foot + Vector2(2.6, 0.0), foot + Vector2(2.2, -h), foot + Vector2(0.4, -h), DecorKit.with_alpha(ctx.spec.rim_color, 0.5))
		var top := foot + Vector2(0.0, -h + 6.0)
		var mid := foot + Vector2(0.0, -h * 0.4)
		if i > 0:
			m.line(prev_top, top, 2.6, rail)
			m.line(prev_mid, mid, 2.6, rail)
		prev_top = top
		prev_mid = mid
