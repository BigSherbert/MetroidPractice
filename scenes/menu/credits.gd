extends Control

var paused_for_animasonic := false

@onready var back_button: Button = $CreditsPanel/Margin/Content/BackButton
@onready var fade: ColorRect = $Fade

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_button.grab_focus()
	fade.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, 0.4)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and paused_for_animasonic:
		paused_for_animasonic = false
		get_tree().paused = false

func _on_animasonic_link_pressed() -> void:
	paused_for_animasonic = true
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back_to_menu()

func _on_back_button_pressed() -> void:
	_back_to_menu()

func _back_to_menu() -> void:
	back_button.disabled = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.25)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
