extends CharacterBody2D

#Camera Physics
#Im trying to prevent vertical movement except in scene transitions
@onready var camera: Camera2D = $Camera2D
@export var starting_camera_y: float = -540
#Top floor:     -950
#Second floor:  -540
#Third floor:   -156
#Boss floor:     250
var camera_floor_y: float

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

#Player Health System
@export var max_health := 12
var health: int
#Im not entirely sure i-frames are going to be the right route
#If you get shot 3 times you should lose 3 health like the scrub you are.
#Casuals gonna Casual though...
var invincible := false
#Starting with .5
@export var invincibility_time := 0.5


#Creating a Custom Signals
signal shoot(pos: Vector2, dir: Vector2)
signal health_changed(current_health: int, maximum_health: int)
signal lives_changed(current_lives: int)


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

func _ready() -> void:
	
	lives_changed.emit(AutoloadState.lives)
	health = max_health
	invincible = false
	
	camera.top_level = true
	
	if AutoloadState.has_checkpoint:
		global_position = AutoloadState.checkpoint_position
		camera_floor_y = AutoloadState.checkpoint_camera_y
		camera.limit_left = AutoloadState.checkpoint_camera_limit_left
		camera.limit_right = AutoloadState.checkpoint_camera_limit_right
		camera.limit_bottom = AutoloadState.checkpoint_camera_limit_bottom
		camera.zoom = AutoloadState.checkpoint_camera_zoom
		camera.offset = AutoloadState.checkpoint_camera_offset
	else:
		camera_floor_y = starting_camera_y
		AutoloadState.set_checkpoint(global_position,starting_camera_y,camera.limit_left,camera.limit_right,camera.limit_bottom)
		
	camera.global_position = Vector2(global_position.x,camera_floor_y)
	camera.reset_smoothing()
	health_changed.emit(health, max_health)

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
	camera.global_position = Vector2(global_position.x,camera_floor_y)
	
	#Choose Legs animation after movement.
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
	#Adding if check to prevent Vector2(0,0) which isnt supported by the dictionary.
	if gun_directions.has(adjustedtorsodirection): $Torso.frame = gun_directions[adjustedtorsodirection]
	
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

#Player Damage Logic

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

#Called by enemy lasers and other damaging objects.
func shot_at() -> void:
	take_damage(1)

func take_damage(amount: int, knockback := Vector2.ZERO) -> void:
	#i-frame nonsense
	if invincible:
		return
	shake()
	invincible = true
	health = max(health - amount, 0)
	health_changed.emit(health, max_health)
	
	print("Player Health: ",health)
	
	if health <= 0:
		player_die()
		return
	
	velocity = knockback
	$HurtSound.play()
	
	#Use a tween to flash player, could use shader her but meh.
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.2, 0.2), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	
	await get_tree().create_timer(invincibility_time).timeout
	invincible = false


func player_die() -> void:
	print("Player died lol")
	set_physics_process(false)
	var can_respawn := AutoloadState.lose_life()
	lives_changed.emit(AutoloadState.lives)
	#Insert something here later for end screen or something.
	$GameOver.play()
	await $GameOver.finished
	if can_respawn:
		call_deferred("reload_level")
	else:
		call_deferred("game_over")
	#Temporarily restart the current level.
	#get_tree().reload_current_scene()

func game_over():
	print("Game Over")
	AutoloadState.reset_run()
	get_tree().reload_current_scene()

func reload_level() -> void:
	get_tree().reload_current_scene()


#Camera Function
func set_camera_floor(new_camera_y: float) -> void:
	camera_floor_y = new_camera_y
	camera.global_position.y = camera_floor_y
	#This would snap the camera, I kind of like having the smooth transition.
	#I like setting smoothing speed to 10p/s in inspector. Looks way better.
	#camera.reset_smoothing()

var shake_tween: Tween
func shake(intensity := 6.0):
	if shake_tween:
		shake_tween.kill()
	var base_offset : Vector2 = $Camera2D.offset
	shake_tween = create_tween()
	for i in 8:
		var random_offset = Vector2(randf_range(-intensity, intensity),randf_range(-intensity, intensity))
		shake_tween.tween_property($Camera2D, "offset", base_offset + random_offset, 0.02)
	shake_tween.tween_property($Camera2D, "offset", base_offset, 0.03)
