class_name HomeScreen
extends MenuScreen
## Main menu: the title, a big DRIVE button that names the selected vehicle and stage, and
## shortcuts to the garage, the stage list and the settings.

const COLUMN_GAP := 40
const DRIVE_HEIGHT := 152.0
const NAV_HEIGHT := 104.0

var _showcase: VehicleShowcase


func _ready() -> void:
	var columns := UiKit.hbox(COLUMN_GAP)
	add_child(columns)
	columns.add_child(_build_left_column())
	columns.add_child(_build_right_column())
	_showcase.show_vehicle(GameState.selected_vehicle, true)


func _build_left_column() -> VBoxContainer:
	var column := UiKit.vbox(18)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(UiKit.label("HILL GAME", 100, UiKit.CREAM, true))
	column.add_child(UiKit.label("Climb the hills. Collect coins. Upgrade.", 28, UiKit.CREAM_DIM))
	column.add_child(UiKit.spacer())
	column.add_child(_build_drive_button())
	column.add_child(_build_nav_row())
	return column


func _build_drive_button() -> UiButton:
	var drive := UiButton.create("", UiButton.Kind.PRIMARY, DRIVE_HEIGHT)
	drive.name = "Drive"
	var vehicle_name: String = Catalog.VEHICLES[GameState.selected_vehicle]["name"]
	var stage_name: String = Catalog.STAGES[GameState.selected_stage]["name"]
	drive.set_rows("DRIVE", -1, 72)
	var detail := UiKit.label("%s  -  %s" % [vehicle_name, stage_name], 26, UiKit.INK)
	detail.label_settings.shadow_color.a = 0.0
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drive.add_row(detail)
	drive.pressed.connect(go.bind("drive"))
	return drive


func _build_nav_row() -> HBoxContainer:
	var row := UiKit.hbox(14)
	for entry: Array in [["GARAGE", "garage"], ["STAGES", "stages"], ["SETTINGS", "settings"]]:
		var button := UiButton.create(entry[0], UiButton.Kind.SECONDARY, NAV_HEIGHT, 28)
		button.name = (entry[0] as String).capitalize()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(go.bind(entry[1]))
		row.add_child(button)
	return row


func _build_right_column() -> VBoxContainer:
	var column := UiKit.vbox(10)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := UiKit.hbox(0)
	top.add_child(UiKit.spacer())
	top.add_child(CoinBadge.new())
	column.add_child(top)
	_showcase = VehicleShowcase.new()
	_showcase.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_showcase.custom_minimum_size = Vector2(0.0, 300.0)
	column.add_child(_showcase)
	var vehicle_name: String = Catalog.VEHICLES[GameState.selected_vehicle]["name"]
	var name_label := UiKit.label(vehicle_name, 40, UiKit.CREAM, true)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	var best := GameState.best_for(GameState.selected_stage, GameState.selected_vehicle)
	var best_text := "Best here: %s m" % UiKit.format_int(int(best)) if best > 0.0 else "No run here yet"
	var best_label := UiKit.label(best_text, 24, UiKit.CREAM_DIM)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(best_label)
	return column
