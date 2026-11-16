extends Node
## Autoload "GameState": everything the player keeps between runs, saved to user://save.cfg.
##
## Coins, owned vehicles and stages, upgrade levels, the selected vehicle and stage, best
## distances and the settings. Every change saves immediately. Reads never throw: a missing file
## starts a fresh game and a damaged one is copied aside (save.corrupt.cfg) and then ignored.
##
## Save layout (ConfigFile): [meta] [owned] [upgrades.<vehicle>] [best.<stage>] [stats] [settings].
## An old file that only has [run] best=... is migrated to the Meadow / Hatchback best.

signal coins_changed(coins: int)
signal progress_changed
signal settings_changed

const SAVE_PATH := "user://save.cfg"
const SAVE_VERSION := 1
const START_VEHICLE := "hatchback"
const START_STAGE := "meadow"
const LEGACY_SECTION := "run"
const LEGACY_KEY := "best"

## Menu screen to open the next time the menu loads ("main", "garage", "stages", "settings").
var pending_screen := ""
## Where the save lives. Tests point this somewhere else before calling load_game().
var save_path := SAVE_PATH

var coins: int:
	get:
		return _coins
var selected_vehicle: String:
	get:
		return _selected_vehicle
var selected_stage: String:
	get:
		return _selected_stage
var music_on: bool:
	get:
		return _music_on
var sfx_on: bool:
	get:
		return _sfx_on
var runs_played: int:
	get:
		return _runs
var total_distance_m: float:
	get:
		return _total_distance
var total_coins_earned: int:
	get:
		return _total_coins

var _coins := 0
var _selected_vehicle := START_VEHICLE
var _selected_stage := START_STAGE
var _owned_vehicles := {}
var _owned_stages := {}
var _upgrades := {}
var _best := {}
var _runs := 0
var _total_distance := 0.0
var _total_coins := 0
var _music_on := true
var _sfx_on := true


func _ready() -> void:
	load_game()


# --- Coins ---------------------------------------------------------------------------------

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	_coins += amount
	coins_changed.emit(_coins)
	save_game()


func can_afford(price: int) -> bool:
	return price <= _coins


# --- Vehicles and stages -------------------------------------------------------------------

func owns_vehicle(vehicle_id: String) -> bool:
	return _owned_vehicles.has(vehicle_id)


func owns_stage(stage_id: String) -> bool:
	return _owned_stages.has(stage_id)


## Returns true if the vehicle was bought. False if unknown, already owned or too expensive.
func buy_vehicle(vehicle_id: String) -> bool:
	if not Catalog.VEHICLES.has(vehicle_id) or owns_vehicle(vehicle_id):
		return false
	var price: int = Catalog.VEHICLES[vehicle_id]["price"]
	if not can_afford(price):
		return false
	_coins -= price
	_owned_vehicles[vehicle_id] = true
	_commit()
	return true


func buy_stage(stage_id: String) -> bool:
	if not Catalog.STAGES.has(stage_id) or owns_stage(stage_id):
		return false
	var price: int = Catalog.STAGES[stage_id]["price"]
	if not can_afford(price):
		return false
	_coins -= price
	_owned_stages[stage_id] = true
	_commit()
	return true


func select_vehicle(vehicle_id: String) -> bool:
	if not owns_vehicle(vehicle_id):
		return false
	_selected_vehicle = vehicle_id
	_commit(false)
	return true


func select_stage(stage_id: String) -> bool:
	if not owns_stage(stage_id):
		return false
	_selected_stage = stage_id
	_commit(false)
	return true


# --- Upgrades ------------------------------------------------------------------------------

func upgrade_level(vehicle_id: String, key: String) -> int:
	var levels: Dictionary = _upgrades.get(vehicle_id, {})
	return int(levels.get(key, 0))


## A copy with every upgrade key: {"engine": 0, "suspension": 0, "tyres": 0, "fuel": 0}.
func upgrades_for(vehicle_id: String) -> Dictionary:
	var levels := {}
	for key: String in Catalog.UPGRADE_KEYS:
		levels[key] = upgrade_level(vehicle_id, key)
	return levels


## Coins for the next level of this upgrade, or -1 when it is already at the maximum.
func next_upgrade_cost(vehicle_id: String, key: String) -> int:
	var level := upgrade_level(vehicle_id, key)
	if level >= Catalog.MAX_UPGRADE_LEVEL:
		return -1
	return Catalog.upgrade_cost(vehicle_id, level)


## Buys one level. Needs an owned vehicle, a known key, a level below the cap and enough coins.
func upgrade(vehicle_id: String, key: String) -> bool:
	if not owns_vehicle(vehicle_id) or not Catalog.UPGRADE_KEYS.has(key):
		return false
	var cost := next_upgrade_cost(vehicle_id, key)
	if cost < 0 or not can_afford(cost):
		return false
	_coins -= cost
	var levels: Dictionary = _upgrades.get(vehicle_id, {})
	levels[key] = upgrade_level(vehicle_id, key) + 1
	_upgrades[vehicle_id] = levels
	_commit()
	return true


# --- Runs ----------------------------------------------------------------------------------

## Best distance in metres for this stage and vehicle (0 if never driven).
func best_for(stage_id: String, vehicle_id: String) -> float:
	var per_vehicle: Dictionary = _best.get(stage_id, {})
	return float(per_vehicle.get(vehicle_id, 0.0))


## Stores a finished run. Returns true when distance_m beats the stored best.
## It updates the best distance and the lifetime stats only; it never changes the coin
## balance. The caller adds the coins with add_coins().
func record_run(stage_id: String, vehicle_id: String, distance_m: float, coins_earned: int) -> bool:
	if not Catalog.STAGES.has(stage_id) or not Catalog.VEHICLES.has(vehicle_id):
		push_error("record_run: unknown stage '%s' or vehicle '%s'" % [stage_id, vehicle_id])
		return false
	var distance := maxf(distance_m, 0.0)
	var is_new_best := distance > best_for(stage_id, vehicle_id)
	if is_new_best:
		var per_vehicle: Dictionary = _best.get(stage_id, {})
		per_vehicle[vehicle_id] = distance
		_best[stage_id] = per_vehicle
	_runs += 1
	_total_distance += distance
	_total_coins += maxi(coins_earned, 0)
	_commit(false)
	return is_new_best


## Wipes coins, vehicles, stages, upgrades, bests and stats. Settings are kept.
func reset_progress() -> void:
	_reset_progress_state()
	_commit()


# --- Settings ------------------------------------------------------------------------------

func set_music(enabled: bool) -> void:
	if enabled == _music_on:
		return
	_music_on = enabled
	settings_changed.emit()
	save_game()


func set_sfx(enabled: bool) -> void:
	if enabled == _sfx_on:
		return
	_sfx_on = enabled
	settings_changed.emit()
	save_game()


## Returns the screen the menu should open on, once. Empty means the main screen.
func take_pending_screen() -> String:
	var screen := pending_screen
	pending_screen = ""
	return screen if not screen.is_empty() else "main"


# --- Save and load -------------------------------------------------------------------------

## Writes the save file (to a temporary file first, then renamed over the real one).
func save_game() -> bool:
	var file := ConfigFile.new()
	_write_meta(file)
	_write_owned(file)
	_write_upgrades(file)
	_write_best(file)
	file.set_value("stats", "runs", _runs)
	file.set_value("stats", "total_distance", _total_distance)
	file.set_value("stats", "total_coins", _total_coins)
	file.set_value("settings", "music", _music_on)
	file.set_value("settings", "sfx", _sfx_on)
	var temp_path := save_path + ".tmp"
	var error := file.save(temp_path)
	if error == OK:
		error = DirAccess.rename_absolute(temp_path, save_path)
	if error != OK:
		push_error("Could not save progress: %s" % error_string(error))
		return false
	return true


## Reads the save file. Missing or damaged files give a fresh game; bad values are repaired.
func load_game() -> void:
	_reset_progress_state()
	_music_on = true
	_sfx_on = true
	if not FileAccess.file_exists(save_path):
		_announce()
		return
	var file := ConfigFile.new()
	var error := file.load(save_path)
	if error != OK:
		_set_corrupt_file_aside(error)
		_announce()
		return
	if file.has_section("meta"):
		_read_progress(file)
	else:
		_migrate_legacy(file)
	_announce()


func _commit(coins_changed_too: bool = true) -> void:
	if coins_changed_too:
		coins_changed.emit(_coins)
	progress_changed.emit()
	save_game()


func _announce() -> void:
	coins_changed.emit(_coins)
	progress_changed.emit()
	settings_changed.emit()


func _reset_progress_state() -> void:
	_coins = 0
	_selected_vehicle = START_VEHICLE
	_selected_stage = START_STAGE
	_owned_vehicles = {START_VEHICLE: true}
	_owned_stages = {START_STAGE: true}
	_upgrades = {}
	_best = {}
	_runs = 0
	_total_distance = 0.0
	_total_coins = 0


func _set_corrupt_file_aside(error: int) -> void:
	var backup := save_path.get_basename() + ".corrupt.cfg"
	DirAccess.copy_absolute(save_path, backup)
	push_warning("Save file unreadable (%s). Starting fresh; the old file is kept at %s." % [error_string(error), backup])


func _migrate_legacy(file: ConfigFile) -> void:
	var legacy := _to_float(file.get_value(LEGACY_SECTION, LEGACY_KEY, 0.0))
	if legacy > 0.0:
		_best[START_STAGE] = {START_VEHICLE: legacy}


# --- Reading -------------------------------------------------------------------------------

func _read_progress(file: ConfigFile) -> void:
	_coins = maxi(_to_int(file.get_value("meta", "coins", 0)), 0)
	for id in _valid_ids(file.get_value("owned", "vehicles", []), Catalog.VEHICLES):
		_owned_vehicles[id] = true
	for id in _valid_ids(file.get_value("owned", "stages", []), Catalog.STAGES):
		_owned_stages[id] = true
	var vehicle := str(file.get_value("meta", "vehicle", START_VEHICLE))
	_selected_vehicle = vehicle if owns_vehicle(vehicle) else START_VEHICLE
	var stage := str(file.get_value("meta", "stage", START_STAGE))
	_selected_stage = stage if owns_stage(stage) else START_STAGE
	_read_upgrades(file)
	_read_best(file)
	_runs = maxi(_to_int(file.get_value("stats", "runs", 0)), 0)
	_total_distance = maxf(_to_float(file.get_value("stats", "total_distance", 0.0)), 0.0)
	_total_coins = maxi(_to_int(file.get_value("stats", "total_coins", 0)), 0)
	_music_on = bool(file.get_value("settings", "music", true))
	_sfx_on = bool(file.get_value("settings", "sfx", true))


func _read_upgrades(file: ConfigFile) -> void:
	for vehicle_id: String in Catalog.VEHICLES:
		var section := "upgrades." + vehicle_id
		var levels := {}
		for key: String in Catalog.UPGRADE_KEYS:
			var level := _to_int(file.get_value(section, key, 0))
			levels[key] = clampi(level, 0, Catalog.MAX_UPGRADE_LEVEL)
		_upgrades[vehicle_id] = levels


func _read_best(file: ConfigFile) -> void:
	for stage_id: String in Catalog.STAGES:
		var section := "best." + stage_id
		var per_vehicle := {}
		for vehicle_id: String in Catalog.VEHICLES:
			var distance := _to_float(file.get_value(section, vehicle_id, 0.0))
			if distance > 0.0:
				per_vehicle[vehicle_id] = distance
		if not per_vehicle.is_empty():
			_best[stage_id] = per_vehicle


## Keeps only the ids that exist in `known` (a catalog dictionary).
func _valid_ids(value: Variant, known: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	if typeof(value) != TYPE_ARRAY and typeof(value) != TYPE_PACKED_STRING_ARRAY:
		return ids
	for item in value:
		var id := str(item)
		if known.has(id) and not ids.has(id):
			ids.append(id)
	return ids


func _to_int(value: Variant) -> int:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return int(value)
	return 0


func _to_float(value: Variant) -> float:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return float(value)
	return 0.0


# --- Writing -------------------------------------------------------------------------------

func _write_meta(file: ConfigFile) -> void:
	file.set_value("meta", "version", SAVE_VERSION)
	file.set_value("meta", "coins", _coins)
	file.set_value("meta", "vehicle", _selected_vehicle)
	file.set_value("meta", "stage", _selected_stage)


func _write_owned(file: ConfigFile) -> void:
	file.set_value("owned", "vehicles", _owned_vehicles.keys())
	file.set_value("owned", "stages", _owned_stages.keys())


func _write_upgrades(file: ConfigFile) -> void:
	for vehicle_id: String in Catalog.VEHICLES:
		for key: String in Catalog.UPGRADE_KEYS:
			file.set_value("upgrades." + vehicle_id, key, upgrade_level(vehicle_id, key))


func _write_best(file: ConfigFile) -> void:
	for stage_id: String in _best:
		var per_vehicle: Dictionary = _best[stage_id]
		for vehicle_id: String in per_vehicle:
			file.set_value("best." + stage_id, vehicle_id, per_vehicle[vehicle_id])
