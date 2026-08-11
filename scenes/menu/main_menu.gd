extends Control

func _ready() -> void:
	$MenuPanel/MenuButtons/StartButton.grab_focus()
	$Fade.color.a = 1.0
	var tween := create_tween()
	tween.tween_property($Fade, "color:a", 0.0, 0.45)

func _on_start_button_pressed() -> void:
	AutoloadState.reset_run()
	await _fade_out()
	get_tree().change_scene_to_file("res://scenes/menu/intro_cutscene.tscn")

func _on_credits_button_pressed() -> void:
	await _fade_out()
	get_tree().change_scene_to_file("res://scenes/menu/credits.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

#modulate .25 for now, maybe speed up?
func _fade_out() -> void:
	$Fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property($Fade, "color:a", 1.0, 0.25)
	await tween.finished
