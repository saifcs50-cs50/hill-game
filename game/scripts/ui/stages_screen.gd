class_name StagesScreen
extends MenuScreen
## Stage select: one card per stage with a painted preview, the best distance with the selected
## vehicle, and a Buy or Select button.

const CARD_GAP := 16
const THUMB_MIN_HEIGHT := 140.0
const BLURB_HEIGHT := 96.0
const SELECTED_BORDER := UiKit.TEAL

var _cards := {}


func _ready() -> void:
	var vehicle_name: String = Catalog.VEHICLES[GameState.selected_vehicle]["name"]
	var page := build_page("STAGES", "Best distances shown for your %s" % vehicle_name)
	var row := UiKit.hbox(CARD_GAP)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(row)
	for stage_id: String in Catalog.STAGE_ORDER:
		row.add_child(_build_card(stage_id))
	GameState.progress_changed.connect(_refresh)
	GameState.coins_changed.connect(_on_coins_changed)
	_refresh()


func _build_card(stage_id: String) -> PanelContainer:
	var data: Dictionary = Catalog.STAGES[stage_id]
	var card := UiKit.panel(UiKit.PANEL_FILL, UiKit.PANEL_RADIUS, 14)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := UiKit.vbox(8)
	card.add_child(column)
	var thumb := StageThumb.new()
	thumb.stage_id = stage_id
	thumb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	thumb.custom_minimum_size = Vector2(0.0, THUMB_MIN_HEIGHT)
	column.add_child(thumb)
	column.add_child(UiKit.label(data["name"], 38, UiKit.CREAM, true))
	var blurb := UiKit.label(data["blurb"], 20, UiKit.CREAM_DIM)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(0.0, BLURB_HEIGHT)
	column.add_child(blurb)
	var best := UiKit.label("", 24, UiKit.TEAL)
	column.add_child(best)
	var action := UiButton.create("", UiButton.Kind.PRIMARY, UiKit.BUTTON_HEIGHT)
	action.name = "Action_" + stage_id
	action.pressed.connect(_on_action.bind(stage_id))
	column.add_child(action)
	_cards[stage_id] = {"card": card, "thumb": thumb, "best": best, "action": action}
	return card


func _refresh() -> void:
	for stage_id: String in Catalog.STAGE_ORDER:
		var parts: Dictionary = _cards[stage_id]
		var owned := GameState.owns_stage(stage_id)
		var selected := owned and stage_id == GameState.selected_stage
		(parts["thumb"] as StageThumb).locked = not owned
		_update_best(parts["best"], stage_id, owned)
		_update_action(parts["action"], stage_id, owned, selected)
		_update_border(parts["card"], selected)


func _update_best(label: Label, stage_id: String, owned: bool) -> void:
	var best := GameState.best_for(stage_id, GameState.selected_vehicle)
	if not owned:
		label.text = "Locked"
		label.label_settings.font_color = UiKit.ORANGE
	elif best > 0.0:
		label.text = "BEST  %s m" % UiKit.format_int(int(best))
		label.label_settings.font_color = UiKit.TEAL
	else:
		label.text = "No run yet"
		label.label_settings.font_color = UiKit.CREAM_DIM


func _update_action(button: UiButton, stage_id: String, owned: bool, selected: bool) -> void:
	var price: int = Catalog.STAGES[stage_id]["price"]
	if not owned:
		button.apply_kind(UiButton.Kind.PRIMARY)
		button.set_rows("BUY", price)
		button.set_enabled(GameState.can_afford(price))
	elif selected:
		button.apply_kind(UiButton.Kind.ACTIVE)
		button.set_rows("SELECTED", -1, 30)
		button.set_enabled(false)
	else:
		button.apply_kind(UiButton.Kind.SECONDARY)
		button.set_rows("SELECT", -1, 36)
		button.set_enabled(true)


func _update_border(card: PanelContainer, selected: bool) -> void:
	var style: StyleBoxFlat = card.get_theme_stylebox("panel")
	style.border_color = SELECTED_BORDER if selected else UiKit.BORDER
	style.set_border_width_all(4 if selected else 2)


func _on_coins_changed(_coins: int) -> void:
	_refresh()


func _on_action(stage_id: String) -> void:
	if not GameState.owns_stage(stage_id):
		if GameState.buy_stage(stage_id):
			GameState.select_stage(stage_id)
	else:
		GameState.select_stage(stage_id)
