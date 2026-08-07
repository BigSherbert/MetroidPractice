extends CharacterBody2D

var exploding := false
var attacking := false
var player: CharacterBody2D
var starting_position: Vector2
var scan_time := 0.0

@export var speed := 40.0
@export var health := 4
@export var laser_damage := 3
@export var laser_length := 240.0
@export var charge_time := 0.8
@export var aim_lock_warning_time := 0.45
@export var cooldown_time := 2.5

const fire_time := 0.35
const blast_radius := 35.0
const frenzy_duration := 5.0
const give_up_distance := 525.0
const scan_speed := 1.5
const flash_speed := 8.0

var frenzy_time_left := 0.0

func _ready() -> void:
	$AnimatedSprite2D.material = $AnimatedSprite2D.material.duplicate()
	starting_position = global_position
	$ScanPivot/ScanningLight.modulate = Color(0.3, 0.7, 1.0, 0.35)
	
	$LaserOrigin.visible = false
	$LaserOrigin.modulate.a = 0.0
	
	set_laser_visible(false)
	update_laser_length()

func _physics_process(delta: float) -> void:
	if exploding:
		return
	
	if player:
		$AnimatedSprite2D.flip_h = player.global_position.x > global_position.x
		if player.global_position.x > global_position.x :
			$LaserOrigin.scale.x = 1
		else :
			$LaserOrigin.scale.x = -1
	
	
	if player and frenzy_time_left > 0.0:
		frenzy_time_left -= delta
		var distance_to_player := global_position.distance_to(player.global_position)
		if distance_to_player > give_up_distance:
			stop_attacking()
			player = null
			frenzy_time_left = 0.0
		else:
			track_player_with_light(delta)
			if not attacking:
				var direction := (player.global_position - global_position).normalized()
				velocity = direction * speed
				move_and_slide()
			else:
				velocity = Vector2.ZERO
			return
	return_to_start(delta)

func return_to_start(delta: float) -> void:
	if global_position.distance_to(starting_position) > 2.0:
		var direction := (starting_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		global_position = starting_position
		scan_with_light(delta)

func scan_with_light(delta: float) -> void:
	scan_time += delta * scan_speed
	var scan_rotation := remap(sin(scan_time), -1.0, 1.0, -65.0, 25.0)
	if $AnimatedSprite2D.flip_h:
		$ScanPivot.rotation_degrees = scan_rotation
	else:
		$ScanPivot.rotation_degrees = 180.0 - scan_rotation
	$ScanPivot/ScanningLight.modulate = Color(0.3, 0.7, 1.0, 0.35)

func track_player_with_light(delta: float) -> void:
	if player == null:
		return
	
	scan_time += delta * flash_speed
	$ScanPivot.global_rotation = (player.global_position - global_position).angle()
	var red_flash := remap(sin(scan_time), -1.0, 1.0, 0.2, 0.9)
	$ScanPivot/ScanningLight.modulate = Color(1.0, 0.1, 0.1, red_flash)

func _on_detection_area_body_entered(detected_player: CharacterBody2D) -> void:
	player = detected_player
	frenzy_time_left = frenzy_duration
	scan_time = 0.0
	
	if not attacking:
		laser_attack()

func _on_detection_area_body_exited(detected_player: CharacterBody2D) -> void:
	if detected_player == player and frenzy_time_left <= 0.0:
		stop_attacking()
		player = null

#LaserOriginFlash
func flash_laser_origin() -> void:
	$LaserOrigin.visible = true
	$LaserOrigin.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property($LaserOrigin, "modulate:a", 1.0, 0.08)
	await tween.finished

func laser_attack() -> void:
	if attacking or player == null or exploding:
		return
	
	attacking = true
	velocity = Vector2.ZERO
	$LaserPivot/WarningLine.visible = true
	$ChargeSound.play()
	
	# Track the player for the first part of the charge, then LOCK the beam.
	# That locked warning line is the player's cue to dodge before damage begins.
	var tracking_time: float = maxf(charge_time - aim_lock_warning_time, 0.0)
	var aim_time: float = 0.0
	while aim_time < tracking_time:
		if player == null or exploding:
			stop_attacking()
			return

		$LaserPivot.global_rotation = (player.global_position - $LaserPivot.global_position).angle()
		aim_time += get_physics_process_delta_time()
		await get_tree().physics_frame

	# Final aim sample. From here until the shot, the warning line no longer follows.
	if player == null or exploding:
		stop_attacking()
		return
	$LaserPivot.global_rotation = (player.global_position - $LaserPivot.global_position).angle()

	await get_tree().create_timer(aim_lock_warning_time).timeout
	if player == null or exploding:
		stop_attacking()
		return

	$LaserPivot/WarningLine.visible = false
	$LaserPivot/LaserBeam.visible = true
	$LaserPivot/DamageArea/DamageCollision.set_deferred("disabled", false)
	
	flash_laser_origin()
	$LaserSound.play()
	
	await get_tree().physics_frame
	damage_player_in_beam()
	
	await get_tree().create_timer(fire_time).timeout
	
	$LaserPivot/LaserBeam.visible = false
	$LaserPivot/DamageArea/DamageCollision.set_deferred("disabled", true)
	
	$LaserOrigin.visible = false
	$LaserOrigin.modulate.a = 0.0
	
	await get_tree().create_timer(cooldown_time).timeout
	
	attacking = false
	if player and frenzy_time_left > 0.0 and not exploding:
		laser_attack()

func damage_player_in_beam() -> void:
	for body in $LaserPivot/DamageArea.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(laser_damage)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if $LaserPivot/LaserBeam.visible and body.has_method("take_damage"):
		body.take_damage(laser_damage)

func update_laser_length() -> void:
	$LaserPivot/WarningLine.points = PackedVector2Array([Vector2.ZERO,Vector2(laser_length, 0.0)])
	$LaserPivot/LaserBeam.points = PackedVector2Array([Vector2.ZERO,Vector2(laser_length, 0.0)])
	var beam_shape := $LaserPivot/DamageArea/DamageCollision.shape as RectangleShape2D
	beam_shape.size = Vector2(laser_length, 8.0)
	$LaserPivot/DamageArea/DamageCollision.position.x = laser_length / 2.0

func set_laser_visible(show_laser: bool) -> void:
	$LaserPivot/WarningLine.visible = show_laser
	$LaserPivot/LaserBeam.visible = show_laser
	$LaserPivot/DamageArea/DamageCollision.disabled = not show_laser

func stop_attacking() -> void:
	attacking = false
	$LaserPivot/WarningLine.visible = false
	$LaserPivot/LaserBeam.visible = false
	$LaserPivot/DamageArea/DamageCollision.set_deferred("disabled", true)

func _on_self_destruct_area_body_entered(body: Node2D) -> void:
	if exploding:
		return
	if body.has_method("take_damage"):
		body.take_damage(2)
	drone_explode()

func shot_at() -> void:
	var found_player := get_tree().get_first_node_in_group("Player") as CharacterBody2D
	if found_player:
		player = found_player
		frenzy_time_left = frenzy_duration
		if not attacking:
			laser_attack()
	
	health -= 1
	$ShotAtSound.play()
	
	var tween := create_tween()
	tween.tween_property($AnimatedSprite2D.material, "shader_parameter/HitShaderMix", 0.0, 0.05)
	tween.tween_property($AnimatedSprite2D.material, "shader_parameter/HitShaderMix", 1.0, 0.1)
	
	if health <= 0:
		drone_explode()

func explode_nearby_drones() -> void:
	for drone in get_tree().get_nodes_in_group("Drones"):
		if drone != self and global_position.distance_to(drone.global_position) <= blast_radius:
			if drone.has_method("drone_explode"):
				drone.drone_explode()

func drone_explode() -> void:
	if exploding:
		return
	
	exploding = true
	stop_attacking()
	speed = 0.0
	velocity = Vector2.ZERO
	$DroneCollisionArea.set_deferred("disabled", true)
	$SelfDestructArea/SelfDestructCollision.set_deferred("disabled", true)
	$ScanPivot/ScanningLight.visible = false
	$AnimatedSprite2D.visible = false
	$ExplosionAnimation.play("explode")
	$ExplosionSound.play()
	explode_nearby_drones()

func _on_explosion_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"explode":
		queue_free()
