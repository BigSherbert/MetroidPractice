extends Area2D

@export var camera_limit_left: int = -32
@export var camera_limit_right: int = 4720
@export var camera_y: float = -540.0


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	var camera := body.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = camera_limit_left
	camera.limit_right = camera_limit_right
	body.set_camera_floor(camera_y)
