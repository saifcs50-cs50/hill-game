class_name SupercarSpec
extends VehicleSpec
## Supercar: low, stiff, short travel, highest top speed, rear-biased drive. Electric blue
## with white stripes, orange accents and a big rear wing.

const BODY := Color("2f6bff")
const BODY_LIGHT := Color("86b4ff")
const BODY_DARK := Color("1d3fb8")
const BODY_DEEP := Color("12287a")
const WHITE := Color("f4f7ff")
const TRIM := Color("141824")
const ORANGE := Color("ff8a2a")
const BELT := -14.0
const SILL := 14.0

const OUTLINE: Array[Vector2] = [
	Vector2(-104, 14), Vector2(-114, 6), Vector2(-112, -4), Vector2(-100, -12), Vector2(-72, -16), Vector2(-44, -44),
	Vector2(-18, -50), Vector2(14, -50), Vector2(74, -16), Vector2(106, -2), Vector2(114, 8), Vector2(108, 14),
]
const CANOPY: Array[Vector2] = [
	Vector2(-76, -14), Vector2(-44, -44), Vector2(-18, -50), Vector2(14, -50), Vector2(76, -14),
]
const WINDOW: Array[Vector2] = [
	Vector2(-60, -14), Vector2(-41, -40), Vector2(-18, -46), Vector2(12, -46), Vector2(62, -14),
]


func _init() -> void:
	mass = 12.0
	gyration = 60.0
	center_of_mass = Vector2(-14.0, 6.0)
	angular_damp = 2.0
	hull = hull_from(OUTLINE, SILL, 30.0, 70.0, 8.0)
	dummy_pos = Vector2(-14.0, -6.0)
	head_center = Vector2(-11.0, -33.0)
	head_radius = 20.0
	wheel_radius = 25.0
	wheel_mass = 1.4
	wheel_xs = PackedFloat32Array([-86.0, 86.0])
	mount_y = 6.0
	rest_offset = 18.0
	travel = 34.0
	spring_k = 2200.0
	spring_c = 70.0
	wheel_bounce = 0.1
	drive_torque = 300000.0
	drive_share = PackedFloat32Array([1.0, 0.3])
	brake_torque = 130000.0
	max_spin = 100.0
	base_grip = 0.5
	reaction = 0.09
	air_accel = 7.0
	add_strut(0, Vector2(-44, 8), 7.0, TRIM)
	add_strut(1, Vector2(44, 8), 7.0, TRIM)


func draw_body(body: Node2D, overlay: Node2D) -> Node2D:
	VehicleArt.beam(body, Vector2(108, -2), 320.0, 34.0)
	VehicleArt.stroke(body, PackedVector2Array(OUTLINE), VehicleArt.INK, 5.0, true)
	_draw_wing(body)
	VehicleArt.shaded(body, Shapes.rounded(PackedVector2Array(CANOPY), 8.0), BODY_LIGHT, BODY)
	VehicleArt.window_interior(body, PackedVector2Array(WINDOW))
	VehicleArt.stroke(body, PackedVector2Array([Vector2(52, -14), Vector2(40, -24), Vector2(34, -24)]), TRIM, 5.0)
	VehicleArt.stroke(body, VehicleArt.arc(Vector2(38, -30), 7.0, 0.0, TAU, 12), TRIM, 2.6, true)
	var dummy := VehicleArt.add_dummy(body, dummy_pos)
	VehicleArt.glass_sheen(body, PackedVector2Array(WINDOW), Vector2(-20, -47), Vector2(-14, 30), 5.0)
	_draw_lower_body(body)
	_draw_side_details(body)
	_draw_front(body)
	_draw_rear(body)
	_draw_stripes(body)
	_draw_arches(body, overlay)
	return dummy


func draw_wheel(wheel: Node2D, _index: int) -> void:
	VehicleArt.draw_wheel(wheel, wheel_radius, {
		"tread": 28, "depth": 2.0, "rim": 0.74, "spokes": 10, "spoke_width": 2.2, "bolts": 5, "bolt_at": 0.3,
		"tyre": Color("14141c"), "side": Color("20202a"),
		"rim_color": Color("d9e0ee"), "dish_color": Color("1e2438"), "hub_color": ORANGE,
	})


func _draw_wing(body: Node2D) -> void:
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-98, -14), Vector2(-98, -31)]), TRIM, 4.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-84, -17), Vector2(-86, -31)]), TRIM, 4.0)
	VehicleArt.soft(body, PackedVector2Array([Vector2(-116, -40), Vector2(-78, -43), Vector2(-72, -33), Vector2(-80, -30), Vector2(-112, -31)]), BODY_DARK, 3.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-114, -38.5), Vector2(-78, -41.5)]), WHITE, 2.4)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-112, -33), Vector2(-80, -32)]), Color(TRIM, 0.7), 1.6)


func _draw_lower_body(body: Node2D) -> void:
	var lower := PackedVector2Array([
		Vector2(-114, 6), Vector2(-112, -4), Vector2(-100, -12), Vector2(-72, -16), Vector2(-60, BELT), Vector2(62, BELT),
		Vector2(76, -16), Vector2(106, -2), Vector2(114, 8), Vector2(108, SILL), Vector2(-104, SILL),
	])
	VehicleArt.shaded(body, Shapes.rounded(lower, 6.0), BODY_LIGHT.lerp(BODY, 0.45), BODY_DARK)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-108, -5), Vector2(-98, -12.5), Vector2(-72, -16.5), Vector2(-60, BELT - 0.5), Vector2(62, BELT - 0.5)]), Color(BODY_LIGHT, 0.9), 2.4)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(76, -16.5), Vector2(106, -3)]), Color(BODY_LIGHT, 0.9), 2.4)
	var skirt := PackedVector2Array([Vector2(-96, 10), Vector2(98, 10), Vector2(94, SILL + 1), Vector2(-92, SILL + 1)])
	VehicleArt.soft(body, skirt, TRIM, 2.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-60, 9), Vector2(60, 9)]), Color(ORANGE, 0.85), 1.4)


func _draw_side_details(body: Node2D) -> void:
	var intake := PackedVector2Array([Vector2(-62, -4), Vector2(-44, -11), Vector2(-38, 1), Vector2(-58, 7)])
	VehicleArt.soft(body, intake, TRIM, 2.0)
	for k in 3:
		var o := k * 5.0
		VehicleArt.stroke(body, PackedVector2Array([Vector2(-58 + o, 4 - o * 0.4), Vector2(-46 + o, -6 - o * 0.2)]), Color(VehicleArt.CHROME, 0.8), 1.5)
	var seam := Color(VehicleArt.SLATE, 0.65)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(46, BELT), Vector2(50, -4), Vector2(38, 8)]), seam, 1.6)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-30, BELT), Vector2(-34, -2), Vector2(-26, 9)]), seam, 1.6)
	VehicleArt.handle(body, Vector2(-14, -9), 9.0, Color(VehicleArt.CHROME, 0.8))
	VehicleArt.roundel(body, Vector2(8, -1), 7.5, WHITE, BODY_DEEP, "7")
	VehicleArt.mirror(body, Vector2(58, -19), BODY)


func _draw_front(body: Node2D) -> void:
	VehicleArt.headlight(body, Vector2(97, -1), Vector2(14, 5), 20.0)
	VehicleArt.soft(body, PackedVector2Array([Vector2(94, 0), Vector2(110, 2), Vector2(111, 8), Vector2(94, 8)]), TRIM, 2.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(97, 4), Vector2(108, 5)]), Color(VehicleArt.CHROME, 0.6), 1.2)
	VehicleArt.soft(body, PackedVector2Array([Vector2(92, 11), Vector2(120, 9), Vector2(118, 15), Vector2(90, 16)]), TRIM, 2.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(94, 11.5), Vector2(118, 10.2)]), ORANGE, 1.6)
	VehicleArt.soft(body, PackedVector2Array([Vector2(80, -12), Vector2(94, -8), Vector2(92, -5), Vector2(80, -8)]), BODY_DEEP, 2.0)


func _draw_rear(body: Node2D) -> void:
	VehicleArt.taillight(body, Vector2(-111, -3), Vector2(5, 9), 14.0)
	VehicleArt.soft(body, PackedVector2Array([Vector2(-116, 3), Vector2(-100, 3), Vector2(-100, 15), Vector2(-110, 14)]), TRIM, 2.0)
	for k in 3:
		VehicleArt.stroke(body, PackedVector2Array([Vector2(-114 + k * 4.0, 7), Vector2(-112 + k * 4.0, 14)]), Color(VehicleArt.CHROME, 0.45), 1.2)
	VehicleArt.merged(body, [Shapes.circle(3.6, Vector2(-115, 8), 10)], VehicleArt.CHROME)
	VehicleArt.merged(body, [Shapes.circle(2.2, Vector2(-115, 8), 8)], VehicleArt.INK)
	VehicleArt.merged(body, [PackedVector2Array([Vector2(-100, 15), Vector2(-96, 15), Vector2(-96, 29), Vector2(-100, 27)])], TRIM)


func _draw_stripes(body: Node2D) -> void:
	var top: Array[PackedVector2Array] = [
		VehicleArt.bar(Vector2(-100, -13.5), Vector2(-72, -17.4), 2.6),
		VehicleArt.bar(Vector2(-44, -45.4), Vector2(-18, -51.4), 2.6),
		VehicleArt.bar(Vector2(-18, -51.4), Vector2(14, -51.4), 2.6),
		VehicleArt.bar(Vector2(76, -17.2), Vector2(106, -3.4), 2.6),
	]
	VehicleArt.merged(body, top, WHITE)
	var swoosh := PackedVector2Array([Vector2(-96, 4), Vector2(30, 4), Vector2(96, 2), Vector2(98, 5), Vector2(30, 8), Vector2(-96, 8)])
	var swoosh_shapes: Array[PackedVector2Array] = [swoosh]
	VehicleArt.merged(body, swoosh_shapes, Color(WHITE, 0.85))


func _draw_arches(body: Node2D, overlay: Node2D) -> void:
	for i in wheel_xs.size():
		var center := Vector2(wheel_xs[i], mount_y + rest_offset)
		var cut := asin(clampf((center.y - SILL) / (wheel_radius + 5.0), -0.99, 0.99))
		Shapes.poly(body, VehicleArt.arc(center, wheel_radius + 4.0, PI + cut, TAU - cut, 14), VehicleArt.WELL)
		VehicleArt.stroke(overlay, VehicleArt.arc(center, wheel_radius + 6.2, PI + cut - 0.06, TAU - cut + 0.06, 14), BODY_DEEP, 4.0)
		VehicleArt.stroke(overlay, VehicleArt.arc(center, wheel_radius + 8.6, PI + cut + 0.08, TAU - cut - 0.08, 12), Color(BODY_LIGHT, 0.7), 1.8)
