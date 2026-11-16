class_name ResultsPanel
extends CanvasLayer
## End-of-run panel: title (CRASHED! or OUT OF FUEL), distance, coins earned, a NEW BEST badge
## and two buttons. RETRY reloads the run, GARAGE returns to the menu with the garage open.
##
## Usage from main.gd:
##   var is_best := GameState.record_run(stage, vehicle, distance_m, coins)
##   GameState.add_coins(coins)
##   var panel := ResultsPanel.new()
##   add_child(panel)
##   panel.show_results("CRASHED!", distance_m, coins, is_best)

signal retry_pressed
signal garage_pressed

const LAYER := 20
const MENU_SCENE := "res://ui/menu.tscn"
const GARAGE_SCREEN := "garage"
const PANEL_WIDTH := 760.0
const BUTTON_HEIGHT := 104.0
const FADE_TIME := 0.25
const POP_TIME := 0.38
const POP_FROM := 0.86
const COUNT_UP_TIME := 0.8
const BADGE_PULSE := 1.08
const BADGE_PULSE_TIME := 0.5
const DIM_COLOR := Color(0.05, 0.02, 0.12, 0.66)
const CRASH_COLOR := Color("ff6b6b")
const TITLE_COLORS := {"OUT OF FUEL": UiKit.ORANGE}

var _dim: ColorRect
var _panel: PanelContainer
var _title: Label
var _badge: PanelContainer
var _distance: Label
var _coins: Label
var _balance: Label
var _leaving := false


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dim = ColorRect.new()
	_dim.color = DIM_COLOR
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.add_child(center)
	_panel = UiKit.panel(Color(0.09, 0.06, 0.22, 0.94), UiKit.PANEL_RADIUS, 30)
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	_panel.resized.connect(_update_pivot)
	center.add_child(_panel)
	_panel.add_child(_build_content())


## Shows the panel. `title` is "CRASHED!" or "OUT OF FUEL"; coins_earned is this run's coins.
## Call it after GameState.add_coins() so the balance line is up to date.
func show_results(title: String, distance_m: float, coins_earned: int, is_new_best: bool) -> void:
	_title.text = title
	_title.label_settings.font_color = TITLE_COLORS.get(title, CRASH_COLOR)
	_coins.text = "+%s coins" % UiKit.format_int(coins_earned)
	_balance.text = "Bank: %s coins" % UiKit.format_int(GameState.coins)
	_badge.visible = is_new_best
	_set_distance(0.0)
	_dim.visible = true
	_animate_in(distance_m, is_new_best)


func _build_content() -> VBoxContainer:
	var column := UiKit.vbox(8)
	_title = UiKit.label("", 80, CRASH_COLOR, true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_badge = _build_badge()
	column.add_child(_badge)
	var caption := UiKit.label("DISTANCE", 22, UiKit.CREAM_DIM)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	_distance = UiKit.label("0 m", 88, UiKit.TEAL, true)
	_distance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_distance)
	column.add_child(_build_coin_row())
	_balance = UiKit.label("", 22, UiKit.CREAM_DIM)
	_balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_balance)
	column.add_child(UiKit.spacer_fixed(6.0))
	column.add_child(_build_buttons())
	return column


func _build_badge() -> PanelContainer:
	var badge := UiKit.panel(UiKit.ORANGE, 22, 6, false)
	var badge_style: StyleBoxFlat = badge.get_theme_stylebox("panel")
	badge_style.content_margin_left = 22
	badge_style.content_margin_right = 22
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.resized.connect(func() -> void: badge.pivot_offset = badge.size * 0.5)
	var text := UiKit.label("NEW BEST!", 28, UiKit.INK)
	text.label_settings.shadow_color.a = 0.0
	badge.add_child(text)
	return badge


func _build_coin_row() -> HBoxContainer:
	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UiKit.coin_icon(48.0))
	_coins = UiKit.label("", 44, UiKit.GOLD)
	row.add_child(_coins)
	return row


func _build_buttons() -> HBoxContainer:
	var row := UiKit.hbox(18)
	var retry := UiButton.create("RETRY", UiButton.Kind.PRIMARY, BUTTON_HEIGHT, 40)
	retry.name = "Retry"
	retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry.pressed.connect(_on_retry)
	row.add_child(retry)
	var garage := UiButton.create("GARAGE", UiButton.Kind.SECONDARY, BUTTON_HEIGHT, 40)
	garage.name = "Garage"
	garage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	garage.pressed.connect(_on_garage)
	row.add_child(garage)
	return row


func _animate_in(distance_m: float, is_new_best: bool) -> void:
	_dim.modulate.a = 0.0
	_panel.scale = Vector2.ONE * POP_FROM
	var fade := UiKit.tween(self).set_parallel(true)
	fade.tween_property(_dim, "modulate:a", 1.0, FADE_TIME)
	fade.tween_property(_panel, "scale", Vector2.ONE, POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	fade.tween_method(_set_distance, 0.0, distance_m, COUNT_UP_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if is_new_best:
		_badge.scale = Vector2.ONE
		var pulse := UiKit.tween(_badge).set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse.tween_property(_badge, "scale", Vector2.ONE * BADGE_PULSE, BADGE_PULSE_TIME)
		pulse.tween_property(_badge, "scale", Vector2.ONE, BADGE_PULSE_TIME)


func _set_distance(value: float) -> void:
	_distance.text = "%s m" % UiKit.format_int(int(value))


func _update_pivot() -> void:
	_panel.pivot_offset = _panel.size * 0.5


func _on_retry() -> void:
	if _leaving:
		return
	_leaving = true
	Engine.time_scale = 1.0
	retry_pressed.emit()
	get_tree().reload_current_scene()


func _on_garage() -> void:
	if _leaving:
		return
	_leaving = true
	Engine.time_scale = 1.0
	GameState.pending_screen = GARAGE_SCREEN
	garage_pressed.emit()
	get_tree().change_scene_to_file(MENU_SCENE)
