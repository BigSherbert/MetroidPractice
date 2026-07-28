extends CharacterBody2D

var playerdetected = false

var direction : Vector2
@export var speed := 50
var player: CharacterBody2D


func _physics_process(_delta: float) -> void:
	
	#if playerdetected == true :
	
	if player :
		direction = (player.position - position).normalized()
		velocity = direction * speed
		move_and_slide()




#Triggered when Player (Or characterbody2d in Player Collision Layer) enters the Detection Area
func _on_detection_area_body_entered(detectedplayer: CharacterBody2D) -> void:
	#playerdetected = true
	player = detectedplayer


#If player runs away and leaves detection area, stop the drone.
func _on_detection_area_body_exited(_detectedplayer: CharacterBody2D) -> void:
	player = null
