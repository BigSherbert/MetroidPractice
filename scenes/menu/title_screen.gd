extends Control

var leaving := false

func _ready() -> void:
	$Fade.color.a = 1.0
	var tween := create_tween()
	tween.tween_property($Fade, "color:a", 0.0, 0.9)

#fuck you unhandled
func _unhandled_input(event: InputEvent) -> void:
	if leaving:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_open_menu()
	elif event is InputEventMouseButton and event.pressed:
		_open_menu()
	elif event is InputEventJoypadButton and event.pressed:
		_open_menu()

func _open_menu() -> void:
	leaving = true
	var tween := create_tween()
	tween.tween_property($Fade, "color:a", 1.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
