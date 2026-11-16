class_name VehiclePreview
extends RefCounted
## A non-physics visual copy of a vehicle for menus (garage and home screen). It uses the same
## art as the in-game vehicle, resting in its normal pose, scaled down to fit the preview box.

## The box the menus reserve for vehicle art, in art coordinates: origin at the chassis centre,
## tyre bottoms on GROUND_Y. Matches VehicleShowcase.ART_BOUNDS and ART_GROUND_Y.
const BOUNDS := Rect2(-150.0, -105.0, 300.0, 185.0)
const GROUND_Y := 70.0


static func build(vehicle_id: String) -> Node2D:
	var spec := VehicleSpecs.make(vehicle_id)
	var root := Node2D.new()
	var pose := Node2D.new()
	root.add_child(pose)
	var body := Node2D.new()
	pose.add_child(body)
	for strut in spec.struts:
		var hub := _hub(spec, strut.wheel) + strut.hub_offset
		Shapes.line(body, PackedVector2Array([strut.anchor, hub]), strut.color, strut.width)
	var overlay := Node2D.new()
	overlay.z_index = 1
	body.add_child(overlay)
	spec.draw_body(body, overlay)
	for i in spec.wheel_xs.size():
		var wheel := Node2D.new()
		wheel.position = _hub(spec, i)
		pose.add_child(wheel)
		spec.draw_wheel(wheel, i)
	_fit(pose, spec)
	return root


static func _hub(spec: VehicleSpec, wheel: int) -> Vector2:
	return Vector2(spec.wheel_xs[wheel], spec.mount_y + spec.rest_offset)


## Scales the pose down (never up) so it fits BOUNDS, centres it, and puts the tyres on GROUND_Y.
static func _fit(pose: Node2D, spec: VehicleSpec) -> void:
	var pts := PackedVector2Array()
	_collect(pose, Transform2D.IDENTITY, pts)
	var low := pts[0]
	var high := pts[0]
	for p in pts:
		low = Vector2(minf(low.x, p.x), minf(low.y, p.y))
		high = Vector2(maxf(high.x, p.x), maxf(high.y, p.y))
	var ride := spec.mount_y + spec.rest_offset + spec.wheel_radius
	var fit := minf(1.0, minf(BOUNDS.size.x / (high.x - low.x), (GROUND_Y - BOUNDS.position.y) / (ride - low.y)))
	pose.scale = Vector2.ONE * fit
	pose.position = Vector2(-(low.x + high.x) * 0.5 * fit, GROUND_Y - ride * fit)


## Gathers every visible vertex under `node` (glows and light beams are left out).
static func _collect(node: Node, xform: Transform2D, pts: PackedVector2Array) -> void:
	for child in node.get_children():
		var item := child as Node2D
		if item == null:
			continue
		var local := xform * item.transform
		if item is Polygon2D and item.material == null:
			for p in (item as Polygon2D).polygon:
				pts.append(local * p)
		elif item is Line2D:
			var half := (item as Line2D).width * 0.5
			for p in (item as Line2D).points:
				var at := local * p
				pts.append(at - Vector2(half, half))
				pts.append(at + Vector2(half, half))
		_collect(item, local, pts)
