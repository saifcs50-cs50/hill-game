class_name MonsterSpec
extends VehicleSpec
## Monster truck: huge wheels, soft long-travel springs, high ride, all-wheel drive.
## Crimson shell with yellow bolts, chrome pipes and yellow shocks.

const BODY := Color("e8403c")
const BODY_LIGHT := Color("ff8a6a")
const BODY_DARK := Color("a2202f")
const BODY_DEEP := Color("6e1428")
const TRIM := Color("1a1620")
const YELLOW := Color("ffc928")
const BELT := -30.0
const SILL := 8.0

const OUTLINE: Array[Vector2] = [
	Vector2(-104, 8), Vector2(-108, -4), Vector2(-108, -30), Vector2(-34, -30), Vector2(-30, -70), Vector2(-22, -76),
	Vector2(30, -76), Vector2(54, -30), Vector2(100, -28), Vector2(110, -16), Vector2(112, -2), Vector2(108, 8),
]
const WINDOW: Array[Vector2] = [
	Vector2(-14, -34), Vector2(-14, -70), Vector2(22, -70), Vector2(28, -66), Vector2(48, -34),
]


func _init() -> void:
	mass = 22.0
	gyration = 72.0
	center_of_mass = Vector2(0.0, 16.0)
	angular_damp = 1.5
	hull = hull_from(OUTLINE, SILL, 30.0, 72.0, 6.0)
	dummy_pos = Vector2(4.0, -26.0)
	head_center = Vector2(7.0, -53.0)
	head_radius = 26.0
	wheel_radius = 44.0
	wheel_mass = 4.0
	wheel_xs = PackedFloat32Array([-72.0, 72.0])
	mount_y = -4.0
	rest_offset = 60.0
	travel = 100.0
	spring_k = 460.0
	spring_c = 42.0
	wheel_bounce = 0.15
	drive_torque = 440000.0
	drive_share = PackedFloat32Array([1.0, 1.0])
	brake_torque = 300000.0
	max_spin = 42.0
	reaction = 0.06
	air_accel = 4.0
	dust_color = Color(0.9, 0.7, 0.5, 0.32)
	add_strut(0, Vector2(-20, 14), 10.0, Color("2b2736"))
	add_strut(1, Vector2(20, 14), 10.0, Color("2b2736"))
	add_strut(0, Vector2(-52, -8), 7.0, YELLOW, Vector2(10, -6))
	add_strut(1, Vector2(52, -8), 7.0, YELLOW, Vector2(-10, -6))


func draw_body(body: Node2D, overlay: Node2D) -> Node2D:
	VehicleArt.beam(body, Vector2(108, -14), 340.0, 46.0)
	_draw_frame(body)
	VehicleArt.stroke(body, PackedVector2Array(OUTLINE), VehicleArt.INK, 5.0, true)
	_draw_exhausts(body)
	var cab := PackedVector2Array([Vector2(-34, -28), Vector2(-30, -70), Vector2(-22, -76), Vector2(30, -76), Vector2(54, -28)])
	VehicleArt.shaded(body, Shapes.rounded(cab, 7.0), BODY_LIGHT, BODY)
	VehicleArt.window_interior(body, PackedVector2Array(WINDOW))
	_draw_cage(body)
	var dummy := VehicleArt.add_dummy(body, dummy_pos)
	VehicleArt.glass_sheen(body, PackedVector2Array(WINDOW), Vector2(-6, -71), Vector2(-14, 36), 5.0)
	_draw_lower_body(body)
	_draw_decals(body)
	_draw_hood(body)
	_draw_front(body)
	_draw_rear(body)
	_draw_roof(body)
	_draw_flares(overlay)
	return dummy


func draw_wheel(wheel: Node2D, _index: int) -> void:
	VehicleArt.draw_wheel(wheel, wheel_radius, {
		"tread": 22, "depth": 7.0, "skew": 0.1, "rim": 0.5, "spokes": 0, "bolts": 12, "bolt_at": 0.84,
		"tyre": Color("141219"), "side": Color("1f1c27"),
		"rim_color": YELLOW, "dish_color": Color("3a3445"), "hub_color": Color("c8cfdb"),
	})


func _draw_frame(body: Node2D) -> void:
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-96, 14), Vector2(98, 14)]), TRIM, 9.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-96, 11), Vector2(98, 11)]), Color("3a3445"), 2.0)
	VehicleArt.soft(body, PackedVector2Array([Vector2(-18, 14), Vector2(20, 14), Vector2(14, 26), Vector2(-12, 26)]), Color("2b2736"), 3.0)


func _draw_exhausts(body: Node2D) -> void:
	for k in 2:
		var x := -64.0 + k * 12.0
		VehicleArt.stroke(body, PackedVector2Array([Vector2(x, -26), Vector2(x - 2, -64), Vector2(x - 6, -86)]), VehicleArt.CHROME, 6.0)
		VehicleArt.stroke(body, PackedVector2Array([Vector2(x - 1, -26), Vector2(x - 3, -64)]), Color(1, 1, 1, 0.45), 1.6)
		VehicleArt.merged(body, [Shapes.circle(3.4, Vector2(x - 6, -87), 10)], VehicleArt.INK)


func _draw_cage(body: Node2D) -> void:
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-12, -34), Vector2(-12, -68), Vector2(20, -68), Vector2(34, -44), Vector2(46, -34)]), Color(TRIM, 0.85), 3.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(36, -36), Vector2(30, -44), Vector2(24, -45)]), TRIM, 5.0)
	VehicleArt.stroke(body, VehicleArt.arc(Vector2(28, -50), 8.0, 0.0, TAU, 14), TRIM, 2.8, true)


func _draw_lower_body(body: Node2D) -> void:
	var lower := PackedVector2Array([
		Vector2(-108, BELT), Vector2(-34, BELT), Vector2(-14, BELT - 1), Vector2(50, BELT - 1), Vector2(54, BELT), Vector2(100, -28),
		Vector2(110, -16), Vector2(112, -2), Vector2(108, SILL), Vector2(-104, SILL), Vector2(-108, -4),
	])
	VehicleArt.shaded(body, Shapes.rounded(lower, 5.0), BODY_LIGHT.lerp(BODY, 0.4), BODY_DARK)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-106, BELT + 1.5), Vector2(-36, BELT + 1.5)]), Color(BODY_LIGHT, 0.85), 2.5)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(56, -27), Vector2(100, -26)]), Color(BODY_LIGHT, 0.85), 2.5)
	VehicleArt.dirt(body, -102, 106, SILL, 15.0, Color("4a2c20"), 11)


func _draw_decals(body: Node2D) -> void:
	var seam := Color(VehicleArt.SLATE, 0.65)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-14, BELT), Vector2(-15, -4), Vector2(-12, 4)]), seam, 1.6)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(44, BELT), Vector2(45, -6), Vector2(42, 3)]), seam, 1.6)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-34, BELT), Vector2(-35, 4)]), seam, 1.6)
	VehicleArt.handle(body, Vector2(34, -20), 10.0, VehicleArt.CHROME)
	var bolt := PackedVector2Array([Vector2(-102, -22), Vector2(-62, -26), Vector2(-68, -18), Vector2(-38, -22), Vector2(-76, -6), Vector2(-72, -13), Vector2(-102, -10)])
	var shadow := PackedVector2Array()
	for p in bolt:
		shadow.append(p + Vector2(1.6, 1.8))
	var shadow_shapes: Array[PackedVector2Array] = [shadow]
	VehicleArt.merged(body, shadow_shapes, Color(TRIM, 0.8))
	var bolt_shapes: Array[PackedVector2Array] = [bolt]
	VehicleArt.merged(body, bolt_shapes, YELLOW)
	VehicleArt.roundel(body, Vector2(15, -10), 9.5, YELLOW, TRIM, "5")
	VehicleArt.mirror(body, Vector2(52, -36), TRIM)


func _draw_hood(body: Node2D) -> void:
	VehicleArt.soft(body, PackedVector2Array([Vector2(64, -29), Vector2(70, -52), Vector2(90, -52), Vector2(94, -29)]), VehicleArt.CHROME, 3.0)
	VehicleArt.soft(body, PackedVector2Array([Vector2(69, -31), Vector2(72, -47), Vector2(88, -47), Vector2(90, -31)]), Color("22202c"), 2.0)
	for k in 4:
		VehicleArt.stroke(body, PackedVector2Array([Vector2(71 + k * 5.0, -31), Vector2(72 + k * 5.0, -46)]), Color(VehicleArt.CHROME, 0.55), 1.2)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(60, -30), Vector2(100, -29)]), Color(BODY_DEEP, 0.7), 1.4)


func _draw_front(body: Node2D) -> void:
	VehicleArt.soft(body, PackedVector2Array([Vector2(100, -24), Vector2(110, -18), Vector2(112, -4), Vector2(100, -4)]), TRIM, 2.5)
	for k in 3:
		VehicleArt.stroke(body, PackedVector2Array([Vector2(102, -19 + k * 5.0), Vector2(111, -17 + k * 5.0)]), Color(VehicleArt.CHROME, 0.7), 1.5)
	VehicleArt.headlight(body, Vector2(104, -26), Vector2(11, 8), 22.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(104, 6), Vector2(120, 6), Vector2(122, -8), Vector2(116, -10)]), VehicleArt.CHROME, 5.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(104, 6), Vector2(104, -4)]), VehicleArt.CHROME, 4.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(105, 4), Vector2(119, 4)]), Color(1, 1, 1, 0.5), 1.4)
	VehicleArt.merged(body, [Shapes.circle(3.0, Vector2(113, -1), 10)], VehicleArt.LAMP)


func _draw_rear(body: Node2D) -> void:
	VehicleArt.taillight(body, Vector2(-106, -18), Vector2(6, 14), 14.0)
	VehicleArt.soft(body, PackedVector2Array([Vector2(-114, -4), Vector2(-98, -4), Vector2(-98, 10), Vector2(-110, 10)]), TRIM, 3.0)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-112, -2.5), Vector2(-99, -2.5)]), Color(VehicleArt.CHROME, 0.7), 1.6)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-108, -30), Vector2(-109, -6)]), Color(VehicleArt.SLATE, 0.55), 1.6)


func _draw_roof(body: Node2D) -> void:
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-22, -77.5), Vector2(30, -77.5)]), Color(BODY_LIGHT, 0.9), 2.4)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-10, -77), Vector2(-10, -82), Vector2(24, -82), Vector2(24, -77)]), TRIM, 3.2)
	VehicleArt.stroke(body, PackedVector2Array([Vector2(-14, -85), Vector2(28, -85)]), TRIM, 5.0)
	for k in 5:
		VehicleArt.headlight(body, Vector2(-8.0 + k * 8.5, -86), Vector2(6, 6), 14.0)


func _draw_flares(overlay: Node2D) -> void:
	for i in wheel_xs.size():
		var center := Vector2(wheel_xs[i], mount_y + rest_offset)
		VehicleArt.stroke(overlay, VehicleArt.arc(center, wheel_radius + 9.0, PI * 1.12, PI * 1.88, 18), BODY_DARK, 9.0)
		VehicleArt.stroke(overlay, VehicleArt.arc(center, wheel_radius + 13.0, PI * 1.14, PI * 1.86, 16), Color(BODY_LIGHT, 0.75), 2.2)
		VehicleArt.stroke(overlay, VehicleArt.arc(center, wheel_radius + 4.5, PI * 1.12, PI * 1.88, 16), TRIM, 2.0)
