class_name PickupSpec
extends VehicleSpec
## All-wheel-drive 4x4: long wheelbase, heavy, stable, climbs anything. Lime green with
## black trim and orange accents.

const BODY := Color("5fbf45")
const BODY_LIGHT := Color("b4ec78")
const BODY_DARK := Color("2f7d33")
const BODY_DEEP := Color("1f5a2b")
const TRIM := Color("1a1d27")
const ORANGE := Color("ff8a2a")
const BELT := -22.0
const SILL := 28.0

const OUTLINE: Array[Vector2] = [
	Vector2(-110, 28), Vector2(-114, 16), Vector2(-114, -22), Vector2(-26, -22), Vector2(-22, -64), Vector2(-14, -72),
	Vector2(34, -72), Vector2(62, -22), Vector2(102, -20), Vector2(112, -8), Vector2(114, 14), Vector2(109, 28),
]
const CAB: Array[Vector2] = [
	Vector2(-27, -20), Vector2(-22, -64), Vector2(-14, -72), Vector2(34, -72), Vector2(62, -20),
]
const WINDOW: Array[Vector2] = [
	Vector2(-6, -26), Vector2(-5, -65), Vector2(26, -65), Vector2(32, -62), Vector2(54, -26),
]


func _init() -> void:
	mass = 16.0
	gyration = 68.0
	center_of_mass = Vector2(2.0, 12.0)
	angular_damp = 1.6
	hull = hull_from(OUTLINE, SILL, 36.0, 80.0, 12.0)
	dummy_pos = Vector2(14.0, -20.0)
	head_center = Vector2(17.0, -47.0)
	head_radius = 26.0
	wheel_radius = 33.0
	wheel_mass = 2.0
	wheel_xs = PackedFloat32Array([-80.0, 80.0])
	mount_y = 10.0
	rest_offset = 28.0
	travel = 62.0
	spring_k = 990.0
	spring_c = 56.0
	drive_torque = 270000.0
	drive_share = PackedFloat32Array([1.0, 1.0])
	brake_torque = 150000.0
	max_spin = 58.0
	reaction = 0.07
	air_accel = 4.5
	dust_color = Color(0.85, 0.7, 0.5, 0.3)
	add_strut(0, Vector2(-40, 12), 8.0, TRIM)
	add_strut(1, Vector2(40, 12), 8.0, TRIM)


func draw_body(body: Node2D, overlay: Node2D) -> Node2D:
	VehicleArt.beam(body, Vector2(108, -4), 320.0, 44.0)
	VehicleArt.stroke(body, PackedVector2Array(OUTLINE), VehicleArt.INK, 5.0, true)
	_draw_bed_load(body)
	VehicleArt.shaded(body, Shapes.rounded(PackedVector2Array(CAB), 7.0), BODY_LIGHT, BODY)
	VehicleArt.window_interior(body, PackedVector2Array(WINDOW))
	_draw_dashboard(body)
	var dummy := VehicleArt.add_dummy(body, dummy_pos)
	VehicleArt.glass_sheen(body, PackedVector2Array(WINDOW), Vector2(0, -66), Vector2(-12, 40), 5.0)
	_draw_lower_body(body)
	_draw_side_details(body)
	_draw_front(body)
	_draw_rear(body)
	_draw_roof(body)
	_draw_arches(body, overlay)
	return dummy


func draw_wheel(wheel: Node2D, _index: int) -> void:
	VehicleArt.draw_wheel(wheel, wheel_radius, {
		"tread": 22, "depth": 4.4, "rim": 0.56, "spokes": 0, "bolts": 6,
		"rim_color": Color("b9c0cc"), "dish_color": Color("7c8494"), "hub_color": ORANGE,
	})


func _draw_bed_load(body: Node2D) -> void:
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-34, BELT), Vector2(-36, -58), Vector2(-60, -64), Vector2(-84, -58), Vector2(-86, BELT)]), Color("aeb7c6"), 4.5)
	Shapes.poly(body, Shapes.circle(21.0, Vector2(-58, -40), 24), Color("15131d"))
	Shapes.poly(body, Shapes.circle(12.0, Vector2(-58, -40), 18), Color("b9c0cc"))
	Shapes.poly(body, Shapes.circle(4.0, Vector2(-58, -40), 10), ORANGE)
	VehicleArt.soft(body, VehicleArt.rect(-108, -48, -90, BELT), Color("d8402f"), 3.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-104, -48), Vector2(-102, -54), Vector2(-96, -54), Vector2(-94, -48)]), TRIM, 2.4)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-107, -38), Vector2(-91, -38)]), Color("8f1f17"), 1.8)
	VehicleArt.soft(body, VehicleArt.rect(-86, -38, -66, BELT), Color("b98a4e"), 2.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-86, -30), Vector2(-66, -30)]), Color("7c5a2c"), 1.8)


func _draw_dashboard(body: Node2D) -> void:
	VehicleArt.stroke(body, PackedVector2Array([Vector2(46, -26), Vector2(40, -34), Vector2(32, -35)]), TRIM, 6.0)
	VehicleArt.stroke(body, VehicleArt.arc(Vector2(36, -42), 9.0, 0.0, TAU, 14), TRIM, 3.0, true)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-1, -26), Vector2(-1, -48)]), TRIM, 7.0)


func _draw_lower_body(body: Node2D) -> void:
	var lower := PackedVector2Array([
		Vector2(-114, BELT), Vector2(-26, BELT), Vector2(-8, BELT - 1), Vector2(40, BELT - 1), Vector2(62, -22), Vector2(102, -20),
		Vector2(112, -8), Vector2(114, 14), Vector2(109, SILL), Vector2(-110, SILL), Vector2(-114, 16),
	])
	VehicleArt.shaded(body, Shapes.rounded(lower, 5.0), BODY_LIGHT.lerp(BODY, 0.35), BODY_DARK)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-112, BELT + 1.5), Vector2(-28, BELT + 1.5)]), Color(BODY_LIGHT, 0.9), 2.5)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(62, -21), Vector2(102, -19)]), Color(BODY_LIGHT, 0.9), 2.5)
	VehicleArt.dirt(body, -112, 110, SILL, 16.0, Color("5a3d26"), 7)


func _draw_side_details(body: Node2D) -> void:
	var stripe: Array[PackedVector2Array] = [VehicleArt.rect(-113, -9, 108, -4), VehicleArt.rect(-113, -1.5, 109, 0.5)]
	VehicleArt.merged(body, stripe, ORANGE)
	var seam := Color(VehicleArt.SLATE, 0.6)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-5, BELT), Vector2(-6, 12), Vector2(-3, 20)]), seam, 1.6)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(44, BELT), Vector2(45, 10), Vector2(42, 18)]), seam, 1.6)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-26, BELT), Vector2(-27, 20)]), seam, 1.6)
	VehicleArt.handle(body, Vector2(34, -14), 11.0, VehicleArt.CHROME)
	VehicleArt.roundel(body, Vector2(19, 8), 9.5, VehicleArt.CREAM, VehicleArt.SLATE, "4")
	VehicleArt.mirror(body, Vector2(57, -29), TRIM)
	VehicleArt.soft(body, PackedVector2Array([Vector2(-38, 22), Vector2(30, 22), Vector2(28, 30), Vector2(-36, 30)]), TRIM, 3.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-34, 23.5), Vector2(26, 23.5)]), Color(VehicleArt.CHROME, 0.5), 1.4)
	VehicleArt.merged(body, [Shapes.circle(4.0, Vector2(-50, -8), 12)], TRIM)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(60, -26), Vector2(48, -50), Vector2(36, -69)]), TRIM, 4.2)
	VehicleArt.soft(body, PackedVector2Array([Vector2(33, -73), Vector2(40, -73), Vector2(40, -67), Vector2(33, -67)]), TRIM, 1.5)


func _draw_front(body: Node2D) -> void:
	VehicleArt.soft(body, PackedVector2Array([Vector2(101, -12), Vector2(111, -9), Vector2(113, 10), Vector2(101, 10)]), TRIM, 2.5)
	for k in 3:
		VehicleArt.stroke(body, PackedVector2Array([Vector2(103, -6 + k * 5.0), Vector2(112, -5 + k * 5.0)]), Color(VehicleArt.CHROME, 0.75), 1.5)
	VehicleArt.headlight(body, Vector2(103, -16), Vector2(11, 9), 22.0)
	VehicleArt.soft(body, PackedVector2Array([Vector2(96, 12), Vector2(119, 11), Vector2(120, 26), Vector2(108, 31), Vector2(96, 30)]), TRIM, 4.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(98, 14.5), Vector2(117, 14)]), Color(VehicleArt.CHROME, 0.7), 1.6)
	VehicleArt.merged(body, [Shapes.circle(4.5, Vector2(110, 22), 12)], Color("2b3142"))
	VehicleArt.merged(body, [Shapes.circle(2.5, Vector2(110, 22), 10)], ORANGE)
	VehicleArt.merged(body, [Shapes.circle(3.2, Vector2(100, 4), 10)], VehicleArt.LAMP)
	VehicleArt.soft(body, PackedVector2Array([Vector2(74, -26), Vector2(94, -25), Vector2(92, -20), Vector2(76, -20)]), BODY_DARK, 2.0)
	VehicleArt.merged(body, [PackedVector2Array([Vector2(106, 28), Vector2(101, 28), Vector2(101, 46), Vector2(106, 44)])], TRIM)


func _draw_rear(body: Node2D) -> void:
	VehicleArt.taillight(body, Vector2(-111, -13), Vector2(6, 15), 14.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-108, -17), Vector2(-109, 14), Vector2(-104, 18)]), Color(VehicleArt.SLATE, 0.55), 1.6)
	VehicleArt.handle(body, Vector2(-111, -2), 8.0, VehicleArt.CHROME)
	VehicleArt.soft(body, PackedVector2Array([Vector2(-117, 16), Vector2(-100, 16), Vector2(-100, 30), Vector2(-112, 30)]), TRIM, 3.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-114, 29), Vector2(-124, 29)]), Color("9aa3b5"), 3.4)
	VehicleArt.merged(body, [Shapes.circle(4.2, Vector2(-125, 27), 10)], Color("9aa3b5"))
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-98, 26), Vector2(-122, 31)]), VehicleArt.CHROME, 4.6)
	VehicleArt.merged(body, [Shapes.circle(2.2, Vector2(-122, 31), 8)], VehicleArt.INK)
	VehicleArt.merged(body, [PackedVector2Array([Vector2(-111, 30), Vector2(-106, 30), Vector2(-106, 47), Vector2(-111, 45)])], TRIM)


func _draw_roof(body: Node2D) -> void:
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-14, -73.5), Vector2(34, -73.5)]), Color(BODY_LIGHT, 0.9), 2.4)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-2, -73), Vector2(-2, -78), Vector2(30, -78), Vector2(30, -73)]), TRIM, 3.2)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-2, -81), Vector2(30, -81)]), TRIM, 5.0)
	for k in 4:
		VehicleArt.headlight(body, Vector2(2.0 + k * 8.5, -82), Vector2(6, 6), 14.0)


func _draw_arches(body: Node2D, overlay: Node2D) -> void:
	for i in wheel_xs.size():
		var center := Vector2(wheel_xs[i], mount_y + rest_offset)
		var cut := asin((center.y - SILL) / (wheel_radius + 8.0))
		Shapes.poly(body, VehicleArt.arc(center, wheel_radius + 6.0, PI + cut, TAU - cut, 16), VehicleArt.WELL)
		VehicleArt.stroke(overlay, VehicleArt.arc(center, wheel_radius + 9.0, PI + cut - 0.1, TAU - cut + 0.1, 16), TRIM, 7.0)
		VehicleArt.stroke(overlay, VehicleArt.arc(center, wheel_radius + 12.6, PI + cut + 0.05, TAU - cut - 0.05, 14), Color(VehicleArt.CHROME, 0.35), 1.6)
