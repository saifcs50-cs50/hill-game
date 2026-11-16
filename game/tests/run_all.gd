extends SceneTree
## Headless test runner: `$GODOT --headless --path game -s res://tests/run_all.gd`.
## Exits with code 1 if any check fails.

var _failures := 0
var _checks := 0


func _initialize() -> void:
	_test_upgrade_costs()
	_test_upgrade_effects()
	_test_terrain_is_deterministic()
	_test_stunt_flip_count()
	print("TESTS %d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)


func _test_upgrade_costs() -> void:
	for id: String in Catalog.VEHICLE_ORDER:
		var previous := 0
		for level in Catalog.MAX_UPGRADE_LEVEL:
			var cost := Catalog.upgrade_cost(id, level)
			_check(cost > previous, "%s upgrade cost must rise at level %d (%d <= %d)" % [id, level, cost, previous])
			_check(cost % 10 == 0, "%s upgrade cost %d should be a round number" % [id, cost])
			previous = cost
	_check(Catalog.upgrade_cost("hatchback", 0) <= 200, "first hatchback upgrade must be affordable after about one run")


func _test_upgrade_effects() -> void:
	_check(is_equal_approx(Catalog.upgrade_effect("engine", 0), 1.0), "stock engine is x1")
	_check(Catalog.upgrade_effect("engine", 10) > Catalog.upgrade_effect("engine", 5), "engine upgrades must help")
	_check(is_equal_approx(Catalog.upgrade_effect("suspension", 10), 1.0), "max suspension quality is 1")


func _test_terrain_is_deterministic() -> void:
	var a := Terrain.new()
	var b := Terrain.new()
	for x in [0.0, 650.0, 1234.5, 9000.0, 52000.0]:
		_check(is_equal_approx(a.height_at(x), b.height_at(x)), "terrain height must match at x=%s" % x)
	_check(is_equal_approx(a.height_at(0.0), a.height_at(500.0)), "the start area must be flat")
	a.free()
	b.free()


func _test_stunt_flip_count() -> void:
	var tolerance := Stunts.FLIP_TOLERANCE
	_check(int((TAU - 0.4 + tolerance) / TAU) == 1, "a slightly short rotation still counts as a flip")
	_check(int((PI + tolerance) / TAU) == 0, "half a rotation is not a flip")
	_check(int((2.0 * TAU + tolerance) / TAU) == 2, "two rotations count as two flips")
