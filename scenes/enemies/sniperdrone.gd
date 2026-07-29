extends CharacterBody2D

var playerdetected = false
var exploding := false

var direction : Vector2
@export var speed := 50
var player: CharacterBody2D

@export var health := 3

#Shooting Variables
@export var reloadtime := 3.0
@export var firstshottime := 1.0

#Creating a Custom Signal
signal droneshoot(pos: Vector2, dir: Vector2)


func _physics_process(_delta: float) -> void:
	
	#if playerdetected == true :
	#Move the drone towards the player. Delta is accounted for in Move_and_slide
	if player :
		direction = (player.position - position).normalized()
		velocity = direction * speed
		if velocity.x > 0:
			$AnimatedSprite2D.flip_h = true
		elif velocity.x < 0:
			$AnimatedSprite2D.flip_h = false
		move_and_slide()



#Drone Detection
#Triggered when Player (Or characterbody2d in Player Collision Layer) enters the Detection Area
func _on_detection_area_body_entered(detectedplayer: CharacterBody2D) -> void:
	#playerdetected = true
	player = detectedplayer
	$ReloadTimer.start(firstshottime)

#Cancel Drone Detection
#If player runs away and leaves detection area, stop the drone.
func _on_detection_area_body_exited(detectedplayer: CharacterBody2D) -> void:
	if detectedplayer == player:
		player = null
		$ReloadTimer.stop()

#Drone Shoots At Player
func _on_reload_timer_timeout() -> void:
	if player == null:
		return
	print("Fire!")
	droneshoot.emit(global_position,(player.global_position - global_position).normalized())
	$ReloadTimer.start(reloadtime)



#Explode on impact with Player
func _on_area_2d_body_entered(_body: Node2D) -> void:
	drone_explode()

#Drone is Shot At
func ShotAt():
	print("Drone was ShotAt")
	health -= 1
	print("Drone Health: ", health)
	if health <= 0 :
		drone_explode()

#Explosion Animation
func drone_explode() :
	if exploding:
		return
	exploding = true
	#print("Play Explosion")
	speed = 0
	$DroneCollisionArea.set_deferred("disabled", true)
	$AnimatedSprite2D.visible = false
	$AnimationPlayer.play("explode")

#Remove the drone when explosion finished.
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"explode" :
		queue_free()
