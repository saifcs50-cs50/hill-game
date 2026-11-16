class_name MenuRoot
extends Control
## Root of ui/menu.tscn, the application's main scene. Owns the dusk backdrop and swaps the
## screens (main, garage, stages, settings). DRIVE leaves for the run scene.

const RUN_SCENE := "res://main.tscn"
const HOME := "main"
const DRIVE := "drive"
const SCREEN_FADE := 0.2

var _holder := Control.new()
var _screen: MenuScreen
var _screen_id := ""


func _ready() -> void:
	Engine.time_scale = 1.0
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBackdrop.new())
	_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_holder)
	show_screen(GameState.take_pending_screen())


func _exit_tree() -> void:
	get_tree().quit_on_go_back = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()


func show_screen(screen_id: String) -> void:
	var screen := _make_screen(screen_id)
	if screen == null:
		push_error("Unknown menu screen '%s'" % screen_id)
		return
	if _screen != null:
		_holder.remove_child(_screen)
		_screen.queue_free()
	_screen = screen
	_screen_id = screen_id
	_screen.navigate.connect(_on_navigate)
	_holder.add_child(_screen)
	UiKit.fade_in(_screen, SCREEN_FADE)
	get_tree().quit_on_go_back = screen_id == HOME


func current_screen() -> MenuScreen:
	return _screen


func _make_screen(screen_id: String) -> MenuScreen:
	match screen_id:
		"main":
			return HomeScreen.new()
		"garage":
			return GarageScreen.new()
		"stages":
			return StagesScreen.new()
		"settings":
			return SettingsScreen.new()
	return null


func _on_navigate(screen_id: String) -> void:
	if screen_id == DRIVE:
		get_tree().change_scene_to_file(RUN_SCENE)
	else:
		show_screen(screen_id)


func _go_back() -> void:
	if _screen_id != HOME:
		show_screen(HOME)
