extends CharacterBody2D

#Character Physics
#@export allows us to expose these variables to the inspector
@export var player_speed : int = 120
@export var jump_velocity : int = -450
#Global Gravity is stored in Project Settings (Physics) of Godot so we could call that or we could state explicitly.
#Calling Gravity
#var playergravity = ProjectSettings.get_setting("physics/2d/default_gravity")
#Stating Gravity Explicitly
#@export allows us to expose these variables to the inspector
@export var gravity : float = 981.0

#Creating a Custom Signal
signal shoot(pos: Vector2, dir: Vector2)

#Create dictionary for gun directions
const gun_directions = {
	Vector2i(1,0):   0,
	Vector2i(1,1):   1,
	Vector2i(0,1):   2,
	Vector2i(-1,1):  3,
	Vector2i(-1,0):  4,
	Vector2i(-1,-1): 5,
	Vector2i(0,-1):  6,
	Vector2i(1,-1):  7,
	}




func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	var playerdirection := Input.get_axis("left", "right")
	
	if playerdirection != 0:
		velocity.x = playerdirection * player_speed
		$Legs.flip_h = playerdirection < 0
	else:
		velocity.x = move_toward(velocity.x, 0, player_speed)
	
	move_and_slide()
	
	# Choose Legs animation after movement.
	if !is_on_floor():
		$LegsAnimationPlayer.play("jumping")
	elif playerdirection != 0:
		$LegsAnimationPlayer.play("run")
	else:
		$LegsAnimationPlayer.play("idle")
	
	#Choose Torso animation after movement but before shooting
	var torsodirection = get_local_mouse_position().normalized()
	var adjustedtorsodirection = Vector2i(round(torsodirection.x),round(torsodirection.y))
	#print(adjustedtorsodirection)
	$Torso.frame = gun_directions[adjustedtorsodirection]
	
	#Logic for Mouse Marker
	#we could probably create functions for all these animations and what not
	#would make things more neat, but meh
	$Crosshair.position =  (get_global_mouse_position() - global_position).limit_length(50)
	

	if Input.is_action_just_pressed("shoot") and $ReloadTimer.time_left == 0.0:
		shoot.emit(global_position,(get_global_mouse_position() - global_position).normalized())
		#Tweens are POWERFUL for adjusting properties of nodes super quick
		var tween = get_tree().create_tween()
		tween.tween_property($Crosshair, "scale",Vector2(.1,.1),.25)
		tween.tween_property($Crosshair, "scale",Vector2(.5,.5),.25)
		$ReloadTimer.start()
