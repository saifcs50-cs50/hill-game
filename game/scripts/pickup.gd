class_name Pickup
extends Area2D
## Coin or fuel can floating above the track.

signal collected(kind: int)

enum { COIN, FUEL }

var kind := COIN

var _art := Node2D.new()
var _taken := false
var _phase := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var circle := CircleShape2D.new()
	circle.radius = 24.0 if kind == COIN else 36.0
	var collider := CollisionShape2D.new()
	collider.shape = circle
	add_child(collider)
	add_child(_art)
	if kind == COIN:
		_draw_coin()
	else:
		_draw_fuel()
	_phase = position.x * 0.01
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_phase += delta * 3.0
	_art.position.y = sin(_phase) * 5.0


func _glow(color: Color, size: float) -> void:
	var glow := Sprite2D.new()
	glow.texture = Shapes.glow_texture(64, color)
	glow.scale = Vector2.ONE * size / 64.0
	glow.material = Shapes.additive()
	_art.add_child(glow)


func _draw_coin() -> void:
	_glow(Color(1.0, 0.75, 0.25, 0.55), 110.0)
	Shapes.poly(_art, Shapes.circle(17.0), Color("f29a1f"))
	Shapes.poly(_art, Shapes.circle(13.0), Color("ffd45c"))
	Shapes.poly(_art, Shapes.circle(8.0), Color("ffbf3a"))
	Shapes.line(_art, PackedVector2Array([Vector2(-9, -3), Vector2(-4, -9)]), Color(1, 1, 1, 0.85), 3.0)


func _draw_fuel() -> void:
	_glow(Color(1.0, 0.35, 0.35, 0.5), 170.0)
	Shapes.line(_art, PackedVector2Array([Vector2(-8, -24), Vector2(-8, -31), Vector2(8, -31), Vector2(8, -24)]), Color("c9303f"), 5.0)
	Shapes.poly(_art, Shapes.rounded(PackedVector2Array([Vector2(-19, -24), Vector2(19, -24), Vector2(19, 24), Vector2(-19, 24)]), 6.0), Color("ff4d5e"))
	Shapes.poly(_art, Shapes.rounded(PackedVector2Array([Vector2(-19, 12), Vector2(19, 12), Vector2(19, 24), Vector2(-19, 24)]), 5.0), Color("c9303f"))
	Shapes.poly(_art, PackedVector2Array([Vector2(0, -14), Vector2(8, -1), Vector2(0, 7), Vector2(-8, -1)]), Color("fff1d6"))
	Shapes.poly(_art, Shapes.circle(6.5, Vector2(0, 1), 18), Color("fff1d6"))


func _on_body_entered(_body: Node) -> void:
	if _taken:
		return
	_taken = true
	collected.emit(kind)
	var tween := create_tween().set_parallel()
	tween.tween_property(_art, "scale", Vector2.ONE * 1.8, 0.2)
	tween.tween_property(_art, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
