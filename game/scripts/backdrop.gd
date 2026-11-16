class_name Backdrop
extends CanvasLayer
## A stage's sky and parallax scenery, all drawn in code and built once.
##
## Usage: `var backdrop := Backdrop.new(); backdrop.configure("arctic"); add_child(backdrop)`.
## Ridges, clouds and the foreground are periodic meshes that are only moved each frame
## (see ScrollLayer), so nothing is re-triangulated while playing.

const PERIOD := 2560.0
const DESIGN_HEIGHT := 720.0
const FOREGROUND_LAYER := 5
const TWINKLE_SPEED := 0.9


class Bird:
	extends Line2D
	var speed := 30.0
	var phase := 0.0
	var spread := 16.0
	var home_y := 0.0

	func tick(time: float, cam_x: float, width: float) -> void:
		var flap := sin(time * 5.0 + phase) * spread * 0.45
		points = PackedVector2Array([
			Vector2(-spread, flap), Vector2(-spread * 0.5, -spread * 0.2 + flap * 0.5), Vector2.ZERO,
			Vector2(spread * 0.5, -spread * 0.2 + flap * 0.5), Vector2(spread, flap)])
		var span := maxf(width, 1280.0) + 300.0
		position = Vector2(fposmod(phase * 211.0 + time * speed - cam_x * 0.03, span) - 150.0, home_y + sin(time * 0.6 + phase) * 14.0)


var stage_id := "meadow"

var _spec: StageSpec
var _scrollers: Array[ScrollLayer] = []
var _stars: Array[MeshInstance2D] = []
var _aurora: Array[MeshInstance2D] = []
var _birds: Array[Bird] = []
var _foreground: ScrollLayer
var _rays: MeshInstance2D
var _time := 0.0


func _init() -> void:
	configure("meadow")


## Chooses the stage. Call before add_child.
func configure(p_stage_id: String) -> void:
	_spec = StageLibrary.get_spec(p_stage_id)
	stage_id = _spec.id


func _ready() -> void:
	layer = -10
	_add_sky()
	if not _spec.sun_colors.is_empty():
		add_child(SkyBuilder.sun_rect(_spec))
	if _spec.rays_color.a > 0.0:
		_add_rays()
	if _spec.earth:
		_add_earth()
	if _spec.aurora:
		_add_aurora()
	for cfg in _spec.layers:
		match cfg["type"]:
			"ridge":
				_add_ridge(cfg)
			"haze":
				add_child(SkyBuilder.haze_rect(cfg))
			"clouds":
				_add_clouds(cfg)
	_add_birds()
	if _spec.snow:
		_add_snow()
	_add_foreground()


func _process(delta: float) -> void:
	_time += delta
	var viewport := get_viewport()
	var camera := viewport.get_camera_2d()
	var cam := camera.get_screen_center_position() if camera else Vector2.ZERO
	var size := viewport.get_visible_rect().size
	for scroller in _scrollers:
		scroller.track(cam, _time, size)
	if _foreground:
		_foreground.track(cam, _time, size)
	_animate_sky(cam, size)


func _add_sky() -> void:
	var sky := TextureRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.texture = SkyBuilder.sky_texture(_spec)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(sky)
	if _spec.star_count > 0:
		for mesh in SkyBuilder.star_meshes(_spec):
			var stars := mesh.apply()
			add_child(stars)
			_stars.append(stars)


func _add_rays() -> void:
	_rays = SkyBuilder.ray_mesh(_spec).apply()
	_rays.material = Shapes.additive()
	add_child(_rays)


func _add_earth() -> void:
	var glow := SkyBuilder.centered_rect(Vector2(0.2, 0.3), 560.0)
	var tex := Shapes.glow_texture(256, Color(0.35, 0.6, 1.0, 0.35))
	glow.texture = tex
	glow.material = Shapes.additive()
	add_child(glow)
	var globe := ColorRect.new()
	globe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	globe.anchor_left = 0.2
	globe.anchor_right = 0.2
	globe.anchor_top = 0.3
	globe.anchor_bottom = 0.3
	globe.offset_left = -130.0
	globe.offset_right = 130.0
	globe.offset_top = -130.0
	globe.offset_bottom = 130.0
	globe.material = EarthShader.make_material(_spec.terrain_seed)
	add_child(globe)


func _add_aurora() -> void:
	var anchors := [0.3, 0.22, 0.38]
	var meshes := SkyBuilder.aurora_meshes()
	for k in meshes.size():
		var node := meshes[k].apply()
		node.material = Shapes.additive()
		node.position = Vector2(0.0, DESIGN_HEIGHT * float(anchors[k]))
		node.set_meta("anchor", anchors[k])
		node.set_meta("phase", k * 2.1)
		add_child(node)
		_aurora.append(node)



func _add_ridge(cfg: Dictionary) -> void:
	var light_side := 1.0 if _spec.sun_anchor.x >= 0.5 else -1.0
	var ridge := ScrollLayer.new()
	ridge.factor = cfg["factor"]
	ridge.anchor = cfg["base"]
	ridge.period = PERIOD
	ridge.mesh = RidgeBuilder.build(cfg, PERIOD, light_side).to_mesh()
	add_child(ridge)
	_scrollers.append(ridge)


func _add_clouds(cfg: Dictionary) -> void:
	var band: Vector2 = cfg["band"]
	var clouds := ScrollLayer.new()
	clouds.factor = cfg["factor"]
	clouds.drift = cfg["drift"]
	clouds.anchor = band.x
	clouds.y_follow = 0.0
	clouds.period = PERIOD
	clouds.mesh = SkyBuilder.cloud_mesh(_spec, cfg, PERIOD).to_mesh()
	add_child(clouds)
	_scrollers.append(clouds)


func _add_birds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12 + _spec.terrain_seed
	for i in _spec.birds:
		var bird := Bird.new()
		bird.width = 2.2
		bird.default_color = _spec.bird_color
		bird.joint_mode = Line2D.LINE_JOINT_ROUND
		bird.begin_cap_mode = Line2D.LINE_CAP_ROUND
		bird.end_cap_mode = Line2D.LINE_CAP_ROUND
		bird.antialiased = true
		bird.speed = rng.randf_range(14.0, 34.0)
		bird.phase = rng.randf() * TAU
		bird.spread = rng.randf_range(9.0, 17.0)
		bird.home_y = rng.randf_range(0.14, 0.42) * DESIGN_HEIGHT
		add_child(bird)
		_birds.append(bird)


func _add_snow() -> void:
	add_child(SkyBuilder.snow_particles(60, 70.0, 0.55, 0.75))
	var front := CanvasLayer.new()
	front.layer = FOREGROUND_LAYER
	front.add_child(SkyBuilder.snow_particles(22, 170.0, 0.9, 0.55))
	add_child(front)


func _add_foreground() -> void:
	if _spec.foreground == "":
		return
	var front := CanvasLayer.new()
	front.layer = FOREGROUND_LAYER - 1
	_foreground = ScrollLayer.new()
	_foreground.factor = 1.45
	_foreground.anchor = 1.0
	_foreground.y_follow = 0.0
	_foreground.period = PERIOD
	_foreground.mesh = SkyBuilder.foreground_mesh(_spec, PERIOD).to_mesh()
	front.add_child(_foreground)
	add_child(front)


func _animate_sky(cam: Vector2, size: Vector2) -> void:
	if _rays:
		_rays.position = size * _spec.sun_anchor
		_rays.rotation = _time * 0.012
	for i in _stars.size():
		_stars[i].modulate.a = 0.78 + 0.22 * sin(_time * TWINKLE_SPEED * (1.0 + i * 0.4) + i * 2.0)
	for node in _aurora:
		var phase: float = node.get_meta("phase")
		node.position = Vector2(sin(_time * 0.12 + phase) * 50.0 - cam.x * 0.008, size.y * float(node.get_meta("anchor")))
		node.modulate.a = 0.65 + 0.35 * sin(_time * 0.35 + phase * 1.7)
		node.skew = sin(_time * 0.17 + phase) * 0.06
	for bird in _birds:
		bird.tick(_time, cam.x, size.x)
