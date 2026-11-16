class_name StageLibrary
extends RefCounted
## The four launch stages as StageSpec data. Friction and gravity are read from
## Catalog.STAGES so the shared contract stays the single source of truth.

static var _cache := {}


## Returns the spec for a stage id; unknown ids fall back to the meadow.
static func get_spec(stage_id: String) -> StageSpec:
	if not Catalog.STAGES.has(stage_id):
		push_warning("Unknown stage '%s', using meadow" % stage_id)
		stage_id = "meadow"
	if not _cache.has(stage_id):
		var spec: StageSpec
		match stage_id:
			"desert":
				spec = _desert()
			"arctic":
				spec = _arctic()
			"moon":
				spec = _moon()
			_:
				spec = _meadow()
		spec.id = stage_id
		spec.friction = float(Catalog.STAGES[stage_id]["friction"])
		spec.gravity = float(Catalog.STAGES[stage_id]["gravity"])
		_cache[stage_id] = spec
	return _cache[stage_id]


static func _ridge(factor: float, base: float, amp: float, freq: float, kind: String, props: String, top: Color, bottom: Color, glow: Color = Color(0, 0, 0, 0)) -> Dictionary:
	return {"type": "ridge", "factor": factor, "base": base, "amp": amp, "freq": freq, "kind": kind,
		"props": props, "top": top, "bottom": bottom, "glow": glow}


static func _haze(top: float, color: Color, alpha: float) -> Dictionary:
	return {"type": "haze", "top": top, "color": color, "alpha": alpha}


static func _clouds(factor: float, drift: float, band: Vector2, count: int, size: Vector2, style: String) -> Dictionary:
	return {"type": "clouds", "factor": factor, "drift": drift, "band": band, "count": count, "size": size, "style": style}


static func _meadow() -> StageSpec:
	var s := StageSpec.new()
	s.terrain_seed = 20261002
	s.shape = "hills"
	s.noise_frequency = 0.0011
	s.decor = "meadow"
	s.ground_depths = PackedFloat32Array([0.0, 22.0, 110.0, 520.0, 1700.0])
	s.ground_colors = [Color("4a2a68"), Color("43245f"), Color("2b1a47"), Color("1b1033"), Color("120b24")]
	s.lit_color = Color("86528f")
	s.shade_color = Color("361e52")
	s.light_dir = Vector2(0.6, -0.8).normalized()
	s.rim_color = Color("ffbf73")
	s.strata_color = Color("8a58a5")
	s.strata_count = 5
	s.pebble_colors = [Color("5b3a7a"), Color("6d4a86"), Color("4a2c6a"), Color("7a5090")]
	s.sky_offsets = [0.0, 0.3, 0.55, 0.74, 0.9]
	s.sky_colors = [Color("171a47"), Color("4a2a78"), Color("b8416f"), Color("f47c4e"), Color("ffd58a")]
	s.sun_anchor = Vector2(0.7, 0.57)
	s.sun_size = 660.0
	s.sun_offsets = [0.0, 0.15, 0.18, 0.5, 1.0]
	s.sun_colors = [Color("fff8e4"), Color("ffeab4"), Color(1.0, 0.78, 0.45, 0.5), Color(1.0, 0.55, 0.3, 0.14), Color(1.0, 0.5, 0.3, 0.0)]
	s.rays_color = Color(1.0, 0.7, 0.45, 0.055)
	s.star_count = 90
	s.star_zone = 0.42
	s.cloud_hi = Color("ffb38a")
	s.cloud_lo = Color("8a4d8f")
	s.cloud_alpha = 0.42
	s.birds = 4
	s.bird_color = Color("3b2259")
	s.foreground = "grass"
	s.foreground_color = Color("150b27")
	s.layers = [
		_clouds(0.012, 5.0, Vector2(0.12, 0.40), 7, Vector2(150.0, 7.0), "streak"),
		_ridge(0.03, 0.63, 150.0, 0.0021, "jagged", "", Color("b9597f"), Color("e07a6a"), Color("ffd0a0")),
		_haze(0.4, Color("ff9b5e"), 0.34),
		_clouds(0.025, 9.0, Vector2(0.2, 0.5), 5, Vector2(210.0, 30.0), "puff"),
		_ridge(0.08, 0.66, 95.0, 0.0026, "smooth", "windmill", Color("86427c"), Color("b25c7c"), Color("f0a07c")),
		_ridge(0.16, 0.7, 75.0, 0.003, "smooth", "pines", Color("5a2e6c"), Color("7a3f78"), Color("c9707c")),
		_haze(0.6, Color("ff9b5e"), 0.2),
		_ridge(0.3, 0.75, 60.0, 0.0036, "smooth", "pines", Color("3b2259"), Color("4d2b66"), Color("a05a7c")),
	]
	return s


static func _desert() -> StageSpec:
	var s := StageSpec.new()
	s.terrain_seed = 5150771
	s.bump_seed = 31
	s.shape = "dunes"
	s.noise_frequency = 0.0004
	s.ramp_floor = 0.5
	s.ramp_dist = 12000.0
	s.shape_params = {"wavelength": 3100.0, "crest": 300.0, "roll": 70.0}
	s.decor = "desert"
	s.ground_depths = PackedFloat32Array([0.0, 24.0, 120.0, 560.0, 1700.0])
	s.ground_colors = [Color("dca55a"), Color("cf9246"), Color("b27239"), Color("7d4a2c"), Color("3d2018")]
	s.lit_color = Color("f6d58e")
	s.shade_color = Color("b87a3c")
	s.light_dir = Vector2(0.7, -0.7).normalized()
	s.rim_color = Color("fff0bc")
	s.rim_glow = 0.2
	s.rim_width = 3.5
	s.strata_color = Color("8f4f2a")
	s.strata_count = 6
	s.pebble_colors = [Color("e8bc78"), Color("bd8044"), Color("94592f"), Color("f2d595")]
	s.sky_offsets = [0.0, 0.3, 0.55, 0.78, 0.93]
	s.sky_colors = [Color("1d5a9c"), Color("3f8cc6"), Color("8cc4dc"), Color("f4dcae"), Color("ffc886")]
	s.sun_anchor = Vector2(0.72, 0.42)
	s.sun_size = 780.0
	s.sun_offsets = [0.0, 0.1, 0.13, 0.4, 1.0]
	s.sun_colors = [Color("ffffff"), Color("fffbd8"), Color(1.0, 0.92, 0.6, 0.55), Color(1.0, 0.8, 0.42, 0.16), Color(1.0, 0.75, 0.4, 0.0)]
	s.rays_color = Color(1.0, 0.95, 0.7, 0.045)
	s.cloud_hi = Color("ffffff")
	s.cloud_lo = Color("cfe6f2")
	s.cloud_alpha = 0.55
	s.birds = 3
	s.bird_color = Color("4a2a20")
	s.foreground = "cacti"
	s.foreground_color = Color("3a1d12")
	s.layers = [
		_clouds(0.012, 4.0, Vector2(0.08, 0.34), 6, Vector2(190.0, 24.0), "puff"),
		_ridge(0.03, 0.6, 95.0, 0.0017, "mesa", "", Color("d6a07c"), Color("ecc196"), Color("fff0cc")),
		_haze(0.42, Color("fbd9a0"), 0.36),
		_ridge(0.08, 0.66, 70.0, 0.002, "dune", "", Color("cf8f5e"), Color("e1ad78"), Color("ffe3a8")),
		_ridge(0.16, 0.71, 56.0, 0.0024, "dune", "cacti", Color("b66d45"), Color("cf8d5c"), Color("f3c488")),
		_haze(0.62, Color("f6c07a"), 0.2),
		_ridge(0.3, 0.77, 46.0, 0.003, "dune", "cacti", Color("8f4e38"), Color("a8643f"), Color("d9985f")),
	]
	return s


static func _arctic() -> StageSpec:
	var s := StageSpec.new()
	s.terrain_seed = 90210
	s.bump_seed = 53
	s.shape = "icy"
	s.noise_frequency = 0.0013
	s.ramp_floor = 0.5
	s.shape_params = {"flat_scale": 0.03, "mask_frequency": 0.00052}
	s.decor = "arctic"
	s.ground_depths = PackedFloat32Array([0.0, 26.0, 70.0, 130.0, 560.0, 1700.0])
	s.ground_colors = [Color("e4f3ff"), Color("cfe6f8"), Color("86b0d8"), Color("4c79ac"), Color("27497d"), Color("0e1f40")]
	s.lit_color = Color("fbfeff")
	s.shade_color = Color("93b8da")
	s.light_dir = Vector2(-0.45, -0.89).normalized()
	s.rim_color = Color("d9f4ff")
	s.rim_glow = 0.22
	s.rim_width = 4.0
	s.strata_color = Color("d4ecff")
	s.strata_count = 5
	s.pebble_colors = [Color("d8eeff"), Color("8fbbe6"), Color("5f8fc4"), Color("ffffff")]
	s.sky_offsets = [0.0, 0.35, 0.65, 0.88]
	s.sky_colors = [Color("040a20"), Color("0b2447"), Color("1a5576"), Color("5ba5b0")]
	s.sun_anchor = Vector2(0.17, 0.2)
	s.sun_size = 330.0
	s.sun_offsets = [0.0, 0.12, 0.16, 0.45, 1.0]
	s.sun_colors = [Color("ffffff"), Color("eef8ff"), Color(0.75, 0.9, 1.0, 0.4), Color(0.5, 0.8, 1.0, 0.1), Color(0.5, 0.8, 1.0, 0.0)]
	s.star_count = 200
	s.star_zone = 0.62
	s.star_color = Color("e4f2ff")
	s.cloud_hi = Color("9fe3d4")
	s.cloud_lo = Color("4a6fb0")
	s.cloud_alpha = 0.25
	s.aurora = true
	s.snow = true
	s.foreground = "pines"
	s.foreground_color = Color("06142c")
	s.layers = [
		_clouds(0.012, 3.0, Vector2(0.45, 0.62), 5, Vector2(220.0, 12.0), "streak"),
		_ridge(0.03, 0.62, 140.0, 0.0019, "jagged", "", Color("3b73a0"), Color("5d9bbd"), Color("d4f2ff")),
		_haze(0.45, Color("8fd0da"), 0.3),
		_ridge(0.08, 0.67, 90.0, 0.0025, "smooth", "snow_pines", Color("29567f"), Color("3f7aa0"), Color("bde8ff")),
		_ridge(0.16, 0.71, 70.0, 0.003, "smooth", "snow_pines", Color("1c3f69"), Color("2f5f88"), Color("9fd8f4")),
		_haze(0.62, Color("6fb8d4"), 0.2),
		_ridge(0.3, 0.76, 56.0, 0.0036, "smooth", "snow_pines", Color("12294d"), Color("1d3c64"), Color("7cc0e4")),
	]
	return s


static func _moon() -> StageSpec:
	var s := StageSpec.new()
	s.terrain_seed = 1969072
	s.bump_seed = 97
	s.shape = "craters"
	s.noise_frequency = 0.0008
	s.ramp_floor = 0.5
	s.shape_params = {"cell": 3400.0, "crater_chance": 0.6, "ramp_chance": 0.9}
	s.decor = "moon"
	s.ground_depths = PackedFloat32Array([0.0, 20.0, 110.0, 540.0, 1700.0])
	s.ground_colors = [Color("a3a2b2"), Color("86859a"), Color("535263"), Color("2c2b3a"), Color("12121c")]
	s.lit_color = Color("dcdbe8")
	s.shade_color = Color("5a596c")
	s.light_dir = Vector2(0.75, -0.66).normalized()
	s.rim_color = Color("f4f6ff")
	s.rim_glow = 0.2
	s.rim_width = 3.5
	s.strata_color = Color("c4c3d4")
	s.strata_count = 4
	s.pebble_colors = [Color("bdbccc"), Color("7d7c8f"), Color("4f4e60"), Color("dad9e8")]
	s.sky_offsets = [0.0, 1.0]
	s.sky_colors = [Color("010207"), Color("0a0d22")]
	s.sun_anchor = Vector2(0.86, 0.5)
	s.sun_size = 300.0
	s.sun_offsets = [0.0, 0.07, 0.1, 0.35, 1.0]
	s.sun_colors = [Color("ffffff"), Color("ffffff"), Color(1.0, 0.97, 0.88, 0.45), Color(1.0, 0.95, 0.85, 0.08), Color(1.0, 0.95, 0.85, 0.0)]
	s.star_count = 420
	s.star_zone = 0.8
	s.star_color = Color("f4f6ff")
	s.earth = true
	s.foreground = "rocks"
	s.foreground_color = Color("07070d")
	s.layers = [
		_ridge(0.03, 0.62, 120.0, 0.0018, "crag", "", Color("5d607c"), Color("7b7e98"), Color("c8cbe6")),
		_ridge(0.08, 0.67, 85.0, 0.0023, "crag", "", Color("42445d"), Color("585a76"), Color("a0a3c4")),
		_ridge(0.16, 0.72, 66.0, 0.003, "crag", "", Color("2e3046"), Color("40425c"), Color("8588aa")),
		_ridge(0.3, 0.77, 50.0, 0.0038, "crag", "", Color("1c1d2e"), Color("2a2c40"), Color("6a6d90")),
	]
	return s
