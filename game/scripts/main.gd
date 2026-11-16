extends Node2D
## Demo run: drive as far as possible before the dummy's head hits or fuel runs out.
##
## Test modes (debug only): `--autodrive` or a `user://autodrive` file lets a bot drive;
## `--bench` or a `user://bench` file adds three bot vehicles and never ends the run.

const FUEL_SECONDS := 45.0
const PX_PER_M := 100.0
const START_X := 500.0
const RESULTS_DELAY := 0.9
const SLOW_MOTION := 0.35
const BENCH_BOTS := 3
const PERF_WINDOW := 5.0
const STUCK_SPEED := 40.0
const STUCK_SECONDS := 3.0
const LAG_BEHIND := 1800.0
const SHAKE_DECAY := 40.0
const CRASH_SHAKE := 16.0

var _terrain: Terrain
var _car: Vehicle
var _bots: Array[Vehicle] = []
var _stuck := {}
var _cam: Camera2D
var _hud: Hud
var _stunts: Stunts
var _shake := 0.0
var _fuel := 1.0
var _coins := 0
var _best := 0.0
var _running := true
var _stopped_for := 0.0
var _touches := {}
var _autodrive := false
var _bench := false
var _ticks := 0
var _perf_frames := 0
var _perf_time := 0.0
var _perf_worst := 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_bench = args.has("--bench") or FileAccess.file_exists("user://bench")
	_autodrive = _bench or args.has("--autodrive") or FileAccess.file_exists("user://autodrive")
	_best = GameState.best_for(GameState.selected_stage, GameState.selected_vehicle)
	var stage_id: String = GameState.selected_stage
	_apply_stage_gravity(stage_id)
	var backdrop := Backdrop.new()
	backdrop.configure(stage_id)
	add_child(backdrop)
	_terrain = Terrain.new()
	_terrain.configure(stage_id)
	_terrain.chunk_created.connect(_on_chunk_created)
	add_child(_terrain)
	_terrain.update(START_X)
	_car = _spawn_vehicle(START_X, _autodrive)
	if _bench:
		for i in BENCH_BOTS:
			_bots.append(_spawn_vehicle(START_X - 230.0 * (i + 1), true))
	_cam = Camera2D.new()
	_cam.position = _car.position + Vector2(240.0, -60.0)
	_cam.zoom = Vector2(1.25, 1.25)
	add_child(_cam)
	_cam.make_current()
	_cam.reset_physics_interpolation()
	_hud = Hud.new()
	add_child(_hud)
	_stunts = Stunts.new()
	_stunts.trick_landed.connect(_on_trick_landed)
	add_child(_stunts)
	_stunts.watch(_car)


## Gravity lives in the physics space, which survives scene reloads, so it is set at every run start.
func _apply_stage_gravity(stage_id: String) -> void:
	var gravity: float = Catalog.STAGES[stage_id]["gravity"]
	var space := get_viewport().find_world_2d().space
	PhysicsServer2D.area_set_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY, gravity)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = _is_gas_side(event.position)
		else:
			_touches.erase(event.index)
	elif event is InputEventScreenDrag:
		_touches[event.index] = _is_gas_side(event.position)


func _physics_process(delta: float) -> void:
	var body := _car.chassis
	var gas := _touches.values().has(true) or Input.is_physical_key_pressed(KEY_RIGHT)
	var brake := _touches.values().has(false) or Input.is_physical_key_pressed(KEY_LEFT)
	if not _autodrive:
		_car.gas = gas and _running and _fuel > 0.0
		_car.brake = brake and _running
	_hud.set_pedals(_car.gas, _car.brake)
	if _running and not _bench:
		_tick_run(delta, body)
	if _bench:
		_tick_bench(delta)
	_terrain.update(body.global_position.x)
	_follow(delta, body)
	_ticks += 1
	if _autodrive and not _bench and _ticks % 120 == 0:
		print("t=%ds x=%.0f y=%.0f v=%.0f rot=%.2f grounded=%d" % [_ticks / 120, body.global_position.x, body.global_position.y, body.linear_velocity.length(), body.rotation, _car.grounded])


func _process(delta: float) -> void:
	_hud.set_stats(_distance(), maxf(_best, _distance()), _coins, _fuel)
	if OS.is_debug_build():
		_log_perf(delta)


func _log_perf(delta: float) -> void:
	_perf_frames += 1
	_perf_time += delta
	_perf_worst = maxf(_perf_worst, delta)
	if _perf_time < PERF_WINDOW:
		return
	print("PERF fps=%.1f worst_ms=%.1f physics_ms=%.2f process_ms=%.2f vehicles=%d x=%.0f" % [
		_perf_frames / _perf_time, _perf_worst * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		1 + _bots.size(), _car.chassis.global_position.x])
	_perf_frames = 0
	_perf_time = 0.0
	_perf_worst = 0.0


func _spawn_vehicle(x: float, bot: bool) -> Vehicle:
	var vehicle := Vehicle.new()
	vehicle.is_bot = bot
	vehicle.position = Vector2(x, _terrain.height_at(x) - 80.0)
	vehicle.crashed.connect(_on_crashed.bind(vehicle))
	add_child(vehicle)
	return vehicle


func _tick_run(delta: float, body: RigidBody2D) -> void:
	_fuel = maxf(_fuel - delta / FUEL_SECONDS, 0.0)
	if _fuel <= 0.0:
		_stopped_for = _stopped_for + delta if body.linear_velocity.length() < 30.0 else 0.0
		if _stopped_for > 1.2:
			_end_run("OUT OF FUEL")
	if body.global_position.y > _terrain.height_at(body.global_position.x) + 500.0:
		_end_run("CRASHED!")


## Keeps every benchmark vehicle moving: one that is stuck or far behind is put back.
func _tick_bench(delta: float) -> void:
	var lead_x := _car.chassis.global_position.x
	for i in _bots.size():
		var bot := _bots[i]
		var body := bot.chassis
		var slow := body.linear_velocity.length() < STUCK_SPEED
		_stuck[bot] = _stuck.get(bot, 0.0) + delta if slow else 0.0
		if _stuck[bot] > STUCK_SECONDS or body.global_position.x < lead_x - LAG_BEHIND:
			_stuck.erase(bot)
			bot.queue_free()
			_bots[i] = _spawn_vehicle(lead_x - 260.0 * (i + 1), true)
	var slow_lead := _car.chassis.linear_velocity.length() < STUCK_SPEED
	_stuck[_car] = _stuck.get(_car, 0.0) + delta if slow_lead else 0.0
	if _stuck[_car] > STUCK_SECONDS:
		_respawn_lead()


func _respawn_lead() -> void:
	_stuck.erase(_car)
	var x := _car.chassis.global_position.x + 200.0
	_car.queue_free()
	_car = _spawn_vehicle(x, true)
	_stunts.watch(_car)


func _follow(delta: float, body: RigidBody2D) -> void:
	var v := body.linear_velocity
	var target := body.global_position + Vector2(240.0 + v.x * 0.28, -60.0 + clampf(v.y * 0.1, -80.0, 120.0))
	_cam.global_position = _cam.global_position.lerp(target, 1.0 - exp(-5.0 * delta))
	_shake = move_toward(_shake, 0.0, SHAKE_DECAY * delta)
	_cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	var zoom := lerpf(1.25, 0.9, clampf(v.length() / 1500.0, 0.0, 1.0))
	_cam.zoom = _cam.zoom.lerp(Vector2(zoom, zoom), 1.0 - exp(-2.0 * delta))


func _distance() -> float:
	return maxf((_car.chassis.global_position.x - START_X) / PX_PER_M, 0.0)


func _is_gas_side(point: Vector2) -> bool:
	return point.x >= get_viewport_rect().size.x * 0.5


func _on_chunk_created(chunk: Node2D, index: int) -> void:
	var x0 := index * Terrain.CHUNK_WIDTH
	for group in 1:
		var group_x := x0 + 1100.0
		if group_x < START_X + 700.0:
			continue
		for k in 5:
			var x := group_x + k * 72.0
			var lift := 72.0 + sin(PI * k / 4.0) * 48.0
			_spawn_pickup(chunk, Pickup.COIN, Vector2(x, _terrain.height_at(x) - lift))
	if index > 0 and index % 6 == 4:
		var fuel_x := x0 + 1500.0
		_spawn_pickup(chunk, Pickup.FUEL, Vector2(fuel_x, _terrain.height_at(fuel_x) - 66.0))


func _spawn_pickup(chunk: Node2D, kind: int, at: Vector2) -> void:
	var pickup := Pickup.new()
	pickup.kind = kind
	pickup.position = at
	pickup.collected.connect(_on_collected)
	chunk.add_child(pickup)


func _on_collected(kind: int) -> void:
	if kind == Pickup.COIN:
		_coins += Catalog.COIN_VALUE
	else:
		_fuel = 1.0
		_stopped_for = 0.0


func _on_trick_landed(label: String, coins: int, combo: int) -> void:
	if not _running:
		return
	_coins += coins
	_hud.show_trick(label, coins, combo)
	_shake = maxf(_shake, 3.0 + combo)
	if _autodrive:
		print("TRICK %s +%d x%d" % [label, coins, combo])


func _on_crashed(vehicle: Vehicle) -> void:
	if _bench:
		if vehicle == _car:
			_respawn_lead.call_deferred()
		return
	if not _running or vehicle != _car:
		return
	if _autodrive:
		print("HEAD HIT at x=%.0f" % _car.chassis.global_position.x)
	Engine.time_scale = SLOW_MOTION
	_shake = CRASH_SHAKE
	_stunts.break_combo()
	_end_run("CRASHED!")


func _end_run(title: String) -> void:
	if not _running:
		return
	_running = false
	var distance := _distance()
	var is_best := GameState.record_run(GameState.selected_stage, GameState.selected_vehicle, distance, _coins)
	GameState.add_coins(_coins)
	await get_tree().create_timer(RESULTS_DELAY, true, false, true).timeout
	Engine.time_scale = 1.0
	var panel := ResultsPanel.new()
	add_child(panel)
	panel.show_results(title, distance, _coins, is_best)
