extends CharacterBody2D

#Character Physics
var playerspeed : int = 100
var playerjump_velocity : int = -450
#Global Gravity is stored in Project Settings (Physics) of Godot so we could call that or we could state explicitly.
#Calling Gravity
#var playergravity = ProjectSettings.get_setting("physics/2d/default_gravity")
#Stating Gravity Explicitly
var playergravity : float = 981.0

func _physics_process(delta: float) -> void:
	
	#If the player is not on a platform, use gravity.
	if !is_on_floor():
		velocity.y += playergravity * delta
	
	#If the player presses jump move the character up on y axis, but only if they are on a platform.
	if Input.is_action_just_pressed("jump") and is_on_floor() :
		velocity.y += playerjump_velocity
	
	#Gravity will handle Y Axis, so we only need to worry about X axis movement.
	#We will store axis direction as a variable so we can test it every process.
	var playerdirection = Input.get_axis("left","right")
	
	if playerdirection :
		velocity.x = playerdirection * playerspeed
	else:
		#Clunky movement
		#velocity.x = 0.0
		#Better Movement
		velocity.x = move_toward(velocity.x, 0, playerspeed)
	
	move_and_slide()
	
