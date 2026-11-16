class_name MenuScreen
extends MarginContainer
## Base for every menu screen: full-rect with the 48 px safe margins and a shared header
## (BACK button, title, coin balance). Screens ask the menu to switch with `navigate`.

signal navigate(screen_id: String)

const HEADER_GAP := 12
const BACK_WIDTH := 210.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		add_theme_constant_override("margin_" + side, UiKit.MARGIN)


## Page skeleton: header on top, then the returned body container filling the rest.
func build_page(title: String, subtitle: String = "") -> VBoxContainer:
	var page := UiKit.vbox(HEADER_GAP)
	add_child(page)
	page.add_child(_build_header(title, subtitle))
	return page


func go(screen_id: String) -> void:
	navigate.emit(screen_id)


func _build_header(title: String, subtitle: String) -> HBoxContainer:
	var row := UiKit.hbox(24)
	var back := UiButton.create("BACK", UiButton.Kind.GHOST, UiKit.BUTTON_HEIGHT, 30)
	back.name = "Back"
	back.glyph = "back"
	back.custom_minimum_size.x = BACK_WIDTH
	back.pressed.connect(go.bind("main"))
	row.add_child(back)
	var titles := UiKit.vbox(0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.add_child(UiKit.label(title, 56, UiKit.CREAM, true))
	if not subtitle.is_empty():
		titles.add_child(UiKit.label(subtitle, 22, UiKit.CREAM_DIM))
	row.add_child(titles)
	var badge := CoinBadge.new()
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(badge)
	return row
