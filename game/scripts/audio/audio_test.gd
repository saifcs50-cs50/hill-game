extends SceneTree
## Headless check for the audio system:
##   godot --headless --path game -s res://scripts/audio/audio_test.gd
## Generates every buffer, prints time / duration / peak / seam jump, saves WAVs to /tmp/audio-check,
## and checks the engine maths, buses, Sfx pool and Music node. Exits non-zero on any failure.

const OUT_DIR := "/tmp/audio-check"
const PEAK_LIMIT := 0.98
const MAX_SEAM_RATIO := 1.5
const SEAM_WINDOW := 64
const PREVIEW_PEAK := 0.9
const AUDIBLE_WEIGHT := 0.3
const FRAME_DT := 1.0 / 60.0
const SWEEP_PROFILE: Array = [
	# [seconds, rpm target 0..1, throttle]
	[1.2, 0.0, false], [3.5, 1.0, true], [1.2, 1.0, true], [3.0, 0.0, false], [1.0, 0.0, false],
	[1.5, 0.45, true], [1.0, 0.45, false],
]

var _failures: Array[String] = []
var _generation_ms := 0.0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_check(MusicGrooves.validate().is_empty(), "groove tables valid: %s" % [MusicGrooves.validate()])
	_test_engine_bank()
	_test_sfx_bank()
	_test_music_bank()
	print("\nTOTAL synthesis time (engine + sfx + all %d music stages, no file writes): %.0f ms\n" % [MusicGrooves.stage_ids().size(), _generation_ms])
	_test_engine_maths()
	_test_buses()
	await _test_sfx_pool()
	await _test_engine_node()
	await _test_engine_bind()
	await _test_music_node()
	print("\n%s (%d failures)" % ["PASS" if _failures.is_empty() else "FAIL", _failures.size()])
	for failure in _failures:
		print("  FAILED: ", failure)
	quit(0 if _failures.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


## Prints one buffer's stats, saves its WAV, and fails the run if it clips.
func _report(label: String, stream: AudioStreamWAV, build_ms: float, loop: bool) -> void:
	_generation_ms += build_ms
	var peak := AudioSynth.stream_peak(stream)
	var seam := _seam_ratio(stream) if loop else 0.0
	print("%-22s %6.2f s  peak %.3f  seam %s  built in %6.1f ms" % [label, stream.get_length(), peak, ("%.2fx" % seam) if loop else "  n/a", build_ms])
	_check(peak < PEAK_LIMIT, "%s peaks at %.3f (limit %.2f)" % [label, peak, PEAK_LIMIT])
	_check(peak > 0.05, "%s is silent (peak %.3f)" % [label, peak])
	if loop:
		_check(seam < MAX_SEAM_RATIO, "%s loop seam %.2fx a normal sample step" % [label, seam])
	var error := stream.save_to_wav("%s/%s.wav" % [OUT_DIR, label])
	_check(error == OK, "%s WAV save failed: %s" % [label, error_string(error)])


## Jump across the loop point relative to the largest step between neighbouring samples within a
## few milliseconds either side of it. At or below about 1 the seam is no rougher than the audio.
func _seam_ratio(stream: AudioStreamWAV) -> float:
	var data := stream.data
	var count := data.size() >> 1
	var local_max := 1.0
	for i in range(1, SEAM_WINDOW):
		local_max = maxf(local_max, absf(data.decode_s16(i * 2) - data.decode_s16((i - 1) * 2)))
		var j := count - i
		local_max = maxf(local_max, absf(data.decode_s16(j * 2) - data.decode_s16((j - 1) * 2)))
	var jump := absf(data.decode_s16(0) - data.decode_s16((count - 1) * 2))
	return jump / local_max


func _test_engine_bank() -> void:
	print("--- engine loops ---")
	var t_all := Time.get_ticks_usec()
	var names: Array[String] = ["idle", "low", "mid", "high"]
	for i in EngineBank.STOPS_RPM.size():
		var t0 := Time.get_ticks_usec()
		var stream := AudioSynth.to_stream(EngineBank.build_layer(i), true)
		_report("engine_%d_%s" % [i, names[i]], stream, (Time.get_ticks_usec() - t0) / 1000.0, true)
	print("engine total: %.1f ms" % ((Time.get_ticks_usec() - t_all) / 1000.0))


func _test_sfx_bank() -> void:
	print("--- sfx ---")
	var t_all := Time.get_ticks_usec()
	for id in SfxBank.IDS:
		var t0 := Time.get_ticks_usec()
		_report("sfx_%s" % id, SfxBank.build(id), (Time.get_ticks_usec() - t0) / 1000.0, false)
	print("sfx total: %.1f ms" % ((Time.get_ticks_usec() - t_all) / 1000.0))


func _test_music_bank() -> void:
	print("--- music (percussion only) ---")
	for id in MusicGrooves.stage_ids():
		var groove := MusicGrooves.get_groove(id)
		var t0 := Time.get_ticks_usec()
		var stream := MusicBank.build(id)
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		_report("music_%s" % id, stream, ms, true)
		_check(absf(stream.get_length() - MusicBank.loop_seconds(groove)) < 0.01, "music_%s length matches its tempo" % id)
	var hits := {"dum": Percussion.dum(), "tak": Percussion.tak(), "shaker": Percussion.shaker(), "clap": Percussion.clap(), "rim": Percussion.rim()}
	for hit: String in hits:
		var preview: PackedFloat32Array = hits[hit].duplicate()
		AudioSynth.normalize(preview, PREVIEW_PEAK)
		_report("hit_%s" % hit, AudioSynth.to_stream(preview), 0.0, false)


func _test_engine_maths() -> void:
	print("--- engine maths ---")
	var worst_pitch := 1.0
	for step in 101:
		var rpm := step / 100.0
		var weights := EngineBank.layer_weights(rpm)
		var power := 0.0
		for w in weights:
			power += w * w
		_check(absf(power - 1.0) < 0.001, "layer weights at rpm %.2f are not equal-power (%.4f)" % [rpm, power])
		for i in weights.size():
			if weights[i] > AUDIBLE_WEIGHT:
				var pitch := EngineBank.layer_pitch(i, rpm)
				worst_pitch = maxf(worst_pitch, maxf(pitch, 1.0 / pitch))
	print("widest pitch shift of any layer louder than -10 dB: x%.2f" % worst_pitch)
	_check(worst_pitch < 1.6, "a layer is pitched too far (x%.2f)" % worst_pitch)
	_check(EngineBank.layer_weights(0.0)[0] > 0.999, "idle must be the idle layer only")
	_check(EngineBank.layer_weights(1.0)[3] > 0.999, "redline must be the high layer only")


func _test_buses() -> void:
	print("--- buses ---")
	AudioBuses.ensure()
	AudioBuses.ensure()
	_check(AudioServer.get_bus_index("Music") != -1, "Music bus exists")
	_check(AudioServer.get_bus_index("SFX") != -1, "SFX bus exists")
	var count := AudioServer.bus_count
	AudioBuses.ensure()
	_check(AudioServer.bus_count == count, "ensure() is idempotent")
	AudioBuses.set_music_enabled(false)
	AudioBuses.set_sfx_enabled(false)
	_check(not AudioBuses.is_music_enabled() and not AudioBuses.is_sfx_enabled(), "buses mute")
	AudioBuses.set_music_enabled(true)
	AudioBuses.set_sfx_enabled(true)
	_check(AudioBuses.is_music_enabled() and AudioBuses.is_sfx_enabled(), "buses unmute")
	print("buses: %d total, Music + SFX present, mute toggles work" % AudioServer.bus_count)


func _test_sfx_pool() -> void:
	print("--- sfx pool ---")
	Sfx.warm_up()
	await process_frame
	await process_frame
	for i in 30:
		Sfx.play_coin(i)
	Sfx.play_landing(0.9)
	Sfx.play_landing(0.02)
	Sfx.play_crash()
	Sfx.play_trick(3)
	Sfx.play_ui_click()
	Sfx.play_ui_purchase()
	Sfx.play_fuel()
	Sfx.play_out_of_fuel()
	await process_frame
	var pool := root.get_node_or_null("SfxPool")
	_check(pool != null, "SfxPool is under the root")
	var busy := 0
	for child in pool.get_children():
		if (child as AudioStreamPlayer).playing:
			busy += 1
	print("pool players busy after a 40-sound burst: %d / %d" % [busy, Sfx.POOL_SIZE])
	_check(busy == Sfx.POOL_SIZE, "burst should fill the pool without errors")
	Sfx.set_enabled(false)
	_check(not Sfx.is_enabled(), "Sfx.set_enabled(false) mutes")
	Sfx.set_enabled(true)


func _test_engine_node() -> void:
	print("--- EngineSound node ---")
	var engine := EngineSound.new()
	root.add_child(engine)
	await process_frame
	var players: Array[AudioStreamPlayer] = []
	for child in engine.get_children():
		players.append(child as AudioStreamPlayer)
	_check(players.size() == 4, "four engine layers")
	var playing := 0
	for p in players:
		playing += int(p.playing)
	_check(playing == 4, "all layers play once the node is ready")
	var step_loops := _loops_samples()
	var sweep := PackedFloat32Array()
	var read_pos: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var frames_per_step := roundi(FRAME_DT * AudioSynth.SAMPLE_RATE)
	var rpm_target := 0.0
	var idle_rpm_after := 0.0
	for segment: Array in SWEEP_PROFILE:
		var frames := roundi(float(segment[0]) / FRAME_DT)
		for _f in frames:
			# A wheel that accelerates smoothly towards the target (stand-in for spin_ratio()).
			rpm_target = move_toward(rpm_target, float(segment[1]), FRAME_DT * (0.35 if bool(segment[2]) else 0.3))
			engine.update(rpm_target, bool(segment[2]), FRAME_DT)
			_render_frame(players, step_loops, read_pos, sweep, frames_per_step)
		if float(segment[1]) == 0.0 and not bool(segment[2]):
			idle_rpm_after = engine.current_rpm()
	print("engine rpm after the idle tail: %.3f (target 0, lag makes it settle)" % idle_rpm_after)
	_check(idle_rpm_after < 0.2, "engine settles back to idle")
	AudioSynth.normalize(sweep, 0.9)
	var stream := AudioSynth.to_stream(sweep)
	_report("engine_sweep", stream, 0.0, false)
	_test_engine_lag()
	engine.active = false
	for f in 120:
		engine.update(0.0, false, FRAME_DT)
	var stopped := 0
	for p in players:
		stopped += int(not p.playing)
	_check(stopped == 4, "inactive engine stops its players after the fade (%d stopped)" % stopped)
	engine.active = true
	await process_frame
	var resumed := 0
	for p in players:
		resumed += int(p.playing)
	_check(resumed == 4, "engine resumes when set active again")
	engine.queue_free()


## A stand-in for Vehicle: just what EngineSound reads (`gas`, `grounded`, `spin_ratio()`, `crashed`).
class FakeVehicle extends Node:
	signal crashed
	var gas := false
	var grounded := 2
	var spin := 0.0

	func spin_ratio() -> float:
		return spin


func _test_engine_bind() -> void:
	print("--- EngineSound.bind() ---")
	var vehicle := FakeVehicle.new()
	root.add_child(vehicle)
	var engine := EngineSound.new()
	vehicle.add_child(engine)
	engine.bind(vehicle)
	await process_frame
	vehicle.gas = true
	vehicle.spin = 0.8
	for i in 30:
		await process_frame
	print("bound engine rpm after 30 frames at spin 0.8: %.2f" % engine.current_rpm())
	_check(engine.current_rpm() > 0.2, "bound engine follows vehicle.spin_ratio()")
	vehicle.grounded = 0
	for i in 20:
		await process_frame
	_check(engine.airborne, "bound engine notices the vehicle is airborne")
	vehicle.crashed.emit()
	await create_timer(0.6).timeout
	var silent := true
	for child in engine.get_children():
		silent = silent and not (child as AudioStreamPlayer).playing
	_check(silent, "engine stops after the vehicle crashes")
	vehicle.queue_free()
	await process_frame
	_check(is_instance_valid(engine) == false or not engine.active, "engine does not outlive its vehicle in a broken state")


## Revving up must be quicker than revving down, and off-throttle must be quieter than on.
func _test_engine_lag() -> void:
	var on := EngineSound.new()
	root.add_child(on)
	var frames_up := _frames_until(on, 0.0, 1.0, true, 0.63)
	var frames_down := _frames_until(on, 1.0, 0.0, false, 0.37)
	print("rev lag (same 63%% swing): up takes %d frames, down takes %d frames" % [frames_up, frames_down])
	_check(frames_up > 5 and frames_down > frames_up, "rev up is smooth and faster than rev down")
	var throttle_db := _loudest_db(on, true)
	var coast_db := _loudest_db(on, false)
	print("loudest layer on throttle %.1f dB, off throttle %.1f dB" % [throttle_db, coast_db])
	_check(coast_db < throttle_db - 3.0, "engine is quieter off-throttle")
	on.queue_free()


## Settles the engine at `start`, then counts frames until it crosses `threshold` heading for `goal`.
func _frames_until(engine: EngineSound, start: float, goal: float, throttle: bool, threshold: float) -> int:
	for f in 600:
		engine.update(start, start > 0.0, FRAME_DT)
	var frames := 0
	while frames < 600 and (engine.current_rpm() < threshold if goal > start else engine.current_rpm() > threshold):
		engine.update(goal, throttle, FRAME_DT)
		frames += 1
	return frames


func _loudest_db(engine: EngineSound, throttle: bool) -> float:
	for f in 120:
		engine.update(0.6, throttle, FRAME_DT)
	var loudest := -200.0
	for child in engine.get_children():
		loudest = maxf(loudest, (child as AudioStreamPlayer).volume_db)
	return loudest


func _loops_samples() -> Array[PackedByteArray]:
	var out: Array[PackedByteArray] = []
	for stream in EngineBank.loops():
		out.append(stream.data)
	return out


## Mixes one 1/60 s frame the way the audio server would: each looped layer is read at its pitch.
func _render_frame(players: Array[AudioStreamPlayer], loops: Array[PackedByteArray], read_pos: Array[float], sweep: PackedFloat32Array, frames: int) -> void:
	var base := sweep.size()
	sweep.resize(base + frames)
	for layer in players.size():
		var gain := db_to_linear(players[layer].volume_db) if players[layer].volume_db > -79.0 else 0.0
		if gain <= 0.0:
			continue
		var data := loops[layer]
		var length := data.size() >> 1
		var step := players[layer].pitch_scale
		var pos := read_pos[layer]
		for i in frames:
			var index := int(pos)
			var frac := pos - index
			var a := data.decode_s16((index % length) * 2) / AudioSynth.PCM_MAX
			var b := data.decode_s16(((index + 1) % length) * 2) / AudioSynth.PCM_MAX
			sweep[base + i] += (a + (b - a) * frac) * gain
			pos += step
		read_pos[layer] = fmod(pos, length)


func _test_music_node() -> void:
	print("--- Music node ---")
	var music := Music.shared()
	music.play("desert")
	var waited := 0
	while not music.is_ready("desert") and waited < 600:
		await process_frame
		waited += 1
	_check(music.is_ready("desert"), "desert loop rendered in the background")
	await create_timer(0.2).timeout
	var players: Array[AudioStreamPlayer] = []
	for child in music.get_children():
		if child is AudioStreamPlayer:
			players.append(child)
	_check(players.size() == 2, "two crossfade players")
	_check(players[1].playing or players[0].playing, "music is playing after play('desert')")
	_check(players[0].bus == &"Music" and players[1].bus == &"Music", "music players use the Music bus")
	print("desert playing after %d frames of background render" % waited)
	music.play("desert")
	var playing_before := players[0].playing != players[1].playing
	_check(playing_before, "asking for the same stage again does not start a second player")
	music.play("arctic")
	waited = 0
	while not music.is_ready("arctic") and waited < 600:
		await process_frame
		waited += 1
	await create_timer(0.3).timeout
	_check(players[0].playing and players[1].playing, "both players overlap while crossfading")
	await create_timer(1.2).timeout
	_check(players[0].playing != players[1].playing, "old player stops after the fade-out")
	music.enabled = false
	_check(not players[0].playing and not players[1].playing, "disabling music stops playback")
	_check(not AudioBuses.is_music_enabled(), "disabling music mutes the Music bus")
	music.enabled = true
	await create_timer(0.1).timeout
	_check(players[0].playing or players[1].playing, "enabling music resumes the wanted stage")
	music.volume = 0.5
	_check(absf(AudioBuses.music_volume() - 0.5) < 0.01, "volume sets the bus level")
	music.volume = 1.0
	music.stop(0.1)
	await create_timer(0.3).timeout
	_check(not players[0].playing and not players[1].playing, "stop() fades out and stops")
