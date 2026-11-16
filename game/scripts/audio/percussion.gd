class_name Percussion
extends RefCounted
## Hand-percussion one-shots synthesised from sine glides and filtered noise: frame-drum "dum",
## daf "tak", shaker, hand clap and rim click. Nothing here is melodic. Every hit is returned
## peak-normalised to 1.0; the music mixer sets each hit's level.

const DUM_SECONDS := 0.5
const TAK_SECONDS := 0.16
const CLAP_SECONDS := 0.3
const RIM_SECONDS := 0.08
const SHAKER_SECONDS := 0.24


## Frame-drum low hit: a body tone plus two upper membrane modes and a palm slap, so it still reads on small speakers.
## `pitch` 1.0 is the "dum"; about 1.45 gives a smaller, higher "tom".
static func dum(pitch: float = 1.0) -> PackedFloat32Array:
	var buf := AudioSynth.blank(DUM_SECONDS)
	AudioSynth.add_tone(buf, 0.0, DUM_SECONDS, 205.0 * pitch, 94.0 * pitch, 1.0, 0.13, 0.03)
	AudioSynth.add_tone(buf, 0.0, 0.2, 326.0 * pitch, 150.0 * pitch, 0.34, 0.05, 0.03)
	AudioSynth.add_tone(buf, 0.0, 0.12, 440.0 * pitch, 205.0 * pitch, 0.24, 0.03, 0.03)
	AudioSynth.add_band_noise(buf, 0.0, 0.05, 900.0, 0.8, 0.9, 0.011, 11)
	AudioSynth.soft_clip(buf, 1.8)
	return AudioSynth.finish(buf, 1.0)


## Daf / frame-drum high edge slap.
static func tak() -> PackedFloat32Array:
	var buf := AudioSynth.blank(TAK_SECONDS)
	AudioSynth.add_band_noise(buf, 0.0, 0.1, 2600.0, 1.6, 1.0, 0.016, 21)
	AudioSynth.add_band_noise(buf, 0.0, 0.05, 1500.0, 1.2, 0.5, 0.01, 22)
	AudioSynth.add_tone(buf, 0.0, 0.1, 540.0, 480.0, 0.55, 0.022, 0.01)
	return AudioSynth.finish(buf, 1.0)


## Shaker: a soft swell then a short or long hush. `decay` is the tail time constant in seconds.
static func shaker(decay: float = 0.035) -> PackedFloat32Array:
	var buf := AudioSynth.blank(SHAKER_SECONDS)
	AudioSynth.add_hiss(buf, 0.0, SHAKER_SECONDS, 4300.0, 1.0, decay, 31, 0.007)
	return AudioSynth.finish(buf, 1.0)


## Hand clap: a quick flam of noise bursts, then a short tail.
static func clap() -> PackedFloat32Array:
	var buf := AudioSynth.blank(CLAP_SECONDS)
	var flam: Array[float] = [0.0, 0.009, 0.019, 0.031]
	for i in flam.size():
		AudioSynth.add_band_noise(buf, flam[i], 0.03, 1150.0, 1.2, 0.8, 0.006, 41 + i)
	AudioSynth.add_band_noise(buf, 0.031, 0.25, 1050.0, 1.0, 0.7, 0.07, 45)
	AudioSynth.add_band_noise(buf, 0.0, 0.2, 2400.0, 1.4, 0.3, 0.05, 46)
	return AudioSynth.finish(buf, 1.0)


## Rim click: a dry woody tick.
static func rim() -> PackedFloat32Array:
	var buf := AudioSynth.blank(RIM_SECONDS)
	AudioSynth.add_tone(buf, 0.0, 0.05, 1750.0, 1700.0, 1.0, 0.007, 0.01)
	AudioSynth.add_tone(buf, 0.0, 0.03, 2975.0, 2900.0, 0.4, 0.004, 0.01)
	AudioSynth.add_band_noise(buf, 0.0, 0.01, 2800.0, 1.5, 0.4, 0.002, 51)
	return AudioSynth.finish(buf, 1.0)
