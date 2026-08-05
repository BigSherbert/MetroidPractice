extends AnimatableBody2D


@export_range(0.0, 2000.0, 1.0) var travel_distance: float = 200.0
#0 = right, 90 = down, 180 = left, -90 = up.
@export_range(-180.0, 180.0, 1.0) var travel_angle: float = 0.0
@export_range(1.0, 1000.0, 1.0) var move_speed: float = 80.0
@export_range(0.0, 10.0, 0.1) var end_pause: float = 0.5

@export var start_forward: bool = true

var starting_position: Vector2
var target_position: Vector2
var moving_forward: bool
var pause_timer: float = 0.0


func _ready() -> void:
	starting_position = global_position
	moving_forward = start_forward
	_update_target_position()


func _physics_process(delta: float) -> void:
	if pause_timer > 0.0:
		pause_timer -= delta
		return
	var destination: Vector2
	if moving_forward:
		destination = target_position
	else:
		destination = starting_position
	
	global_position = global_position.move_toward(destination,move_speed * delta)
	
	if global_position.is_equal_approx(destination):
		global_position = destination
		moving_forward = not moving_forward
		pause_timer = end_pause


func _update_target_position() -> void:
	var direction := Vector2.RIGHT.rotated(deg_to_rad(travel_angle))
	target_position = starting_position + direction * travel_distance
