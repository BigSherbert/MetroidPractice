extends Control

var elapsed := 0.0
var finished := false

func _ready() -> void:
	$Fade.color.a = 1.0
	create_tween().tween_property($Fade, "color:a", 0.0, 0.7)

func _process(delta: float) -> void:
	elapsed += delta
	$DrEllis.visible = elapsed >= 0.8
	$Flower.visible = elapsed >= 2.0
	$Caption.visible = elapsed >= 2.8
	$GameOver.visible = elapsed >= 5.4
	$ReturnHint.visible = elapsed >= 6.4
	if elapsed >= 5.4:
		var pulse := 0.85 + sin(elapsed * 3.0) * 0.15
		$GameOver.modulate.a = pulse

func _unhandled_input(event: InputEvent) -> void:
	if elapsed >= 6.4 and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		_return_to_menu()

func _return_to_menu() -> void:
	if finished:
		return
	finished = true
	AutoloadState.reset_run()
	var tween := create_tween()
	tween.tween_property($Fade, "color:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
