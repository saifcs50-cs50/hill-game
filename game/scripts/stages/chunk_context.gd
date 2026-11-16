class_name ChunkContext
extends RefCounted
## Everything a decoration builder needs to know about one terrain chunk.
## Placement goes through y_at(), which interpolates the same samples the collision uses, so
## decoration sits exactly on the physical surface.

var index := 0
var spec: StageSpec
var shape: TerrainShape
var step := 40.0
var x0 := 0.0
var x1 := 0.0
var top := PackedVector2Array() ## surface points from x0 to x1 inclusive
var ext := PackedVector2Array() ## the same with one extra sample on each side (for slopes)
var rng := RandomNumberGenerator.new()


func y_at(x: float) -> float:
	var f := clampf((x - x0) / step, 0.0, float(top.size() - 1) - 0.0001)
	var i := int(f)
	return lerpf(top[i].y, top[i + 1].y, f - i)


func point_at(x: float) -> Vector2:
	return Vector2(x, y_at(x))


## Unit normal pointing out of the ground at x.
func normal_at(x: float) -> Vector2:
	var f := clampf((x - x0) / step, 0.0, float(top.size() - 1) - 0.0001)
	var i := int(f)
	var tangent := (top[i + 1] - top[i]).normalized()
	return Vector2(tangent.y, -tangent.x)


## 0 on slopes facing away from the light, 1 on slopes facing it.
func lit_at_normal(normal: Vector2) -> float:
	return clampf((normal.dot(spec.light_dir) - 0.1) / 0.85, 0.0, 1.0)


func lit_at(x: float) -> float:
	return lit_at_normal(normal_at(x))


## Random x inside this chunk, kept clear of the very edges.
func random_x(margin := 20.0) -> float:
	return rng.randf_range(x0 + margin, x1 - margin)
