class_name TerrainShape
extends RefCounted
## The height function of a stage: a pure function of x plus the stage's fixed seeds.
## Positive "up" values are turned into y-down heights at the end. Everything is scaled by a
## flat start (nothing before spec.flat_start) and a difficulty ramp that grows with distance.

const DETAIL_BUMP := 8.0
const DUNE_PEAK := 0.74 ## where along a dune the crest sits (0..1)
const DUNE_SMOOTH := 70.0 ## half-width in px of the kernel that rounds the crest
const CRATER_FRACTION := 0.3

var spec: StageSpec

var _hills := FastNoiseLite.new()
var _bumps := FastNoiseLite.new()
var _mask := FastNoiseLite.new()


func _init(p_spec: StageSpec) -> void:
	spec = p_spec
	_hills.seed = spec.terrain_seed
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.frequency = spec.noise_frequency
	_hills.fractal_octaves = 2 if spec.shape == "hills" else 1
	_bumps.seed = spec.bump_seed
	_bumps.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_bumps.frequency = 0.009
	_bumps.fractal_type = FastNoiseLite.FRACTAL_NONE
	_mask.seed = spec.terrain_seed + 5
	_mask.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_mask.frequency = _param("mask_frequency", 0.0005)
	_mask.fractal_type = FastNoiseLite.FRACTAL_NONE


## Surface height (y grows downward) at a world x. Pure function of x.
func height_at(x: float) -> float:
	var flat := smoothstep(spec.flat_start, spec.flat_end, x)
	if flat <= 0.0:
		return 0.0
	var ramp := spec.ramp_floor + (1.0 - spec.ramp_floor) * (1.0 - exp(-maxf(x, 0.0) / spec.ramp_dist))
	var bump_scale := DETAIL_BUMP * flat
	var up := 0.0
	match spec.shape:
		"dunes":
			up = _dunes(x)
		"icy":
			var open := open_ice(x)
			up = _icy(x, open)
			bump_scale *= lerpf(0.15, 1.0, open)
		"craters":
			up = _craters(x)
		_:
			up = _hills_up(x)
	return -(up * ramp * flat + _bumps.get_noise_1d(x) * bump_scale)


## Slow -1..1 variation used to mottle the ground colour.
func mottle_at(x: float) -> float:
	return _mask.get_noise_1d(x * 6.0 + 4000.0)


func _param(key: String, fallback: float) -> float:
	return float(spec.shape_params.get(key, fallback))


## Deterministic hash of an integer to 0..1, stable across platforms.
static func hash01(n: int) -> float:
	var h := (n ^ 61) & 0xFFFFFFFF
	h = (h ^ (h >> 16)) & 0xFFFFFFFF
	h = (h * 9) & 0xFFFFFFFF
	h = (h ^ (h >> 4)) & 0xFFFFFFFF
	h = (h * 0x27d4eb2d) & 0xFFFFFFFF
	h = (h ^ (h >> 15)) & 0xFFFFFFFF
	return float(h & 0xFFFFFF) / 16777216.0


func _hills_up(x: float) -> float:
	return sin(x * 0.0021) * 150.0 + sin(x * 0.0057 + 1.3) * 60.0 + _hills.get_noise_1d(x) * 230.0 + sin(x * 0.0113 + 0.7) * 20.0


# Desert: one dune per cell, a long climb then a drop, with a few big crests


func _dunes(x: float) -> float:
	var kernel := DUNE_SMOOTH
	return 0.25 * _dune_raw(x - kernel) + 0.5 * _dune_raw(x) + 0.25 * _dune_raw(x + kernel)


func _dune_raw(x: float) -> float:
	var wavelength := _param("wavelength", 3100.0)
	var crest := _param("crest", 300.0)
	var u := x / wavelength + _hills.get_noise_1d(x) * 0.12
	var cell := floori(u)
	var amp := lerpf(0.55, 1.45, hash01(cell + spec.terrain_seed))
	var roll := sin(x * 0.0007 + 0.8) * _param("roll", 70.0)
	return _dune_profile(u - cell) * amp * crest + roll


## 0 at the dune foot, 1 at the crest: eases up, keeps climbing, then drops away.
static func _dune_profile(f: float) -> float:
	if f < DUNE_PEAK:
		var s := f / DUNE_PEAK
		return s * s * (0.55 + 0.45 * s)
	var d := (f - DUNE_PEAK) / (1.0 - DUNE_PEAK)
	return 0.5 + 0.5 * cos(PI * d)


# Arctic: medium hills with flat icy stretches where the mask is closed

## 0 on flat ice, 1 on open hills.
func open_ice(x: float) -> float:
	return smoothstep(-0.12, 0.3, _mask.get_noise_1d(x))


func _icy(x: float, open: float) -> float:
	var hills := sin(x * 0.0024 + 0.4) * 115.0 + sin(x * 0.0061 + 2.0) * 45.0 + _hills.get_noise_1d(x) * 170.0
	return hills * lerpf(_param("flat_scale", 0.03), 1.0, open)


# Moon: one feature per cell, a crater, a launch ramp or just rolling ground


func _craters(x: float) -> float:
	var cell_width := _param("cell", 3000.0)
	var cell := floori(x / cell_width)
	var rel := x - cell * cell_width
	var seed_base := cell * 7 + spec.terrain_seed
	var kind := hash01(seed_base)
	var up := sin(x * 0.0011) * 80.0 + _hills.get_noise_1d(x) * 110.0
	if kind < _param("crater_chance", 0.62):
		up += _crater(rel, cell_width, seed_base)
	elif kind < _param("ramp_chance", 0.9):
		up += _launch_ramp(rel, seed_base)
	return up


func _crater(rel: float, cell_width: float, seed_base: int) -> float:
	var center := cell_width * (0.34 + 0.32 * hash01(seed_base + 1))
	var radius := 280.0 + 300.0 * hash01(seed_base + 2)
	var depth := radius * (0.24 + 0.16 * hash01(seed_base + 3))
	var d := absf(rel - center) / radius
	var bowl := 0.0
	if d < 1.0:
		var inner := 1.0 - d * d
		bowl = -depth * inner * inner
	var lip := depth * CRATER_FRACTION * exp(-pow((d - 1.1) / 0.22, 2.0))
	return bowl + lip


## A long climb that keeps steepening, then a short drop: a ramp for low-gravity jumps.
func _launch_ramp(rel: float, seed_base: int) -> float:
	var start := 350.0 + 250.0 * hash01(seed_base + 4)
	var length := 700.0 + 200.0 * hash01(seed_base + 5)
	var height := 190.0 + 90.0 * hash01(seed_base + 6)
	var drop := 280.0
	if rel < start:
		return 0.0
	if rel < start + length:
		return height * pow((rel - start) / length, 1.8)
	if rel < start + length + drop:
		var d := (rel - start - length) / drop
		return height * (0.5 + 0.5 * cos(PI * d))
	return 0.0
