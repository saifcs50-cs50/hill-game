class_name ScrollLayer
extends MeshInstance2D
## A wide mesh, built once, that repeats every `period` px and is simply moved each frame:
## parallax layers never rebuild or re-triangulate anything while the game runs.
## The mesh must be two periods wide and the screen no wider than one period.

var factor := 0.1 ## horizontal parallax: 0 = fixed to the screen, 1 = moves with the world
var drift := 0.0 ## extra sideways motion in px/s (clouds)
var anchor := 0.6 ## screen-height fraction where the mesh's local y = 0 sits
var y_follow := 0.3 ## how much the layer follows the camera's vertical movement
var period := 2560.0


func track(cam: Vector2, time: float, size: Vector2) -> void:
	var offset := cam.x * factor + time * drift
	var y := size.y * anchor - clampf(cam.y * factor * y_follow, -60.0, 60.0)
	position = Vector2(-fposmod(offset, period), y)
