class_name HatchbackSpec
extends VehicleSpec
## Starter car: light, rear-wheel drive, short wheelbase, bouncy. Teal with a cream stripe.

const BODY := Color("19b8b0")
const BODY_LIGHT := Color("7ff0e2")
const BODY_DARK := Color("0e7f86")
const BODY_DEEP := Color("0a5a66")
const TRIM := Color("1c2230")
const BELT := -17.0
const SILL := 30.0

const OUTLINE: Array[Vector2] = [
	Vector2(-96, 30), Vector2(-102, 18), Vector2(-102, 0), Vector2(-100, -14), Vector2(-66, -62), Vector2(-58, -68),
	Vector2(-30, -71), Vector2(-4, -70), Vector2(6, -66), Vector2(46, -19), Vector2(88, -15), Vector2(97, -8),
	Vector2(101, 10), Vector2(99, 22), Vector2(95, 30),
]
const REAR_WINDOW: Array[Vector2] = [
	Vector2(-86, -19), Vector2(-65, -54), Vector2(-59, -60), Vector2(-33, -62), Vector2(-33, -19),
]
const FRONT_WINDOW: Array[Vector2] = [
	Vector2(-26, -19), Vector2(-26, -62), Vector2(-4, -64), Vector2(4, -60), Vector2(38, -19),
]


func _init() -> void:
	mass = 10.0
	gyration = 55.0
	center_of_mass = Vector2(-8.0, 10.0)
	hull = hull_from(OUTLINE, SILL, 30.0, 62.0, 12.0)
	dummy_pos = Vector2(-8.0, -19.0)
	head_center = Vector2(-5.0, -46.0)
	head_radius = 24.0
	wheel_radius = 28.0
	wheel_mass = 1.5
	wheel_xs = PackedFloat32Array([-62.0, 62.0])
	mount_y = 10.0
	rest_offset = 30.0
	travel = 56.0
	spring_k = 620.0
	spring_c = 30.0
	drive_torque = 220000.0
	drive_share = PackedFloat32Array([1.0, 0.3])
	brake_torque = 120000.0
	max_spin = 60.0
	reaction = 0.12
	air_accel = 6.0
	base_grip = 0.25
	bot_air_gain = 0.0
	bot_air_lead = 0.25
	dust_color = Color(1.0, 0.8, 0.6, 0.26)
	add_strut(0, Vector2(-30, 12), 7.0, TRIM)
	add_strut(1, Vector2(30, 12), 7.0, TRIM)


func draw_body(body: Node2D, overlay: Node2D) -> Node2D:
	VehicleArt.beam(body, Vector2(98, -4), 300.0, 40.0)
	VehicleArt.stroke(body, PackedVector2Array(OUTLINE), VehicleArt.INK, 5.0, true)
	VehicleArt.shaded(body, Shapes.rounded(PackedVector2Array(OUTLINE), 8.0), BODY_LIGHT, BODY)
	_draw_cabin(body)
	var dummy := VehicleArt.add_dummy(body, dummy_pos)
	_draw_glass(body)
	_draw_lower_body(body)
	_draw_panel_details(body)
	_draw_front(body)
	_draw_rear(body)
	_draw_roof(body)
	_draw_arches(body, overlay)
	return dummy


func draw_wheel(wheel: Node2D, _index: int) -> void:
	VehicleArt.draw_wheel(wheel, wheel_radius, {
		"tread": 22, "depth": 3.4, "rim": 0.6, "spokes": 5, "spoke_width": 4.0, "bolts": 5,
		"rim_color": Color("e8e2d6"), "hub_color": BODY,
	})


func _draw_cabin(body: Node2D) -> void:
	VehicleArt.window_interior(body, PackedVector2Array(REAR_WINDOW))
	VehicleArt.window_interior(body, PackedVector2Array(FRONT_WINDOW))
	VehicleArt.stroke(body, PackedVector2Array([Vector2(30, -19), Vector2(24, -30), Vector2(18, -31)]), VehicleArt.SLATE, 6.0)
	VehicleArt.stroke(body, VehicleArt.arc(Vector2(24, -34), 8.0, 0.0, TAU, 14), VehicleArt.SLATE, 3.0, true)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-14, -19), Vector2(-14, -34)]), TRIM, 7.0)


func _draw_glass(body: Node2D) -> void:
	VehicleArt.glass_sheen(body, PackedVector2Array(REAR_WINDOW), Vector2(-58, -61), Vector2(-14, 40), 5.0)
	VehicleArt.glass_sheen(body, PackedVector2Array(FRONT_WINDOW), Vector2(-17, -63), Vector2(-22, 44), 5.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-29, -63), Vector2(-29, -19)]), BODY_DARK, 6.0)


func _draw_lower_body(body: Node2D) -> void:
	var lower := PackedVector2Array([
		Vector2(-101, BELT + 3), Vector2(-60, BELT), Vector2(20, BELT), Vector2(46, -19), Vector2(88, -15), Vector2(97, -8),
		Vector2(101, 10), Vector2(99, 22), Vector2(95, SILL), Vector2(-96, SILL), Vector2(-102, 18), Vector2(-102, 0),
	])
	VehicleArt.shaded(body, Shapes.rounded(lower, 6.0), BODY_LIGHT.lerp(BODY, 0.4), BODY_DARK)
	VehicleArt.soft(body, PackedVector2Array([Vector2(-34, 19), Vector2(34, 19), Vector2(32, SILL), Vector2(-32, SILL)]), BODY_DEEP, 3.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-98, -14), Vector2(-30, BELT + 0.5), Vector2(46, -18), Vector2(88, -14)]), Color(BODY_LIGHT, 0.9), 2.5)


func _draw_panel_details(body: Node2D) -> void:
	var stripe: Array[PackedVector2Array] = [VehicleArt.rect(-100, -4.5, 98, -0.5), VehicleArt.rect(-100, 2.0, 99, 4.0)]
	VehicleArt.merged(body, stripe, VehicleArt.CREAM)
	var seam := Color(VehicleArt.SLATE, 0.6)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-29, BELT), Vector2(-30, 14), Vector2(-27, 21)]), seam, 1.6)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(30, -18), Vector2(31, 12), Vector2(28, 21)]), seam, 1.6)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-97, -8), Vector2(-100, 12), Vector2(-96, 21)]), seam, 1.6)
	VehicleArt.handle(body, Vector2(-17, -9), 11.0, VehicleArt.CHROME)
	VehicleArt.roundel(body, Vector2(0, 8), 9.0, VehicleArt.CREAM, VehicleArt.SLATE, "1")
	VehicleArt.mirror(body, Vector2(36, -22), BODY)


func _draw_front(body: Node2D) -> void:
	VehicleArt.soft(body, PackedVector2Array([Vector2(88, 4), Vector2(100, 4), Vector2(101, 16), Vector2(90, 17)]), TRIM, 2.5)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(91, 8), Vector2(100, 8)]), Color(VehicleArt.CHROME, 0.7), 1.2)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(90, 12), Vector2(100, 12)]), Color(VehicleArt.CHROME, 0.7), 1.2)
	VehicleArt.headlight(body, Vector2(90, -6), Vector2(12, 8), 20.0)
	VehicleArt.soft(body, PackedVector2Array([Vector2(86, 19), Vector2(103, 18), Vector2(103, 26), Vector2(94, 30), Vector2(86, 29)]), TRIM, 3.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(88, 21), Vector2(102, 20.5)]), Color(VehicleArt.CHROME, 0.8), 1.4)
	VehicleArt.merged(body, [Shapes.circle(2.4, Vector2(93, 25), 8)], VehicleArt.LAMP)
	VehicleArt.merged(body, [PackedVector2Array([Vector2(96, 30), Vector2(91, 30), Vector2(91, 46), Vector2(96, 44)])], TRIM)


func _draw_rear(body: Node2D) -> void:
	VehicleArt.taillight(body, Vector2(-99, -4), Vector2(7, 16), 14.0)
	VehicleArt.soft(body, PackedVector2Array([Vector2(-103, 15), Vector2(-90, 17), Vector2(-90, SILL), Vector2(-97, SILL)]), TRIM, 3.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-92, 27), Vector2(-108, 29)]), VehicleArt.CHROME, 5.0)
	VehicleArt.merged(body, [Shapes.circle(2.4, Vector2(-108, 29), 8)], VehicleArt.INK)
	VehicleArt.merged(body, [PackedVector2Array([Vector2(-96, 30), Vector2(-91, 30), Vector2(-91, 46), Vector2(-96, 44)])], TRIM)


func _draw_roof(body: Node2D) -> void:
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-58, -69.5), Vector2(-30, -72.5), Vector2(-4, -71.5), Vector2(5, -67.5)]), VehicleArt.CREAM, 2.4)
	VehicleArt.soft(body, PackedVector2Array([Vector2(-58, -71), Vector2(-76, -70), Vector2(-81, -63), Vector2(-66, -61)]), BODY_DARK, 2.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-52, -78), Vector2(-9, -78)]), VehicleArt.CHROME, 3.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-50, -71), Vector2(-50, -78)]), VehicleArt.CHROME, 2.4)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-11, -70), Vector2(-11, -78)]), VehicleArt.CHROME, 2.4)
	var duffel := PackedVector2Array([Vector2(-47, -78), Vector2(-14, -78), Vector2(-12, -90), Vector2(-45, -91)])
	VehicleArt.soft(body, duffel, Color("ff9a3c"), 6.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-36, -78.5), Vector2(-36, -90.5)]), Color("b4561a"), 2.2)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-24, -78.5), Vector2(-23, -90)]), Color("b4561a"), 2.2)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-45, -88), Vector2(-14, -88.5)]), Color("ffc27d"), 2.0)


func _draw_arches(body: Node2D, overlay: Node2D) -> void:
	for i in wheel_xs.size():
		var center := Vector2(wheel_xs[i], mount_y + rest_offset)
		var cut := asin((center.y - SILL) / (wheel_radius + 7.0))
		var well := VehicleArt.arc(center, wheel_radius + 6.0, PI + cut, TAU - cut, 16)
		Shapes.poly(body, well, VehicleArt.WELL)
		var lip := VehicleArt.arc(center, wheel_radius + 8.5, PI + cut - 0.08, TAU - cut + 0.08, 16)
		VehicleArt.stroke(overlay, lip, BODY_DARK, 5.0)
		VehicleArt.stroke(overlay, VehicleArt.arc(center, wheel_radius + 11.0, PI + cut + 0.1, TAU - cut - 0.1, 14), Color(BODY_LIGHT, 0.75), 2.0)
