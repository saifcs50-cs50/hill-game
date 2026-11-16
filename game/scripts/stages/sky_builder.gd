class_name SkyBuilder
extends RefCounted
## Builds the pieces of a stage's sky: gradient, sun glow, haze, stars, clouds, aurora, snow,
## birds, Earth and foreground silhouettes. Everything is built once; nothing here runs per frame.

const DESIGN_HEIGHT := 720.0 ## the project's base viewport height
const STAR_WIDTH := 2800.0 ## stars and aurora are built this wide, anchored to the left
const AURORA_COLUMNS := 48
const AURORA_ROWS := 6
const AURORA_COLORS: Array[Color] = [Color("46ffb0"), Color("3fe0ff"), Color("9a7bff")]


static func sky_texture(spec: StageSpec) -> GradientTexture2D:
	var tex := GradientTexture2D.new()
	tex.gradient = Shapes.gradient(spec.sky_offsets, spec.sky_colors)
	tex.width = 4
	tex.height = 256
	tex.fill_to = Vector2(0.0, 1.0)
	return tex


## The sun (or the moon in the arctic): an additive radial glow.
static func sun_rect(spec: StageSpec) -> TextureRect:
	var tex := GradientTexture2D.new()
	tex.gradient = Shapes.gradient(spec.sun_offsets, spec.sun_colors)
	tex.width = 512
	tex.height = 512
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var rect := centered_rect(spec.sun_anchor, spec.sun_size)
	rect.texture = tex
	rect.material = Shapes.additive()
	return rect


## Long soft rays fanning out from the sun, centred on the origin.
static func ray_mesh(spec: StageSpec) -> StageMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33 + spec.terrain_seed
	var m := StageMesh.new()
	var count := 12
	var length := 2200.0
	for i in count:
		var a := TAU * (i + rng.randf_range(-0.25, 0.25)) / count
		var half := rng.randf_range(0.03, 0.09)
		var strength := rng.randf_range(0.4, 1.0)
		var near := DecorKit.with_alpha(spec.rays_color, spec.rays_color.a * strength)
		var far := DecorKit.with_alpha(spec.rays_color, 0.0)
		m.tri_gradient(Vector2.ZERO, Vector2(cos(a - half), sin(a - half)) * length, Vector2(cos(a + half), sin(a + half)) * length, near, far, far)
	return m


static func centered_rect(anchor: Vector2, size: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.anchor_left = anchor.x
	rect.anchor_right = anchor.x
	rect.anchor_top = anchor.y
	rect.anchor_bottom = anchor.y
	rect.offset_left = -size * 0.5
	rect.offset_right = size * 0.5
	rect.offset_top = -size * 0.5
	rect.offset_bottom = size * 0.5
	return rect


static func haze_rect(cfg: Dictionary) -> TextureRect:
	var color: Color = cfg["color"]
	var tex := GradientTexture2D.new()
	tex.gradient = Shapes.gradient([0.0, 1.0], [DecorKit.with_alpha(color, 0.0), DecorKit.with_alpha(color, float(cfg["alpha"]))])
	tex.width = 4
	tex.height = 64
	tex.fill_to = Vector2(0.0, 1.0)
	var haze := TextureRect.new()
	haze.texture = tex
	haze.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	haze.anchor_right = 1.0
	haze.anchor_top = float(cfg["top"])
	haze.anchor_bottom = 1.0
	return haze


## Stars in three groups so each group can twinkle on its own. Returns the three meshes.
static func star_meshes(spec: StageSpec) -> Array[StageMesh]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4 + spec.terrain_seed
	var groups: Array[StageMesh] = [StageMesh.new(), StageMesh.new(), StageMesh.new()]
	var zone := spec.star_zone * DESIGN_HEIGHT
	for i in spec.star_count:
		var p := Vector2(rng.randf() * STAR_WIDTH, pow(rng.randf(), 1.25) * zone)
		var fade := 1.0 - p.y / zone * 0.85
		var radius := rng.randf_range(0.8, 1.9) * (1.0 + 0.8 * float(rng.randf() < 0.06))
		var color := DecorKit.with_alpha(spec.star_color, 0.8 * fade)
		var m := groups[i % 3]
		m.ellipse(p, radius, radius, color, color, 5)
		if radius > 1.9:
			m.ellipse(p, radius * 3.2, radius * 3.2, DecorKit.with_alpha(spec.star_color, 0.16 * fade), DecorKit.with_alpha(spec.star_color, 0.0), 8)
	return groups


## Soft clouds on a repeating strip. Style "streak" is a thin horizontal smear, "puff" a cluster.
static func cloud_mesh(spec: StageSpec, cfg: Dictionary, period: float) -> StageMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(float(cfg["factor"]) * 10000.0) + 29
	var band: Vector2 = cfg["band"]
	var height := (band.y - band.x) * DESIGN_HEIGHT
	var size: Vector2 = cfg["size"]
	var total := int(cfg["count"]) * int(period / 1280.0)
	var placed: Array = []
	for i in total:
		placed.append([(float(i) + rng.randf() * 0.8) * period / total, rng.randf() * height, rng.randf_range(0.6, 1.4)])
	var m := StageMesh.new()
	for copy in 2:
		for item: Array in placed:
			var at := Vector2(float(item[0]) + copy * period, float(item[1]))
			var scale: float = item[2]
			if cfg["style"] == "streak":
				_streak(m, spec, at, size * Vector2(scale, 1.0))
			else:
				_puff(m, spec, at, size * scale, rng)
	return m


static func _streak(m: StageMesh, spec: StageSpec, at: Vector2, size: Vector2) -> void:
	var color := spec.cloud_hi.lerp(spec.cloud_lo, 0.4)
	m.ellipse(at, size.x * 2.0, size.y, DecorKit.with_alpha(color, spec.cloud_alpha), DecorKit.with_alpha(color, 0.0), 16)


static func _puff(m: StageMesh, spec: StageSpec, at: Vector2, size: Vector2, rng: RandomNumberGenerator) -> void:
	var lumps := rng.randi_range(4, 6)
	for i in lumps:
		var f := float(i) / (lumps - 1) - 0.5
		var c := at + Vector2(f * size.x * 1.6, -absf(f) * size.y * 0.5 + rng.randf_range(-0.2, 0.2) * size.y)
		var rx := size.x * rng.randf_range(0.35, 0.6) * (1.0 - absf(f) * 0.6)
		var ry := maxf(size.y * rng.randf_range(0.8, 1.2), 6.0)
		m.ellipse(c + Vector2(0.0, ry * 0.25), rx, ry, DecorKit.with_alpha(spec.cloud_lo, spec.cloud_alpha), DecorKit.with_alpha(spec.cloud_lo, 0.0), 14)
		m.ellipse(c + Vector2(rx * 0.12, -ry * 0.25), rx * 0.8, ry * 0.6, DecorKit.with_alpha(spec.cloud_hi, spec.cloud_alpha * 0.85), DecorKit.with_alpha(spec.cloud_hi, 0.0), 12)


## Three aurora curtains (additive). Returns one mesh per curtain, each with its own base y.
static func aurora_meshes() -> Array[StageMesh]:
	var out: Array[StageMesh] = []
	for k in 3:
		out.append(_aurora_curtain(k))
	return out


static func _aurora_curtain(k: int) -> StageMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 700 + k
	var rows: Array[PackedVector2Array] = []
	var colors: Array[PackedColorArray] = []
	for r in AURORA_ROWS + 1:
		rows.append(PackedVector2Array())
		colors.append(PackedColorArray())
	var phase := rng.randf() * TAU
	var strength := PackedFloat32Array()
	for i in AURORA_COLUMNS + 1:
		strength.append(0.55 + 0.45 * sin(i * 0.9 + phase) * sin(i * 0.37 + k))
	for i in AURORA_COLUMNS + 1:
		var u := float(i) / AURORA_COLUMNS
		var x := -200.0 + u * STAR_WIDTH
		var bottom := sin(u * 7.0 + phase) * 40.0 + sin(u * 17.0 + k) * 12.0
		var height := (150.0 + 90.0 * sin(u * 5.0 + phase * 2.0)) * (0.8 + 0.2 * k)
		var base_color := _aurora_color(u * 2.0 + k * 0.4)
		for r in AURORA_ROWS + 1:
			var f := float(r) / AURORA_ROWS
			var alpha := 0.0
			if f < 0.18:
				alpha = f / 0.18
			else:
				alpha = pow(1.0 - (f - 0.18) / 0.82, 1.6)
			rows[r].append(Vector2(x, bottom - f * height))
			colors[r].append(DecorKit.with_alpha(base_color, alpha * 0.5 * clampf(strength[i], 0.1, 1.0)))
	var m := StageMesh.new()
	m.grid(rows, colors)
	return m


static func _aurora_color(t: float) -> Color:
	var f := fposmod(t, 3.0)
	var i := int(f)
	return AURORA_COLORS[i].lerp(AURORA_COLORS[(i + 1) % 3], smoothstep(0.0, 1.0, f - i))


## Falling snow as a particle emitter in screen space.
static func snow_particles(amount: int, speed: float, size: float, alpha: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(1500.0, 10.0)
	p.position = Vector2(640.0, -20.0)
	p.direction = Vector2(-0.3, 1.0)
	p.spread = 18.0
	p.initial_velocity_min = speed * 0.7
	p.initial_velocity_max = speed * 1.3
	p.gravity = Vector2.ZERO
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size * 1.3
	p.color = Color(0.95, 0.98, 1.0, alpha)
	p.texture = Shapes.glow_texture(8, Color.WHITE)
	return p


# Foreground silhouettes

## A repeating strip of dark shapes growing up from the bottom edge of the screen.
static func foreground_mesh(spec: StageSpec, period: float) -> StageMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91 + spec.terrain_seed
	var m := StageMesh.new()
	var color := spec.foreground_color
	var count := 4
	var placed: Array = []
	for i in count:
		placed.append([(i + rng.randf_range(0.1, 0.9)) * period / count, rng.randf_range(0.55, 1.0), rng.randi()])
	for copy in 2:
		for item: Array in placed:
			var foot := Vector2(float(item[0]) + copy * period, 0.0)
			var local := RandomNumberGenerator.new()
			local.seed = int(item[2])
			_foreground_item(m, spec.foreground, foot, float(item[1]), color, local)
	return m


static func _foreground_item(m: StageMesh, kind: String, foot: Vector2, scale: float, color: Color, rng: RandomNumberGenerator) -> void:
	match kind:
		"cacti":
			DecorKit.cactus(m, foot + Vector2(0.0, 8.0), 95.0 * scale, color, color.lightened(0.08))
		"pines":
			DecorKit.pine(m, foot + Vector2(0.0, 150.0 * scale), 240.0 * scale, 4, color, color.lightened(0.1))
		"rocks":
			DecorKit.rock(m, foot + Vector2(0.0, 14.0), Vector2(70.0, 52.0) * scale, rng, Vector2(0.7, -0.7), color.lightened(0.12), color)
		_:
			DecorKit.tuft(m, foot + Vector2(0.0, 6.0), 9, 50.0 * scale, 100.0 * scale, 18.0, rng, color, color.lightened(0.06))
