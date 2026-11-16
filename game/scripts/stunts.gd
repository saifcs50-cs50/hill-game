class_name Stunts
extends Node
## Watches one vehicle and pays out for air time and flips, with a combo multiplier
## for tricks landed back to back.

signal trick_landed(label: String, coins: int, combo: int)

const AIR_DEBOUNCE := 0.12
const MIN_AIR_TIME := 0.9
const AIR_COINS_PER_SECOND := 12.0
const FLIP_COINS := 30
const UPRIGHT_LIMIT := 1.25
const FLIP_TOLERANCE := 0.6
const COMBO_WINDOW := 3.0
const MAX_COMBO := 5

var _vehicle: Vehicle
var _airborne := false
var _off_ground_for := 0.0
var _air_time := 0.0
var _turned := 0.0
var _combo := 0
var _since_trick := 0.0


func watch(vehicle: Vehicle) -> void:
	_vehicle = vehicle
	_reset_air()
	_combo = 0


func break_combo() -> void:
	_combo = 0


func _physics_process(delta: float) -> void:
	if _vehicle == null or not is_instance_valid(_vehicle) or _vehicle.chassis == null:
		return
	_since_trick += delta
	if _since_trick > COMBO_WINDOW:
		_combo = 0
	if _vehicle.grounded == 0:
		_off_ground_for += delta
		if _off_ground_for >= AIR_DEBOUNCE:
			_airborne = true
		if _airborne:
			_air_time += delta
			_turned += _vehicle.chassis.angular_velocity * delta
		return
	if _airborne:
		_on_landed()
	_reset_air()


func _on_landed() -> void:
	var upright := absf(wrapf(_vehicle.chassis.global_rotation, -PI, PI)) < UPRIGHT_LIMIT
	if not upright:
		return
	var flips := int((absf(_turned) + FLIP_TOLERANCE) / TAU)
	var parts: Array[String] = []
	var coins := 0
	if flips > 0:
		var name := "BACKFLIP" if _turned < 0.0 else "FRONTFLIP"
		parts.append(name if flips == 1 else "%s x%d" % [name, flips])
		coins += FLIP_COINS * flips
	if _air_time >= MIN_AIR_TIME:
		parts.append("AIR %.1fs" % _air_time)
		coins += int(_air_time * AIR_COINS_PER_SECOND)
	if parts.is_empty():
		return
	_combo = mini(_combo + 1, MAX_COMBO)
	_since_trick = 0.0
	trick_landed.emit(" + ".join(parts), coins * _combo, _combo)


func _reset_air() -> void:
	_airborne = false
	_off_ground_for = 0.0
	_air_time = 0.0
	_turned = 0.0
