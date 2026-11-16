class_name CoinBadge
extends PanelContainer
## The coin balance pill shown at the top of every menu screen. Updates itself.

const PULSE_SCALE := 1.12
const BORDER_COLOR := Color(1.0, 0.81, 0.29, 0.5)

var _label: Label


func _init() -> void:
	var style := UiKit.panel_style(Color(0.08, 0.05, 0.2, 0.85), 40, 10)
	style.border_color = BORDER_COLOR
	style.content_margin_left = 14
	style.content_margin_right = 26
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(0.0, 68.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_update_pivot)
	var row := UiKit.hbox(10)
	row.add_child(UiKit.coin_icon(46.0))
	_label = UiKit.label("0", 38)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_label)
	add_child(row)


func _ready() -> void:
	_label.text = UiKit.format_int(GameState.coins)
	GameState.coins_changed.connect(_on_coins_changed)


func _on_coins_changed(coins: int) -> void:
	var text_changed := _label.text != UiKit.format_int(coins)
	_label.text = UiKit.format_int(coins)
	if text_changed:
		_pulse()


func _pulse() -> void:
	scale = Vector2.ONE * PULSE_SCALE
	UiKit.tween(self).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(self, "scale", Vector2.ONE, 0.3)


func _update_pivot() -> void:
	pivot_offset = size * 0.5
