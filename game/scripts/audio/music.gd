class_name Music
extends Node
## Percussion-only background music: one looping groove per stage, crossfaded when the stage changes.
##
## `Music.shared()` gives one instance parked under the scene root, so music carries on across
## scene reloads (a restart that asks for the same stage is a no-op). A stage's loop is rendered on
## a worker thread the first time it is wanted, so `play()` never blocks a frame; the music starts
## a moment later, when the loop is ready. Call `prewarm()` early to hide even that.

const FADE_IN_SECONDS := 1.4
const FADE_OUT_SECONDS := 0.9
const PLAY_DB := -8.0
const SILENT_DB := -50.0

## Linear 0..1, applied on the Music bus.
var volume := 1.0:
	set(value):
		volume = clampf(value, 0.0, 1.0)
		AudioBuses.set_music_volume(volume)

## Master switch for music. Turning it off stops playback; turning it on resumes the wanted stage.
var enabled := true:
	set(value):
		enabled = value
		AudioBuses.set_music_enabled(value)
		if is_inside_tree():
			_refresh()

var stage_id := ""

static var _shared: Music

var _streams: Dictionary = {}
var _tasks: Dictionary = {}
var _built: Dictionary = {}
var _mutex := Mutex.new()
var _players: Array[AudioStreamPlayer] = []
var _tweens: Array[Tween] = [null, null]
var _front := 0
var _playing_stage := ""


## The shared instance, created on first use under the scene root.
static func shared() -> Music:
	if is_instance_valid(_shared):
		return _shared
	_shared = Music.new()
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_shared)
	return _shared


func _ready() -> void:
	name = "Music"
	AudioBuses.ensure()
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = AudioBuses.MUSIC
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)
	AudioBuses.set_music_enabled(enabled)
	AudioBuses.set_music_volume(volume)
	_refresh()


func _exit_tree() -> void:
	for player in _players:
		player.stop()
	_streams.clear()


## Starts (or crossfades to) the groove for `new_stage`. Asking for the stage already playing does nothing.
func play(new_stage: String) -> void:
	stage_id = new_stage
	prewarm(new_stage)
	if is_inside_tree():
		_refresh()


## Fades the music out and forgets the wanted stage.
func stop(fade: float = FADE_OUT_SECONDS) -> void:
	stage_id = ""
	_playing_stage = ""
	if not _players.is_empty():
		_fade_out(_front, fade)


## Starts rendering a stage's loop in the background so a later `play()` is instant.
func prewarm(wanted: String) -> void:
	if _streams.has(wanted) or _tasks.has(wanted):
		return
	_tasks[wanted] = WorkerThreadPool.add_task(_render_in_thread.bind(wanted), false, "music_" + wanted)
	set_process(true)


func is_ready(wanted: String) -> bool:
	return _streams.has(wanted)


func _process(_delta: float) -> void:
	for wanted: String in _tasks.keys():
		if not WorkerThreadPool.is_task_completed(_tasks[wanted]):
			continue
		WorkerThreadPool.wait_for_task_completion(_tasks[wanted])
		_tasks.erase(wanted)
		_mutex.lock()
		_streams[wanted] = _built[wanted]
		_mutex.unlock()
		if wanted == stage_id:
			_refresh()
	set_process(not _tasks.is_empty())


func _render_in_thread(wanted: String) -> void:
	var stream := MusicBank.build(wanted)
	_mutex.lock()
	_built[wanted] = stream
	_mutex.unlock()


## Makes the players match what is wanted: right stage, enabled, loop ready.
func _refresh() -> void:
	if not enabled:
		_stop_all()
		return
	if stage_id.is_empty():
		return
	if stage_id == _playing_stage or not _streams.has(stage_id):
		return
	_fade_out(_front, FADE_OUT_SECONDS)
	_front = 1 - _front
	var player := _players[_front]
	player.stream = _streams[stage_id]
	player.volume_db = SILENT_DB
	player.play()
	_fade_to(_front, PLAY_DB, FADE_IN_SECONDS)
	_playing_stage = stage_id


func _stop_all() -> void:
	_playing_stage = ""
	for index in _players.size():
		_fade_out(index, 0.0)


func _fade_to(index: int, target_db: float, seconds: float) -> void:
	_kill_tween(index)
	var player := _players[index]
	var tween := create_tween()
	tween.tween_property(player, "volume_db", target_db, seconds)
	_tweens[index] = tween


func _fade_out(index: int, seconds: float) -> void:
	var player := _players[index]
	if not player.playing:
		return
	if seconds <= 0.0:
		_kill_tween(index)
		player.stop()
		return
	_fade_to(index, SILENT_DB, seconds)
	_tweens[index].tween_callback(player.stop)


func _kill_tween(index: int) -> void:
	var tween := _tweens[index]
	if tween != null and tween.is_valid():
		tween.kill()
