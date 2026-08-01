extends Area2D

@export var camera_limit_left: int = -10000000
@export var camera_limit_right: int = 10000000
@export var camera_y: float


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	var camera := body.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = camera_limit_left
	camera.limit_right = camera_limit_right
	body.set_camera_floor(camera_y)
	
	#Expiremental Zoom, probably should not be using reddit for code help. We will see.
	var tween = camera.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "zoom", Vector2(1, 1), 1)
