class_name GarageScreen
extends MenuScreen
## Garage: browse the vehicles left and right, see their stats, buy or select one, and spend
## coins on the four upgrades.

const STAT_ORDER: Array[String] = ["speed", "grip", "stability"]
const STAT_NAMES := {"speed": "SPEED", "grip": "GRIP", "stability": "STABILITY"}
const STAT_MAX := 5
const ROW_HEIGHT := 116.0
const ARROW_SIZE := Vector2(88.0, 150.0)
const UPGRADE_BUTTON_WIDTH := 218.0
const EFFECT_TEXT := {
	"engine": "Power +%d%%",
	"tyres": "Grip +%d%%",
	"fuel": "Fuel tank +%d%%",
	"suspension": "Ride quality %d%%",
}

var _index := 0
var _showcase: VehicleShowcase
var _dots: PageDots
var _name_label: Label
var _tag_panel: PanelContainer
var _tag_label: Label
var _blurb: Label
var _stat_bars := {}
var _hint: Label
var _action: UiButton
var _rows := {}


func _ready() -> void:
	_index = maxi(Catalog.VEHICLE_ORDER.find(GameState.selected_vehicle), 0)
	var page := build_page("GARAGE")
	var body := UiKit.hbox(20)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)
	var left := _build_vehicle_panel()
	left.size_flags_stretch_ratio = 1.15
	body.add_child(left)
	body.add_child(_build_upgrade_panel())
	GameState.progress_changed.connect(_refresh)
	GameState.coins_changed.connect(_on_coins_changed)
	_refresh()
	_showcase.show_vehicle(_current_id(), GameState.owns_vehicle(_current_id()))


## Jumps to a vehicle by id (used by the menu's test hooks and handy for deep links).
func show_vehicle_id(vehicle_id: String) -> void:
	var index := Catalog.VEHICLE_ORDER.find(vehicle_id)
	if index >= 0:
		_index = index
		_show_current(0)


func _current_id() -> String:
	return Catalog.VEHICLE_ORDER[_index]


# Building

func _build_vehicle_panel() -> PanelContainer:
	var panel := UiKit.panel(UiKit.PANEL_FILL, UiKit.PANEL_RADIUS, 14)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := UiKit.vbox(6)
	panel.add_child(column)
	column.add_child(_build_carousel())
	_dots = PageDots.new()
	column.add_child(_dots)
	column.add_child(_build_name_row())
	_blurb = UiKit.label("", 22, UiKit.CREAM_DIM)
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.custom_minimum_size = Vector2(0.0, 56.0)
	column.add_child(_blurb)
	column.add_child(_build_stats())
	column.add_child(_build_action_row())
	return panel


func _build_carousel() -> HBoxContainer:
	var row := UiKit.hbox(8)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_build_arrow("PrevVehicle", "left", -1))
	_showcase = VehicleShowcase.new()
	_showcase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_showcase.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_showcase.custom_minimum_size = Vector2(200.0, 150.0)
	row.add_child(_showcase)
	row.add_child(_build_arrow("NextVehicle", "right", 1))
	return row


func _build_arrow(node_name: String, glyph_name: String, step: int) -> UiButton:
	var button := UiButton.create("", UiButton.Kind.GHOST, ARROW_SIZE.y)
	button.name = node_name
	button.glyph = glyph_name
	button.custom_minimum_size = ARROW_SIZE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(_browse.bind(step))
	return button


func _build_name_row() -> HBoxContainer:
	var row := UiKit.hbox(12)
	_name_label = UiKit.label("", 40, UiKit.CREAM, true)
	row.add_child(_name_label)
	row.add_child(UiKit.spacer())
	_tag_panel = UiKit.panel(Color(1.0, 1.0, 1.0, 0.12), 20, 8, false)
	_tag_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_tag_label = UiKit.label("", 20)
	_tag_panel.add_child(_tag_label)
	row.add_child(_tag_panel)
	return row


func _build_stats() -> HBoxContainer:
	var row := UiKit.hbox(18)
	for stat in STAT_ORDER:
		var cell := UiKit.vbox(4)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(UiKit.label(STAT_NAMES[stat], 20, UiKit.CREAM_DIM))
		var bar := PipBar.new()
		bar.custom_minimum_size = Vector2(0.0, 16.0)
		cell.add_child(bar)
		row.add_child(cell)
		_stat_bars[stat] = bar
	return row


func _build_action_row() -> HBoxContainer:
	var row := UiKit.hbox(14)
	_hint = UiKit.label("", 20, UiKit.CREAM_DIM)
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_hint)
	_action = UiButton.create("", UiButton.Kind.PRIMARY, UiKit.BUTTON_HEIGHT)
	_action.name = "Action"
	_action.custom_minimum_size.x = 270.0
	_action.pressed.connect(_on_action)
	row.add_child(_action)
	return row


func _build_upgrade_panel() -> PanelContainer:
	var panel := UiKit.panel(UiKit.PANEL_FILL, UiKit.PANEL_RADIUS, 14)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := UiKit.vbox(8)
	panel.add_child(column)
	for key: String in Catalog.UPGRADE_KEYS:
		column.add_child(_build_upgrade_row(key))
	return panel


func _build_upgrade_row(key: String) -> PanelContainer:
	var card := UiKit.panel(UiKit.INSET_FILL, 22, 10, false)
	card.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var row := UiKit.hbox(14)
	card.add_child(row)
	var info := UiKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	var top := UiKit.hbox(8)
	top.add_child(UiKit.label(Catalog.UPGRADE_NAMES[key], 28))
	top.add_child(UiKit.spacer())
	var level_label := UiKit.label("", 22, UiKit.CREAM_DIM)
	top.add_child(level_label)
	info.add_child(top)
	var bars := PipBar.new()
	bars.custom_minimum_size = Vector2(0.0, 18.0)
	info.add_child(bars)
	var effect := UiKit.label("", 20, UiKit.CREAM_DIM)
	info.add_child(effect)
	row.add_child(info)
	var button := UiButton.create("", UiButton.Kind.PRIMARY, UiKit.BUTTON_HEIGHT)
	button.name = "Upgrade_" + key
	button.custom_minimum_size.x = UPGRADE_BUTTON_WIDTH
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(_on_upgrade.bind(key))
	row.add_child(button)
	_rows[key] = {"bars": bars, "level": level_label, "effect": effect, "button": button}
	return card


# Updating

func _refresh() -> void:
	var id := _current_id()
	var data: Dictionary = Catalog.VEHICLES[id]
	var owned := GameState.owns_vehicle(id)
	_name_label.text = data["name"]
	_blurb.text = data["blurb"]
	var stats: Dictionary = data["stats"]
	for stat: String in STAT_ORDER:
		(_stat_bars[stat] as PipBar).configure(STAT_MAX, stats[stat], UiKit.ORANGE if stat == "speed" else UiKit.TEAL)
	_showcase.set_owned(owned)
	_update_tag(id, owned)
	_update_dots()
	_update_action(id, owned)
	_update_upgrades(id, owned)


func _update_tag(id: String, owned: bool) -> void:
	var text := "LOCKED"
	var color := UiKit.ORANGE
	if owned:
		text = "SELECTED" if id == GameState.selected_vehicle else "OWNED"
		color = UiKit.TEAL if id == GameState.selected_vehicle else UiKit.CREAM
	_tag_label.text = text
	_tag_label.label_settings.font_color = color
	var style: StyleBoxFlat = _tag_panel.get_theme_stylebox("panel")
	style.bg_color = Color(color, 0.16)
	style.border_color = Color(color, 0.5)


func _update_dots() -> void:
	var lit: Array[bool] = []
	for vehicle_id in Catalog.VEHICLE_ORDER:
		lit.append(GameState.owns_vehicle(vehicle_id))
	_dots.set_state(_index, lit)


func _update_action(id: String, owned: bool) -> void:
	var price: int = Catalog.VEHICLES[id]["price"]
	if not owned:
		_action.apply_kind(UiButton.Kind.PRIMARY)
		_action.set_rows("BUY", price)
		_action.set_enabled(GameState.can_afford(price))
		_hint.text = "Tap BUY to own it" if GameState.can_afford(price) else "Need %s more coins" % UiKit.format_int(price - GameState.coins)
	elif id == GameState.selected_vehicle:
		_action.apply_kind(UiButton.Kind.ACTIVE)
		_action.set_rows("SELECTED", -1, 32)
		_action.set_enabled(false)
		_hint.text = "This is your ride"
	else:
		_action.apply_kind(UiButton.Kind.SECONDARY)
		_action.set_rows("SELECT", -1, 36)
		_action.set_enabled(true)
		_hint.text = "Tap SELECT to drive it"


func _update_upgrades(id: String, owned: bool) -> void:
	for key: String in Catalog.UPGRADE_KEYS:
		var level := GameState.upgrade_level(id, key)
		var cost := GameState.next_upgrade_cost(id, key)
		var row: Dictionary = _rows[key]
		(row["bars"] as PipBar).configure(Catalog.MAX_UPGRADE_LEVEL, level, UiKit.ORANGE if key == "engine" else UiKit.TEAL)
		(row["level"] as Label).text = "LEVEL %d / %d" % [level, Catalog.MAX_UPGRADE_LEVEL]
		(row["effect"] as Label).text = _effect_text(key, level) if owned else "Buy this vehicle to upgrade it"
		var button := row["button"] as UiButton
		if cost < 0:
			button.apply_kind(UiButton.Kind.ACTIVE, 30)
			button.set_rows("MAX", -1, 34)
			button.set_enabled(false)
		else:
			button.apply_kind(UiButton.Kind.PRIMARY, 30)
			button.set_rows("UPGRADE", cost, 24, 30)
			button.set_enabled(owned and GameState.can_afford(cost))


func _effect_text(key: String, level: int) -> String:
	var effect := Catalog.upgrade_effect(key, level)
	var percent := effect * 100.0 if key == "suspension" else (effect - 1.0) * 100.0
	if level == 0:
		return "Stock"
	return EFFECT_TEXT[key] % roundi(percent)


func _on_coins_changed(_coins: int) -> void:
	# progress_changed is not emitted for bare add_coins calls, so refresh the affordability here.
	_refresh()


# Actions

func _browse(step: int) -> void:
	_index = posmod(_index + step, Catalog.VEHICLE_ORDER.size())
	_show_current(step)


func _show_current(slide: int) -> void:
	_showcase.show_vehicle(_current_id(), GameState.owns_vehicle(_current_id()), slide)
	_refresh()


func _on_action() -> void:
	var id := _current_id()
	if not GameState.owns_vehicle(id):
		if GameState.buy_vehicle(id):
			GameState.select_vehicle(id)
	else:
		GameState.select_vehicle(id)


func _on_upgrade(key: String) -> void:
	if GameState.upgrade(_current_id(), key):
		((_rows[key] as Dictionary)["bars"] as PipBar).flash()
