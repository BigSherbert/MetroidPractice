extends CharacterBody2D

var exploding := false

var direction : Vector2
@export var speed := 50
var player: CharacterBody2D

@export var health := 3
@export var blast_radius := 20

#Shooting Variables
@export var reloadtime := 3.0
@export var firstshottime := 1.0

#Scanning Variables
@export var scan_speed := 1.5
@export var scan_angle := 45.0
@export var flash_speed := 8.0
var scan_time := 0.0



#Creating a Custom Signal
signal droneshoot(pos: Vector2, dir: Vector2)


func _ready() -> void:
	#Scanning Light
	$ScanPivot/ScanningLight.modulate = Color(0.3, 0.7, 1.0, 0.35)


func _physics_process(delta: float) -> void:
	
	#Move the drone towards the player. Delta is accounted for in Move_and_slide
	if player :
		track_player_with_light(delta)
		direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		if velocity.x > 0:
			$AnimatedSprite2D.flip_h = true
			$MuzzleFlash.scale.x = 1
		elif velocity.x < 0:
			$AnimatedSprite2D.flip_h = false
			$MuzzleFlash.scale.x = -1
		move_and_slide()
	else:
		scan_with_light(delta)
		#velocity = Vector2.ZERO



#Drone Detection

func scan_with_light(delta: float) -> void:
	scan_time += delta * scan_speed
	# Sweep back and forth.
	$ScanPivot.rotation = sin(scan_time) * deg_to_rad(scan_angle)
	# Slowly brighten and dim.
	var alpha := remap(
		sin(scan_time * 2.0),
		-1.0,
		1.0,
		0.15,
		0.45
	)
	$ScanPivot/ScanningLight.modulate = Color(0.3, 0.7, 1.0, alpha)

func track_player_with_light(delta: float) -> void:
	scan_time += delta * flash_speed
	var direction_to_player := player.global_position - global_position
	# Point directly at the player.
	$ScanPivot.global_rotation = direction_to_player.angle()
	# Flash red.
	var alpha := remap(
		sin(scan_time),
		-1.0,
		1.0,
		0.2,
		0.9
	)
	$ScanPivot/ScanningLight.modulate = Color(1.0, 0.1, 0.1, alpha)


#Triggered when Player (Or characterbody2d in Player Collision Layer) enters the Detection Area
func _on_detection_area_body_entered(detectedplayer: CharacterBody2D) -> void:
	player = detectedplayer
	scan_time = 0.0
	$ReloadTimer.start(firstshottime)

#Cancel Drone Detection
#If player runs away and leaves detection area, stop the drone.
func _on_detection_area_body_exited(detectedplayer: CharacterBody2D) -> void:
	if detectedplayer == player:
		player = null
		scan_time = 0.0
		$ReloadTimer.stop()

#Drone Shoots At Player
func _on_reload_timer_timeout() -> void:
	if player == null:
		return
	print("Fire!")
	flash_laser_origin()
	droneshoot.emit(global_position,(player.global_position - global_position).normalized())
	$ReloadTimer.start(reloadtime)

#MuzzleFlash
func flash_laser_origin() -> void:
	$MuzzleFlash.visible = true
	$MuzzleFlash.modulate.a = 1.0
	
	var tween := create_tween()
	tween.tween_property($MuzzleFlash, "modulate:a", 0.0, 0.15)
	
	await tween.finished
	$MuzzleFlash.visible = false



#Explode on impact with Player
func _on_area_2d_body_entered(_body: Node2D) -> void:
	drone_explode()

#Drone is Shot At
func shot_at():
	print("Drone was shot_at")
	health -= 1
	$DetectionArea/DetectAreaCollision.scale = Vector2(1.65,1.65)
	print("Drone Health: ", health)
	if health <= 0 :
		drone_explode()

func explode_nearby_drones():
	for drone in get_tree().get_nodes_in_group("Drones"):
		if drone != self and global_position.distance_to(drone.global_position) <= blast_radius:
			drone.drone_explode()

#Explosion Animation
func drone_explode() :
	if exploding:
		return
	exploding = true
	#print("Play Explosion")
	speed = 0
	
	$DroneCollisionArea.set_deferred("disabled", true)
	$ScanPivot/ScanningLight.visible = false
	$AnimatedSprite2D.visible = false
	$AnimationPlayer.play("explode")
	explode_nearby_drones()

#Remove the drone when explosion finished.
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"explode" :
		queue_free()
