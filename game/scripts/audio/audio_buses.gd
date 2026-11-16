class_name AudioBuses
extends RefCounted
## The two game buses, created in code: "Music" and "SFX" (the engine loops play on SFX).
## Both feed Master. `enabled` is a mute switch, volume is linear 0..1.

const MASTER := &"Master"
const MUSIC := &"Music"
const SFX := &"SFX"
const LIMITER_CEILING_DB := -1.0
const LIMITER_THRESHOLD_DB := -4.0
const MIN_LINEAR := 0.0001


## Creates the buses (and a safety limiter on each) if they do not exist yet. Safe to call often.
static func ensure() -> void:
	for bus_name: StringName in [MUSIC, SFX]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		var index := AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, MASTER)
		var limiter := AudioEffectLimiter.new()
		limiter.ceiling_db = LIMITER_CEILING_DB
		limiter.threshold_db = LIMITER_THRESHOLD_DB
		AudioServer.add_bus_effect(index, limiter)


static func set_music_enabled(enabled: bool) -> void:
	_set_enabled(MUSIC, enabled)


static func set_sfx_enabled(enabled: bool) -> void:
	_set_enabled(SFX, enabled)


static func is_music_enabled() -> bool:
	return _is_enabled(MUSIC)


static func is_sfx_enabled() -> bool:
	return _is_enabled(SFX)


static func set_music_volume(linear: float) -> void:
	_set_volume(MUSIC, linear)


static func set_sfx_volume(linear: float) -> void:
	_set_volume(SFX, linear)


static func music_volume() -> float:
	return _volume(MUSIC)


static func _set_enabled(bus_name: StringName, enabled: bool) -> void:
	ensure()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), not enabled)


static func _is_enabled(bus_name: StringName) -> bool:
	ensure()
	return not AudioServer.is_bus_mute(AudioServer.get_bus_index(bus_name))


static func _set_volume(bus_name: StringName, linear: float) -> void:
	ensure()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(maxf(linear, MIN_LINEAR)))


static func _volume(bus_name: StringName) -> float:
	ensure()
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name)))
