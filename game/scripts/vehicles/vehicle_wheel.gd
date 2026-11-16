class_name VehicleWheel
extends RigidBody2D
## A wheel body that reports its ground contact each physics step: whether it touches, the
## surface normal, and the friction of whatever it touches.

var touching := false
var ground_normal := Vector2.UP
var ground_friction := 1.0


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var count := state.get_contact_count()
	touching = count > 0
	if not touching:
		return
	var best := 0
	var best_up := -2.0
	for i in count:
		var up := -state.get_contact_local_normal(i).y
		if up > best_up:
			best_up = up
			best = i
	var normal := state.get_contact_local_normal(best)
	ground_normal = normal if normal.y < 0.0 else -normal
	ground_friction = _surface_friction(state.get_contact_collider_object(best))


static func _surface_friction(collider: Object) -> float:
	var body := collider as PhysicsBody2D
	if body == null:
		return 1.0
	var material: PhysicsMaterial = null
	if body is StaticBody2D:
		material = (body as StaticBody2D).physics_material_override
	elif body is RigidBody2D:
		material = (body as RigidBody2D).physics_material_override
	return 1.0 if material == null else material.friction
