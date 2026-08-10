extends CharacterBody2D

var exploding := false

var direction : Vector2
@export var speed := 100
var player: CharacterBody2D

@export var health := 3
@export var blast_radius := 35
@export var ally_alert_distance := 200.0

#Scanning Variables
@export var scan_speed := 1.5
@export var flash_speed := 8.0
var scan_time := 0.0
@export var scan_min_angle := -65.0
@export var scan_max_angle := 25.0

#FrenzyMode
@export var frenzy_duration := 5.0
@export var give_up_distance := 475.0
var frenzy_time_left := 0.0
var frenzy_sound_running := false
var starting_position: Vector2
@export var keep_frenzy_distance := 250.0

var boss_summoned := false
var avoiding_obstacle := false
var avoid_direction := 1.0
var avoid_time_left := 0.0
@export var boss_avoid_time := 0.45

func _ready() -> void:
	#Give the drone its own shader
	$AnimatedSprite2D.material = $AnimatedSprite2D.material.duplicate()
	#Save Origin Position
	starting_position = global_position
	#Scanning Light
	$ScanPivot/ScanningLight.modulate = Color(0.3, 0.7, 1.0, 0.35)


func _physics_process(delta: float) -> void:
	if player and frenzy_time_left > 0.0:
		if not boss_summoned:
			frenzy_time_left -= delta
			var distance_to_player := global_position.distance_to(player.global_position)
			if distance_to_player > give_up_distance:
				player = null
				frenzy_time_left = 0.0
			elif frenzy_time_left <= 0.0:
				if distance_to_player <= keep_frenzy_distance:
					frenzy_time_left = frenzy_duration
				else:
					player = null
					frenzy_time_left = 0.0
		if player and frenzy_time_left > 0.0:
			track_player_with_light(delta)

			if boss_summoned and avoiding_obstacle:
				avoid_time_left -= delta
				velocity = Vector2(avoid_direction * speed, 0.0)
				if avoid_time_left <= 0.0:
					avoiding_obstacle = false
			else:
				direction = (player.global_position - global_position).normalized()
				velocity = direction * speed

			if velocity.x > 0:
				$AnimatedSprite2D.flip_h = true
			elif velocity.x < 0:
				$AnimatedSprite2D.flip_h = false

			move_and_slide()

			if boss_summoned and not avoiding_obstacle:
				for i in range(get_slide_collision_count()):
					var collision := get_slide_collision(i)
					var normal := collision.get_normal()
					if abs(normal.y) > 0.7:
						avoiding_obstacle = true
						avoid_time_left = boss_avoid_time
						avoid_direction = 1.0 if player.global_position.x > global_position.x else -1.0
						break
			return
	if boss_summoned:
		velocity = Vector2.ZERO
		return
	if global_position.distance_to(starting_position) > 2.0:
		direction = (starting_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		global_position = starting_position
		scan_with_light(delta)


#Drone Detection
func scan_with_light(delta: float) -> void:
	scan_time += delta * scan_speed
	#Sweep back and forth.
	var scan_rotation := remap(
		sin(scan_time),
		-1.0,
		1.0,
		scan_min_angle,
		scan_max_angle
	)
	
	if $AnimatedSprite2D.flip_h:
		#Drone is facing left: Use the normal scanning angle.
		$ScanPivot.rotation_degrees = scan_rotation
	else:
		#Drone is facing right: Reverse the scanning angle.
		$ScanPivot.rotation_degrees = 180.0 - scan_rotation
	
	$ScanPivot/ScanningLight.modulate = Color(0.3, 0.7, 1.0, 0.35)

func track_player_with_light(delta: float) -> void:
	scan_time += delta * flash_speed
	var direction_to_player := player.global_position - global_position
	#Point directly at the player.
	$ScanPivot.global_rotation = direction_to_player.angle()
	#Flash red.
	var redflash := remap(
		sin(scan_time),
		-1.0,
		1.0,
		0.2,
		0.9
	)
	$ScanPivot/ScanningLight.modulate = Color(1.0, 0.1, 0.1, redflash)

func activate_boss_summon(target: CharacterBody2D) -> void:
	boss_summoned = true
	player = target
	frenzy_time_left = 999999.0
	scan_time = 0.0
	avoiding_obstacle = false
	avoid_time_left = 0.0
	play_detection_alert()

func play_detection_alert() -> void:
	if frenzy_sound_running:
		return

	frenzy_sound_running = true
	await get_tree().create_timer(randf_range(0.0, 0.15)).timeout

	while not exploding and player != null and frenzy_time_left > 0.0:
		$PlayerDetectedSound.pitch_scale = randf_range(0.85, 1.15)
		$PlayerDetectedSound.volume_db = randf_range(-4.0, 0.0)
		$PlayerDetectedSound.play()
		await $PlayerDetectedSound.finished

		if exploding or player == null or frenzy_time_left <= 0.0:
			break

		await get_tree().create_timer(randf_range(0.15, 0.45)).timeout

	frenzy_sound_running = false

func alert_nearby_drones(target: CharacterBody2D) -> void:
	for drone in get_tree().get_nodes_in_group("Drones"):
		if drone == self or drone.global_position.distance_to(global_position) > ally_alert_distance:
			continue
		if drone.has_method("activate_frenzy_from_ally"):
			drone.activate_frenzy_from_ally(target)

func activate_frenzy_from_ally(target: CharacterBody2D) -> void:
	if exploding:
		return
	var was_in_frenzy := player != null and frenzy_time_left > 0.0
	player = target
	frenzy_time_left = frenzy_duration
	scan_time = 0.0
	if not was_in_frenzy:
		play_detection_alert()

#Triggered when Player (Or characterbody2d in Player Collision Layer) enters the Detection Area
func _on_detection_area_body_entered(detectedplayer: CharacterBody2D) -> void:
	player = detectedplayer
	frenzy_time_left = frenzy_duration
	scan_time = 0.0
	play_detection_alert()
	alert_nearby_drones(detectedplayer)

#Cancel Drone Detection
#If player runs away and leaves detection area, stop the drone.
func _on_detection_area_body_exited(detectedplayer: CharacterBody2D) -> void:
	if detectedplayer == player and frenzy_time_left <= 0.0:
		player = null
		scan_time = 0.0

#Explode on impact with Player
func _on_area_2d_body_entered(body: Node2D) -> void:
	if exploding:
		return
	if body.has_method("take_damage"):
		body.take_damage(2)
	drone_explode()

#Drone is Shot At
func shot_at():
	var was_in_frenzy := player != null and frenzy_time_left > 0.0
	var found_player := get_tree().get_first_node_in_group("Player")
	if found_player:
		player = found_player
		frenzy_time_left = frenzy_duration
		scan_time = 0.0
		if not was_in_frenzy and health > 1:
			play_detection_alert()
		alert_nearby_drones(found_player)
	print("Drone was shot_at")
	health -= 1
	print("Drone Health: ", health)
	if health <= 0 :
		drone_explode()
	#$AnimatedSprite2D.material.set_shader_parameter("HitShaderMix",0.0)
	$ShotAtSound.play()
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D.material,"shader_parameter/HitShaderMix",0.0,0.05)
	tween.tween_property($AnimatedSprite2D.material,"shader_parameter/HitShaderMix",1.0,0.1)


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
	velocity = Vector2.ZERO
	$DroneCollisionArea.set_deferred("disabled", true)
	$SelfDestructArea/SelfDestructCollision.set_deferred("disabled", true)
	$ScanPivot/ScanningLight.visible = false
	$AnimatedSprite2D.visible = false
	$ExplosionAnimation.play("explode")
	$ExplosionSound.play()
	explode_nearby_drones()

#Remove the drone when explosion finished.
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"explode" :
		queue_free()
