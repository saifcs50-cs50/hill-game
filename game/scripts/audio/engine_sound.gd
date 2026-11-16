class_name EngineSound
extends Node
## Engine noise for one vehicle: four looped layers crossfaded and pitch-scaled from an rpm value.
##
## Either call `update(rpm, throttle)` every frame, or `bind(vehicle)` and the node reads
## `vehicle.spin_ratio()` and `vehicle.gas` itself. The rpm it plays follows the target with lag:
## it revs up quickly and falls away slowly. Off-throttle it is quieter and duller.

const REV_UP_RATE := 7.0
const REV_DOWN_RATE := 2.4
const LOAD_UP_RATE := 10.0
const LOAD_DOWN_RATE := 4.5
const AIR_RATE := 5.0
const FADE_RATE := 3.0
## The engine revs up when the throttle is pressed even if the wheels have not caught up yet.
const THROTTLE_REV_FLOOR := 0.24
const IDLE_WOBBLE_HZ := 3.3
const IDLE_WOBBLE_DEPTH := 0.014
const MASTER_DB := -7.0
const OFF_THROTTLE_DB := -6.0
const AIRBORNE_DB := -3.0
const BRIGHT_OFF_THROTTLE_DB := -6.0
const SILENT_DB := -80.0
const MIN_GAIN := 0.0001

## Per-vehicle voice: below 1.0 is deeper (monster truck), above is higher (supercar).
var pitch_bias := 1.0
var airborne := false
## Fades the engine out (false) or back in (true). Stopped players are not mixed at all.
var active := true:
	set(value):
		active = value
		if value and is_inside_tree():
			_start_players()

var _rpm := 0.0
var _load := 0.0
var _air := 0.0
var _fade := 1.0
var _clock := 0.0
var _vehicle: Node
var _warned := false
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	AudioBuses.ensure()
	for stream in EngineBank.loops():
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.bus = AudioBuses.SFX
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)
	_apply()
	_start_players()


func _exit_tree() -> void:
	_stop_players()


## Follows `vehicle` every frame (needs `spin_ratio()` and `gas`; fades out on its `crashed` signal).
func bind(vehicle: Node) -> void:
	_vehicle = vehicle
	if vehicle.has_signal("crashed") and not vehicle.is_connected("crashed", _on_vehicle_crashed):
		vehicle.connect("crashed", _on_vehicle_crashed)


## Advances the engine by one frame. `rpm` is 0..1 (wheel spin or engine speed).
func update(rpm: float, throttle: bool, delta: float = -1.0) -> void:
	var dt := delta if delta >= 0.0 else get_process_delta_time()
	var target := clampf(rpm, 0.0, 1.0)
	if throttle:
		target = maxf(target, THROTTLE_REV_FLOOR)
	var rate := REV_UP_RATE if target > _rpm else REV_DOWN_RATE
	_rpm = lerpf(_rpm, target, 1.0 - exp(-rate * dt))
	var load_target := 1.0 if throttle else 0.0
	var load_rate := LOAD_UP_RATE if throttle else LOAD_DOWN_RATE
	_load = lerpf(_load, load_target, 1.0 - exp(-load_rate * dt))
	_air = lerpf(_air, 1.0 if airborne else 0.0, 1.0 - exp(-AIR_RATE * dt))
	_fade = move_toward(_fade, 1.0 if active else 0.0, FADE_RATE * dt)
	_clock += dt
	_apply()
	if _fade <= 0.0 and not active:
		_stop_players()


## The rpm currently being played, 0..1 (after the lag).
func current_rpm() -> float:
	return _rpm


func _process(delta: float) -> void:
	if _vehicle == null:
		return
	if not is_instance_valid(_vehicle):
		_vehicle = null
		active = false
		return
	airborne = int(_vehicle.get("grounded")) == 0
	update(_read_spin(), bool(_vehicle.get("gas")), delta)


func _read_spin() -> float:
	if _vehicle.has_method("spin_ratio"):
		return _vehicle.call("spin_ratio")
	if not _warned:
		_warned = true
		push_warning("EngineSound: %s has no spin_ratio(); engine will only idle and rev on throttle." % _vehicle.name)
	return 0.0


func _on_vehicle_crashed() -> void:
	active = false


func _apply() -> void:
	var weights := EngineBank.layer_weights(_rpm)
	var wobble := 1.0 + sin(_clock * TAU * IDLE_WOBBLE_HZ) * IDLE_WOBBLE_DEPTH * (1.0 - _rpm)
	var master_db := MASTER_DB + lerpf(OFF_THROTTLE_DB, 0.0, _load) + AIRBORNE_DB * _air
	for i in _players.size():
		var bright := i / float(_players.size() - 1)
		var layer_db := master_db + BRIGHT_OFF_THROTTLE_DB * bright * (1.0 - _load)
		var gain := weights[i] * _fade
		var player := _players[i]
		player.volume_db = SILENT_DB if gain < MIN_GAIN else layer_db + linear_to_db(gain)
		player.pitch_scale = EngineBank.layer_pitch(i, _rpm) * pitch_bias * wobble


func _start_players() -> void:
	for player in _players:
		if not player.playing:
			player.play()


func _stop_players() -> void:
	for player in _players:
		player.stop()
