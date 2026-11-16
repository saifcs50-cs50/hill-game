class_name SettingsScreen
extends MenuScreen
## Settings: music and sound toggles, and a two-step reset of all progress.

const PANEL_WIDTH := 820.0
const ERASED_MESSAGE := "Progress erased. You are back to the start."

var _reset_box: VBoxContainer
var _status: Label


func _ready() -> void:
	var page := build_page("SETTINGS")
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(center)
	var panel := UiKit.panel(UiKit.PANEL_FILL, UiKit.PANEL_RADIUS, 22)
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	center.add_child(panel)
	var column := UiKit.vbox(14)
	panel.add_child(column)
	column.add_child(_build_toggle("Music", GameState.music_on, GameState.set_music))
	column.add_child(_build_toggle("Sound effects", GameState.sfx_on, GameState.set_sfx))
	column.add_child(_build_divider())
	_reset_box = UiKit.vbox(10)
	column.add_child(_reset_box)
	_status = UiKit.label("", 22, UiKit.TEAL)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.visible = false
	column.add_child(_status)
	_show_reset(false)


func _build_toggle(title: String, is_on: bool, setter: Callable) -> UiToggle:
	var toggle := UiToggle.make_toggle(title, is_on)
	toggle.name = "Toggle_" + title.replace(" ", "")
	toggle.toggled.connect(setter)
	return toggle


func _build_divider() -> Control:
	var line := ColorRect.new()
	line.color = Color(1.0, 1.0, 1.0, 0.12)
	line.custom_minimum_size = Vector2(0.0, 2.0)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


## Swaps the reset area between its idle button and the confirm step.
func _show_reset(confirming: bool) -> void:
	for child in _reset_box.get_children():
		_reset_box.remove_child(child)
		child.queue_free()
	if confirming:
		_build_confirm()
	else:
		_build_idle()


func _build_idle() -> void:
	var caption := UiKit.label("Erase coins, vehicles, stages, upgrades and best distances.", 22, UiKit.CREAM_DIM)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reset_box.add_child(caption)
	var reset := UiButton.create("RESET PROGRESS", UiButton.Kind.DANGER, UiKit.BUTTON_HEIGHT, 32)
	reset.name = "Reset"
	reset.pressed.connect(_on_reset_pressed)
	_reset_box.add_child(reset)


func _build_confirm() -> void:
	var ask := UiKit.label("Erase everything? This cannot be undone.", 28, UiKit.CREAM)
	ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reset_box.add_child(ask)
	var row := UiKit.hbox(14)
	var cancel := UiButton.create("CANCEL", UiButton.Kind.GHOST, UiKit.BUTTON_HEIGHT, 32)
	cancel.name = "CancelReset"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(_show_reset.bind(false))
	row.add_child(cancel)
	var confirm := UiButton.create("YES, ERASE", UiButton.Kind.DANGER, UiKit.BUTTON_HEIGHT, 32)
	confirm.name = "ConfirmReset"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.pressed.connect(_on_confirm_pressed)
	row.add_child(confirm)
	_reset_box.add_child(row)


func _on_reset_pressed() -> void:
	_status.visible = false
	_show_reset(true)


func _on_confirm_pressed() -> void:
	GameState.reset_progress()
	_show_reset(false)
	_status.text = ERASED_MESSAGE
	_status.visible = true
