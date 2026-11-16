class_name VehicleSpec
extends RefCounted
## Physics numbers and art for one vehicle. Subclasses fill in the fields in _init and draw
## themselves. Units: pixels (100 px = 1 m), seconds. +x is forward, +y is down, and the
## chassis origin sits between the wheels. Wheel index 0 is the rear, 1 is the front.

## One visible suspension link between the body and a wheel hub.
class Strut:
	var wheel := 0
	var anchor := Vector2.ZERO
	var hub_offset := Vector2.ZERO
	var width := 8.0
	var color := Color("1c2230")

# Body
var mass := 10.0
## Radius of gyration in px: the chassis inertia is mass * gyration^2.
var gyration := 53.0
var center_of_mass := Vector2(4.0, 14.0)
var linear_damp := 0.03
var angular_damp := 1.2
var hull := PackedVector2Array()
## Torso centre of the seated dummy; its head sits at dummy_pos + VehicleArt.HEAD_OFFSET.
var dummy_pos := Vector2(-10.0, -38.0)
var head_center := Vector2(-7.0, -65.0)
var head_radius := 12.0

# Wheels and suspension
var wheel_radius := 28.0
var wheel_mass := 1.5
var wheel_xs := PackedFloat32Array([-62.0, 62.0])
var mount_y := 10.0
var rest_offset := 30.0
var travel := 56.0
var spring_k := 620.0
var spring_c := 30.0
var wheel_friction := 1.0
var wheel_bounce := 0.2
var wheel_damp := 0.15
var dust_color := Color(1.0, 0.8, 0.6, 0.26)

# Drive
## Torque on each driven wheel, and which wheels are driven (1 = driven, 0 = free-rolling).
var drive_torque := 150000.0
var drive_share := PackedFloat32Array([1.0, 0.0])
## Braking and reversing torque, applied to every wheel.
var brake_torque := 120000.0
var max_spin := 60.0
## Fraction of the applied wheel torque that pushes back on the chassis (wheelies).
var reaction := 0.12
## Rotation speed gain in the air from the pedals, in rad/s^2.
var air_accel := 6.0

## Extra grip from tyre compound, added to the tyre upgrade (0 = ordinary tyres).
var base_grip := 0.0

# Bot driving limits (rotation in radians; negative is nose up)
## How the bot levels the body in the air: a braking-distance term (gain) plus a look-ahead (lead, in seconds).
var bot_air_gain := 0.5
var bot_air_lead := 0.12
## Release the gas when the nose is this far above the slope, brake when it is further still.
var bot_ground_pitch := -0.5
var bot_brake_pitch := -0.8

var struts: Array[Strut] = []


## Draws the chassis art in `body` (the overlay child draws above the wheels) and returns the
## node holding the seated dummy.
func draw_body(body: Node2D, _overlay: Node2D) -> Node2D:
	Shapes.poly(body, hull, Color("8a8fa0"))
	return VehicleArt.add_dummy(body, dummy_pos)


func draw_wheel(wheel: Node2D, _index: int) -> void:
	VehicleArt.draw_wheel(wheel, wheel_radius, {})


## A collision hull from `outline` (which must start and end at the bottom corners) with the
## underside between the axles raised by `lift`, so a crest cannot beach the car on its belly.
func hull_from(outline: Array[Vector2], sill: float, flat_half: float, ramp_half: float, lift: float) -> PackedVector2Array:
	var pts := PackedVector2Array(outline)
	pts.append(Vector2(ramp_half, sill))
	pts.append(Vector2(flat_half, sill - lift))
	pts.append(Vector2(-flat_half, sill - lift))
	pts.append(Vector2(-ramp_half, sill))
	return pts


func add_strut(wheel: int, anchor: Vector2, width: float, color: Color, hub_offset := Vector2.ZERO) -> void:
	var strut := Strut.new()
	strut.wheel = wheel
	strut.anchor = anchor
	strut.width = width
	strut.color = color
	strut.hub_offset = hub_offset
	struts.append(strut)
