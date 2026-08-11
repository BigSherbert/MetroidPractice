extends Control

func _ready() -> void:
	$BackButton.grab_focus()
	$Fade.color.a = 1.0
	var tween := create_tween()
	tween.tween_property($Fade, "color:a", 0.0, 0.4)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back_to_menu()

func _on_back_button_pressed() -> void:
	_back_to_menu()

func _back_to_menu() -> void:
	$BackButton.disabled = true
	var tween := create_tween()
	tween.tween_property($Fade, "color:a", 1.0, 0.25)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
