class_name Terrain
extends Node2D
## Endless seeded stage terrain, built and freed in chunks around the player.
##
## Usage: `var terrain := Terrain.new(); terrain.configure("desert"); add_child(terrain)`.
## The ground's physics friction comes from Catalog.STAGES[stage].friction. Gravity is NOT
## applied here; main.gd sets it from Catalog.STAGES[stage].gravity.
## Shape numbers and palettes live in StageSpec/StageLibrary; heights come from TerrainShape.
## Physics collision is built at once; the visual detail is built a few ms per frame.

signal chunk_created(chunk: Node2D, index: int)

const STEP := 40.0
const CHUNK_SAMPLES := 64
const CHUNK_WIDTH := STEP * CHUNK_SAMPLES
const KEEP_BEHIND := 2400.0
const KEEP_AHEAD := 4400.0
const DECOR_BUDGET_USEC := 1000 ## per frame; a phone is several times slower than a laptop
const COLLISION_LAYER := 1

var stage_id := "meadow"

var _spec: StageSpec
var _shape: TerrainShape
var _chunks: Dictionary = {}
var _queue: Array = [] ## deferred build steps: [chunk, holder, builder, ctx]


func _init() -> void:
	configure("meadow")


## Chooses the stage. Call before add_child (and before the first update).
func configure(p_stage_id: String) -> void:
	assert(_chunks.is_empty(), "Terrain.configure must be called before chunks exist")
	_spec = StageLibrary.get_spec(p_stage_id)
	stage_id = _spec.id
	_shape = TerrainShape.new(_spec)


## Surface height (y grows downward) at a world x. Pure function of x and the stage.
func height_at(x: float) -> float:
	return _shape.height_at(x)


## The stage data this terrain was built from (palette, friction, gravity, ...).
func get_spec() -> StageSpec:
	return _spec


func update(center_x: float) -> void:
	var first := int(floor((center_x - KEEP_BEHIND) / CHUNK_WIDTH))
	var last := int(floor((center_x + KEEP_AHEAD) / CHUNK_WIDTH))
	var was_empty := _chunks.is_empty()
	for i in range(first, last + 1):
		if not _chunks.has(i):
			var chunk := _build_chunk(i)
			_chunks[i] = chunk
			chunk_created.emit(chunk, i)
	for i: int in _chunks.keys():
		if i < first or i > last:
			_chunks[i].queue_free()
			_chunks.erase(i)
	if was_empty:
		flush_decor()


## Builds all pending visual detail now (used at start-up, so the first frame is complete).
func flush_decor() -> void:
	_run_queue(INF)


func _process(_delta: float) -> void:
	if not _queue.is_empty():
		_run_queue(DECOR_BUDGET_USEC)


func _run_queue(budget_usec: float) -> void:
	var start := Time.get_ticks_usec()
	var ran := 0
	while not _queue.is_empty() and (ran == 0 or Time.get_ticks_usec() - start < budget_usec):
		var job: Array = _queue.pop_front()
		ran += 1
		var chunk: Node2D = job[0]
		if not is_instance_valid(chunk):
			continue
		var mesh := StageMesh.new()
		(job[2] as Callable).call(job[3], mesh)
		(job[1] as Node2D).add_child(mesh.apply())


func _build_chunk(index: int) -> Node2D:
	var ctx := _make_context(index)
	var chunk := Node2D.new()
	add_child(chunk)
	chunk.add_child(_make_body(ctx.top))
	var painter := ChunkPainter.new(ctx)
	chunk.set_meta("painter", painter) ## Callables do not keep their target alive
	for step: Array in painter.build(chunk):
		_queue.append([chunk, step[0], step[1], ctx])
	return chunk


func _make_context(index: int) -> ChunkContext:
	var ctx := ChunkContext.new()
	ctx.index = index
	ctx.spec = _spec
	ctx.shape = _shape
	ctx.step = STEP
	ctx.x0 = index * CHUNK_WIDTH
	ctx.x1 = ctx.x0 + CHUNK_WIDTH
	ctx.rng.seed = hash(index) ^ _spec.terrain_seed
	for i in range(-1, CHUNK_SAMPLES + 2):
		var x := ctx.x0 + i * STEP
		var p := Vector2(x, _shape.height_at(x))
		ctx.ext.append(p)
		if i >= 0 and i <= CHUNK_SAMPLES:
			ctx.top.append(p)
	return ctx


func _make_body(top: PackedVector2Array) -> StaticBody2D:
	var segments := PackedVector2Array()
	for i in range(top.size() - 1):
		segments.append(top[i])
		segments.append(top[i + 1])
	var shape := ConcavePolygonShape2D.new()
	shape.segments = segments
	var collider := CollisionShape2D.new()
	collider.shape = shape
	var material := PhysicsMaterial.new()
	material.friction = _spec.friction
	var body := StaticBody2D.new()
	body.collision_layer = COLLISION_LAYER
	body.collision_mask = 0
	body.physics_material_override = material
	body.add_child(collider)
	return body
