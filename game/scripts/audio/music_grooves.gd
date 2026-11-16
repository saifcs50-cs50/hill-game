class_name MusicGrooves
extends RefCounted
## Percussion-only groove tables, one per stage mood. No melodic or harmonic instruments.
##
## A pattern is one bar of sixteenth notes: '.' is a rest and '1'-'9' is the hit strength. Each
## track lists one or more pattern variants, and `form` picks the variant for each bar of the loop
## (a track with fewer variants wraps round). Tracks are the hit names in MusicBank.HIT_NAMES.
## Rhythms borrow the Middle-Eastern hand-drum vocabulary (maqsum, saidi).

const STEPS_PER_BAR := 16
const REST := "."
const SILENT_BAR := "................"
const DEFAULT_STAGE := "meadow"

const GROOVES := {
	## Relaxed: slow maqsum with a lazy swing and a soft shaker.
	"meadow": {
		"tempo": 92.0, "swing": 0.10, "seed": 101, "peak": 0.80,
		"form": [0, 0, 1, 0, 0, 0, 1, 2],
		"tracks": {
			"dum": ["9.....4.8.....3.", "9.....4.8...3.5.", "9.....4.8.5.6.8."],
			"tak": ["..7...6.....6...", "..7...6...5.6.5.", "..7.5.6.5.6.7.8."],
			"shake": ["4.3.4.3.4.3.4.3.", "5.3.5.3.5.3.5.3."],
			"clap": [SILENT_BAR, "............4...", "......3.....5.6."],
			"rim": [SILENT_BAR, "..........3.....", "........3.4.5.6."],
		},
	},
	## Driving: straight, forward-leaning saidi feel, busy shaker, backbeat claps.
	"desert": {
		"tempo": 112.0, "swing": 0.0, "seed": 202, "peak": 0.88,
		"form": [0, 0, 0, 1, 0, 0, 1, 2],
		"tracks": {
			"dum": ["9...5.6.9...5.6.", "9...5.6.9.5.5.6.", "9.5.5.6.9.5.6.7."],
			"tak": ["..4...4...4...4.", "..4.6.4...4.6.4.", "..5.6.5.6.5.6.7."],
			"shake": ["6.4.6.4.6.4.6.4.", "6343634363436343"],
			"clap": ["....7.......7...", "....7.......7.5.", "....7...7...7.8."],
			"rim": [SILENT_BAR, "..5...5...5...5.", "..5.5.5.5.5.5.5."],
		},
	},
	## Sparse: wide gaps, a hushed shaker and the odd dry tap.
	"arctic": {
		"tempo": 76.0, "swing": 0.0, "seed": 303, "peak": 0.76,
		"form": [0, 0, 1, 0, 0, 1, 0, 2],
		"tracks": {
			"dum": ["8...............", "8.......3...4...", "8.......5......."],
			"tak": ["........3.......", "......4.....3...", "......5.....4.3."],
			"shake": ["..2.......2.....", "..2...2...2...2."],
			"rim": [SILENT_BAR, "............4...", "........3...4..."],
		},
	},
	## Minimal: a slow heartbeat, a soft tick and almost nothing else.
	"moon": {
		"tempo": 68.0, "swing": 0.0, "seed": 404, "peak": 0.68,
		"form": [0, 0, 0, 1, 0, 0, 1, 1],
		"tracks": {
			"dum": ["7...............", "7.......4......."],
			"rim": ["....4.......3...", "....4.......3.4."],
			"shake": [SILENT_BAR, "..........2....."],
			"tom": [SILENT_BAR, "...........4...."],
		},
	},
}


static func stage_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in GROOVES:
		ids.append(id)
	return ids


## The groove for a stage id; unknown ids fall back to the meadow groove.
static func get_groove(stage_id: String) -> Dictionary:
	return GROOVES.get(stage_id, GROOVES[DEFAULT_STAGE])


## Lists every problem in the tables (empty when all is well); used by the tests.
static func validate() -> Array[String]:
	var problems: Array[String] = []
	for id: String in GROOVES:
		var groove: Dictionary = GROOVES[id]
		var tracks: Dictionary = groove["tracks"]
		var form: Array = groove["form"]
		for track: String in tracks:
			var variants: Array = tracks[track]
			if variants.is_empty():
				problems.append("%s/%s has no patterns" % [id, track])
			for pattern: String in variants:
				if pattern.length() != STEPS_PER_BAR:
					problems.append("%s/%s pattern '%s' is not %d steps" % [id, track, pattern, STEPS_PER_BAR])
		if form.size() < 8 or form.size() > 16:
			problems.append("%s form has %d bars (want 8-16)" % [id, form.size()])
	return problems
