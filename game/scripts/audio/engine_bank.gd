class_name EngineBank
extends RefCounted
## Synthesises the small-petrol-engine loops and holds the rpm-to-layer maths.
##
## Four seamless loops sit at fixed rpm stops. Each is an uneven firing-pulse train driven through
## two resonant filters (one follows the firing rate, one is a fixed "exhaust" boom), plus a little
## noise and soft clipping. At run time EngineSound crossfades the two neighbouring loops and
## pitch-scales each so the firing rate matches the wanted rpm.

const STOPS_RPM: Array[float] = [1000.0, 1900.0, 3500.0, 6000.0]
const PULSES_PER_LOOP: Array[int] = [16, 30, 58, 100]
const IDLE_RPM := 1000.0
const REDLINE_RPM := 6400.0
## Each crossfade only happens in the middle of the gap between two stops (from this fraction to
## one minus it), so a fading layer is never left stretched far from its natural pitch.
const CROSSFADE_START := 0.25
const FIRING_PULSES_PER_REV := 2.0
const PULSE_WIDTH := 0.34
## Relative strength of the four cylinders in firing order; blended in by `_unevenness`.
const CYLINDER_STRENGTH: Array[float] = [1.0, 0.6, 0.85, 0.5]
const BOOM_HZ := 300.0
const BOOM_Q := 3.0
const FORMANT_Q := 2.2
const FORMANT_BASE_HZ := 150.0
const FORMANT_PER_FIRING_HZ := 3.0
const FORMANT_MAX_HZ := 2800.0
const DRIVE := 1.9
const DC_BLOCK_HZ := 30.0
const LOOP_PEAK := 0.8
const SEED := 7919

static var _loops: Array[AudioStreamWAV] = []


## The four loops, built once on first use.
static func loops() -> Array[AudioStreamWAV]:
	if _loops.is_empty():
		for index in STOPS_RPM.size():
			_loops.append(AudioSynth.to_stream(build_layer(index), true))
	return _loops


## Drops the cached loops so their memory can be freed.
static func clear() -> void:
	_loops.clear()


## Virtual engine rpm for a 0..1 engine speed.
static func real_rpm(rpm01: float) -> float:
	return lerpf(IDLE_RPM, REDLINE_RPM, clampf(rpm01, 0.0, 1.0))


## Equal-power crossfade weights over the loops for a 0..1 engine speed (squares sum to 1).
static func layer_weights(rpm01: float) -> PackedFloat32Array:
	var weights := PackedFloat32Array()
	weights.resize(STOPS_RPM.size())
	var rpm := real_rpm(rpm01)
	var last := STOPS_RPM.size() - 1
	if rpm <= STOPS_RPM[0]:
		weights[0] = 1.0
		return weights
	if rpm >= STOPS_RPM[last]:
		weights[last] = 1.0
		return weights
	var upper := 1
	while rpm > STOPS_RPM[upper]:
		upper += 1
	var gap := log(rpm / STOPS_RPM[upper - 1]) / log(STOPS_RPM[upper] / STOPS_RPM[upper - 1])
	var blend := clampf((gap - CROSSFADE_START) / (1.0 - 2.0 * CROSSFADE_START), 0.0, 1.0)
	weights[upper - 1] = cos(blend * PI * 0.5)
	weights[upper] = sin(blend * PI * 0.5)
	return weights


## Playback pitch that makes loop `index` fire at the rate of the wanted rpm.
static func layer_pitch(index: int, rpm01: float) -> float:
	return real_rpm(rpm01) / STOPS_RPM[index]


## One loop as raw samples (peak LOOP_PEAK). Its length is a whole number of firing pulses.
static func build_layer(index: int) -> PackedFloat32Array:
	var fire_hz := STOPS_RPM[index] / 60.0 * FIRING_PULSES_PER_REV
	var period := AudioSynth.SAMPLE_RATE / fire_hz
	var pulses := PULSES_PER_LOOP[index]
	var length := roundi(pulses * period)
	var excitation := _excitation(index, pulses, period, length)
	var hiss := AudioSynth.noise(length, SEED + index)
	var out := _resonate(excitation, hiss, index, fire_hz)
	AudioSynth.normalize(out, LOOP_PEAK)
	return out


static func _unevenness(index: int) -> float:
	return lerpf(1.0, 0.25, index / float(STOPS_RPM.size() - 1))


## One half-sine pulse per firing, louder or softer per cylinder, with a little random variation.
static func _excitation(index: int, pulses: int, period: float, length: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(length)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + index
	var width := maxi(roundi(period * PULSE_WIDTH), 4)
	var uneven := _unevenness(index)
	for k in pulses:
		var strength := lerpf(1.0, CYLINDER_STRENGTH[k % CYLINDER_STRENGTH.size()], uneven)
		var amp := strength * rng.randf_range(0.92, 1.08)
		var start := roundi(k * period)
		for j in width:
			out[(start + j) % length] += amp * sin(PI * j / width)
	return out


## Runs the pulses through the filters twice and keeps the second pass, so the loop seam is clean.
static func _resonate(excitation: PackedFloat32Array, hiss: PackedFloat32Array, index: int, fire_hz: float) -> PackedFloat32Array:
	var length := excitation.size()
	var rate := float(AudioSynth.SAMPLE_RATE)
	var formant_hz := minf(fire_hz * FORMANT_PER_FIRING_HZ + FORMANT_BASE_HZ, FORMANT_MAX_HZ)
	var f_formant := 2.0 * sin(PI * formant_hz / rate)
	var f_boom := 2.0 * sin(PI * BOOM_HZ / rate)
	var damp_formant := 1.0 / FORMANT_Q
	var damp_boom := 1.0 / BOOM_Q
	var noise_level := lerpf(0.05, 0.14, index / float(STOPS_RPM.size() - 1))
	var dc_coeff := 1.0 - exp(-TAU * DC_BLOCK_HZ / rate)
	var low_a := 0.0
	var band_a := 0.0
	var low_b := 0.0
	var band_b := 0.0
	var dc := 0.0
	var out := PackedFloat32Array()
	out.resize(length)
	for pass_index in 2:
		for i in length:
			var x := excitation[i] + hiss[i] * noise_level
			low_a += f_formant * band_a
			var high_a := x - low_a - damp_formant * band_a
			band_a += f_formant * high_a
			low_b += f_boom * band_b
			var high_b := x - low_b - damp_boom * band_b
			band_b += f_boom * high_b
			var y := tanh((low_a + 0.5 * band_a + 0.7 * low_b) * DRIVE)
			dc += dc_coeff * (y - dc)
			out[i] = y - dc
	return out
