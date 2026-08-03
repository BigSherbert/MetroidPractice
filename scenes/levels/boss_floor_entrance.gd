extends Area2D

@export var camera_limit_left: int = -32
@export var camera_limit_right: int = 10000000
@export var camera_limit_bottom: int = 544
@export var camera_y: float = 250.0
@export var camera_zoom:= Vector2(1.25,1.25)
@export var camera_offset:= Vector2(0,0)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	var camera := body.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = camera_limit_left
	camera.limit_right = camera_limit_right
	camera.limit_bottom = camera_limit_bottom
	body.set_camera_floor(camera_y)
	
	#Expiremental Zoom, probably should not be using reddit for code help. We will see.
	var tween = camera.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "zoom", camera_zoom, 1)
	tween.parallel().tween_property(camera, "offset", camera_offset, 1.5)
	
	AutoloadState.set_checkpoint($BossFloorEntranceRespawn.global_position,camera_y,camera_limit_left,camera_limit_right,camera_limit_bottom,camera_zoom,camera_offset)
