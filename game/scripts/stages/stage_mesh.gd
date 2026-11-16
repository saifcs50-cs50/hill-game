class_name StageMesh
extends RefCounted
## Collects coloured triangles and builds them into a single ArrayMesh, so a whole layer of
## decoration costs one draw call. Vertex colours carry all shading, including alpha.

var _verts := PackedVector2Array()
var _colors := PackedColorArray()
var _indices := PackedInt32Array()


func is_empty() -> bool:
	return _indices.is_empty()


func vertex_count() -> int:
	return _verts.size()


func vert(p: Vector2, color: Color) -> int:
	_verts.push_back(p)
	_colors.push_back(color)
	return _verts.size() - 1


func index_tri(a: int, b: int, c: int) -> void:
	_indices.push_back(a)
	_indices.push_back(b)
	_indices.push_back(c)


func tri(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	index_tri(vert(a, color), vert(b, color), vert(c, color))


func tri_gradient(a: Vector2, b: Vector2, c: Vector2, ca: Color, cb: Color, cc: Color) -> void:
	index_tri(vert(a, ca), vert(b, cb), vert(c, cc))


func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	var ia := vert(a, color)
	var ib := vert(b, color)
	var ic := vert(c, color)
	var id := vert(d, color)
	index_tri(ia, ib, ic)
	index_tri(ia, ic, id)


func quad_gradient(a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	var ia := vert(a, ca)
	var ib := vert(b, cb)
	var ic := vert(c, cc)
	var id := vert(d, cd)
	index_tri(ia, ib, ic)
	index_tri(ia, ic, id)


## A convex polygon as a triangle fan around its centre; the centre can have its own colour.
func fan(pts: PackedVector2Array, color: Color, center_color: Color = color) -> void:
	var count := pts.size()
	if count < 3:
		return
	var center := Vector2.ZERO
	for p in pts:
		center += p
	var ic := vert(center / count, center_color)
	var first := _verts.size()
	for p in pts:
		vert(p, color)
	for i in count:
		index_tri(ic, first + i, first + (i + 1) % count)


func ellipse(center: Vector2, rx: float, ry: float, color: Color, edge_color: Color = color, segments := 12) -> void:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * i / segments
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	var ic := vert(center, color)
	var first := _verts.size()
	for p in pts:
		vert(p, edge_color)
	for i in segments:
		index_tri(ic, first + i, first + (i + 1) % segments)


## A straight stroke from a to b, optionally tapering from width_a to width_b.
func line(a: Vector2, b: Vector2, width_a: float, color: Color, width_b := -1.0, color_b: Color = color) -> void:
	var dir := b - a
	if dir.length_squared() < 0.0001:
		return
	var n := Vector2(-dir.y, dir.x).normalized()
	var hb := (width_a if width_b < 0.0 else width_b) * 0.5
	quad_gradient(a + n * width_a * 0.5, a - n * width_a * 0.5, b - n * hb, b + n * hb, color, color, color_b, color_b)


## A stroke following several points, with round-ish joins from averaged normals.
func polyline(pts: PackedVector2Array, width: float, color: Color, color_end: Color = color) -> void:
	var count := pts.size()
	if count < 2:
		return
	var prev_left := -1
	var prev_right := -1
	for i in count:
		var dir := pts[mini(i + 1, count - 1)] - pts[maxi(i - 1, 0)]
		var n := Vector2(-dir.y, dir.x).normalized() * width * 0.5
		var c := color.lerp(color_end, float(i) / (count - 1))
		var left := vert(pts[i] + n, c)
		var right := vert(pts[i] - n, c)
		if prev_left >= 0:
			index_tri(prev_left, prev_right, right)
			index_tri(prev_left, right, left)
		prev_left = left
		prev_right = right


## A brush-stroke lens: thin at both ends, widest in the middle.
func lens_line(pts: PackedVector2Array, max_width: float, color: Color) -> void:
	var count := pts.size()
	if count < 2:
		return
	var prev_left := -1
	var prev_right := -1
	for i in count:
		var dir := pts[mini(i + 1, count - 1)] - pts[maxi(i - 1, 0)]
		var t := float(i) / (count - 1)
		var n := Vector2(-dir.y, dir.x).normalized() * max_width * 0.5 * pow(sin(PI * t), 0.7)
		var left := vert(pts[i] + n, color)
		var right := vert(pts[i] - n, color)
		if prev_left >= 0:
			index_tri(prev_left, prev_right, right)
			index_tri(prev_left, right, left)
		prev_left = left
		prev_right = right


## Joins rows of points into a surface. rows[r][i] pairs with colors[r][i]; every row must
## have the same length.
func grid(rows: Array[PackedVector2Array], colors: Array[PackedColorArray]) -> void:
	var first: Array[int] = []
	for r in rows.size():
		first.append(_verts.size())
		for i in rows[r].size():
			vert(rows[r][i], colors[r][i])
	for r in range(rows.size() - 1):
		for i in range(rows[r].size() - 1):
			var a := first[r] + i
			var b := first[r + 1] + i
			index_tri(a, a + 1, b)
			index_tri(a + 1, b + 1, b)


func to_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if _indices.is_empty():
		return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _verts
	arrays[Mesh.ARRAY_COLOR] = _colors
	arrays[Mesh.ARRAY_INDEX] = _indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Builds the mesh into a (new or given) MeshInstance2D.
func apply(target: MeshInstance2D = null) -> MeshInstance2D:
	var instance := target if target else MeshInstance2D.new()
	instance.mesh = to_mesh()
	return instance
