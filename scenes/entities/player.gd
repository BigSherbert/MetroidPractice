extends CharacterBody2D

#Character Physics
#@export allows us to expose these variables to the inspector
var playerspeed : int = 100
@export var jump_velocity : int = -450
#Global Gravity is stored in Project Settings (Physics) of Godot so we could call that or we could state explicitly.
#Calling Gravity
#var playergravity = ProjectSettings.get_setting("physics/2d/default_gravity")
#Stating Gravity Explicitly
#@export allows us to expose these variables to the inspector
@export var gravity : float = 981.0

#Creating a Custom Signal
signal shoot(pos: Vector2, dir: Vector2)

func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var playerdirection := Input.get_axis("left", "right")

	if playerdirection != 0:
		velocity.x = playerdirection * playerspeed
		$Legs.flip_h = playerdirection < 0
	else:
		velocity.x = move_toward(velocity.x, 0, playerspeed)

	move_and_slide()

	# Choose animation after movement.
	if !is_on_floor():
		$AnimationPlayer.play("jumping")
	elif playerdirection != 0:
		$AnimationPlayer.play("run")
	else:
		$AnimationPlayer.play("idle")

	if Input.is_action_just_pressed("shoot") and $ReloadTimer.time_left == 0.0:
		shoot.emit(
			global_position,
			(get_global_mouse_position() - global_position).normalized()
		)
		$ReloadTimer.start()
