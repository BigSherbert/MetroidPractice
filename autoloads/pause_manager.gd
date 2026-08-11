extends CanvasLayer

var overlay: ColorRect
var previous_mouse_mode := Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_pause_ui()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_F11 or event.physical_keycode == KEY_F11:
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()
	elif (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE) and _can_pause():
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _can_pause() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	return not scene.scene_file_path.begins_with("res://scenes/menu/")

func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _toggle_pause() -> void:
	var pausing := not get_tree().paused
	if pausing:
		previous_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	overlay.visible = pausing
	get_tree().paused = pausing
	if not pausing:
		Input.mouse_mode = previous_mouse_mode

func _build_pause_ui() -> void:
	overlay = ColorRect.new()
	overlay.name = "PauseOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.01, 0.04, 0.72)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 190)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.035, 0.13, 0.96)
	panel_style.border_color = Color(0.92, 0.2, 0.55, 1.0)
	panel_style.set_border_width_all(3)
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	margin.add_child(box)

	var paused_label := Label.new()
	paused_label.text = "PAUSED"
	paused_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paused_label.add_theme_font_size_override("font_size", 36)
	paused_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.94, 1.0))
	box.add_child(paused_label)

	var MM_button := Button.new()
	MM_button.text = "Return to Main Menu"
	MM_button.custom_minimum_size = Vector2(0, 48)
	MM_button.add_theme_font_size_override("font_size", 20)
	MM_button.pressed.connect(_on_MM_pressed)
	box.add_child(MM_button)

	var hint := Label.new()
	hint.text = "ESC TO RESUME  //  F11 FULLSCREEN"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.78, 0.68, 0.82, 1.0))
	box.add_child(hint)

func _on_MM_pressed() -> void:
	overlay.visible = false
	get_tree().paused = false
	Input.mouse_mode = previous_mouse_mode
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
