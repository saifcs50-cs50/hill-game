class_name Vehicle
extends Node2D
## A data-driven vehicle: script-driven spring suspension on groove joints, per-vehicle drive
## and grip tuning from a VehicleSpec, and a crash-test dummy driver.
##
## Usage: `var v := Vehicle.new(); v.setup("monster", {"engine": 3, ...}); add_child(v)`.

signal crashed

## A drawn suspension link that follows a wheel hub.
class StrutLink:
	var line: Line2D
	var wheel: int
	var offset: Vector2

	func _init(line_node: Line2D, wheel_index: int, hub_offset: Vector2) -> void:
		line = line_node
		wheel = wheel_index
		offset = hub_offset

const FUEL_BASE_SECONDS := 45.0
const DEFAULT_ID := "hatchback"
## The stage whose gravity the spring rest lengths are tuned for (the starter stage).
const REFERENCE_STAGE := "meadow"
## Wheel slip (px/s) at which the tyre traction assist reaches full strength.
const SLIP_FULL := 90.0
## How much of the engine upgrade goes into top wheel spin (the rest goes into torque).
const SPIN_SHARE_OF_ENGINE := 0.5
## Suspension upgrade at level 10 adds this much damping and angular stability.
const DAMPING_GAIN := 0.6
const STABILITY_GAIN := 0.35
const BRAKE_SPIN_LIMIT := 0.5
const EJECT_VELOCITY := Vector2(140.0, -460.0)
const EJECT_SPIN := 10.0
const EJECT_LIFETIME := 6.0
const DUST_AMOUNT := 16
## Cap on the suspension force, so a wedged wheel cannot store runaway energy.
const SPRING_FORCE_LIMIT := 40000.0
## Chassis speed (px/s) beyond which the physics is assumed to have blown up.
const RUNAWAY_SPEED := 5000.0
const BOT_MAX_TARGET := 0.7
const BOT_DEADBAND := 0.08

var chassis: RigidBody2D
var wheels: Array[RigidBody2D] = []
var gas := false
var brake := false
var grounded := 0
var is_bot := false

var _spec: VehicleSpec
var _engine := 1.0
var _stability := 1.0
var _damping := 1.0
var _max_spin := 60.0
var _levels := {}
var _tyre_bonus := 0.0
var _rigs: Array[VehicleWheel] = []
var _mounts: Array[Vector2] = []
var _rests: Array[float] = []
var _strut_links: Array[StrutLink] = []
var _dust: Array[CPUParticles2D] = []
var _dummy: Node2D
var _has_crashed := false
var _spin_ratio := 0.0


## A non-physics visual copy of a vehicle for menus: origin at the chassis centre, +x forward,
## tyres resting on y = 70 and everything inside a 300 x 185 box (see VehiclePreview).
static func build_art(vehicle_id: String) -> Node2D:
	return VehiclePreview.build(vehicle_id)


## Chooses the vehicle and applies upgrade levels (0-10 for engine, suspension, tyres, fuel).
## Call before add_child.
func setup(vehicle_id: String, upgrades: Dictionary = {}) -> void:
	_spec = VehicleSpecs.make(vehicle_id)
	for key: String in Catalog.UPGRADE_KEYS:
		_levels[key] = clampi(int(upgrades.get(key, 0)), 0, Catalog.MAX_UPGRADE_LEVEL)


func _apply_upgrades() -> void:
	_engine = Catalog.upgrade_effect("engine", _levels.get("engine", 0))
	var quality := Catalog.upgrade_effect("suspension", _levels.get("suspension", 0))
	_damping = 1.0 + DAMPING_GAIN * quality
	_stability = 1.0 + STABILITY_GAIN * quality
	_max_spin = _spec.max_spin * (1.0 + (_engine - 1.0) * SPIN_SHARE_OF_ENGINE)
	_tyre_bonus = _spec.base_grip + Catalog.upgrade_effect("tyres", _levels.get("tyres", 0)) - 1.0


## Distance from the chassis origin down to the tyre bottoms at rest. Spawn the vehicle at
## ground height minus this (plus a small drop) so it never starts inside the terrain.
func ride_height() -> float:
	if _spec == null:
		setup(DEFAULT_ID)
	return _spec.mount_y + _spec.rest_offset + _spec.wheel_radius


## For garage previews: holds the vehicle in its rest pose. Call after add_child.
func freeze_pose() -> void:
	chassis.freeze = true
	for wheel in wheels:
		wheel.freeze = true


## Seconds of fuel in a full tank.
func fuel_seconds() -> float:
	return FUEL_BASE_SECONDS * Catalog.upgrade_effect("fuel", _levels.get("fuel", 0))


## Average wheel spin against the top spin, 0-1, for the engine sound.
func spin_ratio() -> float:
	return _spin_ratio


func _ready() -> void:
	if _spec == null:
		setup(DEFAULT_ID)
	_apply_upgrades()
	for i in 2:
		var dust := _make_dust()
		add_child(dust)
		_dust.append(dust)
	chassis = _make_chassis()
	add_child(chassis)
	for i in _spec.wheel_xs.size():
		_add_wheel(i)


func _physics_process(_delta: float) -> void:
	if chassis.linear_velocity.length_squared() > RUNAWAY_SPEED * RUNAWAY_SPEED:
		_calm_down()
	if is_bot:
		_drive_bot()
	var axis := chassis.global_transform.y
	var applied := 0.0
	var spin := 0.0
	grounded = 0
	for i in _rigs.size():
		var wheel := _rigs[i]
		var contact_force := _apply_suspension(i, wheel, axis)
		if wheel.touching:
			grounded += 1
		applied += _apply_drive(i, wheel, contact_force)
		spin += absf(wheel.angular_velocity)
		_update_wheel_visuals(i, wheel)
	_spin_ratio = clampf(spin / (_rigs.size() * _max_spin), 0.0, 1.0)
	chassis.apply_torque(-applied * _spec.reaction)
	if grounded == 0:
		chassis.apply_torque((float(brake) - float(gas)) * _spec.air_accel * chassis.inertia)
	for strut in _strut_links:
		strut.line.set_point_position(1, chassis.to_local(_rigs[strut.wheel].global_position) + strut.offset)


## Safety net: a wedged joint can occasionally throw the solver into a runaway. Past a speed no
## vehicle can reach, stop everything instead of letting it fly off the map.
func _calm_down() -> void:
	push_warning("Vehicle physics runaway stopped at x=%.0f" % chassis.global_position.x)
	for body: RigidBody2D in [chassis] + wheels:
		body.linear_velocity = Vector2.ZERO
		body.angular_velocity = 0.0


## The bot keeps the gas down unless the nose rises too far off the slope, and in the air it
## steers the body to follow its flight path so it lands flat.
func _drive_bot() -> void:
	var pitch := chassis.rotation
	if grounded > 0:
		var relative := pitch - _ground_angle()
		gas = relative > _spec.bot_ground_pitch
		brake = relative < _spec.bot_brake_pitch
		return
	var velocity := chassis.linear_velocity
	var target := clampf(atan2(velocity.y, maxf(velocity.x, 1.0)), -BOT_MAX_TARGET, BOT_MAX_TARGET)
	var spin := chassis.angular_velocity
	var overshoot := spin * absf(spin) / (2.0 * _spec.air_accel) * _spec.bot_air_gain + spin * _spec.bot_air_lead
	var error := target - pitch - overshoot
	gas = error < -BOT_DEADBAND
	brake = error > BOT_DEADBAND


## Slope of the ground under the wheels, as a rotation (negative is uphill).
func _ground_angle() -> float:
	var normal := Vector2.ZERO
	for wheel in _rigs:
		if wheel.touching:
			normal += wheel.ground_normal
	return atan2(normal.x, -normal.y)


## Spring and damper along the chassis' down axis. Returns the force pushing the wheel down.
func _apply_suspension(i: int, wheel: VehicleWheel, axis: Vector2) -> float:
	var arm := chassis.to_global(_mounts[i]) - chassis.global_position
	var mount_velocity := chassis.linear_velocity + Vector2(-arm.y, arm.x) * chassis.angular_velocity
	var extension := (wheel.global_position - chassis.global_position - arm).dot(axis)
	var speed := (wheel.linear_velocity - mount_velocity).dot(axis)
	var force := -_spec.spring_k * (extension - _rests[i]) - _spec.spring_c * _damping * speed
	force = clampf(force, -SPRING_FORCE_LIMIT, SPRING_FORCE_LIMIT)
	wheel.apply_central_force(axis * force)
	chassis.apply_force(-axis * force, arm)
	return force


## Drive or brake torque on one wheel. Returns the torque applied.
func _apply_drive(i: int, wheel: VehicleWheel, contact_force: float) -> float:
	var torque := 0.0
	var direction := 0.0
	var share := _spec.drive_share[i]
	if gas and share > 0.0 and wheel.angular_velocity < _max_spin:
		torque = _spec.drive_torque * _engine * share
		direction = 1.0
	elif brake and wheel.angular_velocity > -_max_spin * BRAKE_SPIN_LIMIT:
		torque = -_spec.brake_torque
		direction = -1.0
	wheel.apply_torque(torque)
	if direction != 0.0 and wheel.touching and _tyre_bonus > 0.0:
		_traction_assist(wheel, direction, contact_force)
	return torque


## Godot combines friction as the minimum of the two surfaces, so a tyre upgrade alone would
## never help on ice. This pushes a slipping wheel along the ground with the grip the upgrade
## would have given, scaled by the surface's own friction.
func _traction_assist(wheel: VehicleWheel, direction: float, contact_force: float) -> void:
	var tangent := Vector2(-wheel.ground_normal.y, wheel.ground_normal.x)
	var slip := (wheel.angular_velocity * _spec.wheel_radius - wheel.linear_velocity.dot(tangent)) * direction
	var strength := clampf(slip / SLIP_FULL, 0.0, 1.0)
	var push := wheel.ground_friction * _tyre_bonus * maxf(contact_force, 0.0) * strength * direction
	wheel.apply_central_force(tangent * push)


func _update_wheel_visuals(i: int, wheel: VehicleWheel) -> void:
	_dust[i].global_position = wheel.global_position + Vector2(0.0, _spec.wheel_radius - 4.0)
	_dust[i].emitting = wheel.touching and absf(wheel.angular_velocity) > 8.0


func _add_wheel(i: int) -> void:
	var mount := Vector2(_spec.wheel_xs[i], _spec.mount_y)
	_mounts.append(mount)
	_rests.append(_spec.rest_offset + _static_load(i) / _spec.spring_k)
	var wheel := _make_wheel(i)
	wheel.position = mount + Vector2(0.0, _spec.rest_offset)
	add_child(wheel)
	_rigs.append(wheel)
	wheels.append(wheel)
	var joint := GrooveJoint2D.new()
	joint.position = mount
	joint.length = _spec.travel
	joint.initial_offset = _spec.rest_offset
	add_child(joint)
	joint.node_a = joint.get_path_to(chassis)
	joint.node_b = joint.get_path_to(wheel)


## Chassis weight carried by wheel `i` at rest, from where the centre of mass sits between
## the axles, so the car rides level whatever its weight balance.
func _static_load(i: int) -> float:
	var gravity: float = Catalog.STAGES[REFERENCE_STAGE]["gravity"]
	var rear := _spec.wheel_xs[0]
	var front := _spec.wheel_xs[_spec.wheel_xs.size() - 1]
	var span := front - rear
	var along := (_spec.center_of_mass.x - rear) / span
	var share := along if i == _spec.wheel_xs.size() - 1 else 1.0 - along
	return _spec.mass * gravity * share


func _make_chassis() -> RigidBody2D:
	var body := RigidBody2D.new()
	body.mass = _spec.mass
	body.inertia = _spec.mass * _spec.gyration * _spec.gyration
	body.collision_layer = 2
	body.collision_mask = 1
	body.center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	body.center_of_mass = _spec.center_of_mass
	body.angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	body.angular_damp = _spec.angular_damp * _stability
	body.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	body.linear_damp = _spec.linear_damp
	var hull := CollisionPolygon2D.new()
	hull.polygon = _spec.hull
	body.add_child(hull)
	body.add_child(_make_head_sensor())
	_draw_chassis(body)
	return body


func _make_head_sensor() -> Area2D:
	var head := Area2D.new()
	head.collision_layer = 0
	head.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _spec.head_radius
	shape.shape = circle
	shape.position = _spec.head_center
	head.add_child(shape)
	head.body_entered.connect(_on_head_hit)
	return head


## Strut lines are created first so the body art covers them; the spec draws the rest.
func _draw_chassis(body: Node2D) -> void:
	for strut in _spec.struts:
		var line := Shapes.line(body, PackedVector2Array([strut.anchor, strut.anchor]), strut.color, strut.width)
		_strut_links.append(StrutLink.new(line, strut.wheel, strut.hub_offset))
	var overlay := Node2D.new()
	overlay.z_index = 1
	body.add_child(overlay)
	_dummy = _spec.draw_body(body, overlay)
	if _dummy == null:
		_dummy = Node2D.new()
		body.add_child(_dummy)


func _make_wheel(index: int) -> VehicleWheel:
	var wheel := VehicleWheel.new()
	wheel.mass = _spec.wheel_mass
	wheel.collision_layer = 2
	wheel.collision_mask = 1
	wheel.contact_monitor = true
	wheel.max_contacts_reported = 3
	wheel.angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	wheel.angular_damp = _spec.wheel_damp
	wheel.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	wheel.linear_damp = 0.0
	var material := PhysicsMaterial.new()
	material.friction = _spec.wheel_friction
	material.bounce = _spec.wheel_bounce
	wheel.physics_material_override = material
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _spec.wheel_radius
	collider.shape = circle
	wheel.add_child(collider)
	_spec.draw_wheel(wheel, index)
	return wheel


func _make_dust() -> CPUParticles2D:
	var dust := CPUParticles2D.new()
	dust.texture = Shapes.glow_texture(32, Color.WHITE)
	dust.amount = DUST_AMOUNT
	dust.lifetime = 0.7
	dust.local_coords = false
	dust.emitting = false
	dust.direction = Vector2(-1.0, -0.45)
	dust.spread = 28.0
	dust.gravity = Vector2(0.0, -30.0)
	dust.initial_velocity_min = 50.0
	dust.initial_velocity_max = 170.0
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.4
	dust.color = _spec.dust_color
	dust.color_ramp = Shapes.gradient([0.0, 1.0], [Color.WHITE, Color(1, 1, 1, 0)])
	return dust


func _on_head_hit(_body: Node) -> void:
	if _has_crashed:
		return
	_has_crashed = true
	crashed.emit()
	_eject_dummy.call_deferred()


## Swaps the seated dummy for a loose tumbling one.
func _eject_dummy() -> void:
	_dummy.visible = false
	var body := RigidBody2D.new()
	body.mass = 1.0
	body.collision_layer = 4
	body.collision_mask = 1
	var material := PhysicsMaterial.new()
	material.bounce = 0.45
	material.friction = 0.6
	body.physics_material_override = material
	var collider := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 13.0
	capsule.height = 54.0
	collider.shape = capsule
	body.add_child(collider)
	var art := Node2D.new()
	body.add_child(art)
	VehicleArt.draw_dummy(art, true)
	body.position = to_local(chassis.to_global(_spec.dummy_pos))
	body.rotation = chassis.global_rotation
	body.linear_velocity = chassis.linear_velocity * 0.8 + EJECT_VELOCITY
	body.angular_velocity = EJECT_SPIN
	add_child(body)
	body.reset_physics_interpolation()
	get_tree().create_timer(EJECT_LIFETIME).timeout.connect(body.queue_free)
