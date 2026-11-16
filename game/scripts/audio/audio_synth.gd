class_name AudioSynth
extends RefCounted
## Small DSP toolbox for the code-synthesised audio.
##
## Buffers are mono PackedFloat32Array (-1..1). Everything here is deterministic and keeps no
## shared state, so any of it can run on a worker thread. Packed arrays are passed by reference,
## so the add_* helpers write straight into the buffer they are given.

const SAMPLE_RATE := 22050
const FADE_IN_SECONDS := 0.001
const FADE_OUT_SECONDS := 0.008
const ATTACK_SAMPLES := 24.0
const PCM_MAX := 32767.0
const LCG_MULTIPLIER := 1664525
const LCG_INCREMENT := 1013904223
const LCG_MASK := 0xFFFFFFFF
const LCG_HALF := 2147483648.0


static func blank(seconds: float, rate: int = SAMPLE_RATE) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(maxi(roundi(seconds * rate), 1))
	return buf


static func noise(count: int, seed_value: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(count)
	var state := seed_value & LCG_MASK
	for i in count:
		state = (state * LCG_MULTIPLIER + LCG_INCREMENT) & LCG_MASK
		out[i] = state / LCG_HALF - 1.0
	return out


## Adds a decaying sine whose pitch glides from `f_start` towards `f_end` (time constant `glide`).
static func add_tone(buf: PackedFloat32Array, start: float, dur: float, f_start: float, f_end: float, amp: float, decay: float, glide: float = 0.03) -> void:
	var first := roundi(start * SAMPLE_RATE)
	var count := mini(roundi(dur * SAMPLE_RATE), buf.size() - first)
	if count <= 0:
		return
	var env_step := exp(-1.0 / (decay * SAMPLE_RATE))
	var glide_step := exp(-1.0 / (glide * SAMPLE_RATE))
	var phase_step := TAU / SAMPLE_RATE
	var phase := 0.0
	var env := amp
	var bend := f_start - f_end
	for i in count:
		phase += (f_end + bend) * phase_step
		buf[first + i] += sin(phase) * env * minf(i / ATTACK_SAMPLES, 1.0)
		env *= env_step
		bend *= glide_step


## Adds a bright struck-metal note: fundamental plus a fast-dying octave and a sharper third partial.
static func add_bell(buf: PackedFloat32Array, start: float, freq: float, amp: float, decay: float) -> void:
	add_tone(buf, start, decay * 5.0, freq, freq, amp, decay, 0.01)
	add_tone(buf, start, decay * 3.0, freq * 2.0, freq * 2.0, amp * 0.35, decay * 0.55, 0.01)
	add_tone(buf, start, decay * 2.0, freq * 3.01, freq * 3.01, amp * 0.14, decay * 0.3, 0.01)


## Adds a burst of band-passed noise (state-variable filter, centre below about 3.5 kHz) with an exponential decay.
static func add_band_noise(buf: PackedFloat32Array, start: float, dur: float, center: float, q: float, amp: float, decay: float, seed_value: int) -> void:
	var first := roundi(start * SAMPLE_RATE)
	var count := mini(roundi(dur * SAMPLE_RATE), buf.size() - first)
	if count <= 0:
		return
	var f := 2.0 * sin(PI * center / SAMPLE_RATE)
	var damp := 1.0 / q
	var env_step := exp(-1.0 / (decay * SAMPLE_RATE))
	var env := amp
	var state := seed_value & LCG_MASK
	var low := 0.0
	var band := 0.0
	for i in count:
		state = (state * LCG_MULTIPLIER + LCG_INCREMENT) & LCG_MASK
		var x := state / LCG_HALF - 1.0
		low += f * band
		var high := x - low - damp * band
		band += f * high
		buf[first + i] += band * damp * env * minf(i / ATTACK_SAMPLES, 1.0)
		env *= env_step


## Adds high-passed noise ("shh", sparkle) with a linear attack and an exponential decay.
static func add_hiss(buf: PackedFloat32Array, start: float, dur: float, cutoff: float, amp: float, decay: float, seed_value: int, attack: float = 0.0) -> void:
	var first := roundi(start * SAMPLE_RATE)
	var count := mini(roundi(dur * SAMPLE_RATE), buf.size() - first)
	if count <= 0:
		return
	var coeff := 1.0 - exp(-TAU * cutoff / SAMPLE_RATE)
	var env_step := exp(-1.0 / (decay * SAMPLE_RATE))
	var attack_samples := maxf(attack * SAMPLE_RATE, ATTACK_SAMPLES)
	var env := amp
	var state := seed_value & LCG_MASK
	var lp1 := 0.0
	var lp2 := 0.0
	for i in count:
		state = (state * LCG_MULTIPLIER + LCG_INCREMENT) & LCG_MASK
		var x := state / LCG_HALF - 1.0
		lp1 += coeff * (x - lp1)
		var stage := x - lp1
		lp2 += coeff * (stage - lp2)
		buf[first + i] += (stage - lp2) * env * minf(i / attack_samples, 1.0)
		env *= env_step


## Adds `src` into `dst` at frame `start`, wrapping past the end so loops stay seamless.
static func mix_wrapped(dst: PackedFloat32Array, src: PackedFloat32Array, start: int, gain: float) -> void:
	var total := dst.size()
	var count := src.size()
	var pos := posmod(start, total)
	var run := mini(count, total - pos)
	for i in run:
		dst[pos + i] += src[i] * gain
	for i in count - run:
		dst[i] += src[run + i] * gain


static func peak(buf: PackedFloat32Array) -> float:
	var top := 0.0
	for i in buf.size():
		top = maxf(top, absf(buf[i]))
	return top


static func rms(buf: PackedFloat32Array) -> float:
	var sum := 0.0
	for i in buf.size():
		sum += buf[i] * buf[i]
	return sqrt(sum / maxi(buf.size(), 1))


static func normalize(buf: PackedFloat32Array, target: float) -> void:
	var top := peak(buf)
	if top < 0.000001:
		return
	var gain := target / top
	for i in buf.size():
		buf[i] *= gain


static func soft_clip(buf: PackedFloat32Array, drive: float) -> void:
	for i in buf.size():
		buf[i] = tanh(buf[i] * drive)


## Fades the first and last few milliseconds so a one-shot starts and ends at zero (no clicks).
static func fade_edges(buf: PackedFloat32Array) -> void:
	var fade_in := mini(roundi(FADE_IN_SECONDS * SAMPLE_RATE), buf.size())
	var fade_out := mini(roundi(FADE_OUT_SECONDS * SAMPLE_RATE), buf.size())
	for i in fade_in:
		buf[i] *= float(i) / fade_in
	for i in fade_out:
		buf[buf.size() - 1 - i] *= float(i) / fade_out


## Finishes a one-shot: edge fades, then a peak normalise to `target`.
static func finish(buf: PackedFloat32Array, target: float) -> PackedFloat32Array:
	fade_edges(buf)
	normalize(buf, target)
	return buf


static func to_stream(buf: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, roundi(clampf(buf[i], -1.0, 1.0) * PCM_MAX))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = buf.size()
	return stream


## Largest absolute sample of a 16-bit mono stream, 0..1 (used by the tests).
static func stream_peak(stream: AudioStreamWAV) -> float:
	var data := stream.data
	var top := 0
	for i in data.size() >> 1:
		top = maxi(top, absi(data.decode_s16(i * 2)))
	return top / PCM_MAX
