class_name StageSpec
extends RefCounted
## Pure data describing one stage: terrain-shape numbers, ground palette, sky and parallax
## layers, and which decoration set to use. Built by StageLibrary; read by Terrain and Backdrop.
## Friction and gravity come from Catalog.STAGES (the shared contract), not from here.

# --- identity and physics (copied from Catalog.STAGES) ---
var id := ""
var terrain_seed := 0
var bump_seed := 77 ## seed of the fine surface bumps
var friction := 1.0
var gravity := 820.0

# --- terrain shape: "hills", "dunes", "icy" or "craters" (see TerrainShape) ---
var shape := "hills"
var flat_start := 700.0 ## everything before this x is perfectly flat
var flat_end := 2000.0 ## the terrain reaches full strength by this x
var ramp_floor := 0.45 ## strength at flat_end, grows towards 1.0 with distance
var ramp_dist := 14000.0 ## distance scale of the difficulty ramp
var noise_frequency := 0.0011
var shape_params := {}

# --- ground look ---
var decor := "meadow" ## "meadow", "desert", "arctic" or "moon"
var ground_depths := PackedFloat32Array() ## rows of the ground fill, in px below the surface
var ground_colors: Array[Color] = [] ## one colour per row
var lit_color := Color.WHITE ## surface colour on slopes facing the light
var shade_color := Color.BLACK ## surface colour on slopes facing away
var light_dir := Vector2(0.55, -0.83) ## 2D direction towards the light (y up is negative)
var rim_color := Color.WHITE
var rim_glow := 0.16
var rim_width := 4.5
var strata_color := Color.WHITE
var strata_count := 4
var pebble_colors: Array[Color] = []

# --- sky ---
var sky_offsets: Array[float] = []
var sky_colors: Array[Color] = []
var sun_anchor := Vector2(0.7, 0.57)
var sun_size := 660.0
var sun_offsets: Array[float] = []
var sun_colors: Array[Color] = []
var rays_color := Color(0, 0, 0, 0) ## sun rays (alpha 0 = none)
var star_count := 0
var star_zone := 0.42 ## stars fill this fraction of the screen height from the top
var star_color := Color(1.0, 0.95, 0.85)
var cloud_hi := Color.WHITE
var cloud_lo := Color.WHITE
var cloud_alpha := 0.4
var birds := 0
var bird_color := Color.BLACK
var aurora := false
var earth := false
var snow := false
var foreground := "" ## kind of dark foreground silhouettes along the bottom edge
var foreground_color := Color.BLACK

## Parallax layers, back to front. Each is a Dictionary with a "type":
## "ridge" (factor, base, amp, freq, kind, props, top, bottom, glow), "haze" (top, color, alpha)
## or "clouds" (factor, drift, band, count, size).
var layers: Array[Dictionary] = []
