class_name SfxBank
extends RefCounted
## Synthesises every one-shot sound effect from sine glides, bells and filtered noise.
## Each recipe returns a peak-normalised AudioStreamWAV; Sfx sets the level when it plays one.

const PEAK := 0.9
const IDS: Array[StringName] = [
	&"coin", &"fuel", &"thud_soft", &"thud_hard", &"crash",
	&"trick", &"ui_click", &"ui_purchase", &"out_of_fuel",
]

static var _streams: Dictionary = {}


## All effects, built once on first use.
static func streams() -> Dictionary:
	if _streams.is_empty():
		for id in IDS:
			_streams[id] = build(id)
	return _streams


## Drops the cached streams (used when the pool leaves the tree, e.g. at shutdown).
static func clear() -> void:
	_streams.clear()


static func build(id: StringName) -> AudioStreamWAV:
	return AudioSynth.to_stream(build_samples(id))


static func build_samples(id: StringName) -> PackedFloat32Array:
	match id:
		&"coin":
			return _coin()
		&"fuel":
			return _fuel()
		&"thud_soft":
			return _thud_soft()
		&"thud_hard":
			return _thud_hard()
		&"crash":
			return _crash()
		&"trick":
			return _trick()
		&"ui_click":
			return _ui_click()
		&"ui_purchase":
			return _ui_purchase()
		&"out_of_fuel":
			return _out_of_fuel()
	push_error("SfxBank: unknown sound '%s'" % id)
	return AudioSynth.blank(0.05)


static func _coin() -> PackedFloat32Array:
	var buf := AudioSynth.blank(0.38)
	AudioSynth.add_bell(buf, 0.0, 987.8, 0.5, 0.045)
	AudioSynth.add_bell(buf, 0.065, 1318.5, 0.62, 0.1)
	AudioSynth.add_hiss(buf, 0.0, 0.03, 3500.0, 0.2, 0.006, 5)
	return AudioSynth.finish(buf, SfxBank.PEAK)


static func _fuel() -> PackedFloat32Array:
	var buf := AudioSynth.blank(0.78)
	for k in 3:
		var start := 0.0 + k * 0.15
		AudioSynth.add_tone(buf, start, 0.16, 210.0 + k * 40.0, 520.0 + k * 90.0, 0.75, 0.07, 0.06)
		AudioSynth.add_band_noise(buf, start, 0.1, 900.0, 1.2, 0.18, 0.04, 40 + k)
	AudioSynth.add_bell(buf, 0.46, 1046.5, 0.5, 0.09)
	AudioSynth.add_bell(buf, 0.54, 1568.0, 0.5, 0.13)
	return AudioSynth.finish(buf, SfxBank.PEAK)


static func _thud_soft() -> PackedFloat32Array:
	var buf := AudioSynth.blank(0.2)
	AudioSynth.add_tone(buf, 0.0, 0.16, 135.0, 72.0, 0.9, 0.045, 0.02)
	AudioSynth.add_band_noise(buf, 0.0, 0.06, 450.0, 0.8, 0.45, 0.018, 51)
	AudioSynth.soft_clip(buf, 1.3)
	return AudioSynth.finish(buf, SfxBank.PEAK)


static func _thud_hard() -> PackedFloat32Array:
	var buf := AudioSynth.blank(0.55)
	AudioSynth.add_tone(buf, 0.0, 0.5, 98.0, 42.0, 1.0, 0.12, 0.05)
	AudioSynth.add_tone(buf, 0.0, 0.25, 190.0, 90.0, 0.35, 0.06, 0.04)
	AudioSynth.add_band_noise(buf, 0.0, 0.2, 700.0, 0.7, 0.7, 0.05, 61)
	AudioSynth.add_band_noise(buf, 0.02, 0.3, 240.0, 0.9, 0.5, 0.09, 62)
	AudioSynth.soft_clip(buf, 1.6)
	return AudioSynth.finish(buf, SfxBank.PEAK)


static func _crash() -> PackedFloat32Array:
	var buf := AudioSynth.blank(1.0)
	AudioSynth.add_tone(buf, 0.0, 0.8, 112.0, 38.0, 1.0, 0.2, 0.06)
	AudioSynth.add_band_noise(buf, 0.0, 0.4, 1200.0, 0.6, 0.9, 0.09, 71)
	AudioSynth.add_band_noise(buf, 0.0, 0.25, 420.0, 0.8, 0.8, 0.07, 72)
	var rings: Array[float] = [412.0, 689.0, 1130.0, 1790.0, 2610.0]
	for i in rings.size():
		AudioSynth.add_tone(buf, 0.0, 0.7, rings[i], rings[i] * 0.995, 0.2 / (1.0 + i * 0.6), 0.16 - i * 0.025, 0.01)
	var rng := RandomNumberGenerator.new()
	rng.seed = 73
	for k in 8:
		var at := 0.06 + k * 0.065 + rng.randf() * 0.02
		AudioSynth.add_band_noise(buf, at, 0.05, rng.randf_range(1500.0, 3300.0), 1.4, 0.4 * (1.0 - k / 9.0), 0.012, 80 + k)
	AudioSynth.soft_clip(buf, 1.5)
	return AudioSynth.finish(buf, SfxBank.PEAK)


static func _trick() -> PackedFloat32Array:
	var buf := AudioSynth.blank(0.7)
	var notes: Array[float] = [1046.5, 1318.5, 1568.0, 2093.0]
	var starts: Array[float] = [0.0, 0.08, 0.16, 0.26]
	for i in notes.size():
		AudioSynth.add_bell(buf, starts[i], notes[i], 0.5, 0.07 + i * 0.03)
	AudioSynth.add_hiss(buf, 0.26, 0.4, 4500.0, 0.12, 0.12, 91, 0.02)
	return AudioSynth.finish(buf, SfxBank.PEAK)


static func _ui_click() -> PackedFloat32Array:
	var buf := AudioSynth.blank(0.06)
	AudioSynth.add_band_noise(buf, 0.0, 0.02, 3000.0, 1.5, 0.6, 0.004, 101)
	AudioSynth.add_tone(buf, 0.0, 0.04, 1900.0, 1300.0, 0.45, 0.009, 0.01)
	AudioSynth.add_tone(buf, 0.0, 0.04, 320.0, 260.0, 0.3, 0.012, 0.01)
	return AudioSynth.finish(buf, SfxBank.PEAK)


static func _ui_purchase() -> PackedFloat32Array:
	var buf := AudioSynth.blank(0.9)
	AudioSynth.add_tone(buf, 0.0, 0.1, 170.0, 110.0, 0.5, 0.03, 0.02)
	AudioSynth.add_band_noise(buf, 0.0, 0.08, 2600.0, 1.0, 0.5, 0.02, 111)
	AudioSynth.add_bell(buf, 0.07, 1568.0, 0.55, 0.12)
	AudioSynth.add_bell(buf, 0.14, 2093.0, 0.6, 0.2)
	AudioSynth.add_hiss(buf, 0.14, 0.5, 4500.0, 0.1, 0.15, 112, 0.01)
	return AudioSynth.finish(buf, SfxBank.PEAK)


static func _out_of_fuel() -> PackedFloat32Array:
	var buf := AudioSynth.blank(1.15)
	var pops: Array[float] = [0.0, 0.17, 0.32, 0.53, 0.82]
	for i in pops.size():
		var strength := 0.95 - i * 0.14
		AudioSynth.add_tone(buf, pops[i], 0.16, 140.0 - i * 12.0, 62.0, strength, 0.04 + i * 0.008, 0.03)
		AudioSynth.add_band_noise(buf, pops[i], 0.08, 320.0, 0.8, strength * 0.7, 0.02, 120 + i)
	AudioSynth.add_tone(buf, 0.0, 1.1, 165.0, 48.0, 0.22, 0.5, 0.5)
	AudioSynth.soft_clip(buf, 1.7)
	return AudioSynth.finish(buf, SfxBank.PEAK)
