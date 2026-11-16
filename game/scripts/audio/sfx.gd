class_name Sfx
extends RefCounted
## Sound effects: a cached bank of synthesised one-shots played through a small pool of players.
##
## All helpers are static: `Sfx.play_coin()`. Call `Sfx.warm_up()` once (main's _ready) so the bank
## is built and the pool is in the tree before the first sound is needed; a sound requested before
## that is dropped, never an error.

const POOL_SIZE := 10
const COIN_PITCH_JITTER := 0.04
const COIN_CHAIN_STEP := 0.045
const COIN_CHAIN_MAX := 8
const MIN_LANDING := 0.05
const HARD_LANDING_START := 0.35
const LANDING_DB := -20.0
const LANDING_PITCH_LIGHT := 1.2
const LANDING_PITCH_HEAVY := 0.88
const TRICK_PITCH_STEP := 0.06
const TRICK_LEVEL_MAX := 5
## Per-sound trim in dB; the bank itself is peak-normalised.
const LEVEL_DB := {
	&"coin": -5.0, &"fuel": -3.0, &"thud_soft": -2.0, &"thud_hard": 0.0, &"crash": 0.0,
	&"trick": -4.0, &"ui_click": -8.0, &"ui_purchase": -3.0, &"out_of_fuel": -2.0,
}

static var _pool: Pool


static func warm_up() -> void:
	AudioBuses.ensure()
	SfxBank.streams()
	_ensure_pool()


static func set_enabled(enabled: bool) -> void:
	AudioBuses.set_sfx_enabled(enabled)


static func is_enabled() -> bool:
	return AudioBuses.is_sfx_enabled()


## Plays a bank sound. `volume_db` is added to the sound's own trim.
static func play(id: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var pool := _ensure_pool()
	if not pool.is_inside_tree():
		return
	var stream: AudioStreamWAV = SfxBank.streams().get(id)
	if stream == null:
		push_error("Sfx: unknown sound '%s'" % id)
		return
	pool.play_stream(stream, volume_db + float(LEVEL_DB.get(id, 0.0)), pitch)


## `chain` is the number of coins collected in a row; the pitch climbs a little with it.
static func play_coin(chain: int = 0) -> void:
	var pitch := 1.0 + minf(chain, COIN_CHAIN_MAX) * COIN_CHAIN_STEP + randf_range(-COIN_PITCH_JITTER, COIN_PITCH_JITTER)
	play(&"coin", 0.0, pitch)


static func play_fuel() -> void:
	play(&"fuel")


## `strength` is 0 (a bump) to 1 (a huge drop). Light and heavy thuds are layered by strength.
static func play_landing(strength: float) -> void:
	var s := clampf(strength, 0.0, 1.0)
	if s < MIN_LANDING:
		return
	var level_db := LANDING_DB * (1.0 - sqrt(s))
	var pitch := lerpf(LANDING_PITCH_LIGHT, LANDING_PITCH_HEAVY, s)
	play(&"thud_soft", level_db, pitch)
	if s > HARD_LANDING_START:
		var heavy := smoothstep(HARD_LANDING_START, 1.0, s)
		play(&"thud_hard", linear_to_db(heavy), pitch)


static func play_crash() -> void:
	play(&"crash")


## `level` is the combo or trick size (0 and up); bigger tricks play a little higher.
static func play_trick(level: int = 0) -> void:
	play(&"trick", 0.0, 1.0 + clampi(level, 0, TRICK_LEVEL_MAX) * TRICK_PITCH_STEP)


static func play_ui_click() -> void:
	play(&"ui_click", 0.0, randf_range(0.97, 1.03))


static func play_ui_purchase() -> void:
	play(&"ui_purchase")


static func play_out_of_fuel() -> void:
	play(&"out_of_fuel")


## The pool of players; created once and parked under the root so it survives scene reloads.
static func _ensure_pool() -> Pool:
	if is_instance_valid(_pool):
		return _pool
	_pool = Pool.new()
	var root := (Engine.get_main_loop() as SceneTree).root
	root.add_child.call_deferred(_pool)
	return _pool


class Pool extends Node:
	var _players: Array[AudioStreamPlayer] = []
	var _next := 0

	func _ready() -> void:
		name = "SfxPool"
		for i in POOL_SIZE:
			var player := AudioStreamPlayer.new()
			player.bus = AudioBuses.SFX
			add_child(player)
			_players.append(player)

	func _exit_tree() -> void:
		for player in _players:
			player.stop()
		SfxBank.clear()

	## Uses a free player; when all are busy the longest-running one is cut off.
	func play_stream(stream: AudioStreamWAV, volume_db: float, pitch: float) -> void:
		var player := _free_player()
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = pitch
		player.play()

	func _free_player() -> AudioStreamPlayer:
		for i in _players.size():
			var candidate := _players[(_next + i) % _players.size()]
			if not candidate.playing:
				_next = (_next + i + 1) % _players.size()
				return candidate
		var stolen := _players[_next]
		_next = (_next + 1) % _players.size()
		return stolen
