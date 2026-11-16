class_name Hud
extends CanvasLayer
## Distance, coins, fuel, the two pedals and the end-of-run overlay.

const INK := Color("1b1238")
const PANEL := Color(0.09, 0.06, 0.2, 0.42)
const PANEL_PRESSED := Color(1.0, 0.72, 0.42, 0.6)
const FUEL_OK := Color("3fe0c5")
const FUEL_LOW := Color("ff4d5e")
const TRICK_COLOR := Color("ffd45c")
const TRICK_TOP := 150.0
const TRICK_STEP := 54.0
const TRICK_HOLD := 1.1

var _distance: Label
var _best: Label
var _coins: Label
var _fuel: ProgressBar
var _fuel_fill := StyleBoxFlat.new()
var _pedals := {}
var _overlay: Control
var _title: Label
var _summary: Label
var _tricks: Array[Label] = []


func _ready() -> void:
	layer = 10
	_distance = _label(Vector2(0, 0), Vector2(56, 26), Vector2(420, 60), 46, HORIZONTAL_ALIGNMENT_LEFT)
	_best = _label(Vector2(0, 0), Vector2(58, 84), Vector2(420, 34), 22, HORIZONTAL_ALIGNMENT_LEFT)
	_coins = _label(Vector2(1, 0), Vector2(-476, 26), Vector2(420, 60), 46, HORIZONTAL_ALIGNMENT_RIGHT)
	_label(Vector2(0.5, 0), Vector2(-190, 64), Vector2(380, 30), 18, HORIZONTAL_ALIGNMENT_CENTER).text = "FUEL"
	_fuel = ProgressBar.new()
	_fuel.show_percentage = false
	_fuel.max_value = 1.0
	_fuel.add_theme_stylebox_override("background", _box(Color(0.09, 0.06, 0.2, 0.55), 13))
	_fuel_fill.set_corner_radius_all(13)
	_fuel.add_theme_stylebox_override("fill", _fuel_fill)
	_place(_fuel, Vector2(0.5, 0), Vector2(-190, 34), Vector2(380, 26))
	_pedals[false] = _pedal(Vector2(0, 1), Vector2(56, -230), "BRAKE")
	_pedals[true] = _pedal(Vector2(1, 1), Vector2(-256, -230), "GAS")
	_build_overlay()


func set_stats(distance_m: float, best_m: float, coins: int, fuel: float) -> void:
	_distance.text = "%d m" % distance_m
	_best.text = "BEST %d m" % best_m
	_coins.text = "%d coins" % coins
	_fuel.value = fuel
	_fuel_fill.bg_color = FUEL_LOW if fuel < 0.25 else FUEL_OK


func set_pedals(gas: bool, brake: bool) -> void:
	_pedals[true].get_theme_stylebox("panel").bg_color = PANEL_PRESSED if gas else PANEL
	_pedals[false].get_theme_stylebox("panel").bg_color = PANEL_PRESSED if brake else PANEL


## Pops a trick callout that rises, then fades; older callouts move up out of the way.
func show_trick(text: String, coins: int, combo: int) -> void:
	for older in _tricks:
		if is_instance_valid(older):
			create_tween().tween_property(older, "offset_top", older.offset_top - TRICK_STEP, 0.15)
	var label := _label(Vector2(0.5, 0), Vector2(-500, TRICK_TOP), Vector2(1000, 56), 40, HORIZONTAL_ALIGNMENT_CENTER)
	label.label_settings.font_color = TRICK_COLOR
	label.text = "%s   +%d" % [text, coins] + ("   COMBO x%d" % combo if combo > 1 else "")
	label.pivot_offset = Vector2(500, 28)
	label.scale = Vector2.ONE * 1.5
	_tricks.append(label)
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(TRICK_HOLD)
	tween.tween_property(label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		_tricks.erase(label)
		label.queue_free())


func show_end(title: String, summary: String) -> void:
	_title.text = title
	_summary.text = summary
	_overlay.visible = true


func _build_overlay() -> void:
	_overlay = ColorRect.new()
	(_overlay as ColorRect).color = Color(0.05, 0.02, 0.12, 0.5)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	add_child(_overlay)
	_title = _label(Vector2(0.5, 0.5), Vector2(-500, -130), Vector2(1000, 110), 92, HORIZONTAL_ALIGNMENT_CENTER, _overlay)
	_summary = _label(Vector2(0.5, 0.5), Vector2(-500, -10), Vector2(1000, 60), 40, HORIZONTAL_ALIGNMENT_CENTER, _overlay)
	_label(Vector2(0.5, 0.5), Vector2(-500, 70), Vector2(1000, 50), 28, HORIZONTAL_ALIGNMENT_CENTER, _overlay).text = "Tap to try again"


func _pedal(anchor: Vector2, offset: Vector2, text: String) -> Panel:
	var panel := Panel.new()
	var box := _box(PANEL, 40)
	box.set_border_width_all(3)
	box.border_color = Color(1, 1, 1, 0.4)
	panel.add_theme_stylebox_override("panel", box)
	_place(panel, anchor, offset, Vector2(200, 180))
	var label := _label(Vector2(0, 0), Vector2(0, 0), Vector2(200, 180), 34, HORIZONTAL_ALIGNMENT_CENTER, panel)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = text
	return panel


func _label(anchor: Vector2, offset: Vector2, size: Vector2, font_size: int, align: HorizontalAlignment, parent: Node = self) -> Label:
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = Color("fff6e6")
	settings.outline_size = maxi(font_size / 5, 4)
	settings.outline_color = INK
	var label := Label.new()
	label.label_settings = settings
	label.horizontal_alignment = align
	_place(label, anchor, offset, size, parent)
	return label


func _place(control: Control, anchor: Vector2, offset: Vector2, size: Vector2, parent: Node = self) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = offset.x
	control.offset_top = offset.y
	control.offset_right = offset.x + size.x
	control.offset_bottom = offset.y + size.y
	parent.add_child(control)


func _box(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box
