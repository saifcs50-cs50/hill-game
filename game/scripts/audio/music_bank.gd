class_name MusicBank
extends RefCounted
## Renders a stage's percussion groove into one seamless looping AudioStreamWAV.
##
## Each hit is synthesised once, then placed on a sixteenth-note grid with a little swing and
## human timing and level jitter. Hits that ring past the end wrap round to the start, so the loop
## has no seam. Only local data is used, so `build()` is safe to run on a worker thread.

const HIT_NAMES: Array[String] = ["dum", "tom", "tak", "shake", "open", "clap", "rim"]
## How loud each voice sits against the others.
const HIT_GAIN := {"dum": 1.0, "tom": 0.7, "tak": 0.75, "shake": 0.42, "open": 0.4, "clap": 0.6, "rim": 0.5}
const TOM_PITCH := 1.45
const OPEN_SHAKER_DECAY := 0.09
const VELOCITY_CURVE := 1.4
const TIMING_JITTER_SECONDS := 0.0025
const LEVEL_JITTER := 0.08
const ZERO_CODE := 48
const MAX_STRENGTH := 9.0


static func build(stage_id: String) -> AudioStreamWAV:
	return AudioSynth.to_stream(render(MusicGrooves.get_groove(stage_id)), true)


## Loop length in seconds for a groove (bars x 16 steps at its tempo).
static func loop_seconds(groove: Dictionary) -> float:
	var form: Array = groove["form"]
	return form.size() * MusicGrooves.STEPS_PER_BAR * _step_seconds(groove)


static func render(groove: Dictionary) -> PackedFloat32Array:
	var form: Array = groove["form"]
	var tracks: Dictionary = groove["tracks"]
	var step_frames := _step_seconds(groove) * AudioSynth.SAMPLE_RATE
	var out := PackedFloat32Array()
	out.resize(roundi(form.size() * MusicGrooves.STEPS_PER_BAR * step_frames))
	var rng := RandomNumberGenerator.new()
	rng.seed = groove["seed"]
	for track: String in tracks:
		var hit := _make_hit(track)
		var variants: Array = tracks[track]
		for bar in form.size():
			var pattern: String = variants[int(form[bar]) % variants.size()]
			_place_bar(out, hit, pattern, bar, groove, step_frames, rng, HIT_GAIN[track])
	AudioSynth.normalize(out, groove["peak"])
	return out


static func _step_seconds(groove: Dictionary) -> float:
	var tempo: float = groove["tempo"]
	return 60.0 / tempo / 4.0


static func _place_bar(out: PackedFloat32Array, hit: PackedFloat32Array, pattern: String, bar: int, groove: Dictionary, step_frames: float, rng: RandomNumberGenerator, voice_gain: float) -> void:
	var swing: float = groove["swing"]
	var jitter := TIMING_JITTER_SECONDS * AudioSynth.SAMPLE_RATE
	for step in MusicGrooves.STEPS_PER_BAR:
		var code := pattern.unicode_at(step)
		if code == MusicGrooves.REST.unicode_at(0):
			continue
		var strength := pow((code - ZERO_CODE) / MAX_STRENGTH, VELOCITY_CURVE)
		strength *= 1.0 + rng.randf_range(-LEVEL_JITTER, LEVEL_JITTER)
		var position := (bar * MusicGrooves.STEPS_PER_BAR + step) * step_frames
		if step % 2 == 1:
			position += swing * step_frames
		AudioSynth.mix_wrapped(out, hit, roundi(position + rng.randf_range(-jitter, jitter)), strength * voice_gain)


static func _make_hit(track: String) -> PackedFloat32Array:
	match track:
		"dum":
			return Percussion.dum()
		"tom":
			return Percussion.dum(TOM_PITCH)
		"tak":
			return Percussion.tak()
		"shake":
			return Percussion.shaker()
		"open":
			return Percussion.shaker(OPEN_SHAKER_DECAY)
		"clap":
			return Percussion.clap()
		"rim":
			return Percussion.rim()
	push_error("MusicBank: unknown track '%s'" % track)
	return AudioSynth.blank(0.01)
