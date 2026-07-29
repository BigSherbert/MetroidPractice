extends CharacterBody2D

var playerdetected = false
var exploding := false

var direction : Vector2
@export var speed := 50
var player: CharacterBody2D

@export var health := 3


func _physics_process(_delta: float) -> void:
	
	#if playerdetected == true :
	#Move the drone towards the player. Delta is accounted for in Move_and_slide
	if player :
		direction = (player.position - position).normalized()
		velocity = direction * speed
		move_and_slide()



#Drone Detection
#Triggered when Player (Or characterbody2d in Player Collision Layer) enters the Detection Area
func _on_detection_area_body_entered(detectedplayer: CharacterBody2D) -> void:
	#playerdetected = true
	player = detectedplayer

#Cancel Drone Detection
#If player runs away and leaves detection area, stop the drone.
func _on_detection_area_body_exited(_detectedplayer: CharacterBody2D) -> void:
	player = null

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
